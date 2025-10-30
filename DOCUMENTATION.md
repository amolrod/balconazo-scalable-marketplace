# 📖 DOCUMENTATION.md - Documentación Técnica Completa

**Proyecto:** BalconazoApp  
**Versión Backend:** 1.0.0  
**Fecha:** Octubre 2025

Este documento proporciona una visión técnica detallada de la arquitectura, diseño y funcionamiento del sistema.

---

## 📋 Tabla de Contenidos

1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Microservicios](#microservicios)
3. [Modelo de Datos](#modelo-de-datos)
4. [Autenticación y Seguridad](#autenticación-y-seguridad)
5. [Flujos de Negocio](#flujos-de-negocio)
6. [Comunicación Entre Servicios](#comunicación-entre-servicios)
7. [Manejo de Errores](#manejo-de-errores)
8. [Endpoints API](#endpoints-api)
9. [Tests Automatizados](#tests-automatizados)
10. [Buenas Prácticas Implementadas](#buenas-prácticas-implementadas)

---

## 🏗️ Arquitectura del Sistema

### Patrón Arquitectónico

**BalconazoApp** implementa una **arquitectura de microservicios** basada en los principios de:

- **Domain-Driven Design (DDD)**: Cada microservicio tiene su dominio claramente definido
- **Event-Driven Architecture**: Comunicación asíncrona vía Kafka
- **API Gateway Pattern**: Punto de entrada único
- **Service Discovery**: Registro dinámico con Eureka
- **Circuit Breaker**: Resiliencia con Resilience4j
- **CQRS parcial**: Separación de lectura (Search) y escritura (Catalog)

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTE HTTP                             │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                      API GATEWAY (8080)                          │
│  - Rate Limiting                                                 │
│  - Authentication Check                                          │
│  - Routing                                                       │
│  - Circuit Breaker                                               │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                   ┌───────────┴──────────┐
                   │                      │
        ┌──────────▼────────┐  ┌─────────▼────────┐
        │  EUREKA SERVER    │  │   REDIS CACHE    │
        │    (8761)         │  │     (6379)       │
        └───────────────────┘  └──────────────────┘
                   │
        ┌──────────┴─────────────┬──────────────────┐
        │                        │                  │
┌───────▼────────┐   ┌──────────▼─────┐   ┌───────▼────────┐
│  AUTH SERVICE  │   │ CATALOG SERVICE│   │ BOOKING SERVICE│
│    (8084)      │   │     (8085)     │   │     (8082)     │
│                │   │                │   │                │
│  - JWT Auth    │   │  - Spaces CRUD │   │  - Bookings    │
│  - Users       │   │  - Availability│   │  - Reviews     │
└────────┬───────┘   └────────┬───────┘   └────────┬───────┘
         │                    │                     │
    ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
    │  MySQL  │          │  Postgre│          │  Postgre│
    │  (3307) │          │   SQL   │          │   SQL   │
    └─────────┘          │  (5433) │          │  (5434) │
                         └─────────┘          └─────────┘
                               │
                   ┌───────────▼──────────┐
                   │   KAFKA (9092)       │
                   │  - Space Events      │
                   │  - Booking Events    │
                   └───────────┬──────────┘
                               │
                   ┌───────────▼──────────┐
                   │  SEARCH SERVICE      │
                   │     (8083)           │
                   │                      │
                   │  - Geo Search        │
                   │  - Event Consumer    │
                   └───────────┬──────────┘
                               │
                          ┌────▼────┐
                          │ Postgre │
                          │  +GIS   │
                          │ (5435)  │
                          └─────────┘
```

---

## 🔧 Microservicios

### 1. API Gateway (Puerto 8080)

**Responsabilidades:**
- Punto de entrada único al sistema
- Enrutamiento de peticiones a microservicios
- Validación básica de JWT
- Rate limiting (5 req/s por IP)
- Circuit breaker para resilencia
- CORS y headers de seguridad

**Tecnologías:**
- Spring Cloud Gateway
- Spring Security (OAuth2 Resource Server)
- Resilience4j (Circuit Breaker)
- Redis (Rate Limiter)

**Rutas Configuradas:**

| Ruta | Destino | Filtros |
|------|---------|---------|
| `/api/auth/**` | auth-service | Público |
| `/api/catalog/**` | catalog-service | JWT requerido |
| `/api/booking/**` | booking-service | JWT requerido |
| `/api/search/**` | search-service | Público |

**Configuración de Circuit Breaker:**

```yaml
resilience4j:
  circuitbreaker:
    configs:
      default:
        slidingWindowSize: 10
        failureRateThreshold: 50
        waitDurationInOpenState: 10000
        permittedNumberOfCallsInHalfOpenState: 3
```

---

### 2. Eureka Server (Puerto 8761)

**Responsabilidades:**
- Service Discovery
- Health monitoring
- Load balancing side

**Dashboard:** http://localhost:8761

**Servicios registrados:**
- api-gateway
- auth-service
- catalog-service
- booking-service
- search-service

---

### 3. Auth Service (Puerto 8084)

**Responsabilidades:**
- Registro de usuarios
- Autenticación con JWT
- Gestión de roles (HOST, GUEST, ADMIN)
- Refresh tokens
- Perfil de usuario

**Base de Datos:** MySQL (`auth_db`)

**Entidades:**
- `User` (id, email, passwordHash, role, status, trustScore)

**Endpoints Principales:**

```http
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
GET    /api/auth/me
PUT    /api/auth/profile
```

**JWT Claims:**
```json
{
  "sub": "userId",
  "email": "user@example.com",
  "role": "HOST",
  "iat": 1234567890,
  "exp": 1234567890
}
```

**Algoritmo:** HS512 (symmetric)  
**Secret:** Variable de entorno `JWT_SECRET`  
**Expiración:** 24 horas

---

### 4. Catalog Service (Puerto 8085)

**Responsabilidades:**
- CRUD de espacios
- Gestión de disponibilidad
- Activación/desactivación de espacios
- Caché de espacios con Redis

**Base de Datos:** PostgreSQL (`catalog_db`)

**Entidades:**
- `Space` (id, title, description, ownerId, lat, lon, capacity, price, amenities, status)
- `AvailabilitySlot` (id, spaceId, startTime, endTime, isAvailable)
- `User` (replica para integridad referencial)

**Endpoints Principales:**

```http
POST   /api/catalog/spaces
GET    /api/catalog/spaces
GET    /api/catalog/spaces/{id}
PUT    /api/catalog/spaces/{id}
POST   /api/catalog/spaces/{id}/activate
GET    /api/catalog/spaces/owner/{ownerId}
GET    /api/catalog/spaces/active
```

**Eventos Kafka Publicados:**
- `SpaceCreatedEvent`
- `SpaceUpdatedEvent`
- `SpaceActivatedEvent`

**Estrategia de Caché:**
- Key: `space:{id}`
- TTL: 5 minutos
- Invalidación: al actualizar/eliminar

---

### 5. Booking Service (Puerto 8082)

**Responsabilidades:**
- Gestión de reservas
- Transiciones de estado (pending → confirmed → completed)
- Cancelaciones con políticas
- Sistema de reseñas
- Validaciones de negocio

**Base de Datos:** PostgreSQL (`booking_db`)

**Entidades:**
- `Booking` (id, spaceId, guestId, startTs, endTs, numGuests, totalPriceCents, status, paymentStatus)
- `Review` (id, bookingId, spaceId, guestId, rating, comment)
- `OutboxEvent` (para patrón Outbox con Kafka)

**Estados de Booking:**

```
pending ──(confirm)──> confirmed ──(complete)──> completed
   │                       │
   └───(cancel)────────────┴────────> cancelled
```

**Endpoints Principales:**

```http
POST   /api/booking/bookings
GET    /api/booking/bookings/{id}
GET    /api/booking/bookings/guest/{guestId}
GET    /api/booking/bookings/space/{spaceId}
POST   /api/booking/bookings/{id}/confirm
POST   /api/booking/bookings/{id}/complete
POST   /api/booking/bookings/{id}/cancel

POST   /api/booking/reviews
GET    /api/booking/reviews/{id}
GET    /api/booking/reviews/space/{spaceId}
GET    /api/booking/reviews/reviewer/{reviewerId}
```

**Validaciones de Negocio:**
- Duración mínima: 1 hora
- Antelación mínima: 0 horas (inmediata)
- Cancelación con 1 hora de antelación
- Review solo en bookings completados
- No overlapping bookings

**Eventos Kafka Publicados:**
- `BookingCreatedEvent`
- `BookingConfirmedEvent`
- `BookingCancelledEvent`

---

### 6. Search Service (Puerto 8083)

**Responsabilidades:**
- Búsqueda geoespacial de espacios
- Indexación de espacios desde Catalog
- Filtros avanzados (precio, capacidad, rating)
- Ordenamiento por distancia/precio/rating

**Base de Datos:** PostgreSQL + PostGIS (`search_db`)

**Entidades:**
- `SpaceProjection` (vista materializada/tabla optimizada para lectura)
  - Incluye: geo (POINT con índice espacial), avg_rating, total_reviews

**Endpoints Principales:**

```http
GET    /api/search/spaces?lat={lat}&lon={lon}&radius={km}
POST   /api/search/spaces/filter
GET    /api/search/spaces/{id}
```

**Ejemplo de Query Geoespacial:**

```sql
SELECT 
    s.*,
    ST_Distance(
        s.geo::geography,
        ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography
    ) / 1000 as distance_km
FROM search.spaces_projection s
WHERE ST_DWithin(
    s.geo::geography,
    ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography,
    ?
)
AND s.status = 'active'
ORDER BY distance_km ASC
LIMIT ? OFFSET ?
```

**Eventos Kafka Consumidos:**
- `SpaceCreatedEvent` → Crear proyección
- `SpaceUpdatedEvent` → Actualizar proyección
- `ReviewCreatedEvent` → Recalcular rating promedio

---

## 💾 Modelo de Datos

### Diagrama Entidad-Relación (Simplificado)

```
┌─────────────┐         ┌──────────────┐
│    USER     │         │    SPACE     │
├─────────────┤         ├──────────────┤
│ id (PK)     │◄────────│ owner_id(FK) │
│ email       │         │ title        │
│ password    │         │ description  │
│ role        │         │ lat, lon     │
│ status      │         │ capacity     │
└─────────────┘         │ price        │
                        │ status       │
                        └──────┬───────┘
                               │
                               │ 1:N
                               │
                        ┌──────▼───────┐
                        │   BOOKING    │
                        ├──────────────┤
                        │ id (PK)      │
                        │ space_id(FK) │
                        │ guest_id(FK) │
                        │ start_ts     │
                        │ end_ts       │
                        │ status       │
                        │ payment_sts  │
                        └──────┬───────┘
                               │
                               │ 1:1
                               │
                        ┌──────▼───────┐
                        │    REVIEW    │
                        ├──────────────┤
                        │ id (PK)      │
                        │ booking_id   │
                        │ rating       │
                        │ comment      │
                        └──────────────┘
```

### Relaciones Clave

1. **User → Space** (1:N): Un host puede tener múltiples espacios
2. **Space → Booking** (1:N): Un espacio puede tener múltiples reservas
3. **User → Booking** (1:N): Un guest puede tener múltiples reservas
4. **Booking → Review** (1:1): Una reserva puede tener una reseña

### Índices Importantes

**Catalog Service:**
```sql
CREATE INDEX idx_space_owner ON catalog.spaces(owner_id);
CREATE INDEX idx_space_status ON catalog.spaces(status);
```

**Booking Service:**
```sql
CREATE INDEX idx_booking_guest ON booking.bookings(guest_id);
CREATE INDEX idx_booking_space ON booking.bookings(space_id);
CREATE INDEX idx_booking_dates ON booking.bookings(start_ts, end_ts);
```

**Search Service:**
```sql
CREATE INDEX idx_space_geo ON search.spaces_projection USING GIST(geo);
CREATE INDEX idx_space_status ON search.spaces_projection(status);
```

---

## 🔐 Autenticación y Seguridad

### Flujo de Autenticación

```
1. Cliente → POST /api/auth/login {email, password}
2. Auth Service → Valida credenciales (BCrypt)
3. Auth Service → Genera JWT (HS512)
4. Cliente ← {accessToken, refreshToken, user}

5. Cliente → GET /api/catalog/spaces (Authorization: Bearer {token})
6. API Gateway → Valida JWT (firma + expiración)
7. API Gateway → Extrae claims (userId, role)
8. API Gateway → Forward request con headers:
   - X-User-Id: {userId}
   - X-User-Role: {role}
9. Catalog Service → Usa headers para lógica de negocio
10. Cliente ← Respuesta
```

### Configuración de Seguridad

**API Gateway (WebFlux):**

```java
@Bean
SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
    return http
        .csrf(ServerHttpSecurity.CsrfSpec::disable)
        .authorizeExchange(ex -> ex
            .pathMatchers("/", "/actuator/**", "/api/auth/**", "/api/search/**").permitAll()
            .anyExchange().authenticated()
        )
        .oauth2ResourceServer(oauth -> oauth.jwt())
        .build();
}

@Bean
ReactiveJwtDecoder jwtDecoder() {
    SecretKey key = new SecretKeySpec(
        jwtSecret.getBytes(StandardCharsets.UTF_8), 
        "HmacSHA512"
    );
    return NimbusReactiveJwtDecoder.withSecretKey(key)
        .macAlgorithm(MacAlgorithm.HS512)
        .build();
}
```

**Microservicios (MVC):**

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) {
    return http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/actuator/**").permitAll()
            .anyRequest().authenticated()
        )
        .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
        .build();
}
```

### Roles y Permisos

| Rol | Permisos |
|-----|----------|
| **GUEST** | Buscar espacios, crear reservas, dejar reseñas |
| **HOST** | Todo lo de GUEST + crear/gestionar espacios |
| **ADMIN** | Acceso completo (futuro) |

### Validación en Servicios

```java
// Ejemplo en Catalog Service
public SpaceDTO createSpace(CreateSpaceDTO dto) {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    boolean isHost = auth.getAuthorities().stream()
        .anyMatch(a -> a.getAuthority().equals("ROLE_HOST"));
    
    if (!isHost) {
        throw new ForbiddenException("Solo hosts pueden crear espacios");
    }
    
    // ... lógica
}
```

---

## 🔄 Flujos de Negocio

### 1. Flujo de Registro y Login

```
Usuario → Register → Auth Service
                     ↓
                 Hash password (BCrypt)
                     ↓
                 Guardar en MySQL
                     ↓
                 Login con credenciales
                     ↓
                 Generar JWT
                     ↓
                 Retornar {accessToken, refreshToken}
```

### 2. Flujo de Creación de Espacio

```
Host → POST /api/catalog/spaces (JWT)
       ↓
API Gateway → Valida JWT
       ↓
Catalog Service → Valida rol HOST
       ↓
Guarda en PostgreSQL (status: draft)
       ↓
Publica SpaceCreatedEvent a Kafka
       ↓
Search Service → Consume evento
       ↓
Indexa en spaces_projection
       ↓
Host ← Space creado
```

### 3. Flujo de Búsqueda

```
Usuario → GET /api/search/spaces?lat=X&lon=Y&radius=Z
          ↓
API Gateway → Forward (público, no JWT)
          ↓
Search Service → Query geoespacial con PostGIS
          ↓
Calcula distancias, aplica filtros
          ↓
Usuario ← Lista de espacios cercanos
```

### 4. Flujo Completo de Reserva

```
Guest → Buscar espacio
        ↓
      Ver detalle
        ↓
      Crear reserva (pending)
        ↓
Booking Service → Validar disponibilidad
        ↓
      Calcular precio
        ↓
      Guardar en BD (status: pending)
        ↓
Guest ← bookingId
        ↓
      Pagar (simulado)
        ↓
      Confirmar reserva (paymentIntentId)
        ↓
Booking Service → Cambiar status a confirmed
        ↓
      Publicar BookingConfirmedEvent
        ↓
      (Futuro: Enviar email confirmación)
        ↓
Guest ← Reserva confirmada
        ↓
      [Espera a fecha de reserva]
        ↓
      Completar reserva
        ↓
Booking Service → Cambiar status a completed
        ↓
Guest ← Puede dejar reseña
        ↓
      Crear review (rating + comment)
        ↓
Booking Service → Validar que booking esté completed
        ↓
      Guardar review
        ↓
      Publicar ReviewCreatedEvent
        ↓
Search Service → Recalcular avg_rating del espacio
        ↓
Guest ← Review creada
```

---

## 🔗 Comunicación Entre Servicios

### Síncrona (HTTP REST)

**Uso:** Operaciones CRUD, consultas en tiempo real

**Vía:** API Gateway → Eureka → Microservicio

**Ejemplo:**
```java
// No hay llamadas HTTP directas entre microservicios
// Todo pasa por API Gateway
```

### Asíncrona (Kafka)

**Uso:** Propagación de eventos, consistencia eventual

**Topics:**
- `space.events` (SpaceCreated, SpaceUpdated)
- `booking.events` (BookingCreated, BookingConfirmed, BookingCancelled)
- `review.events` (ReviewCreated)

**Patrón Outbox:**

```java
@Transactional
public BookingDTO confirmBooking(UUID id, String paymentIntentId) {
    // 1. Actualizar booking
    booking.setStatus(BookingStatus.confirmed);
    bookingRepository.save(booking);
    
    // 2. Guardar evento en outbox (misma transacción)
    OutboxEvent event = OutboxEvent.builder()
        .aggregateId(id)
        .eventType("BookingConfirmed")
        .payload(toJson(booking))
        .build();
    outboxRepository.save(event);
    
    // 3. Scheduled job envía eventos a Kafka
    return toDTO(booking);
}
```

**Consumer en Search Service:**

```java
@KafkaListener(topics = "space.events", groupId = "search-service")
public void handleSpaceEvent(String eventJson) {
    SpaceCreatedEvent event = fromJson(eventJson);
    
    SpaceProjection projection = SpaceProjection.builder()
        .spaceId(event.getSpaceId())
        .title(event.getTitle())
        .geo(createPoint(event.getLat(), event.getLon()))
        .build();
    
    repository.save(projection);
}
```

---

## ⚠️ Manejo de Errores

### Jerarquía de Excepciones

```
RuntimeException
├── BusinessValidationException (400)
│   ├── BookingValidationException
│   └── SpaceValidationException
├── ResourceNotFoundException (404)
│   ├── BookingNotFoundException
│   └── SpaceNotFoundException
├── BookingStateException (400)
└── ForbiddenException (403)
```

### GlobalExceptionHandler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(BookingNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(BookingNotFoundException ex) {
        return ResponseEntity.status(404).body(
            ErrorResponse.builder()
                .status(404)
                .error("Not Found")
                .message(ex.getMessage())
                .timestamp(LocalDateTime.now())
                .build()
        );
    }
    
    @ExceptionHandler(BookingStateException.class)
    public ResponseEntity<ErrorResponse> handleInvalidState(BookingStateException ex) {
        return ResponseEntity.status(400).body(
            ErrorResponse.builder()
                .status(400)
                .error("Invalid State")
                .message(String.format(
                    "Estado inválido: actual='%s', requerido='%s'",
                    ex.getCurrentState(),
                    ex.getRequiredState()
                ))
                .timestamp(LocalDateTime.now())
                .build()
        );
    }
}
```

### Respuestas de Error Estándar

```json
{
  "timestamp": "2025-10-30T12:30:45",
  "status": 400,
  "error": "Bad Request",
  "message": "La reserva debe ser de al menos 1 hora"
}
```

---

## 🌐 Endpoints API

Ver documentación completa en: **[POSTMAN_ENDPOINTS.md](POSTMAN_ENDPOINTS.md)**

### Resumen por Servicio

**Auth Service (18 endpoints)**
- Registro, login, refresh token
- Gestión de perfil

**Catalog Service (12 endpoints)**
- CRUD de espacios
- Gestión de disponibilidad

**Booking Service (15 endpoints)**
- Gestión de reservas
- Sistema de reseñas

**Search Service (3 endpoints)**
- Búsqueda geoespacial
- Filtros avanzados

**Total:** 48 endpoints funcionales

---

## 🧪 Tests Automatizados

### Tests E2E (test-e2e-completo.sh)

**Suite incluye:**

1. **Health Checks** (6 tests)
   - Verifica que todos los servicios respondan 200

2. **Registro en Eureka** (5 tests)
   - Valida que servicios estén registrados

3. **Autenticación** (2 tests)
   - Registro de usuario
   - Login y obtención de JWT

4. **Catalog Service** (3 tests)
   - Crear espacio
   - Listar espacios
   - Obtener por ID

5. **Search Service** (2 tests)
   - Búsqueda geoespacial
   - Obtener espacio por ID

6. **Booking Service** (5 tests)
   - Crear reserva
   - Obtener reservas del guest
   - Confirmar reserva
   - Completar reserva
   - Crear review

7. **Seguridad** (2 tests)
   - Acceso sin JWT (debe fallar)
   - Acceso público

8. **Eventos Kafka** (1 test)
   - Verificar propagación de eventos

9. **Actuator** (3 tests)
   - Health endpoints
   - Métricas
   - Gateway routes

**Ejecutar:**
```bash
./test-e2e-completo.sh
```

**Resultado esperado:**
```
Tests ejecutados: 29
Tests exitosos: 29 ✅
Tests fallidos: 0 ❌
Tasa de éxito: 100%
```

### Tests Unitarios (Futuro)

```bash
# Por servicio
cd catalog_microservice
mvn test

# Coverage report
mvn jacoco:report
open target/site/jacoco/index.html
```

---

## ✨ Buenas Prácticas Implementadas

### 1. Arquitectura y Diseño

✅ **Separation of Concerns**: Cada microservicio tiene responsabilidades claras  
✅ **DDD**: Entidades, Value Objects, Repositories bien definidos  
✅ **SOLID Principles**: Código extensible y mantenible  
✅ **Clean Architecture**: Capas bien separadas (Controller → Service → Repository)  

### 2. Código

✅ **DTO Pattern**: Separación entre modelos de dominio y API  
✅ **Mapeo automático**: MapStruct para conversiones  
✅ **Lombok**: Reducción de boilerplate  
✅ **Exception Handling**: Excepciones específicas por dominio  
✅ **Logging**: SLF4J con logs estructurados  

### 3. Seguridad

✅ **JWT Stateless**: No sesiones en servidor  
✅ **Password Hashing**: BCrypt con salt  
✅ **HTTPS Ready**: Configurado para SSL  
✅ **CORS**: Configurado en API Gateway  
✅ **Rate Limiting**: Protección contra abuso  

### 4. Performance

✅ **Caché distribuida**: Redis para datos frecuentes  
✅ **Índices de BD**: Queries optimizadas  
✅ **Connection Pooling**: HikariCP configurado  
✅ **Lazy Loading**: JPA fetch estratégico  

### 5. Resiliencia

✅ **Circuit Breaker**: Resilience4j en Gateway  
✅ **Retry Logic**: Reintentos automáticos  
✅ **Timeouts**: Configurados en todos los servicios  
✅ **Graceful Shutdown**: Spring Actuator  

### 6. Observabilidad

✅ **Health Checks**: `/actuator/health` en todos los servicios  
✅ **Metrics**: Prometheus-ready con Micrometer  
✅ **Logs Estructurados**: JSON logging  
✅ **Correlation IDs**: Trazabilidad de requests  

### 7. DevOps

✅ **Infrastructure as Code**: Docker Compose  
✅ **Scripts Automatizados**: Start/stop/recompile  
✅ **Environment Variables**: Configuración externa  
✅ **Health Checks en Docker**: Restart automático  

---

## 📊 Métricas del Sistema

### Rendimiento Actual (Local)

| Métrica | Valor |
|---------|-------|
| Latencia promedio (p50) | <100ms |
| Latencia p95 | <300ms |
| Throughput | ~200 req/s |
| Tiempo de arranque | ~45s |
| Uso de RAM (todos los servicios) | ~2.5GB |

### Capacidad Estimada (Producción)

| Escenario | Usuarios Concurrentes | RPS | Infraestructura |
|-----------|----------------------|-----|-----------------|
| MVP | 100 | 50 | 2 pods/servicio |
| Crecimiento | 1,000 | 500 | 4 pods/servicio |
| Escala | 10,000 | 2,000 | 8 pods/servicio + CDN |

---

## 📚 Referencias y Recursos

### Documentación Oficial

- [Spring Boot Reference](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Cloud Gateway](https://cloud.spring.io/spring-cloud-gateway/reference/html/)
- [Spring Security](https://docs.spring.io/spring-security/reference/index.html)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [Apache Kafka](https://kafka.apache.org/documentation/)

### Patrones y Arquitectura

- [Microservices Patterns (Chris Richardson)](https://microservices.io/patterns/)
- [Domain-Driven Design (Eric Evans)](https://domainlanguage.com/ddd/)
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)

---

**Documento actualizado:** Octubre 2025  
**Mantenedor:** Equipo de Backend  
**Próxima revisión:** Trimestral

