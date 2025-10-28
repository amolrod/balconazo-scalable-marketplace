# 🎯 SIGUIENTES PASOS - PROYECTO BALCONAZO

## ✅ ESTADO ACTUAL (28 Octubre 2025)

### Lo que está FUNCIONANDO al 100%:

1. ✅ **Catalog Microservice** (puerto 8085)
   - Gestión de usuarios (hosts y guests)
   - Gestión de espacios (CRUD completo)
   - Gestión de disponibilidad
   - Publicación de eventos a Kafka

2. ✅ **Booking Microservice** (puerto 8082)
   - Creación de reservas
   - Confirmación con payment intent
   - Cancelación de reservas
   - Sistema de reviews
   - Patrón Outbox implementado
   - Scheduler publicando eventos cada 5s

3. ✅ **Infraestructura**
   - PostgreSQL: catalog_db y booking_db
   - Kafka en modo KRaft
   - Redis para cache/locks
   - Scripts de inicio automatizados

4. ✅ **Prueba E2E exitosa**
   - Usuario host creado
   - Usuario guest creado
   - Espacio creado
   - Reserva creada
   - Evento publicado en Kafka

---

## 🎯 SIGUIENTE PASO INMEDIATO: SEARCH & PRICING MICROSERVICE

### ¿Por qué es el siguiente?

El Search & Pricing Microservice es **el núcleo funcional del marketplace**:
- Permite a los usuarios **buscar espacios** cerca de su ubicación
- Calcula **precios dinámicos** basados en demanda y otros factores
- Consume los eventos de Catalog y Booking para mantener un **read-model optimizado**
- Es **esencial para el MVP** - sin él, el marketplace no es funcional para usuarios finales

---

## 📋 PLAN DE IMPLEMENTACIÓN - SEARCH MICROSERVICE

### FASE 1: Setup inicial (Día 1)

#### 1.1 Crear estructura del proyecto

```bash
cd /Users/angel/Desktop/BalconazoApp/search_microservice

# Crear estructura de paquetes
mkdir -p src/main/java/com/balconazo/search_microservice/{entity,repository,service,controller,dto,mapper,kafka,config,constants}
mkdir -p src/main/resources
mkdir -p src/test/java/com/balconazo/search_microservice
```

#### 1.2 Crear pom.xml

Dependencias necesarias:
- Spring Boot Web
- Spring Data JPA
- PostgreSQL Driver
- **Hibernate Spatial** (para PostGIS)
- Spring Kafka
- Redis (Spring Data Redis)
- MapStruct
- Lombok
- Spring Boot Actuator

#### 1.3 Setup PostgreSQL con PostGIS

```bash
# Crear contenedor con PostGIS
docker run -d --name balconazo-pg-search \
  -p 5435:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=search_db \
  -e POSTGRES_USER=postgres \
  postgis/postgis:16-3.4-alpine

# Esperar 5 segundos
sleep 5

# Crear schema y habilitar PostGIS
docker exec balconazo-pg-search psql -U postgres -d search_db -c "
  CREATE SCHEMA IF NOT EXISTS search;
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
"
```

#### 1.4 Crear application.properties

```properties
server.port=8083
spring.application.name=search-microservice

# PostgreSQL
spring.datasource.url=jdbc:postgresql://localhost:5435/search_db
spring.datasource.username=postgres
spring.datasource.password=

# JPA/Hibernate
spring.jpa.database-platform=org.hibernate.spatial.dialect.postgis.PostgisDialect
spring.jpa.hibernate.ddl-auto=update
spring.jpa.properties.hibernate.default_schema=search
spring.jpa.show-sql=true

# Kafka
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=search-service
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=false

# Redis
spring.data.redis.host=localhost
spring.data.redis.port=6379

# Actuator
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
```

---

### FASE 2: Entidades del read-model (Día 2)

#### 2.1 SpaceProjection (proyección principal)

```java
@Entity
@Table(name = "spaces_projection", schema = "search")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SpaceProjection {
    @Id
    private UUID id;
    
    // Datos del espacio (desde Catalog)
    private UUID ownerId;
    private String ownerEmail;
    private String title;
    private String description;
    private String address;
    
    // Ubicación geoespacial
    @Column(columnDefinition = "geography(Point,4326)")
    private Point location;  // PostGIS Point
    
    // Características
    private Integer capacity;
    private BigDecimal areaSqm;
    private String status;
    
    @Type(JsonBinaryType.class)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> rules;
    
    @Column(columnDefinition = "text[]")
    private String[] amenities;
    
    // Pricing
    private Integer basePriceCents;
    private Integer currentPriceCents;  // precio dinámico
    
    // Datos agregados (desde Booking)
    private Double averageRating;
    private Integer totalReviews;
    private Integer totalBookings;
    private Integer completedBookings;
    private LocalDateTime lastBookingAt;
    
    // Metadatos
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

#### 2.2 ProcessedEvent (idempotencia)

```java
@Entity
@Table(name = "processed_events", schema = "search")
@Data
public class ProcessedEventEntity {
    @Id
    private UUID eventId;
    private UUID aggregateId;
    private String eventType;
    private LocalDateTime processedAt;
}
```

---

### FASE 3: Repositorio con búsqueda geoespacial (Día 3)

#### 3.1 SpaceProjectionRepository

```java
@Repository
public interface SpaceProjectionRepository extends JpaRepository<SpaceProjection, UUID> {
    
    /**
     * Búsqueda geoespacial por radio
     */
    @Query(value = """
        SELECT s.*, 
               ST_Distance(s.location::geography, 
                          ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000 as distance_km
        FROM search.spaces_projection s
        WHERE ST_DWithin(s.location::geography, 
                        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 
                        :radiusMeters)
          AND s.status = 'active'
          AND (:minCapacity IS NULL OR s.capacity >= :minCapacity)
          AND (:minPrice IS NULL OR s.current_price_cents >= :minPrice)
          AND (:maxPrice IS NULL OR s.current_price_cents <= :maxPrice)
        ORDER BY 
          CASE WHEN :sortBy = 'distance' THEN ST_Distance(s.location::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) END ASC,
          CASE WHEN :sortBy = 'price' THEN s.current_price_cents END ASC,
          CASE WHEN :sortBy = 'rating' THEN s.average_rating END DESC
        LIMIT :limit OFFSET :offset
        """, nativeQuery = true)
    List<Map<String, Object>> searchByLocation(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") int radiusMeters,
        @Param("minCapacity") Integer minCapacity,
        @Param("minPrice") Integer minPrice,
        @Param("maxPrice") Integer maxPrice,
        @Param("sortBy") String sortBy,
        @Param("limit") int limit,
        @Param("offset") int offset
    );
    
    /**
     * Buscar con filtro de amenidades
     */
    @Query(value = """
        SELECT s.* FROM search.spaces_projection s
        WHERE s.status = 'active'
          AND s.amenities @> CAST(:amenities AS text[])
        """, nativeQuery = true)
    List<SpaceProjection> findByAmenities(@Param("amenities") String[] amenities);
}
```

---

### FASE 4: Consumers de Kafka (Día 4-5)

#### 4.1 SpaceEventConsumer

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class SpaceEventConsumer {
    
    private final SpaceProjectionRepository spaceRepository;
    private final ProcessedEventRepository processedEventRepository;
    
    @KafkaListener(topics = "space-events-v1", groupId = "search-service")
    public void handleSpaceEvent(String eventJson, 
                                   @Header(KafkaHeaders.RECEIVED_KEY) String key) {
        log.info("Received space event: key={}", key);
        
        try {
            // Parsear evento genérico
            ObjectMapper mapper = new ObjectMapper();
            JsonNode eventNode = mapper.readTree(eventJson);
            
            String eventType = eventNode.get("eventType").asText();
            UUID eventId = UUID.fromString(eventNode.get("eventId").asText());
            
            // Verificar idempotencia
            if (processedEventRepository.existsById(eventId)) {
                log.info("Event {} already processed, skipping", eventId);
                return;
            }
            
            // Procesar según tipo
            switch (eventType) {
                case "SpaceCreatedEvent" -> handleSpaceCreated(eventNode);
                case "SpaceUpdatedEvent" -> handleSpaceUpdated(eventNode);
                case "SpaceDeactivatedEvent" -> handleSpaceDeactivated(eventNode);
                default -> log.warn("Unknown event type: {}", eventType);
            }
            
            // Marcar como procesado
            ProcessedEventEntity processed = new ProcessedEventEntity();
            processed.setEventId(eventId);
            processed.setAggregateId(UUID.fromString(eventNode.get("spaceId").asText()));
            processed.setEventType(eventType);
            processed.setProcessedAt(LocalDateTime.now());
            processedEventRepository.save(processed);
            
        } catch (Exception e) {
            log.error("Error processing space event", e);
            throw new RuntimeException(e);  // Retry por Kafka
        }
    }
    
    private void handleSpaceCreated(JsonNode event) {
        SpaceProjection projection = new SpaceProjection();
        projection.setId(UUID.fromString(event.get("spaceId").asText()));
        projection.setOwnerId(UUID.fromString(event.get("ownerId").asText()));
        projection.setTitle(event.get("title").asText());
        projection.setDescription(event.get("description").asText());
        projection.setAddress(event.get("address").asText());
        
        // Crear Point de PostGIS
        GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
        Point location = geometryFactory.createPoint(new Coordinate(
            event.get("lon").asDouble(),
            event.get("lat").asDouble()
        ));
        projection.setLocation(location);
        
        projection.setCapacity(event.get("capacity").asInt());
        projection.setAreaSqm(new BigDecimal(event.get("areaSqm").asText()));
        projection.setBasePriceCents(event.get("basePriceCents").asInt());
        projection.setCurrentPriceCents(event.get("basePriceCents").asInt());
        projection.setStatus(event.get("status").asText());
        
        // Amenities
        List<String> amenities = new ArrayList<>();
        event.get("amenities").forEach(a -> amenities.add(a.asText()));
        projection.setAmenities(amenities.toArray(new String[0]));
        
        // Inicializar métricas
        projection.setAverageRating(0.0);
        projection.setTotalReviews(0);
        projection.setTotalBookings(0);
        projection.setCreatedAt(LocalDateTime.now());
        
        spaceRepository.save(projection);
        log.info("Created space projection: {}", projection.getId());
    }
    
    private void handleSpaceUpdated(JsonNode event) {
        UUID spaceId = UUID.fromString(event.get("spaceId").asText());
        SpaceProjection projection = spaceRepository.findById(spaceId)
            .orElseThrow(() -> new RuntimeException("Space not found: " + spaceId));
        
        // Actualizar campos que cambiaron
        if (event.has("title")) projection.setTitle(event.get("title").asText());
        if (event.has("capacity")) projection.setCapacity(event.get("capacity").asInt());
        if (event.has("basePriceCents")) {
            projection.setBasePriceCents(event.get("basePriceCents").asInt());
            // Recalcular precio dinámico aquí
        }
        
        projection.setUpdatedAt(LocalDateTime.now());
        spaceRepository.save(projection);
        log.info("Updated space projection: {}", spaceId);
    }
    
    private void handleSpaceDeactivated(JsonNode event) {
        UUID spaceId = UUID.fromString(event.get("spaceId").asText());
        SpaceProjection projection = spaceRepository.findById(spaceId)
            .orElseThrow(() -> new RuntimeException("Space not found: " + spaceId));
        
        projection.setStatus("inactive");
        projection.setUpdatedAt(LocalDateTime.now());
        spaceRepository.save(projection);
        log.info("Deactivated space projection: {}", spaceId);
    }
}
```

#### 4.2 BookingEventConsumer

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class BookingEventConsumer {
    
    private final SpaceProjectionRepository spaceRepository;
    private final ProcessedEventRepository processedEventRepository;
    
    @KafkaListener(topics = "booking.events.v1", groupId = "search-service")
    public void handleBookingEvent(String eventJson) {
        // Similar estructura a SpaceEventConsumer
        // Actualizar totalBookings, completedBookings, lastBookingAt
    }
    
    @KafkaListener(topics = "review.events.v1", groupId = "search-service")
    public void handleReviewEvent(String eventJson) {
        // Recalcular averageRating y totalReviews
        // SELECT AVG(rating), COUNT(*) FROM booking.reviews WHERE space_id = ?
    }
}
```

---

### FASE 5: Service y Controller (Día 6)

#### 5.1 SearchService

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class SearchService {
    
    private final SpaceProjectionRepository repository;
    
    public SearchResultDTO searchSpaces(SearchRequestDTO request) {
        int radiusMeters = request.getRadiusKm() * 1000;
        
        List<Map<String, Object>> results = repository.searchByLocation(
            request.getLat(),
            request.getLon(),
            radiusMeters,
            request.getMinCapacity(),
            request.getMinPriceCents(),
            request.getMaxPriceCents(),
            request.getSortBy(),
            request.getPageSize(),
            request.getPage() * request.getPageSize()
        );
        
        // Mapear a DTOs
        // Incluir distance_km en la respuesta
        
        return SearchResultDTO.builder()
            .spaces(mappedSpaces)
            .totalResults(results.size())
            .page(request.getPage())
            .build();
    }
}
```

#### 5.2 SearchController

```http
GET /api/search/spaces
  ?lat=40.4168
  &lon=-3.7038
  &radius=5
  &minPrice=50
  &maxPrice=200
  &capacity=4
  &amenities=wifi,pool
  &sortBy=distance
  &page=0
  &size=20

GET /api/search/spaces/{id}
```

---

### FASE 6: Motor de Pricing Dinámico (Día 7-8)

#### 6.1 PricingService

```java
@Service
@Slf4j
public class PricingService {
    
    public int calculateDynamicPrice(UUID spaceId, LocalDateTime startDate) {
        SpaceProjection space = repository.findById(spaceId).orElseThrow();
        
        int basePrice = space.getBasePriceCents();
        
        // Factor demanda (reservas recientes en la zona)
        double demandFactor = calculateDemandFactor(space);
        
        // Factor estacionalidad (fin de semana, festivos)
        double seasonalityFactor = calculateSeasonalityFactor(startDate);
        
        // Factor rating
        double ratingFactor = calculateRatingFactor(space.getAverageRating());
        
        // Calcular precio final
        int dynamicPrice = (int) (basePrice 
            * (1 + demandFactor * 0.3)
            * (1 + seasonalityFactor * 0.2)
            * (1 + ratingFactor * 0.1));
        
        return dynamicPrice;
    }
}
```

---

## 📊 CRONOGRAMA ESTIMADO

| Día | Tarea | Duración |
|-----|-------|----------|
| 1 | Setup proyecto + PostgreSQL PostGIS | 2-3h |
| 2 | Entidades del read-model | 2-3h |
| 3 | Repository con queries geoespaciales | 3-4h |
| 4-5 | Consumers de Kafka (Space, Booking, Review) | 6-8h |
| 6 | Service y Controller de búsqueda | 3-4h |
| 7-8 | Motor de pricing dinámico | 4-6h |
| 9 | Pruebas E2E y optimización | 3-4h |
| 10 | Documentación y refinamiento | 2h |

**Total estimado:** 25-35 horas (~1.5-2 semanas)

---

## ✅ CRITERIOS DE ÉXITO

El Search Microservice estará **completado** cuando:

- [ ] PostgreSQL con PostGIS configurado
- [ ] Búsqueda geoespacial funciona (encuentra espacios en radio de X km)
- [ ] Filtros funcionan (precio, capacidad, amenidades)
- [ ] Consumers procesan eventos de Catalog correctamente
- [ ] Consumers procesan eventos de Booking correctamente
- [ ] Rating promedio se calcula automáticamente al crear reviews
- [ ] Motor de pricing calcula precios dinámicos
- [ ] Proyecciones se actualizan en tiempo real
- [ ] Health check incluye estado de consumers
- [ ] Prueba E2E: crear espacio → buscar → encontrarlo en resultados
- [ ] Latencia de búsqueda <200ms P95

---

## 🎯 DESPUÉS DE SEARCH MICROSERVICE

Una vez completado, el siguiente paso será:

### API Gateway (Sprint 4)
- Spring Cloud Gateway
- JWT authentication
- Rate limiting con Redis
- Unificación de endpoints

**Objetivo:** Tener un único punto de entrada HTTP para todos los microservicios.

---

## 📚 DOCUMENTACIÓN ACTUALIZADA

Archivos actualizados hoy (28 Oct 2025):

1. ✅ **ESTADO_ACTUAL.md** - Estado completo del proyecto
2. ✅ **HOJA_DE_RUTA.md** - Roadmap detallado
3. ✅ **README.md** - Documentación principal actualizada
4. ✅ **SIGUIENTES_PASOS.md** - Este documento

Archivos eliminados (obsoletos):
- ❌ KAFKA_SETUP.md
- ❌ SESION_COMPLETADA.md
- ❌ KAFKA_HEALTH_CHECK.md
- ❌ SIGUIENTE_PASO.md
- ❌ RESUMEN_SESION_BOOKING.md

---

## 🚀 COMANDOS RÁPIDOS

```bash
# Ver estado actual
docker ps --filter "name=balconazo"

# Health checks
curl http://localhost:8085/actuator/health | python3 -m json.tool
curl http://localhost:8082/actuator/health | python3 -m json.tool

# Prueba E2E completa
./test-e2e.sh

# Ver eventos en Kafka
docker exec balconazo-kafka kafka-topics --list --bootstrap-server localhost:9092
```

---

**Última actualización:** 28 de Octubre de 2025  
**Siguiente hito:** Search & Pricing Microservice  
**Progreso total:** 65% → ~85% al completar Search

