# 🗺️ HOJA DE RUTA - PROYECTO BALCONAZO

## 📊 PROGRESO ACTUAL: 65%

```
████████████████████████████████░░░░░░░░░░░░░░░░  65%

Completado:
✅ Infraestructura (PostgreSQL, Kafka, Redis)
✅ Catalog Microservice (100%)
✅ Booking Microservice (100%)
✅ Pruebas E2E exitosas

Pendiente:
⏭️ Search & Pricing Microservice
⏭️ API Gateway
⏭️ Frontend
⏭️ Despliegue en la nube
```

---

## 🎯 FASE ACTUAL: MVP FUNCIONAL (FASE 3 DE 5)

### ✅ FASE 1: INFRAESTRUCTURA (COMPLETADA)
- ✅ PostgreSQL con 2 bases de datos independientes
- ✅ Kafka en modo KRaft
- ✅ Redis para cache y locks
- ✅ Scripts de inicio automatizados

### ✅ FASE 2: MICROSERVICIOS CORE (COMPLETADA)
- ✅ Catalog Microservice (gestión de espacios y usuarios)
- ✅ Booking Microservice (gestión de reservas y reviews)
- ✅ Eventos Kafka entre servicios
- ✅ Patrón Outbox en Booking
- ✅ Health checks completos

### ⏭️ FASE 3: BÚSQUEDA Y PRICING (EN CURSO)
**Objetivo:** Motor de búsqueda geoespacial y pricing dinámico

**Duración estimada:** 1-2 semanas

**Componentes:**

#### 1. Search Microservice (Alta Prioridad)
**Puerto:** 8083  
**Base de datos:** search_db (puerto 5435)  
**Tecnologías:** PostgreSQL + PostGIS

**Funcionalidades:**
- ✅ Búsqueda geoespacial por ubicación (radio en km)
- ✅ Filtros: precio, capacidad, amenidades, rating
- ✅ Ordenamiento: distancia, precio, rating
- ✅ Paginación de resultados
- ✅ Proyección de datos desde Catalog y Booking

**Endpoints a implementar:**
```
GET /api/search/spaces
  ?lat=40.4168
  &lon=-3.7038
  &radius=5
  &minPrice=50
  &maxPrice=200
  &capacity=4
  &amenities=wifi,pool
  &sortBy=distance|price|rating
  &page=0
  &size=20

GET /api/search/spaces/{id}
  (detalle con rating promedio, reviews count, disponibilidad)
```

**Eventos a consumir:**
- `SpaceCreatedEvent` → Crear proyección en search_db
- `SpaceUpdatedEvent` → Actualizar proyección
- `SpaceDeactivatedEvent` → Marcar como inactivo
- `BookingConfirmedEvent` → Actualizar estadísticas de reservas
- `ReviewCreatedEvent` → Recalcular rating promedio

#### 2. Pricing Microservice (Alta Prioridad)
**Integrado en Search Service**  
**Tecnología:** Kafka Streams

**Motor de pricing dinámico:**
- Base: precio del host (`basePriceCents`)
- Factor demanda: reservas recientes en la zona
- Factor estacionalidad: fines de semana, festivos
- Factor rating: espacios con mejor rating → precio más alto
- Factor ubicación: zonas populares → precio más alto

**Fórmula:**
```
precioFinal = precioBase × (1 + demanda × 0.3) 
                        × (1 + estacionalidad × 0.2)
                        × (1 + (rating - 3) × 0.1)
                        × (1 + popularidadZona × 0.15)
```

**Ventanas de agregación:**
- 5 minutos para métricas en tiempo real
- 1 hora para tendencias
- 1 día para análisis histórico

**Endpoints:**
```
GET /api/pricing/spaces/{id}/price
  ?startDate=2025-12-31
  &endDate=2026-01-01
  (devuelve precio dinámico para esas fechas)

POST /api/pricing/recompute
  (forzar recálculo de todos los precios)
```

#### 3. Consumers de Kafka (Alta Prioridad)
**Responsable:** Search Microservice

**Consumers a implementar:**
```java
@KafkaListener(topics = "space-events-v1")
public void handleSpaceEvent(SpaceEvent event) {
    switch (event.getType()) {
        case CREATED -> createSpaceProjection(event);
        case UPDATED -> updateSpaceProjection(event);
        case DEACTIVATED -> deactivateSpaceProjection(event);
    }
}

@KafkaListener(topics = "booking.events.v1")
public void handleBookingEvent(BookingEvent event) {
    if (event instanceof BookingConfirmedEvent) {
        updateSpaceStatistics(event.getSpaceId());
        updateDemandMetrics(event);
    }
}

@KafkaListener(topics = "review.events.v1")
public void handleReviewEvent(ReviewCreatedEvent event) {
    recalculateAverageRating(event.getSpaceId());
    updateSearchProjection(event.getSpaceId());
}
```

**Características:**
- ✅ Procesamiento idempotente (tabla `processed_events`)
- ✅ Reintentos automáticos con backoff exponencial
- ✅ Dead Letter Topic para errores irrecuperables
- ✅ Actualización incremental de proyecciones

---

### ⏭️ FASE 4: API GATEWAY Y AUTH (SIGUIENTE)
**Objetivo:** Unificar endpoints y agregar autenticación

**Duración estimada:** 1-2 semanas

**Componentes:**

#### 1. API Gateway
**Puerto:** 8080  
**Tecnología:** Spring Cloud Gateway

**Funcionalidades:**
- ✅ Enrutamiento a microservicios
- ✅ Autenticación JWT
- ✅ Rate limiting global
- ✅ CORS configurado
- ✅ Circuit breaker
- ✅ Request/Response logging

**Rutas:**
```yaml
/api/catalog/**  → catalog-service:8085
/api/booking/**  → booking-service:8082
/api/search/**   → search-service:8083
```

#### 2. Autenticación JWT (Simplificada para MVP)
**Proveedor:** Keycloak (dev) / AWS Cognito (prod)

**Roles:**
- `guest`: puede buscar y reservar espacios
- `host`: puede crear espacios y gestionar disponibilidad
- `admin`: acceso completo

**Claims en JWT:**
```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "role": "host",
  "exp": 1640000000
}
```

**Endpoints públicos (sin auth):**
- `GET /api/search/**` (búsqueda pública)
- `GET /api/catalog/spaces/**` (ver espacios)
- `POST /api/catalog/users` (registro)

**Endpoints privados:**
- `POST /api/catalog/spaces` (solo hosts)
- `POST /api/booking/bookings` (solo guests autenticados)
- `POST /api/booking/reviews` (solo guests con booking completado)

#### 3. Rate Limiting con Redis
**Estrategia:**
- 100 requests/minuto por usuario
- 1000 requests/minuto global por IP
- 10 requests/segundo para búsquedas

**Implementación:**
```java
@RateLimiter(name = "search", fallbackMethod = "searchFallback")
public List<SpaceDTO> searchSpaces(...) { ... }
```

---

### ⏭️ FASE 5: FRONTEND Y DESPLIEGUE (FINAL)
**Objetivo:** Interfaz de usuario y producción

**Duración estimada:** 2-3 semanas

#### 1. Frontend Angular
**Puerto:** 4200  
**Framework:** Angular 20

**Páginas:**
- `/` - Landing page con búsqueda
- `/search` - Resultados de búsqueda
- `/spaces/{id}` - Detalle de espacio
- `/booking` - Proceso de reserva
- `/my-bookings` - Mis reservas (guest)
- `/my-spaces` - Mis espacios (host)
- `/host/create` - Crear espacio (host)

**Características:**
- ✅ Integración con Google Maps
- ✅ Calendario de disponibilidad
- ✅ Sistema de reviews
- ✅ Gestión de perfil
- ✅ Dashboard host/guest

#### 2. Despliegue en AWS
**Arquitectura:**
```
CloudFront
    ↓
ALB (Application Load Balancer)
    ↓
ECS/EKS (3 microservicios)
    ↓
RDS PostgreSQL (Multi-AZ)
    ↓
MSK (Managed Kafka)
    ↓
ElastiCache Redis
```

**Servicios AWS:**
- ✅ ECS Fargate para microservicios
- ✅ RDS PostgreSQL con Multi-AZ
- ✅ MSK para Kafka
- ✅ ElastiCache Redis
- ✅ S3 para imágenes de espacios
- ✅ CloudFront para CDN
- ✅ Route 53 para DNS
- ✅ Cognito para autenticación

**CI/CD:**
- ✅ GitHub Actions
- ✅ Docker images en ECR
- ✅ Terraform para IaC
- ✅ Monitoreo con CloudWatch

---

## 📅 CRONOGRAMA PROPUESTO

### Semana 1-2: Search & Pricing Microservice
- **Día 1-2:** Setup de search_db con PostGIS
- **Día 3-4:** Implementar búsqueda geoespacial
- **Día 5-6:** Implementar consumers de Kafka
- **Día 7-8:** Implementar motor de pricing
- **Día 9-10:** Pruebas y optimización

### Semana 3-4: API Gateway y Auth
- **Día 1-2:** Setup de Spring Cloud Gateway
- **Día 3-4:** Configurar rutas y CORS
- **Día 5-6:** Integrar Keycloak/Cognito
- **Día 7-8:** Implementar rate limiting con Redis
- **Día 9-10:** Pruebas de seguridad

### Semana 5-7: Frontend Angular
- **Semana 5:** Landing, búsqueda, listado
- **Semana 6:** Detalle de espacio, reserva, perfil
- **Semana 7:** Dashboard host, gestión de espacios

### Semana 8-9: Despliegue y Producción
- **Semana 8:** Setup AWS, Terraform, Docker
- **Semana 9:** CI/CD, monitoreo, pruebas de carga

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

### 1. Crear Search Microservice (SIGUIENTE)
```bash
# Crear estructura del proyecto
cd /Users/angel/Desktop/BalconazoApp
mkdir -p search_microservice/src/main/java/com/balconazo/search_microservice
cd search_microservice

# Crear pom.xml con dependencias
# - Spring Boot Web
# - Spring Data JPA
# - PostgreSQL + PostGIS
# - Spring Kafka
# - Redis
# - MapStruct
# - Lombok
```

### 2. Setup PostgreSQL con PostGIS
```bash
# Crear contenedor search_db
docker run -d --name balconazo-pg-search \
  -p 5435:5432 \
  -e POSTGRES_DB=search_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgis/postgis:16-3.4-alpine

# Crear schema y extensiones
docker exec balconazo-pg-search psql -U postgres -d search_db -c "
  CREATE SCHEMA IF NOT EXISTS search;
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- para búsqueda de texto
"
```

### 3. Implementar entidades del read-model
```java
@Entity
@Table(name = "spaces_projection", schema = "search")
public class SpaceProjection {
    @Id private UUID id;
    private UUID ownerId;
    private String ownerEmail;
    private String title;
    private String description;
    
    @Column(columnDefinition = "geography(Point,4326)")
    private Point location;  // PostGIS
    
    private Integer capacity;
    private BigDecimal areaSqm;
    private Integer basePriceCents;
    private Integer currentPriceCents;  // precio dinámico
    private String[] amenities;
    private String status;
    
    // Datos agregados de Booking
    private Double averageRating;
    private Integer totalReviews;
    private Integer totalBookings;
    private LocalDateTime lastBookingAt;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

### 4. Implementar búsqueda geoespacial
```java
@Repository
public interface SpaceProjectionRepository extends JpaRepository<SpaceProjection, UUID> {
    
    @Query(value = """
        SELECT s.*, 
               ST_Distance(s.location::geography, 
                          ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000 as distance_km
        FROM search.spaces_projection s
        WHERE ST_DWithin(s.location::geography, 
                        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 
                        :radiusMeters)
          AND s.status = 'active'
          AND s.capacity >= :minCapacity
          AND s.current_price_cents BETWEEN :minPrice AND :maxPrice
        ORDER BY distance_km ASC
        LIMIT :limit OFFSET :offset
        """, nativeQuery = true)
    List<SpaceProjection> searchByLocation(
        double lat, double lon, int radiusMeters,
        int minCapacity, int minPrice, int maxPrice,
        int limit, int offset
    );
}
```

### 5. Implementar consumers de Kafka
```java
@Service
@Slf4j
public class SpaceEventConsumer {
    
    @KafkaListener(topics = "space-events-v1", groupId = "search-service")
    public void handleSpaceEvent(String eventJson) {
        // Parsear evento
        // Actualizar proyección
        // Marcar como procesado (idempotencia)
    }
}
```

---

## ✅ CRITERIOS DE ÉXITO POR FASE

### Fase 3 (Search & Pricing) - COMPLETADA CUANDO:
- [ ] Búsqueda geoespacial funciona (latencia <200ms P95)
- [ ] Motor de pricing calcula precios dinámicos
- [ ] Consumers procesan eventos de Catalog y Booking
- [ ] Proyecciones en search_db actualizadas en tiempo real
- [ ] Health check incluye estado de consumers
- [ ] Prueba E2E: buscar espacios cerca de una ubicación

### Fase 4 (API Gateway) - COMPLETADA CUANDO:
- [ ] Gateway enruta correctamente a los 3 microservicios
- [ ] JWT authentication funciona
- [ ] Rate limiting bloquea exceso de requests
- [ ] CORS configurado para frontend
- [ ] Prueba E2E: flujo completo con autenticación

### Fase 5 (Frontend) - COMPLETADA CUANDO:
- [ ] Usuario puede buscar espacios en mapa
- [ ] Usuario puede crear reserva
- [ ] Host puede crear espacios
- [ ] Dashboard funcional para host y guest
- [ ] Prueba E2E: flujo completo desde UI

---

## 📞 RECURSOS Y REFERENCIAS

**Documentación técnica:**
- `/Users/angel/Desktop/BalconazoApp/ESTADO_ACTUAL.md` (este documento)
- `/Users/angel/Desktop/BalconazoApp/documentacion.md` (especificación original)
- `/Users/angel/Desktop/BalconazoApp/GUIA_SCRIPTS.md` (scripts de arranque)

**Scripts disponibles:**
- `./test-e2e.sh` - Prueba end-to-end completa
- `./start-infrastructure.sh` - Levantar toda la infraestructura
- `./start-catalog.sh` - Iniciar Catalog Service
- `./start-booking.sh` - Iniciar Booking Service

**Health checks:**
- Catalog: http://localhost:8085/actuator/health
- Booking: http://localhost:8082/actuator/health

**Bases de datos:**
- catalog_db: localhost:5433
- booking_db: localhost:5434
- search_db: localhost:5435 (pendiente)

---

## 🎉 CONCLUSIÓN

**Estado actual:** Sistema funcional con 2 microservicios principales completados y probados end-to-end.

**Siguiente hito:** Implementar Search & Pricing Microservice para completar el MVP.

**Objetivo final:** Marketplace completamente funcional con búsqueda geoespacial, pricing dinámico, autenticación, frontend y despliegue en producción.

**Progreso:** 65% → 100% en ~4-6 semanas

---

**Última actualización:** 28 de Octubre de 2025  
**Próxima revisión:** Al completar Search & Pricing Microservice

