# 🏗️ BALCONAZO - Documentación Técnica Completa

> **Marketplace de Alquiler de Espacios (Balcones/Terrazas para Eventos)**  
> Arquitectura de Microservicios con Spring Boot 3.5, Java 21, Kafka, PostgreSQL, Redis y Angular 20

---

## 📋 ÍNDICE

1. [Estado Actual del Proyecto](#estado-actual)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Arquitectura de Microservicios](#arquitectura)
4. [Bounded Contexts y Distribución](#bounded-contexts)
5. [Catalog Microservice (IMPLEMENTADO)](#catalog-service)
6. [Base de Datos](#base-de-datos)
7. [Eventos Kafka](#eventos-kafka)
8. [Configuración Docker](#docker)
9. [Roadmap](#roadmap)

---

<a name="estado-actual"></a>
## ✅ ESTADO ACTUAL DEL PROYECTO (27 Oct 2025)

### Completado
- ✅ **catalog-service** - 100% funcional
  - Puerto: 8085
  - PostgreSQL: Conectado (puerto 5433)
  - Tablas: users, spaces, availability_slots, processed_events
  - Endpoints REST: Implementados
  - Kafka Producers: Preparados
  - Health Check: ✅ UP

### En Progreso
- ⏳ Kafka + Zookeeper (próximo paso)
- ⏳ booking-service (siguiente microservicio)
- ⏳ search-pricing-service

### Pendiente
- ⏸️ API Gateway (Spring Cloud Gateway)
- ⏸️ Frontend Angular 20
- ⏸️ Docker Compose completo
- ⏸️ Deployment AWS

---

<a name="stack-tecnológico"></a>
## 🛠️ STACK TECNOLÓGICO

### Backend
- **Framework:** Spring Boot 3.5.7
- **Lenguaje:** Java 21 (OpenJDK 21.0.6)
- **Build:** Maven 3.9+
- **API Gateway:** Spring Cloud Gateway (pendiente)
- **Messaging:** Apache Kafka 3.7 (Bitnami)
- **Base de Datos:** PostgreSQL 16 (Alpine)
- **Cache:** Redis 7 (Alpine)
- **ORM:** Hibernate 6.6.33 (JPA)
- **Pool Conexiones:** HikariCP

### Frontend
- **Framework:** Angular 20 (standalone components)
- **CSS:** Tailwind CSS
- **HTTP:** HttpClient + JWT Interceptor

### Infraestructura
- **Desarrollo:** Docker + Docker Compose
- **Producción:** AWS ECS/EKS, MSK, RDS, ElastiCache

### Patrones Implementados
- ✅ SOLID principles
- ✅ Repository Pattern
- ✅ Service Layer
- ✅ DTO Pattern
- ✅ Outbox Pattern (preparado)
- ✅ Event-Driven Architecture
- ⏳ Saga Pattern (para booking)
- ⏳ CQRS (read-model en search-pricing)

---

<a name="arquitectura"></a>
## 🏗️ ARQUITECTURA DE MICROSERVICIOS

```
┌─────────────────────────────────────────────────────────────────┐
│                     Angular Frontend :4200                      │
│                    (Tailwind CSS + HttpClient)                  │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS/JWT
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│              Spring Cloud Gateway :8080 (Pendiente)             │
│         (JWT Validation, Rate Limiting, CORS, Routing)          │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
                 ▼             ▼             ▼
       ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
       │  Catalog    │ │  Booking    │ │Search-Pricing│
       │  Service    │ │  Service    │ │   Service    │
       │   :8081     │ │   :8082     │ │   :8083      │
       │             │ │             │ │              │
       │ ✅ RUNNING │ │ ⏳ TODO     │ │ ⏳ TODO      │
       └──────┬──────┘ └──────┬──────┘ └──────┬───────┘
              │                │                │
              ▼                ▼                ▼
       ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
       │PostgreSQL   │ │PostgreSQL   │ │PostgreSQL   │
       │ catalog_db  │ │ booking_db  │ │ search_db   │
       │   :5433     │ │   :5434     │ │   :5435     │
       │ ✅ RUNNING │ │ ⏸️ TODO     │ │ ⏸️ TODO     │
       └─────────────┘ └─────────────┘ └─────────────┘

              ▲                ▲                ▲
              └────────────────┼────────────────┘
                               │
                ┌──────────────▼──────────────┐
                │      Apache Kafka :9092     │
                │    (+ Zookeeper :2181)      │
                │        ⏳ TODO              │
                └─────────────────────────────┘

                ┌─────────────────────────────┐
                │       Redis :6379           │
                │    (Cache + Locks)          │
                │        ⏸️ TODO              │
                └─────────────────────────────┘
```

---

<a name="bounded-contexts"></a>
## 🎯 BOUNDED CONTEXTS Y DISTRIBUCIÓN

### Contextos Originales (8)
1. Identidad & Confianza
2. Catálogo (Listings)
3. Búsqueda
4. Precios
5. Reservas (Bookings)
6. Pagos
7. Reputación (Reviews & Disputes)
8. Notificaciones

### Redistribución en 3 Microservicios

#### 1️⃣ MS-Catalog (catalog-service) ✅ IMPLEMENTADO
**Agrupa:** Identidad & Confianza + Catálogo (Spaces, Availability)

**Responsabilidades:**
- Gestión de usuarios (hosts/guests) con roles y trust score
- CRUD de espacios (balcones/terrazas)
- Gestión de disponibilidad temporal
- Validación de propiedad y reglas de negocio

**Por qué junto:**
- El host y su inventario están acoplados lógicamente
- Compartir transacciones simplifica invariantes de propiedad
- Emisión consistente de eventos (SpaceCreated, AvailabilityChanged)

**Publica a Kafka:**
- `space.events.v1` → SpaceCreated, SpaceUpdated, SpaceDeactivated
- `availability.events.v1` → AvailabilityAdded, AvailabilityRemoved

**Base de Datos:** `catalog_db` (PostgreSQL 16)
**Puerto:** 8081 (configurado actualmente en 8085 para desarrollo)

#### 2️⃣ MS-Booking (booking-service) ⏳ TODO
**Agrupa:** Reservas + Pagos + Reputación + Notificaciones

**Responsabilidades:**
- Orquestar saga de reserva (hold → preauth → confirm/cancel)
- Integración con pasarela de pago (Stripe stub en dev)
- Gestión de reviews post-estancia
- Disputas y resoluciones
- Emisión de notificaciones (email/SMS)

**Por qué junto:**
- Consistencia crítica entre reserva, cobro y review
- Evita coreografías complejas en el camino crítico
- Transacciones ACID para operaciones de pago

**Publica a Kafka:**
- `booking.events.v1` → BookingRequested, BookingConfirmed, BookingCancelled
- `payment.events.v1` → PaymentAuthorized, PaymentCaptured, RefundIssued
- `review.events.v1` → ReviewCreated, ReviewUpdated
- `notification.events.v1` → NotificationRequested

**Base de Datos:** `booking_db` (PostgreSQL 16)
**Puerto:** 8082

#### 3️⃣ MS-SearchPricing (search-pricing-service) ⏳ TODO
**Agrupa:** Búsqueda + Precios

**Responsabilidades:**
- Proyección de búsqueda geoespacial (PostGIS)
- Motor de pricing dinámico (Kafka Streams)
- Precálculo de precios efectivos
- Cache en Redis para baja latencia (<200ms P95)
- Índices de búsqueda optimizados

**Por qué junto:**
- El precio efectivo es parte del read-model de búsqueda
- Precalcular y servir desde el mismo servicio reduce latencia
- Escalado horizontal independiente

**Consume de Kafka:**
- `space.events.v1`
- `availability.events.v1`
- `booking.events.v1`

**Publica a Kafka:**
- `pricing.events.v1` → PriceUpdated, DemandSurgeDetected

**Base de Datos:** `search_db` (PostgreSQL 16 + PostGIS)
**Puerto:** 8083

---

<a name="catalog-service"></a>
## ✅ CATALOG MICROSERVICE (IMPLEMENTADO)

### Estado
- ✅ **FUNCIONANDO** en puerto **8085**
- ✅ Conectado a PostgreSQL (localhost:5433)
- ✅ Tablas creadas automáticamente por Hibernate
- ✅ Health check: UP
- ✅ Endpoints REST operativos

### Arquitectura Interna

```
catalog-service/
├── controller/          # REST Controllers
│   ├── UserController.java
│   ├── SpaceController.java
│   └── AvailabilityController.java
├── service/             # Business Logic
│   ├── UserService.java (interface)
│   ├── UserServiceImpl.java
│   ├── SpaceService.java (interface)
│   ├── SpaceServiceImpl.java
│   ├── AvailabilityService.java (interface)
│   └── AvailabilityServiceImpl.java
├── repository/          # JPA Repositories
│   ├── UserRepository.java
│   ├── SpaceRepository.java
│   ├── AvailabilitySlotRepository.java
│   └── ProcessedEventRepository.java
├── entity/              # JPA Entities
│   ├── UserEntity.java
│   ├── SpaceEntity.java
│   ├── AvailabilitySlotEntity.java
│   └── ProcessedEventEntity.java
├── dto/                 # Data Transfer Objects
│   ├── CreateUserDTO.java
│   ├── UserDTO.java
│   ├── CreateSpaceDTO.java
│   ├── SpaceDTO.java
│   ├── CreateAvailabilityDTO.java
│   └── AvailabilitySlotDTO.java
├── mapper/              # MapStruct Mappers
│   ├── UserMapper.java
│   └── SpaceMapper.java
├── kafka/               # Kafka Producers
│   ├── producer/
│   │   ├── SpaceEventProducer.java
│   │   └── AvailabilityEventProducer.java
│   └── event/
│       ├── SpaceCreatedEvent.java
│       ├── SpaceUpdatedEvent.java
│       ├── SpaceDeactivatedEvent.java
│       ├── AvailabilityAddedEvent.java
│       └── AvailabilityRemovedEvent.java
├── config/              # Configuration
│   ├── KafkaConfig.java
│   ├── SwaggerConfig.java
│   └── GlobalExceptionHandler.java
├── exception/           # Custom Exceptions
│   ├── ResourceNotFoundException.java
│   └── BusinessValidationException.java
└── constants/           # Constants
    └── CatalogConstants.java
```

### Endpoints REST

#### Usuarios
```
POST   /api/catalog/users          - Crear usuario
GET    /api/catalog/users/{id}     - Obtener usuario
GET    /api/catalog/users          - Listar usuarios
PUT    /api/catalog/users/{id}     - Actualizar usuario
```

#### Espacios
```
POST   /api/catalog/spaces         - Crear espacio
GET    /api/catalog/spaces         - Listar espacios activos
GET    /api/catalog/spaces/{id}    - Obtener espacio
PUT    /api/catalog/spaces/{id}    - Actualizar espacio
DELETE /api/catalog/spaces/{id}    - Desactivar espacio
GET    /api/catalog/spaces/owner/{ownerId} - Espacios por propietario
```

#### Disponibilidad
```
POST   /api/catalog/availability                   - Crear slot disponibilidad
GET    /api/catalog/availability/space/{spaceId}   - Listar disponibilidad
DELETE /api/catalog/availability/{id}              - Eliminar slot
GET    /api/catalog/availability/{id}              - Obtener slot
```

#### Actuator
```
GET    /actuator/health            - Estado del servicio
GET    /actuator/info              - Información del servicio
GET    /actuator/metrics           - Métricas
```

### Modelo de Datos

#### users
```sql
CREATE TABLE catalog.users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,  -- 'host' | 'guest' | 'admin'
    status VARCHAR(255) NOT NULL, -- 'ACTIVE' | 'SUSPENDED' | 'DELETED'
    trust_score INTEGER,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
```

#### spaces
```sql
CREATE TABLE catalog.spaces (
    id UUID PRIMARY KEY,
    owner_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    capacity INTEGER NOT NULL,
    area_sqm NUMERIC(6,2),
    base_price_cents INTEGER NOT NULL,
    amenities TEXT[],
    rules JSONB,
    status VARCHAR(255) NOT NULL, -- 'ACTIVE' | 'INACTIVE' | 'DELETED'
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP
);
```

#### availability_slots
```sql
CREATE TABLE catalog.availability_slots (
    id UUID PRIMARY KEY,
    space_id UUID NOT NULL REFERENCES spaces(id),
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP NOT NULL,
    max_guests INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL
);
```

#### processed_events
```sql
CREATE TABLE catalog.processed_events (
    event_id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    processed_at TIMESTAMP NOT NULL
);
-- Para idempotencia de eventos Kafka
```

---

<a name="base-de-datos"></a>
## 💾 BASE DE DATOS

### Estrategia: Database per Service

Cada microservicio tiene su propia base de datos PostgreSQL para garantizar:
- ✅ Aislamiento de datos
- ✅ Escalado independiente
- ✅ Schema evolution sin coordinación
- ✅ Resiliencia (un DB down no afecta otros servicios)

### Configuración Docker (Desarrollo)

#### catalog_db (✅ FUNCIONANDO)
```bash
docker run -d \
  --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:16-alpine
```

#### booking_db (⏳ TODO)
```bash
docker run -d \
  --name balconazo-pg-booking \
  -p 5434:5432 \
  -e POSTGRES_DB=booking_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgres:16-alpine
```

#### search_db (⏳ TODO)
```bash
docker run -d \
  --name balconazo-pg-search \
  -p 5435:5432 \
  -e POSTGRES_DB=search_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  postgis/postgis:16-3.4-alpine  # PostGIS para búsqueda geoespacial
```

### Configuración Producción (AWS RDS)
- PostgreSQL 16.x
- Multi-AZ para alta disponibilidad
- Backups automáticos diarios
- Encryption at rest (KMS)
- Connection pooling con RDS Proxy

---

<a name="eventos-kafka"></a>
## 📨 EVENTOS KAFKA

### Tópicos Definidos

#### space.events.v1
**Key:** `space_id` (UUID)  
**Particiones:** 12  
**Replication Factor:** 3 (prod) / 1 (dev)

**Eventos:**
1. **SpaceCreated**
```json
{
  "eventType": "SpaceCreated",
  "version": 1,
  "spaceId": "uuid",
  "ownerId": "uuid",
  "title": "string",
  "description": "string",
  "capacity": 20,
  "areaSqm": 50.0,
  "basePriceCents": 15000,
  "amenities": ["wifi", "barbecue"],
  "rules": {"no_smoking": true},
  "address": "string",
  "lat": 40.4168,
  "lon": -3.7038,
  "status": "ACTIVE",
  "occurredAt": "2025-10-27T14:00:00Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "uuid",
    "correlationId": "uuid"
  }
}
```

2. **SpaceUpdated**
```json
{
  "eventType": "SpaceUpdated",
  "version": 1,
  "spaceId": "uuid",
  "ownerId": "uuid",
  "title": "string",
  "capacity": 25,
  "basePriceCents": 18000,
  "status": "ACTIVE",
  "occurredAt": "2025-10-27T15:00:00Z",
  "metadata": {...}
}
```

3. **SpaceDeactivated**
```json
{
  "eventType": "SpaceDeactivated",
  "version": 1,
  "spaceId": "uuid",
  "ownerId": "uuid",
  "status": "INACTIVE",
  "occurredAt": "2025-10-27T16:00:00Z",
  "metadata": {...}
}
```

#### availability.events.v1
**Key:** `space_id` (UUID)  
**Particiones:** 12

**Eventos:**
1. **AvailabilityAdded**
```json
{
  "eventType": "AvailabilityAdded",
  "version": 1,
  "slotId": "uuid",
  "spaceId": "uuid",
  "startTs": "2025-12-31T18:00:00Z",
  "endTs": "2025-12-31T23:59:59Z",
  "maxGuests": 20,
  "occurredAt": "2025-10-27T14:00:00Z",
  "metadata": {...}
}
```

2. **AvailabilityRemoved**
```json
{
  "eventType": "AvailabilityRemoved",
  "version": 1,
  "slotId": "uuid",
  "spaceId": "uuid",
  "startTs": "2025-12-31T18:00:00Z",
  "endTs": "2025-12-31T23:59:59Z",
  "occurredAt": "2025-10-27T15:00:00Z",
  "metadata": {...}
}
```

#### booking.events.v1 (⏳ TODO)
**Key:** `booking_id` (UUID)

**Eventos:** BookingRequested, BookingHeld, BookingConfirmed, BookingCancelled, BookingExpired

#### payment.events.v1 (⏳ TODO)
**Key:** `booking_id` (UUID)

**Eventos:** PaymentIntentCreated, PaymentAuthorized, PaymentCaptured, PaymentFailed, RefundIssued

#### review.events.v1 (⏳ TODO)
**Key:** `booking_id` (UUID)

**Eventos:** ReviewCreated, ReviewUpdated

#### pricing.events.v1 (⏳ TODO)
**Key:** `space_id` (UUID)

**Eventos:** PriceUpdated, DemandSurgeDetected

---

<a name="docker"></a>
## 🐳 CONFIGURACIÓN DOCKER

### Servicios Actuales

#### PostgreSQL Catalog (✅ FUNCIONANDO)
```yaml
pg-catalog:
  image: postgres:16-alpine
  container_name: balconazo-pg-catalog
  ports:
    - "5433:5432"
  environment:
    POSTGRES_DB: catalog_db
    POSTGRES_USER: postgres
    POSTGRES_HOST_AUTH_METHOD: trust
  volumes:
    - pg-catalog-data:/var/lib/postgresql/data
```

### Próximos Servicios a Levantar

#### Zookeeper (⏳ PRÓXIMO)
```yaml
zookeeper:
  image: bitnami/zookeeper:3.9
  container_name: balconazo-zookeeper
  ports:
    - "2181:2181"
  environment:
    - ALLOW_ANONYMOUS_LOGIN=yes
```

#### Kafka (⏳ PRÓXIMO)
```yaml
kafka:
  image: bitnami/kafka:3.7
  container_name: balconazo-kafka
  ports:
    - "9092:9092"
    - "29092:29092"
  environment:
    - KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
    - ALLOW_PLAINTEXT_LISTENER=yes
    - KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,PLAINTEXT_HOST://:29092
    - KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
  depends_on:
    - zookeeper
```

#### Redis (⏳ PRÓXIMO)
```yaml
redis:
  image: redis:7-alpine
  container_name: balconazo-redis
  ports:
    - "6379:6379"
  command: redis-server --appendonly yes
```

---

<a name="roadmap"></a>
## 🗺️ ROADMAP

### Fase 1: Backend Core (EN PROGRESO)
- [x] Configuración inicial del proyecto
- [x] catalog-service implementado y funcional
- [ ] Levantar Kafka + Zookeeper
- [ ] Crear tópicos de Kafka
- [ ] Probar publicación de eventos desde catalog
- [ ] Implementar booking-service
- [ ] Implementar search-pricing-service
- [ ] Implementar API Gateway

### Fase 2: Integración y Comunicación
- [ ] Configurar Redis para cache y locks
- [ ] Implementar Saga de booking con Outbox Pattern
- [ ] Implementar consumidores de eventos en search-pricing
- [ ] Integración con pasarela de pago (Stripe stub)
- [ ] Motor de pricing dinámico con Kafka Streams

### Fase 3: Frontend
- [ ] Setup Angular 20 con standalone components
- [ ] Configurar Tailwind CSS
- [ ] Implementar autenticación con JWT
- [ ] Páginas: Home, Búsqueda, Detalle, Booking, Perfil
- [ ] Integración con API Gateway

### Fase 4: Testing
- [ ] Unit tests (JUnit 5 + Mockito)
- [ ] Integration tests (Testcontainers)
- [ ] Contract testing (Spring Cloud Contract)
- [ ] E2E tests (Playwright)

### Fase 5: Producción
- [ ] Docker Compose completo para desarrollo
- [ ] CI/CD con GitHub Actions
- [ ] Deployment en AWS ECS/EKS
- [ ] Configuración AWS MSK (Kafka managed)
- [ ] Configuración AWS RDS (PostgreSQL managed)
- [ ] Configuración AWS ElastiCache (Redis managed)
- [ ] Monitoring con CloudWatch + Prometheus + Grafana

---

## 📞 COMANDOS ÚTILES

### Desarrollo Local

#### Arrancar catalog-service
```bash
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

#### Ver logs de PostgreSQL
```bash
docker logs balconazo-pg-catalog -f
```

#### Conectarse a PostgreSQL
```bash
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db
```

#### Health check
```bash
curl http://localhost:8085/actuator/health
```

#### Compilar proyecto
```bash
mvn clean install -DskipTests
```

### Docker

#### Ver contenedores corriendo
```bash
docker ps
```

#### Detener todos los contenedores
```bash
docker stop $(docker ps -q)
```

#### Limpiar volúmenes
```bash
docker volume prune -f
```

---

## 📚 REFERENCIAS

- [Spring Boot 3.5 Documentation](https://docs.spring.io/spring-boot/docs/3.5.7/reference/)
- [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [PostgreSQL 16 Documentation](https://www.postgresql.org/docs/16/)
- [Angular 20 Documentation](https://angular.dev/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Última actualización:** 27 de octubre de 2025  
**Versión:** 1.0.0  
**Estado:** Catalog Service Funcional ✅

