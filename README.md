# Balconazo - Marketplace de Espacios

![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.3-brightgreen.svg)
![Java](https://img.shields.io/badge/Java-21-orange.svg)
![Docker](https://img.shields.io/badge/Docker-24%2B-blue.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)
![Kafka](https://img.shields.io/badge/Kafka-3.7-black.svg)
![Redis](https://img.shields.io/badge/Redis-7-red.svg)
![Angular](https://img.shields.io/badge/Angular-20-red.svg)

## 📋 Descripción

**Balconazo** es un marketplace escalable para el alquiler de espacios tipo balcones y terrazas para eventos. Implementa una arquitectura de microservicios event-driven con patrones DDD, CQRS, Saga y Outbox, diseñada para alta disponibilidad y escalabilidad horizontal.

El sistema permite:
- 🔍 Búsqueda geoespacial de espacios disponibles (latencia <200ms P95)
- 💰 Pricing dinámico basado en demanda con Kafka Streams
- 📅 Reservas con saga orquestada (hold → payment → confirm)
- ⭐ Sistema de reviews y reputación post-estancia
- 🔐 Autenticación JWT con roles diferenciados (host/guest/admin)
- ⚡ Rate limiting y caché distribuida con Redis

---

## 🏗️ Arquitectura Visual

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Angular Frontend :4200                               │
│                   (Standalone Components + Tailwind)                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTP + JWT
                                 ↓
┌─────────────────────────────────────────────────────────────────────────┐
│              Spring Cloud Gateway :8080                                 │
│         (JWT Validation + Rate Limiting + CORS)                         │
└───┬─────────────────────┬─────────────────────┬───────────────────────┘
    │                     │                     │
    ↓                     ↓                     ↓
┌───────────────┐  ┌──────────────────┐  ┌────────────────────────┐
│ Catalog :8081 │  │ Booking :8082    │  │ Search-Pricing :8083   │
│               │  │                  │  │                        │
│ • Users       │  │ • Bookings       │  │ • Geospatial Search    │
│ • Spaces      │  │ • Payments       │  │ • Dynamic Pricing      │
│ • Availability│  │ • Reviews        │  │ • Price Surface        │
│               │  │ • Notifications  │  │ • Demand Analytics     │
└───────┬───────┘  └────────┬─────────┘  └──────────┬─────────────┘
        │                   │                       │
        ↓                   ↓                       ↓
   ┌─────────┐        ┌─────────┐           ┌─────────┐
   │ PG :5433│        │ PG :5434│           │ PG :5435│
   │catalog  │        │booking  │           │search   │
   │_db      │        │_db      │           │_db      │
   └─────────┘        └─────────┘           └─────────┘
        │                   │                       │
        └───────────────────┼───────────────────────┘
                            ↓
        ┌───────────────────────────────────────────┐
        │      Apache Kafka :29092 (Bitnami)        │
        │  • space.events.v1                        │
        │  • availability.events.v1                 │
        │  • booking.events.v1                      │
        │  • payment.events.v1                      │
        │  • review.events.v1                       │
        │  • pricing.events.v1                      │
        │  • analytics.search.v1                    │
        └───────────────────────────────────────────┘
                            │
                            ↓
                   ┌─────────────────┐
                   │  Redis :6379    │
                   │  • Locks        │
                   │  • Price Cache  │
                   │  • Rate Limit   │
                   └─────────────────┘
```

---

## ✨ Características Principales

### 🔍 Búsqueda Geoespacial con PostGIS
- Queries de proximidad basadas en latitud/longitud con radio configurable
- Índices GIST para consultas en <100-200ms P95
- Proyección de lectura (CQRS) actualizada por eventos de Kafka
- Caché caliente en Redis para resultados frecuentes (TTL 60-180s)

### 💰 Pricing Dinámico con Kafka Streams
- **Fórmula concreta definida:** `multiplier = 1.0 + (demandScore * 1.5)` donde demandScore se calcula con búsquedas (peso 0.01), holds (0.1) y bookings (0.5)
- **MVP:** Scheduler con `@Scheduled` cada 5 minutos (más simple que Kafka Streams)
- **Producción:** Migración a Kafka Streams cuando >50k búsquedas/hora
- Análisis de demanda por tile geoespacial (tileId) agregando métricas de las últimas 24h
- Multiplicadores dinámicos [1.0–2.5] aplicados sobre precio base
- Precálculo de `price_surface` por timeslot con warming a Redis
- **Ver algoritmo completo:** [docs/PRICING_ALGORITHM.md](./docs/PRICING_ALGORITHM.md)

### 📅 Saga de Reservas con Outbox Pattern
- Orquestación centralizada en booking-service para consistencia estricta
- Flujo: `held` (10 min TTL) → `payment authorized` → `confirmed` → review habilitado
- Locks distribuidos en Redis para prevenir double-booking
- Compensaciones automáticas (cancel + refund) en caso de fallos
- Idempotencia con `Idempotency-Key` header + tabla `processed_events`

### 🔐 Autenticación y Autorización
- **MVP:** JWT HS256 generado en API Gateway (sin Keycloak para simplificar)
- **Producción:** Migración fácil a Keycloak/Cognito (solo cambiar Gateway)
- Roles en claims: `host` (publica espacios), `guest` (reserva), `admin` (ops)
- Rate limiting: 100 req/min por `sub` (user ID) usando Redis
- CORS configurado para frontend en localhost:4200
- **Ver detalles:** [docs/AUTH_SIMPLIFIED.md](./docs/AUTH_SIMPLIFIED.md)

### ⚡ Resiliencia y Observabilidad
- Circuit breakers con Resilience4j en integraciones externas
- Dead Letter Topics (DLT) por cada tópico Kafka
- Spring Boot Actuator en todos los servicios (`/actuator/health`, `/metrics`, `/prometheus`)
- Tracing con `X-Correlation-Id` propagado desde API Gateway
- Logging estructurado JSON con `traceId` para distributed tracing

---

## 🛠️ Stack Tecnológico Detallado

### Backend
- **Framework:** Spring Boot 3.3.3 (Java 21)
- **API Gateway:** Spring Cloud Gateway 2024.0.3
  - JWT validation con `spring-boot-starter-oauth2-resource-server`
  - Rate limiting con `RedisRateLimiter`
- **Mensajería:** Apache Kafka 3.7 (Bitnami image)
  - Productores idempotentes (`enable.idempotence=true`)
  - Transacciones Kafka para Outbox Pattern
  - 12 particiones por tópico (escalable a 48/96 en prod)
- **Bases de datos:** PostgreSQL 16 + PostGIS 3.4
  - Database-per-service: `catalog_db`, `booking_db`, `search_db`
  - Schemas aislados: `catalog`, `booking`, `search`
  - Constraints exclusivos con `btree_gist` para prevenir overlaps
- **Caché/Locks:** Redis 7
  - Locks con TTL automático (`SET ... NX PX`)
  - Precio precalculado por slot: `price:{spaceId}:{timeslot}`
  - Rate limiting: `ratelimit:{userId}:{window}`
- **Patrones:**
  - SOLID, Repository, Service Layer, DTO
  - Outbox Pattern para atomicidad (DB + Kafka)
  - Saga orquestada en reservas
  - CQRS con read-model geoespacial en SearchPricing

### Frontend
- **Framework:** Angular 20 (standalone components)
- **Estilos:** Tailwind CSS 3.x
- **HTTP Client:** `HttpClient` con interceptor JWT
- **Estado:** Servicios inyectables con signals (Angular 20)

### Infraestructura
- **Dev:** Docker Compose 3.9
  - 9 contenedores: Gateway, 3 servicios, Kafka, ZK, 3 Postgres, Redis, Keycloak
- **Prod (AWS):**
  - Compute: ECS/EKS (imágenes Docker multi-stage)
  - Mensajería: AWS MSK (Kafka managed)
  - Bases de datos: AWS RDS PostgreSQL (Multi-AZ)
  - Caché: AWS ElastiCache (Redis)
  - Secrets: AWS Secrets Manager
  - Observabilidad: CloudWatch + Prometheus/Grafana

---

## 📁 Estructura de Directorios

```
BalconazoApp/
├── README.md
├── ARCHITECTURE.md
├── KAFKA_EVENTS.md
├── QUICKSTART.md
├── documentacion.md
├── pom.xml                          # Parent POM (BOM Spring Boot 3.3.3 + Spring Cloud 2024.0.3)
├── docker-compose.yml               # Orquestación dev local
│
├── ddl/                             # Scripts DDL para init de Postgres
│   ├── catalog.sql
│   ├── booking.sql
│   └── search.sql
│
├── backend/
│   ├── api-gateway/
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── src/main/
│   │       ├── java/com/balconazo/gateway/
│   │       │   ├── GatewayApplication.java
│   │       │   ├── config/
│   │       │   │   ├── SecurityConfig.java
│   │       │   │   ├── RateLimiterConfig.java
│   │       │   │   └── CorsConfig.java
│   │       │   └── filter/
│   │       │       └── CorrelationIdFilter.java
│   │       └── resources/
│   │           └── application.yml
│   │
│   ├── catalog-service/
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── src/main/
│   │       ├── java/com/balconazo/catalog/
│   │       │   ├── CatalogServiceApplication.java
│   │       │   ├── domain/
│   │       │   │   ├── model/
│   │       │   │   │   ├── User.java
│   │       │   │   │   ├── Space.java
│   │       │   │   │   ├── AvailabilitySlot.java
│   │       │   │   │   └── vo/              # Value Objects (SpaceId, UserId, etc.)
│   │       │   │   ├── repository/          # Ports (interfaces)
│   │       │   │   │   ├── UserRepository.java
│   │       │   │   │   └── SpaceRepository.java
│   │       │   │   └── service/
│   │       │   │       └── SpaceDomainService.java
│   │       │   ├── application/
│   │       │   │   ├── dto/
│   │       │   │   │   ├── CreateSpaceCommand.java
│   │       │   │   │   ├── SpaceDto.java
│   │       │   │   │   └── UserDto.java
│   │       │   │   └── service/
│   │       │   │       ├── SpaceApplicationService.java
│   │       │   │       └── UserApplicationService.java
│   │       │   ├── infrastructure/
│   │       │   │   ├── persistence/
│   │       │   │   │   ├── jpa/
│   │       │   │   │   │   ├── SpaceJpaEntity.java
│   │       │   │   │   │   ├── UserJpaEntity.java
│   │       │   │   │   │   ├── SpaceJpaRepository.java
│   │       │   │   │   │   └── UserJpaRepository.java
│   │       │   │   │   └── adapter/
│   │       │   │   │       └── JpaSpaceRepositoryAdapter.java
│   │       │   │   ├── messaging/
│   │       │   │   │   └── kafka/
│   │       │   │   │       ├── SpaceEventProducer.java
│   │       │   │   │       └── config/KafkaProducerConfig.java
│   │       │   │   └── config/
│   │       │   │       └── JpaConfig.java
│   │       │   └── interfaces/
│   │       │       └── rest/
│   │       │           ├── SpaceController.java
│   │       │           ├── UserController.java
│   │       │           └── mapper/
│   │       │               └── SpaceMapper.java  # MapStruct
│   │       └── resources/
│   │           ├── application.yml
│   │           └── application-dev.yml
│   │
│   ├── booking-service/
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── src/main/
│   │       ├── java/com/balconazo/booking/
│   │       │   ├── BookingServiceApplication.java
│   │       │   ├── domain/
│   │       │   │   ├── model/
│   │       │   │   │   ├── Booking.java
│   │       │   │   │   ├── Review.java
│   │       │   │   │   ├── Outbox.java
│   │       │   │   │   └── vo/
│   │       │   │   ├── repository/
│   │       │   │   │   ├── BookingRepository.java
│   │       │   │   │   ├── ReviewRepository.java
│   │       │   │   │   └── OutboxRepository.java
│   │       │   │   └── service/
│   │       │   │       ├── BookingSaga.java
│   │       │   │       └── PaymentGateway.java  # Port
│   │       │   ├── application/
│   │       │   │   ├── dto/
│   │       │   │   │   ├── CreateBookingCommand.java
│   │       │   │   │   ├── ConfirmBookingCommand.java
│   │       │   │   │   └── BookingDto.java
│   │       │   │   └── service/
│   │       │   │       ├── BookingApplicationService.java
│   │       │   │       ├── OutboxPublisher.java  # @Scheduled
│   │       │   │       └── BookingExpiryWorker.java
│   │       │   ├── infrastructure/
│   │       │   │   ├── persistence/
│   │       │   │   │   └── jpa/
│   │       │   │   ├── messaging/
│   │       │   │   │   └── kafka/
│   │       │   │   │       ├── BookingEventProducer.java
│   │       │   │   │       ├── PaymentEventConsumer.java
│   │       │   │   │       └── config/
│   │       │   │   ├── payment/
│   │       │   │   │   └── StripeGatewayAdapter.java  # Mock en dev
│   │       │   │   └── lock/
│   │       │   │       └── RedisLockService.java
│   │       │   └── interfaces/
│   │       │       └── rest/
│   │       │           ├── BookingController.java
│   │       │           └── ReviewController.java
│   │       └── resources/
│   │           ├── application.yml
│   │           └── application-dev.yml
│   │
│   └── search-pricing-service/
│       ├── pom.xml
│       ├── Dockerfile
│       └── src/main/
│           ├── java/com/balconazo/search/
│           │   ├── SearchPricingServiceApplication.java
│           │   ├── domain/
│           │   │   ├── model/
│           │   │   │   ├── SpaceProjection.java
│           │   │   │   ├── PriceSurface.java
│           │   │   │   └── DemandAggregate.java
│           │   │   └── repository/
│           │   │       ├── SpaceProjectionRepository.java
│           │   │       └── PriceSurfaceRepository.java
│           │   ├── application/
│           │   │   ├── dto/
│           │   │   │   ├── SearchQuery.java
│           │   │   │   └── SearchResultDto.java
│           │   │   └── service/
│           │   │       ├── SearchApplicationService.java
│           │   │       └── PricingApplicationService.java
│           │   ├── infrastructure/
│           │   │   ├── persistence/
│           │   │   │   └── jpa/
│           │   │   ├── messaging/
│           │   │   │   └── kafka/
│           │   │   │       ├── streams/
│           │   │   │       │   └── PricingTopology.java  # Kafka Streams
│           │   │   │       └── consumer/
│           │   │   │           └── SpaceEventConsumer.java
│           │   │   ├── cache/
│           │   │   │   └── RedisPriceCache.java
│           │   │   └── config/
│           │   │       └── KafkaStreamsConfig.java
│           │   └── interfaces/
│           │       └── rest/
│           │           ├── SearchController.java
│           │           └── PricingController.java
│           └── resources/
│               ├── application.yml
│               └── application-dev.yml
│
├── frontend/
│   ├── package.json
│   ├── angular.json
│   ├── tailwind.config.js
│   ├── tsconfig.json
│   ├── Dockerfile
│   └── src/
│       ├── index.html
│       ├── main.ts
│       ├── styles.css              # @tailwind directives
│       └── app/
│           ├── app.component.ts
│           ├── app.routes.ts
│           ├── core/
│           │   ├── auth.service.ts
│           │   ├── jwt.interceptor.ts
│           │   └── api.config.ts
│           └── features/
│               ├── search/
│               │   ├── search.page.ts
│               │   └── search.service.ts
│               ├── space-detail/
│               │   ├── space-detail.page.ts
│               │   └── space-detail.service.ts
│               ├── booking/
│               │   ├── booking.page.ts
│               │   └── booking.service.ts
│               └── host/
│                   ├── host-dashboard.page.ts
│                   └── host.service.ts
│
└── docs/
    ├── adr/                        # Architecture Decision Records
    │   ├── 001-three-microservices.md
    │   ├── 002-orchestration-saga.md
    │   └── 003-outbox-pattern.md
    └── diagrams/
        └── c4/
```

---

## ⚙️ Requisitos Previos

| Herramienta | Versión Mínima | Comando Verificación |
|-------------|----------------|---------------------|
| Java        | 21             | `java -version`     |
| Maven       | 3.9+           | `mvn -version`      |
| Docker      | 24+            | `docker --version`  |
| Docker Compose | 2.x        | `docker-compose --version` |
| Node.js     | 20+            | `node --version`    |
| npm         | 10+            | `npm --version`     |

---

## 🚀 Instalación Paso a Paso

### 1. Clonar el Repositorio
```bash
git clone https://github.com/amolrod/balconazo-scalable-marketplace.git
cd balconazo-scalable-marketplace
# Iniciar componentes de infraestructura (sin Keycloak en MVP)
docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search
### 2. Levantar Infraestructura Base
```bash
# Iniciar componentes de infraestructura
docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search keycloak

# Esperar 60 segundos para que todos los servicios estén healthy
sleep 60

**Nota:** Keycloak NO es necesario en MVP. El API Gateway genera JWTs directamente.

# Verificar estado
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

Deberías ver todos los contenedores con estado "healthy" o "Up".

### 3. Crear Tópicos Kafka
```bash
# Script para crear todos los tópicos con 12 particiones
docker exec -it kafka kafka-topics.sh --create \
  --topic space.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic availability.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic booking.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic payment.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic review.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic pricing.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

docker exec -it kafka kafka-topics.sh --create \
  --topic analytics.search.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1

# Verificar creación
docker exec -it kafka kafka-topics.sh --list \
  --bootstrap-server localhost:9092
```

### 4. Compilar Microservicios Backend
```bash
cd backend

# Compilar todos los módulos (incluye parent POM)
mvn clean install -DskipTests

cd ..
```

### 5. Levantar Microservicios
```bash
# Iniciar API Gateway y los 3 microservicios
docker-compose up -d api-gateway catalog-service booking-service search-pricing-service

# Esperar 30 segundos para inicialización
sleep 30
```

### 6. Verificar Health Endpoints
```bash
# API Gateway
curl http://localhost:8080/actuator/health
# Esperado: {"status":"UP"}

# Catalog Service
curl http://localhost:8081/actuator/health
# Esperado: {"status":"UP","components":{"db":{"status":"UP"},"kafka":{"status":"UP"}}}

# Booking Service
curl http://localhost:8082/actuator/health

# Search-Pricing Service
curl http://localhost:8083/actuator/health
```

### 7. Seed Data Inicial (Opcional)
```bash
# Crear usuario host
curl -X POST http://localhost:8080/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@balconazo.com",
    "role": "host"
  }'

# Respuesta esperada: {"id":"uuid-generado","email":"host@balconazo.com","role":"host",...}
# Guardar el ID del usuario para el siguiente paso

# Crear espacio
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "uuid-del-usuario-anterior",
    "title": "Terraza con vistas al Retiro",
    "capacity": 15,
    "lat": 40.4168,
    "lon": -3.7038,
    "basePriceCents": 3500,
    "address": "Calle Alcalá 123, Madrid",
    "rules": {"noSmoking": true, "maxNoise": "moderate"}
  }'

# Crear disponibilidad para el espacio
curl -X POST http://localhost:8080/api/catalog/availability \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "uuid-del-espacio-anterior",
    "startTs": "2025-12-31T22:00:00Z",
    "endTs": "2026-01-01T06:00:00Z",
    "maxGuests": 15
  }'
```

### 8. Levantar Frontend Angular
```bash
cd frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm start

# Abrir navegador en http://localhost:4200
```

### 9. Flujo de Prueba End-to-End

#### a) Registrar Usuario Guest
En el frontend (http://localhost:4200), registrar un usuario tipo `guest`.

#### b) Buscar Espacios en Madrid
```bash
curl "http://localhost:8080/api/search?lat=40.4168&lon=-3.7038&radius_m=5000&capacity=10"
# Respuesta: array de espacios con precio calculado
```

#### c) Ver Detalle de Espacio
Desde el frontend, hacer clic en uno de los resultados para ver detalles completos.

#### d) Crear Booking
```bash
# Primero obtener token JWT desde Keycloak (dev) o usar mock
# Luego:
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Idempotency-Key: unique-uuid-here" \
  -d '{
    "spaceId": "uuid-del-espacio",
    "guestId": "uuid-del-guest",
    "startTs": "2025-12-31T22:00:00Z",
    "endTs": "2026-01-01T06:00:00Z"
  }'

# Respuesta: {"id":"booking-uuid","status":"held","priceCents":4200,...}
```

#### e) Confirmar Booking
```bash
curl -X POST http://localhost:8080/api/bookings/{booking-id}/confirm \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Respuesta: {"id":"booking-uuid","status":"confirmed",...}
```

#### f) Verificar Eventos en Kafka
```bash
docker exec -it kafka kafka-console-consumer.sh \
  --topic booking.events.v1 \
  --bootstrap-server localhost:9092 \
  --from-beginning \
  --property print.key=true \
  --property print.timestamp=true

# Deberías ver eventos: BookingHeld, PaymentAuthorized, BookingConfirmed
```

---

## 📡 Endpoints Principales por Servicio

### Catalog Service (:8081)
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| POST   | `/spaces` | Crear espacio | host |
| GET    | `/spaces/{id}` | Detalle de espacio | public |
| GET    | `/spaces?ownerId={uuid}` | Espacios por propietario | public |
| POST   | `/availability` | Añadir slots disponibles | host |
| POST   | `/users` | Crear usuario | public |
| GET    | `/users/{id}` | Detalle usuario | auth |

### Booking Service (:8082)
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| POST   | `/bookings` | Crear reserva (hold 10 min) | guest |
| GET    | `/bookings/{id}` | Detalle de reserva | owner |
| POST   | `/bookings/{id}/confirm` | Confirmar reserva (capture payment) | owner |
| POST   | `/reviews` | Crear review (1 por booking) | guest/host |
| GET    | `/reviews?bookingId={uuid}` | Reviews de booking | public |

### Search-Pricing Service (:8083)
| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| GET    | `/search?lat={lat}&lon={lon}&radius_m={m}&capacity={n}` | Búsqueda geoespacial | public |
| GET    | `/search?lat={lat}&lon={lon}&radius_m={m}&capacity={n}&start={iso}&end={iso}` | Búsqueda con fechas | public |
| POST   | `/pricing/recompute` | Forzar recálculo de precios (admin) | admin |
| GET    | `/pricing/{spaceId}?timeslot={iso}` | Precio para slot específico | public |

### API Gateway (:8080)
Todas las rutas con prefijo `/api/*` son enrutadas a los servicios correspondientes.

**Ejemplo:**
- `http://localhost:8080/api/catalog/spaces` → `http://catalog-service:8081/spaces`
- `http://localhost:8080/api/bookings` → `http://booking-service:8082/bookings`
- `http://localhost:8080/api/search` → `http://search-pricing-service:8083/search`

---

## 📨 Arquitectura de Eventos (Kafka)

| Tópico | Key | Productor | Consumidores | Particiones | Retención |
|--------|-----|-----------|--------------|-------------|-----------|
| `space.events.v1` | space_id | catalog-service | search-pricing-service | 12 | 14 días |
| `availability.events.v1` | space_id | catalog-service | search-pricing-service | 12 | 14 días |
| `booking.events.v1` | booking_id | booking-service | search-pricing-service | 12 | 14 días |
| `payment.events.v1` | booking_id | booking-service | booking-service (consume propios) | 12 | 14 días |
| `review.events.v1` | booking_id | booking-service | catalog-service (actualiza ratings) | 12 | 14 días |
| `pricing.events.v1` | space_id | search-pricing-service | catalog-service (opcional) | 12 | 7 días |
| `analytics.search.v1` | tile_id | search-pricing-service | search-pricing-service (Streams) | 12 | 48 horas |

**Eventos principales:**
- `SpaceCreated`, `SpaceUpdated`, `SpaceDeactivated`
- `AvailabilityAdded`, `AvailabilityRemoved`, `AvailabilityChanged`
- `BookingRequested`, `BookingHeld`, `BookingConfirmed`, `BookingCancelled`, `BookingExpired`
- `PaymentIntentCreated`, `PaymentAuthorized`, `PaymentCaptured`, `PaymentFailed`, `RefundIssued`
- `ReviewSubmitted`, `DisputeOpened`, `DisputeResolved`
- `PriceRecomputeRequested`, `PriceUpdated`
- `SearchQueryLogged`

Ver detalles completos en [KAFKA_EVENTS.md](./KAFKA_EVENTS.md).

---

## 🏛️ Patrones Implementados

### SOLID Principles
- **Single Responsibility:** Controllers solo HTTP, Services orquestan, Domain encapsula lógica de negocio
- **Open/Closed:** Estrategias de pricing extensibles sin modificar servicio base
- **Liskov Substitution:** `PaymentGateway` interface con `StripeGateway`, `MockGateway` intercambiables
- **Interface Segregation:** Repositorios específicos (`SpaceReadRepository`, `SpaceWriteRepository`)
- **Dependency Inversion:** Servicios dependen de puertos (interfaces), no de adaptadores concretos

### Domain-Driven Design (DDD)
- **Bounded Contexts:** 3 contextos bien definidos (Catalog, Booking, SearchPricing)
- **Aggregates:** `Space` (catalog), `Booking` (booking), `SpaceProjection` (search)
- **Value Objects:** `SpaceId`, `BookingId`, `Money`, `DateRange`
- **Domain Events:** Emitidos por agregados y publicados vía Kafka

### Event-Driven Architecture
- **Outbox Pattern:** Tabla `outbox` en booking_db para atomicidad (DB write + Kafka publish)
- **Idempotencia:** `event_id` único + tabla `processed_events` en consumidores
- **Dead Letter Topics:** `*.DLT` para eventos fallidos tras retries

### Saga Pattern (Orquestación)
- **Orquestador:** `BookingSaga` en booking-service coordina flujo completo
- **Estados:** `held` → `payment_authorized` → `confirmed` | `cancelled` | `expired`
- **Compensaciones:** Rollback automático con `BookingCancelled` + `RefundIssued`

### CQRS (Command Query Responsibility Segregation)
- **Write Model:** Catalog y Booking escriben en sus DBs transaccionales
- **Read Model:** SearchPricing mantiene proyección optimizada con PostGIS + precio precalculado
- **Sincronización:** Via eventos Kafka consumidos por SearchPricing

### Repository Pattern
- **Interfaces (Ports):** Definidas en `domain/repository`
- **Implementaciones (Adapters):** En `infrastructure/persistence/jpa`
- **Beneficios:** Testabilidad (mocks), swap de tecnología sin impacto en dominio

### Service Layer
- **Application Services:** Orquestan casos de uso, transacciones, publicación de eventos
- **Domain Services:** Lógica de negocio que no pertenece a un agregado específico
- **DTO Mapping:** MapStruct para conversión entre capas

---

## ⚙️ Configuración

### Variables de Entorno por Servicio

#### catalog-service
```bash
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:postgresql://pg-catalog:5432/catalog_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
SPRING_REDIS_HOST=redis
SPRING_REDIS_PORT=6379
SERVER_PORT=8081
```

#### booking-service
```bash
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:postgresql://pg-booking:5432/booking_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
SPRING_REDIS_HOST=redis
SPRING_REDIS_PORT=6379
SERVER_PORT=8082
BALCONAZO_BOOKING_HOLD_TTL_MS=600000  # 10 min
```

#### search-pricing-service
```bash
SPRING_PROFILES_ACTIVE=dev
SPRING_DATASOURCE_URL=jdbc:postgresql://pg-search:5432/search_db
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=postgres
SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
SPRING_KAFKA_STREAMS_APPLICATION_ID=balconazo-pricing
SPRING_REDIS_HOST=redis
SPRING_REDIS_PORT=6379
SERVER_PORT=8083
```

#### api-gateway
```bash
SPRING_PROFILES_ACTIVE=dev
SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=http://keycloak:8080/realms/balconazo/protocol/openid-connect/certs
SPRING_DATA_REDIS_HOST=redis
SPRING_DATA_REDIS_PORT=6379
SERVER_PORT=8080
BALCONAZO_CORS_ALLOWED_ORIGINS=http://localhost:4200
```

---

## 🧪 Testing

### Estrategia de Testing
```
backend/
├── catalog-service/
│   └── src/test/
│       ├── unit/                   # Tests unitarios (JUnit 5 + Mockito)
│       │   └── SpaceApplicationServiceTest.java
│       ├── integration/            # Tests de integración (Testcontainers)
│       │   └── SpaceRepositoryIT.java
│       └── contract/               # Contract testing (Pact)
│           └── SpaceControllerContractTest.java
```

### Comandos de Testing
```bash
# Tests unitarios (rápidos, sin infra)
mvn test

# Tests de integración (requiere Docker para Testcontainers)
mvn verify -Pintegration-tests

# Coverage report (JaCoCo)
mvn clean verify jacoco:report
open target/site/jacoco/index.html
```

### Testcontainers (Ejemplo)
```java
@Testcontainers
@SpringBootTest
class BookingRepositoryIT {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("booking_test")
        .withInitScript("ddl/booking.sql");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    // Tests...
}
```

---

## ☁️ Despliegue AWS (Producción)

### Arquitectura Cloud
```
┌─────────────────────────────────────────────────────────────┐
│                      Route 53 (DNS)                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│              CloudFront + S3 (Angular SPA)                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│   ALB (Application Load Balancer) → Target Group: Gateway  │
└───────────────────────────┬─────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ↓                  ↓                  ↓
    ┌─────────┐       ┌─────────┐       ┌─────────┐
    │ ECS Task│       │ ECS Task│       │ ECS Task│
    │ Catalog │       │ Booking │       │ Search  │
    └────┬────┘       └────┬────┘       └────┬────┘
         │                 │                  │
         └────────┬────────┴────────┬─────────┘
                  │                 │
         ┌────────▼────────┐ ┌──────▼────────┐
         │  AWS MSK        │ │ ElastiCache   │
         │  (Kafka)        │ │ (Redis)       │
         └─────────────────┘ └───────────────┘
                  │
         ┌────────▼────────┐
         │  RDS PostgreSQL │
         │  Multi-AZ       │
         │  • catalog_db   │
         │  • booking_db   │
         │  • search_db    │
         └─────────────────┘
```

### Componentes Productivos

| Componente | Servicio AWS | Configuración |
|------------|--------------|---------------|
| Compute | ECS Fargate | 3 servicios, 2 tasks cada uno (HA), auto-scaling en CPU >70% |
| API Gateway | ALB + ECS Gateway | 2 tasks, health checks `/actuator/health` |
| Mensajería | AWS MSK | 3 brokers, 48 particiones/tópico, retención 14 días |
| Bases de Datos | RDS PostgreSQL 16 | Multi-AZ, 3 instancias db.r6g.large, backups diarios |
| Caché | ElastiCache Redis | Cluster mode, 3 nodos, replicación automática |
| Secrets | Secrets Manager | DB passwords, JWT keys, API keys |
| Logs | CloudWatch Logs | Retention 30 días, alarmas en errores >5% |
| Métricas | CloudWatch + Prometheus | Custom metrics, dashboards Grafana |
| CI/CD | CodePipeline + ECR | Build → Push → Deploy automático en main |

### Costos Estimados (us-east-1)
- ECS Fargate (6 tasks): ~$150/mes
- RDS Multi-AZ (3 DBs): ~$400/mes
- MSK (3 brokers): ~$500/mes
- ElastiCache (3 nodos): ~$100/mes
- ALB + Data Transfer: ~$50/mes
- **Total estimado:** ~$1,200/mes (sin Reserved Instances)

---

## 🔧 Troubleshooting

### 1. ❌ Kafka No Conecta
**Síntomas:** Servicios fallan al iniciar con `TimeoutException: Failed to update metadata`.

**Solución:**
```bash
# Verificar que Kafka está escuchando en 9092 (interno) y 29092 (host)
docker exec -it kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# Revisar KAFKA_CFG_ADVERTISED_LISTENERS en docker-compose.yml
# Debe tener: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092

# Reiniciar Kafka
docker-compose restart kafka
sleep 30
```

### 2. ❌ Locks Redis No Expiran
**Síntomas:** Bookings quedan bloqueados indefinidamente, no se pueden crear nuevas reservas para el mismo slot.

**Solución:**
```bash
# Conectar a Redis y verificar locks
docker exec -it redis redis-cli

# Listar todas las claves de lock
KEYS lock:booking:*

# Ver TTL de un lock (debe ser >0)
TTL lock:booking:space-uuid:2025-12-31T22:00:00Z-2026-01-01T06:00:00Z

# Si TTL=-1 (sin expiración), eliminarlo manualmente
DEL lock:booking:space-uuid:2025-12-31T22:00:00Z-2026-01-01T06:00:00Z

# Verificar código: RedisLockService debe usar SET ... PX 600000
```

### 3. ❌ Búsqueda Sin Resultados
**Síntomas:** `GET /search` devuelve array vacío pese a haber espacios creados.

**Solución:**
```bash
# Verificar que search-pricing-service está consumiendo space.events.v1
docker logs search-pricing-service | grep "SpaceCreated"

# Conectar a pg-search y verificar proyección
docker exec -it pg-search psql -U postgres -d search_db
SELECT * FROM search.spaces_projection;

# Si está vacía, republicar eventos desde catalog
curl -X POST http://localhost:8081/admin/republish-spaces

# O insertar manualmente (temporal):
INSERT INTO search.spaces_projection (space_id, title, capacity, geo, base_price_cents, status)
VALUES ('uuid-del-espacio', 'Test Space', 10, ST_Point(-3.7038, 40.4168)::geography, 3500, 'active');
```

### 4. ❌ Booking Falla con 409 Conflict
**Síntomas:** `POST /bookings` devuelve `{"error":"Slot already booked"}`.

**Solución:**
```bash
# Verificar exclusion constraint en booking.bookings
docker exec -it pg-booking psql -U postgres -d booking_db

SELECT * FROM booking.bookings 
WHERE space_id = 'uuid-del-espacio' 
  AND tstzrange(start_ts, end_ts) && tstzrange('2025-12-31T22:00:00Z', '2026-01-01T06:00:00Z')
  AND status IN ('held', 'confirmed');

# Si hay booking en estado 'held' expirado, ejecutar manualmente expiry worker:
UPDATE booking.bookings SET status = 'expired' 
WHERE status = 'held' AND created_at < now() - interval '10 minutes';

# Liberar locks correspondientes en Redis
docker exec -it redis redis-cli DEL lock:booking:...
```

### 5. ❌ JWT Inválido en Gateway
**Síntomas:** Todas las requests devuelven `401 Unauthorized`.

**Solución:**
```bash
# Verificar que Keycloak está corriendo
curl http://localhost:8081/realms/balconazo/.well-known/openid-configuration

# Verificar JWK Set URI en api-gateway/application.yml
# Debe coincidir con: http://keycloak:8080/realms/balconazo/protocol/openid-connect/certs

# Obtener token válido desde Keycloak
curl -X POST http://localhost:8081/realms/balconazo/protocol/openid-connect/token \
  -d "grant_type=password" \
  -d "client_id=balconazo-client" \
  -d "username=testuser" \
  -d "password=testpass"

# Decodificar token en https://jwt.io y verificar claims (sub, realm_access.roles)
```

---

## 📊 Roadmap

### Q1 2026
- [ ] **Verticales adicionales:** PoolNazo (piscinas), RoofNazo (azoteas)
- [ ] **Schema Registry:** Avro para eventos Kafka con validación centralizada
- [ ] **Observabilidad avanzada:** Grafana dashboards + Prometheus alerts
- [ ] **Tests E2E:** Cypress para flujos críticos frontend

### Q2 2026
- [ ] **Multi-región:** Despliegue en us-east-1 + eu-west-1 con replicación Kafka
- [ ] **Machine Learning:** Modelo de pricing con históricos de demanda (SageMaker)
- [ ] **Mobile Apps:** React Native para iOS/Android
- [ ] **Payment integrations:** Stripe + PayPal reales (no mock)

### Q3 2026
- [ ] **Advanced Search:** Filtros por amenities, reviews, precio dinámico con slider
- [ ] **Notificaciones Push:** Firebase Cloud Messaging + WebSockets
- [ ] **Dispute Resolution:** Sistema de mediación integrado en reviews
- [ ] **Analytics Dashboard:** Métricas de negocio para hosts (Tableau/Metabase)

---

## 📄 Licencia

Este proyecto está licenciado bajo **MIT License**. Ver archivo [LICENSE](./LICENSE) para más detalles.

---

## 👥 Contribución

Contribuciones son bienvenidas. Por favor:
1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

**Convenciones:**
- Código siguiendo Google Java Style Guide
- Commits semánticos (feat, fix, docs, refactor, test)
- Tests para toda nueva funcionalidad (coverage >80%)
- Actualizar ARCHITECTURE.md si hay decisiones arquitectónicas

---



**Construido por el equipo de Balconazo**


