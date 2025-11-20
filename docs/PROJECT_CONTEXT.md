# 📘 PROJECT CONTEXT - BalconazoApp
## Documento Maestro de Contexto del Proyecto

**Versión:** 1.0.0  
**Fecha:** 20 de Noviembre de 2025  
**Estado:** Backend 100% Funcional | Frontend 70% Completado  
**Propósito:** Documento autosuficiente para que cualquier desarrollador o agente IA pueda continuar el proyecto

---

## 📋 ÍNDICE

1. [Descripción General del Sistema](#1-descripción-general-del-sistema)
2. [Arquitectura Técnica Completa](#2-arquitectura-técnica-completa)
3. [Stack Tecnológico](#3-stack-tecnológico)
4. [Estructura del Proyecto](#4-estructura-del-proyecto)
5. [Microservicios Detallados](#5-microservicios-detallados)
6. [Bases de Datos y Esquemas](#6-bases-de-datos-y-esquemas)
7. [Endpoints de API](#7-endpoints-de-api)
8. [Autenticación y Seguridad](#8-autenticación-y-seguridad)
9. [Guía de Inicio Rápido](#9-guía-de-inicio-rápido)
10. [Variables de Entorno](#10-variables-de-entorno)
11. [Datos de Prueba](#11-datos-de-prueba)
12. [Roadmap y Próximos Pasos](#12-roadmap-y-próximos-pasos)
13. [Decisiones Arquitectónicas](#13-decisiones-arquitectónicas)
14. [Estado Actual del Desarrollo](#14-estado-actual-del-desarrollo)
15. [Convenciones de Código](#15-convenciones-de-código)
16. [Testing](#16-testing)
17. [Troubleshooting](#17-troubleshooting)
18. [Frontend](#18-frontend)

---

## 1. DESCRIPCIÓN GENERAL DEL SISTEMA

### ¿Qué es BalconazoApp?

**BalconazoApp** es una plataforma marketplace de alquiler de espacios compartidos (terrazas, balcones, patios, azoteas) enfocada en eventos y reuniones. Similar a Airbnb pero especializada en espacios al aire libre y por horas.

### Propósito del Negocio

Conectar **propietarios de espacios únicos (hosts)** con **personas que buscan alquilar estos espacios por horas (guests)** para:
- Eventos privados (cumpleaños, cenas, reuniones)
- Sesiones de fotos/vídeo
- Reuniones corporativas al aire libre
- Clases y talleres
- Pop-up stores temporales

### Funcionalidad Principal

#### Para Guests:
1. **Buscar espacios** por ubicación (búsqueda geoespacial con radio)
2. **Filtrar** por capacidad, precio, amenities, rating
3. **Ver detalles** del espacio con galería de fotos
4. **Reservar** por horas (mínimo 1 hora)
5. **Pagar** con tarjeta (integración Stripe - pendiente)
6. **Dejar reseñas** después de usar el espacio
7. **Gestionar reservas** (upcoming, past, cancelaciones)

#### Para Hosts:
1. **Publicar espacios** con fotos, descripción, ubicación
2. **Gestionar disponibilidad** (calendario, horarios)
3. **Recibir solicitudes** de reserva
4. **Aceptar/Rechazar** reservas
5. **Ver ganancias** e historial de pagos
6. **Responder reseñas** de guests
7. **Pausar/Activar** espacios según necesidad

### Modelo de Negocio

- **Comisión:** 10-15% sobre cada transacción (pagada por el guest)
- **Pago a hosts:** 48-72 horas después de completar la reserva
- **Política de cancelación:** Flexible (hasta 24h antes) o Estricta (7 días antes)
- **Precio dinámico:** Algoritmo que ajusta precios según demanda (implementado pero no activo)

---

## 2. ARQUITECTURA TÉCNICA COMPLETA

### Patrón Arquitectónico

**Microservicios con Event-Driven Architecture**

#### Principios Aplicados:
- ✅ **Domain-Driven Design (DDD)**: Cada servicio tiene su bounded context
- ✅ **CQRS Parcial**: Separación de lectura (Search Service) y escritura (Catalog Service)
- ✅ **Event Sourcing Light**: Eventos Kafka para propagación de cambios
- ✅ **Outbox Pattern**: Garantiza consistencia eventual entre servicios
- ✅ **API Gateway Pattern**: Punto de entrada único con enrutamiento
- ✅ **Service Discovery**: Registro dinámico con Eureka
- ✅ **Circuit Breaker**: Resiliencia con Resilience4j

### Diagrama de Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENTE (Browser/Mobile)                    │
└──────────────────────────────┬──────────────────────────────────┘
                               │ HTTPS
┌──────────────────────────────▼──────────────────────────────────┐
│                      API GATEWAY (8080)                          │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ - Rate Limiting (5 req/s por IP) con Redis            │     │
│  │ - JWT Validation (OAuth2 Resource Server)             │     │
│  │ - Circuit Breaker (Resilience4j)                      │     │
│  │ - CORS Configuration                                  │     │
│  │ - Request/Response Logging                            │     │
│  │ - Route Predicates (path, method)                     │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                   ┌───────────┴──────────┐
                   │                      │
        ┌──────────▼────────┐  ┌─────────▼────────┐
        │  EUREKA SERVER    │  │   REDIS (6379)   │
        │    (8761)         │  │   - Cache        │
        │  Service Registry │  │   - Rate Limiter │
        └──────────┬────────┘  └──────────────────┘
                   │
        ┌──────────┴─────────────┬──────────────────┬────────────┐
        │                        │                  │            │
┌───────▼────────┐   ┌──────────▼─────┐   ┌───────▼────────┐  ┌─▼──────┐
│  AUTH SERVICE  │   │ CATALOG SERVICE│   │ BOOKING SERVICE│  │ SEARCH │
│    (8084)      │   │     (8085)     │   │     (8082)     │  │ (8083) │
│                │   │                │   │                │  │        │
│ - JWT Gen      │   │ - Spaces CRUD  │   │ - Bookings     │  │ - Geo  │
│ - User Mgmt    │   │ - Availability │   │ - Reviews      │  │ Search │
│ - Roles        │   │ - Images       │   │ - Payments     │  │        │
└────────┬───────┘   └────────┬───────┘   └────────┬───────┘  └───┬────┘
         │                    │                     │              │
    ┌────▼────┐          ┌────▼────┐          ┌────▼────┐    ┌───▼────┐
    │  MySQL  │          │PostgreSQL│         │PostgreSQL│   │PostGIS │
    │  (3307) │          │  (5433) │          │  (5434) │    │ (5435) │
    │ auth_db │          │catalog  │          │ booking │    │ search │
    └─────────┘          └─────────┘          └────┬────┘    └────────┘
                                                    │
                                   ┌────────────────┴────────────────┐
                                   │   KAFKA (9092) + Zookeeper      │
                                   │   Topics:                        │
                                   │   - space.events                 │
                                   │   - booking.events               │
                                   │   - review.events                │
                                   └──────────────┬──────────────────┘
                                                  │
                                   ┌──────────────▼──────────────────┐
                                   │   Event Consumers (async)        │
                                   │   - Search Service               │
                                   │   - Notification Service (future)│
                                   └──────────────────────────────────┘
```

### Flujo de una Request Típica

```
1. Cliente → POST https://balconazo.com/api/catalog/spaces
2. API Gateway → Valida JWT (extrae userId, role)
3. API Gateway → Check Rate Limit (Redis)
4. API Gateway → Consulta Eureka: "¿Dónde está catalog-service?"
5. Eureka → Responde: "localhost:8085"
6. API Gateway → Forward request con headers:
   - Authorization: Bearer {token}
   - X-User-Id: {userId}
   - X-User-Role: {role}
7. Catalog Service → Procesa request
8. Catalog Service → Guarda en PostgreSQL (catalog_db)
9. Catalog Service → Publica SpaceCreatedEvent a Kafka
10. Kafka → Propaga evento a consumers
11. Search Service → Consume evento
12. Search Service → Indexa en PostGIS (search_db)
13. Catalog Service → Response HTTP 201 Created
14. API Gateway → Forward response al cliente
15. Cliente ← Recibe JSON con el space creado
```

---

## 3. STACK TECNOLÓGICO

### Backend (Java)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Java** | 21 | Lenguaje principal |
| **Spring Boot** | 3.5.7 | Framework base |
| **Spring Cloud** | 2024.0.0 | Microservicios |
| **Spring Cloud Gateway** | - | API Gateway (WebFlux) |
| **Spring Cloud Netflix Eureka** | - | Service Discovery |
| **Spring Security** | 6.2.x | Autenticación JWT |
| **Spring Data JPA** | - | ORM con Hibernate |
| **Hibernate** | 6.6.x | ORM |
| **MapStruct** | 1.6.x | Mapeo DTO ↔ Entity |
| **Lombok** | Latest | Reducir boilerplate |
| **Jackson** | 2.15.x | Serialización JSON |
| **JJWT (Java JWT)** | 0.12.x | Generación/validación JWT |

### Bases de Datos

| Base de Datos | Versión | Puerto | Propósito |
|---------------|---------|--------|-----------|
| **MySQL** | 8.0 | 3307 | Auth Service (usuarios) |
| **PostgreSQL** | 16 | 5433 | Catalog Service (espacios) |
| **PostgreSQL** | 16 | 5434 | Booking Service (reservas) |
| **PostgreSQL + PostGIS** | 16 + 3.4 | 5435 | Search Service (geo) |

### Infraestructura

| Componente | Versión | Puerto | Propósito |
|------------|---------|--------|-----------|
| **Docker** | 20.x+ | - | Contenedores |
| **Docker Compose** | 2.x+ | - | Orquestación local |
| **Redis** | 7-alpine | 6379 | Cache + Rate Limiting |
| **Apache Kafka** | 3.9.x | 9092 | Message Broker |
| **Zookeeper** | 3.9.x | 2181 | Coordinación Kafka |

### Frontend (Angular)

| Tecnología | Versión | Propósito |
|------------|---------|-----------|
| **Angular** | 20.3.3 | Framework frontend |
| **TypeScript** | 5.x | Lenguaje |
| **RxJS** | 7.8.x | Programación reactiva |
| **SCSS** | - | Preprocesador CSS |
| **Leaflet** | 1.9.4 | Mapas interactivos |
| **ngx-toastr** | 19.1.0 | Notificaciones |
| **@auth0/angular-jwt** | 5.2.0 | Manejo JWT |

### Build y DevOps

| Herramienta | Versión | Propósito |
|-------------|---------|-----------|
| **Maven** | 3.9+ | Build Java |
| **Angular CLI** | 20.3.x | Build Angular |
| **Git** | 2.x+ | Control de versiones |

---

## 4. ESTRUCTURA DEL PROYECTO

### Directorio Raíz

```
BalconazoApp/
├── api-gateway/                    # API Gateway (Puerto 8080)
│   ├── src/main/java/com/balconazo/gateway/
│   │   ├── config/
│   │   │   ├── GatewayConfig.java
│   │   │   ├── SecurityConfig.java
│   │   │   └── RedisConfig.java
│   │   ├── controller/
│   │   │   ├── FallbackController.java
│   │   │   └── WelcomeController.java
│   │   └── ApiGatewayApplication.java
│   ├── src/main/resources/
│   │   └── application.yml
│   ├── pom.xml
│   └── README.md
│
├── eureka-server/                  # Service Discovery (Puerto 8761)
│   ├── src/main/java/com/balconazo/eureka/
│   │   └── EurekaServerApplication.java
│   ├── src/main/resources/
│   │   └── application.yml
│   └── pom.xml
│
├── auth-service/                   # Autenticación JWT (Puerto 8084)
│   ├── src/main/java/com/balconazo/auth/
│   │   ├── config/
│   │   │   └── SecurityConfig.java
│   │   ├── controller/
│   │   │   └── AuthController.java
│   │   ├── dto/
│   │   │   ├── LoginRequest.java
│   │   │   ├── LoginResponse.java
│   │   │   ├── RegisterRequest.java
│   │   │   └── UserResponse.java
│   │   ├── entity/
│   │   │   └── User.java
│   │   ├── filter/
│   │   │   └── JwtAuthenticationFilter.java
│   │   ├── repository/
│   │   │   └── UserRepository.java
│   │   ├── service/
│   │   │   ├── AuthService.java
│   │   │   └── JwtService.java
│   │   └── AuthServiceApplication.java
│   ├── src/main/resources/
│   │   └── application.properties
│   └── pom.xml
│
├── catalog_microservice/           # CRUD Espacios (Puerto 8085)
│   ├── src/main/java/com/balconazo/catalog_microservice/
│   │   ├── config/
│   │   │   └── RedisConfig.java
│   │   ├── constants/
│   │   │   └── CatalogConstants.java
│   │   ├── controller/
│   │   │   ├── SpaceController.java
│   │   │   ├── SpaceImageController.java
│   │   │   ├── AvailabilityController.java
│   │   │   └── CacheController.java
│   │   ├── dto/
│   │   │   ├── SpaceDTO.java
│   │   │   ├── CreateSpaceDTO.java
│   │   │   ├── UpdateSpaceDTO.java
│   │   │   └── SpaceImageDTO.java
│   │   ├── entity/
│   │   │   ├── Space.java
│   │   │   ├── SpaceImage.java
│   │   │   └── AvailabilitySlot.java
│   │   ├── event/
│   │   │   ├── EventPublisher.java
│   │   │   ├── SpaceCreatedEvent.java
│   │   │   └── SpaceUpdatedEvent.java
│   │   ├── mapper/
│   │   │   └── SpaceMapper.java
│   │   ├── repository/
│   │   │   ├── SpaceRepository.java
│   │   │   ├── SpaceImageRepository.java
│   │   │   └── AvailabilityRepository.java
│   │   ├── service/
│   │   │   ├── impl/
│   │   │   │   ├── SpaceServiceImpl.java
│   │   │   │   ├── SpaceImageServiceImpl.java
│   │   │   │   └── LocalStorageService.java
│   │   │   └── interfaces/
│   │   └── CatalogMicroserviceApplication.java
│   ├── uploads/                    # Imágenes subidas
│   └── pom.xml
│
├── booking_microservice/           # Reservas (Puerto 8082)
│   ├── src/main/java/com/balconazo/booking_microservice/
│   │   ├── controller/
│   │   │   ├── BookingController.java
│   │   │   └── ReviewController.java
│   │   ├── dto/
│   │   │   ├── BookingDTO.java
│   │   │   ├── CreateBookingDTO.java
│   │   │   ├── ReviewDTO.java
│   │   │   └── CreateReviewDTO.java
│   │   ├── entity/
│   │   │   ├── Booking.java
│   │   │   ├── Review.java
│   │   │   └── OutboxEvent.java
│   │   ├── enums/
│   │   │   ├── BookingStatus.java
│   │   │   └── PaymentStatus.java
│   │   ├── kafka/
│   │   │   ├── producer/
│   │   │   │   ├── OutboxService.java
│   │   │   │   └── OutboxRelayService.java
│   │   │   └── events/
│   │   ├── repository/
│   │   │   ├── BookingRepository.java
│   │   │   ├── ReviewRepository.java
│   │   │   └── OutboxRepository.java
│   │   ├── service/
│   │   │   ├── impl/
│   │   │   │   ├── BookingServiceImpl.java
│   │   │   │   └── ReviewServiceImpl.java
│   │   │   └── interfaces/
│   │   └── BookingMicroserviceApplication.java
│   └── pom.xml
│
├── search_microservice/            # Búsqueda Geo (Puerto 8083)
│   ├── src/main/java/com/balconazo/search_microservice/
│   │   ├── controller/
│   │   │   └── SearchController.java
│   │   ├── dto/
│   │   │   ├── SearchRequestDTO.java
│   │   │   └── SearchResponseDTO.java
│   │   ├── entity/
│   │   │   └── SpaceProjection.java
│   │   ├── kafka/
│   │   │   ├── SpaceEventConsumer.java
│   │   │   └── BookingEventConsumer.java
│   │   ├── repository/
│   │   │   └── SpaceProjectionRepository.java
│   │   ├── service/
│   │   │   └── SearchService.java
│   │   └── SearchMicroserviceApplication.java
│   └── pom.xml
│
├── balconazo-frontend/             # Angular App (Puerto 4200)
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/
│   │   │   │   ├── guards/
│   │   │   │   ├── interceptors/
│   │   │   │   ├── models/
│   │   │   │   └── services/
│   │   │   ├── features/
│   │   │   │   ├── auth/
│   │   │   │   ├── home/
│   │   │   │   ├── spaces/
│   │   │   │   ├── host/
│   │   │   │   └── bookings/
│   │   │   └── shared/
│   │   ├── assets/
│   │   ├── styles/
│   │   └── environments/
│   ├── angular.json
│   ├── package.json
│   └── tsconfig.json
│
├── ddl/                            # Scripts SQL
│   ├── init-postgres.sh
│   ├── catalog.sql
│   ├── booking.sql
│   ├── search.sql
│   └── test-data-*.sql
│
├── docs/                           # Documentación
│   ├── PROJECT_CONTEXT.md          # Este documento
│   ├── ADR_API_GATEWAY_SIN_PERSISTENCIA.md
│   ├── ADR_MODELO_ROLES_DINAMICOS.md
│   ├── PRICING_ALGORITHM.md
│   └── WIREFRAMES.md
│
├── docker-compose.yml              # Infraestructura Docker
├── pom.xml                         # Parent POM
├── README.md                       # Entrada principal
├── DOCUMENTATION.md                # Docs técnicas
├── DATABASE.md                     # Esquemas BD
├── CHANGELOG.md                    # Historial cambios
├── NEXT-STEPS.md                   # Roadmap
├── start-infrastructure.sh         # Inicia Docker
├── start-all-services.sh           # Inicia microservicios
├── stop-all.sh                     # Detiene todo
├── recompile-all.sh                # Recompila todo
└── test-e2e-completo.sh            # Tests E2E
```

### Convenciones de Nombres

#### Backend (Java)
- **Paquetes:** `com.balconazo.<servicio>.<capa>`
- **Clases:**
  - Entidades: `User`, `Space`, `Booking` (sin sufijo)
  - DTOs: `UserDTO`, `CreateSpaceDTO`, `UpdateBookingDTO`
  - Repositories: `UserRepository` (extends JpaRepository)
  - Services: `AuthService` (interface), `AuthServiceImpl` (impl)
  - Controllers: `AuthController`, `SpaceController`
  - Excepciones: `UserNotFoundException`, `BookingStateException`

#### Frontend (Angular)
- **Archivos:** kebab-case (`auth-login.component.ts`)
- **Clases:** PascalCase (`AuthLoginComponent`)
- **Interfaces:** PascalCase (`User`, `LoginRequest`)
- **Services:** PascalCase + Service (`AuthService`)
- **Guards:** PascalCase + Guard (`AuthGuard`)

---

## 5. MICROSERVICIOS DETALLADOS

### 5.1 API Gateway (Puerto 8080)

**Responsabilidad:** Punto de entrada único al sistema

**Características:**
- Spring Cloud Gateway (WebFlux - no bloqueante)
- OAuth2 Resource Server para JWT
- Rate Limiting con Redis (5 req/s por IP)
- Circuit Breaker con Resilience4j
- CORS configurado para desarrollo
- Request/Response logging
- Health checks en `/actuator/health`

**Rutas Configuradas:**

| Path | Destino | Filtros | Público |
|------|---------|---------|---------|
| `/api/auth/**` | auth-service (8084) | - | ✅ Sí |
| `/api/catalog/**` | catalog-service (8085) | JWT required | ❌ No |
| `/api/booking/**` | booking-service (8082) | JWT required | ❌ No |
| `/api/search/**` | search-service (8083) | - | ✅ Sí |

**application.yml:**
```yaml
server:
  port: 8080

spring:
  application:
    name: api-gateway
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: lb://auth-service
          predicates:
            - Path=/api/auth/**
          filters:
            - StripPrefix=1
        
        - id: catalog-service
          uri: lb://catalog-service
          predicates:
            - Path=/api/catalog/**
          filters:
            - StripPrefix=1
            - name: CircuitBreaker
              args:
                name: catalogCircuitBreaker
                fallbackUri: forward:/fallback/catalog
        
        - id: booking-service
          uri: lb://booking-service
          predicates:
            - Path=/api/booking/**
          filters:
            - StripPrefix=1
        
        - id: search-service
          uri: lb://search-service
          predicates:
            - Path=/api/search/**
          filters:
            - StripPrefix=1

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

**Sin Persistencia:** El Gateway NO tiene base de datos propia. Solo enruta y valida JWTs.

---

### 5.2 Eureka Server (Puerto 8761)

**Responsabilidad:** Service Discovery

**Dashboard:** http://localhost:8761

**Servicios Registrados:**
- api-gateway
- auth-service
- catalog-service
- booking-service
- search-service

**application.yml:**
```yaml
server:
  port: 8761

spring:
  application:
    name: eureka-server

eureka:
  instance:
    hostname: localhost
  client:
    register-with-eureka: false
    fetch-registry: false
    service-url:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
```

---

### 5.3 Auth Service (Puerto 8084)

**Responsabilidad:** Autenticación y gestión de usuarios

**Base de Datos:** MySQL `auth_db` (puerto 3307)

**Entidades:**
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String passwordHash;  // BCrypt
    
    @Enumerated(EnumType.STRING)
    private Role role;  // HOST, GUEST, ADMIN
    
    private String status;  // active, suspended
    private Integer trustScore;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**Endpoints:**

```java
POST   /api/auth/register
       Body: { "email", "password", "role" }
       Response: UserDTO

POST   /api/auth/login
       Body: { "email", "password" }
       Response: { "accessToken", "refreshToken", "userId", "email", "role" }

POST   /api/auth/refresh
       Body: { "refreshToken" }
       Response: { "accessToken", "refreshToken" }

GET    /api/auth/me
       Headers: Authorization: Bearer {token}
       Response: UserDTO

PUT    /api/auth/profile
       Body: { "firstName", "lastName", ... }
       Response: UserDTO

POST   /api/auth/logout
       Response: 204 No Content
```

**JWT Claims:**
```json
{
  "sub": "userId (UUID)",
  "email": "user@example.com",
  "role": "HOST",
  "iat": 1700000000,
  "exp": 1700086400
}
```

**JWT Config:**
- Algoritmo: HS512 (symmetric)
- Secret: Variable de entorno `JWT_SECRET` (default: key de 64 chars)
- Expiración Access Token: 24 horas
- Expiración Refresh Token: 7 días

**Seguridad:**
- Passwords hasheados con BCrypt (strength 12)
- JWT solo contiene claims públicos (no password)
- Refresh tokens almacenados en BD (pendiente implementar)
- Logout invalida token (futuro: blacklist en Redis)

---

### 5.4 Catalog Service (Puerto 8085)

**Responsabilidad:** CRUD de espacios y disponibilidad

**Base de Datos:** PostgreSQL `catalog_db` (puerto 5433)

**Entidades:**

```java
@Entity
@Table(name = "spaces", schema = "catalog")
public class Space {
    @Id
    @GeneratedValue
    private UUID id;
    
    private UUID ownerId;
    private String title;
    private String description;
    private String address;
    
    private Double lat;
    private Double lon;
    
    private Integer capacity;
    private Integer basePriceCents;  // Precio en centavos
    private BigDecimal areaSqm;
    
    @Column(columnDefinition = "text[]")
    private String[] amenities;
    
    @Column(columnDefinition = "jsonb")
    private String rules;
    
    private String status;  // ACTIVE, SNOOZED, DELETED, DRAFT
    
    @OneToMany(mappedBy = "space", cascade = CascadeType.ALL)
    private List<SpaceImage> images;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

@Entity
@Table(name = "space_images", schema = "catalog")
public class SpaceImage {
    @Id
    @GeneratedValue
    private UUID id;
    
    @ManyToOne
    @JoinColumn(name = "space_id")
    private Space space;
    
    private String url;
    private Boolean isPrimary;
    private Integer displayOrder;
    private LocalDateTime uploadedAt;
}

@Entity
@Table(name = "availability_slots", schema = "catalog")
public class AvailabilitySlot {
    @Id
    @GeneratedValue
    private UUID id;
    
    @ManyToOne
    @JoinColumn(name = "space_id")
    private Space space;
    
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Boolean isAvailable;
}
```

**Endpoints:**

```java
// Spaces
POST   /api/catalog/spaces
GET    /api/catalog/spaces
GET    /api/catalog/spaces/{id}
PUT    /api/catalog/spaces/{id}
DELETE /api/catalog/spaces/{id}
GET    /api/catalog/spaces/active
GET    /api/catalog/spaces/owner/{ownerId}
POST   /api/catalog/spaces/{id}/activate
POST   /api/catalog/spaces/{id}/deactivate

// Images
POST   /api/catalog/spaces/{spaceId}/images
GET    /api/catalog/spaces/{spaceId}/images
DELETE /api/catalog/spaces/{spaceId}/images/{imageId}
PUT    /api/catalog/spaces/{spaceId}/images/{imageId}/primary

// Availability
POST   /api/catalog/spaces/{spaceId}/availability
GET    /api/catalog/spaces/{spaceId}/availability
DELETE /api/catalog/availability/{slotId}

// Cache Management
POST   /api/catalog/cache/clear
POST   /api/catalog/cache/warmup
```

**Estados de Spaces:**

| Estado | Descripción | Visible en búsqueda | Reservable |
|--------|-------------|---------------------|------------|
| `ACTIVE` | Publicado y visible | ✅ | ✅ |
| `SNOOZED` | Pausado temporalmente | ❌ | ❌ |
| `DELETED` | Soft delete | ❌ | ❌ |
| `DRAFT` | Borrador (no usado actualmente) | ❌ | ❌ |

**Eventos Kafka Publicados:**

```java
// space.events topic
{
  "eventType": "SpaceCreated",
  "aggregateId": "uuid",
  "payload": {
    "spaceId": "uuid",
    "ownerId": "uuid",
    "title": "string",
    "lat": 40.4168,
    "lon": -3.7038,
    ...
  },
  "timestamp": "2025-11-20T10:00:00"
}
```

**Caché con Redis:**
- Key pattern: `space:{id}`
- TTL: 5 minutos
- Invalidación: al actualizar/eliminar espacio
- Cache-aside pattern

---

### 5.5 Booking Service (Puerto 8082)

**Responsabilidad:** Gestión de reservas y reseñas

**Base de Datos:** PostgreSQL `booking_db` (puerto 5434)

**Entidades:**

```java
@Entity
@Table(name = "bookings", schema = "booking")
public class Booking {
    @Id
    @GeneratedValue
    private UUID id;
    
    private UUID spaceId;
    private UUID guestId;
    
    private LocalDateTime startTs;
    private LocalDateTime endTs;
    private Integer numGuests;
    
    private Integer totalPriceCents;
    
    @Enumerated(EnumType.STRING)
    private BookingStatus status;  // pending, confirmed, completed, cancelled
    
    @Enumerated(EnumType.STRING)
    private PaymentStatus paymentStatus;  // pending, processing, succeeded, failed, refunded
    
    private String paymentIntentId;  // Stripe payment intent
    private String cancellationReason;
    
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

@Entity
@Table(name = "reviews", schema = "booking")
public class Review {
    @Id
    @GeneratedValue
    private UUID id;
    
    @OneToOne
    @JoinColumn(name = "booking_id", unique = true)
    private Booking booking;
    
    private UUID spaceId;
    private UUID guestId;  // reviewer
    
    @Column(nullable = false)
    private Integer rating;  // 1-5
    
    private String comment;
    private LocalDateTime createdAt;
}

@Entity
@Table(name = "outbox_events", schema = "booking")
public class OutboxEvent {
    @Id
    @GeneratedValue
    private UUID id;
    
    private UUID aggregateId;
    private String eventType;
    
    @Column(columnDefinition = "jsonb")
    private String payload;
    
    private Boolean processed;
    private LocalDateTime createdAt;
    private LocalDateTime processedAt;
}
```

**Endpoints:**

```java
// Bookings
POST   /api/booking/bookings
       Body: { "spaceId", "guestId", "startTs", "endTs", "numGuests" }
       
GET    /api/booking/bookings/{id}
GET    /api/booking/bookings/guest/{guestId}
GET    /api/booking/bookings/space/{spaceId}

POST   /api/booking/bookings/{id}/confirm?paymentIntentId=pi_xxx
POST   /api/booking/bookings/{id}/complete
POST   /api/booking/bookings/{id}/cancel?reason=...

// Reviews
POST   /api/booking/reviews
       Body: { "bookingId", "rating", "comment" }
       
GET    /api/booking/reviews/{id}
GET    /api/booking/reviews/space/{spaceId}
GET    /api/booking/reviews/reviewer/{guestId}
```

**Flujo de Estados de Booking:**

```
     ┌─────────┐
     │ pending │ (se crea la reserva, payment pending)
     └────┬────┘
          │
     (confirm + paymentIntentId)
          │
     ┌────▼────────┐
     │  confirmed  │ (pago confirmado, reserva activa)
     └────┬────────┘
          │
     (complete - después de la fecha)
          │
     ┌────▼────────┐
     │  completed  │ (puede dejar review)
     └─────────────┘
     
     Desde pending o confirmed:
          │
     (cancel)
          │
     ┌────▼────────┐
     │  cancelled  │
     └─────────────┘
```

**Validaciones de Negocio:**

```java
// BookingServiceImpl.java
- Duración mínima: 1 hora
- No overlap con otras reservas del mismo espacio
- startTs debe ser futuro (al crear)
- endTs > startTs
- numGuests <= capacity del espacio
- Solo se puede cancelar con 1h de antelación
- Solo se puede hacer review de bookings "completed"
- Solo 1 review por booking
```

**Eventos Kafka:**

```java
// booking.events topic
{
  "eventType": "BookingConfirmed",
  "aggregateId": "booking-uuid",
  "payload": {
    "bookingId": "uuid",
    "spaceId": "uuid",
    "guestId": "uuid",
    "startTs": "2025-12-01T10:00:00",
    "endTs": "2025-12-01T14:00:00",
    "totalPriceCents": 14000
  }
}

{
  "eventType": "ReviewCreated",
  "payload": {
    "reviewId": "uuid",
    "spaceId": "uuid",
    "rating": 5
  }
}
```

**Patrón Outbox:**
- Todas las operaciones que publican eventos usan transacciones
- Evento se guarda en tabla `outbox_events` (misma transacción)
- Job scheduled cada 5 segundos envía eventos pendientes a Kafka
- Marca eventos como `processed = true`
- Garantiza consistencia eventual

---

### 5.6 Search Service (Puerto 8083)

**Responsabilidad:** Búsqueda geoespacial optimizada

**Base de Datos:** PostgreSQL + PostGIS `search_db` (puerto 5435)

**Entidad:**

```java
@Entity
@Table(name = "spaces_projection", schema = "search")
public class SpaceProjection {
    @Id
    private UUID spaceId;
    
    private UUID ownerId;
    private String ownerEmail;
    
    private String title;
    private String description;
    private String address;
    
    @Column(columnDefinition = "geometry(Point, 4326)")
    private Point geo;  // PostGIS Point con SRID 4326 (WGS84)
    
    private Integer capacity;
    private BigDecimal areaSqm;
    private Integer basePriceCents;
    
    @Column(columnDefinition = "text[]")
    private String[] amenities;
    
    private String status;
    
    private Double avgRating;  // Calculado desde reviews
    private Integer totalReviews;
    
    private LocalDateTime createdAt;
}
```

**Índices PostGIS:**

```sql
-- Índice espacial GIST (clave para performance)
CREATE INDEX idx_spaces_geo ON search.spaces_projection USING GIST(geo);

-- Índices adicionales
CREATE INDEX idx_spaces_status ON search.spaces_projection(status);
CREATE INDEX idx_spaces_price ON search.spaces_projection(base_price_cents);
CREATE INDEX idx_spaces_rating ON search.spaces_projection(avg_rating);
```

**Endpoints:**

```java
GET    /api/search/spaces?lat={lat}&lon={lon}&radius={km}&minCapacity={n}&maxPrice={cents}&page={page}&pageSize={size}

POST   /api/search/spaces/filter
       Body: {
         "lat": 40.4168,
         "lon": -3.7038,
         "radiusKm": 10,
         "minCapacity": 5,
         "maxPrice": 10000,
         "minRating": 4.0,
         "amenities": ["wifi", "parking"],
         "page": 0,
         "pageSize": 20
       }

GET    /api/search/spaces/{spaceId}
```

**Query Geoespacial:**

```sql
SELECT 
    s.space_id,
    s.title,
    s.base_price_cents,
    s.capacity,
    s.avg_rating,
    ST_Distance(
        s.geo::geography,
        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
    ) / 1000 AS distance_km
FROM search.spaces_projection s
WHERE ST_DWithin(
    s.geo::geography,
    ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
    :radiusMeters
)
AND UPPER(s.status) = 'ACTIVE'
AND s.capacity >= :minCapacity
AND (:maxPrice IS NULL OR s.base_price_cents <= :maxPrice)
AND (:minRating IS NULL OR s.avg_rating >= :minRating)
ORDER BY distance_km ASC
LIMIT :pageSize OFFSET :offset;
```

**Kafka Consumers:**

```java
@KafkaListener(topics = "space.events", groupId = "search-service")
public void handleSpaceEvent(String eventJson) {
    SpaceEvent event = parse(eventJson);
    
    switch(event.getEventType()) {
        case "SpaceCreated":
            createProjection(event);
            break;
        case "SpaceUpdated":
            updateProjection(event);
            break;
        case "SpaceDeleted":
            deleteProjection(event);
            break;
    }
}

@KafkaListener(topics = "review.events", groupId = "search-service")
public void handleReviewEvent(String eventJson) {
    ReviewEvent event = parse(eventJson);
    
    // Recalcular avg_rating del espacio
    UUID spaceId = event.getSpaceId();
    Double newAvgRating = calculateAvgRating(spaceId);
    Integer totalReviews = countReviews(spaceId);
    
    updateRating(spaceId, newAvgRating, totalReviews);
}
```

**Ventajas de Search Service:**
- **Read Model Optimizado**: Solo datos necesarios para búsqueda
- **PostGIS**: Queries geoespaciales ultra rápidas (índice GIST)
- **Desnormalización**: Evita JOINs, todo en una tabla
- **Consistencia Eventual**: OK para búsquedas (no crítico)
- **Escalable**: Puede tener réplicas read-only

---

## 6. BASES DE DATOS Y ESQUEMAS

### 6.1 Acceso a Bases de Datos

**Conectarse a MySQL (Auth):**
```bash
docker exec -it balconazo-mysql-auth mysql -uroot -proot auth_db
```

**Conectarse a PostgreSQL (Catalog):**
```bash
docker exec -e PGPASSWORD=postgres -it balconazo-pg-catalog psql -U postgres -d catalog_db
```

**Conectarse a PostgreSQL (Booking):**
```bash
docker exec -e PGPASSWORD=postgres -it balconazo-pg-booking psql -U postgres -d booking_db
```

**Conectarse a PostgreSQL + PostGIS (Search):**
```bash
docker exec -e PGPASSWORD=postgres -it balconazo-pg-search psql -U postgres -d search_db
```

### 6.2 Esquemas Completos

#### Auth Service (MySQL)

```sql
CREATE DATABASE auth_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE auth_db;

CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('HOST', 'GUEST', 'ADMIN')),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    trust_score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB;
```

#### Catalog Service (PostgreSQL)

```sql
CREATE SCHEMA IF NOT EXISTS catalog;

CREATE TABLE catalog.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE catalog.spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES catalog.users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    base_price_cents INT NOT NULL CHECK (base_price_cents > 0),
    area_sqm DECIMAL(6,2),
    amenities TEXT[],
    rules JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_space_owner ON catalog.spaces(owner_id);
CREATE INDEX idx_space_status ON catalog.spaces(status);
CREATE INDEX idx_space_location ON catalog.spaces(lat, lon);

CREATE TABLE catalog.space_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL REFERENCES catalog.spaces(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    display_order INT DEFAULT 0,
    uploaded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_image_space ON catalog.space_images(space_id);

CREATE TABLE catalog.availability_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL REFERENCES catalog.spaces(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    CHECK (end_time > start_time)
);

CREATE INDEX idx_availability_space ON catalog.availability_slots(space_id);
CREATE INDEX idx_availability_dates ON catalog.availability_slots(start_time, end_time);
```

#### Booking Service (PostgreSQL)

```sql
CREATE SCHEMA IF NOT EXISTS booking;

CREATE TABLE booking.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP NOT NULL,
    num_guests INT NOT NULL CHECK (num_guests > 0),
    total_price_cents INT NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    payment_intent_id VARCHAR(255),
    payment_status VARCHAR(50) CHECK (payment_status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded')),
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_booking_guest ON booking.bookings(guest_id);
CREATE INDEX idx_booking_space ON booking.bookings(space_id);
CREATE INDEX idx_booking_dates ON booking.bookings(start_ts, end_ts);
CREATE INDEX idx_booking_status ON booking.bookings(status);

CREATE TABLE booking.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL UNIQUE REFERENCES booking.bookings(id),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_review_space ON booking.reviews(space_id);
CREATE INDEX idx_review_guest ON booking.reviews(guest_id);
CREATE INDEX idx_review_rating ON booking.reviews(rating);

CREATE TABLE booking.outbox_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP
);

CREATE INDEX idx_outbox_processed ON booking.outbox_events(processed, created_at);
```

#### Search Service (PostgreSQL + PostGIS)

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS search;

CREATE TABLE search.spaces_projection (
    space_id UUID PRIMARY KEY,
    owner_id UUID NOT NULL,
    owner_email VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255),
    geo GEOMETRY(POINT, 4326) NOT NULL,
    capacity INT NOT NULL,
    area_sqm DECIMAL(6,2),
    base_price_cents INT NOT NULL,
    amenities TEXT[],
    status VARCHAR(50) NOT NULL,
    avg_rating DOUBLE PRECISION DEFAULT 0,
    total_reviews INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índice espacial (CRÍTICO para performance)
CREATE INDEX idx_spaces_geo ON search.spaces_projection USING GIST(geo);

CREATE INDEX idx_spaces_status ON search.spaces_projection(status);
CREATE INDEX idx_spaces_price ON search.spaces_projection(base_price_cents);
CREATE INDEX idx_spaces_capacity ON search.spaces_projection(capacity);
CREATE INDEX idx_spaces_rating ON search.spaces_projection(avg_rating);
```

---

## 7. ENDPOINTS DE API

### 7.1 Auth Service (18 endpoints)

#### Autenticación

**POST /api/auth/register**
```json
// Request
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "role": "HOST"
}

// Response 201 Created
{
  "id": "uuid",
  "email": "user@example.com",
  "role": "HOST",
  "status": "active",
  "createdAt": "2025-11-20T10:00:00"
}
```

**POST /api/auth/login**
```json
// Request
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

// Response 200 OK
{
  "accessToken": "eyJhbGci...",
  "refreshToken": "eyJhbGci...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "userId": "uuid",
  "email": "user@example.com",
  "role": "HOST"
}
```

**GET /api/auth/me**
```bash
curl http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer {token}"

# Response 200 OK
{
  "id": "uuid",
  "email": "user@example.com",
  "role": "HOST",
  "trustScore": 85
}
```

**POST /api/auth/refresh**
```json
// Request
{
  "refreshToken": "eyJhbGci..."
}

// Response 200 OK
{
  "accessToken": "new-token",
  "refreshToken": "new-refresh-token"
}
```

---

### 7.2 Catalog Service (15 endpoints)

**POST /api/catalog/spaces**
```json
// Request (JWT required)
{
  "title": "Terraza con vistas",
  "description": "Espacio amplio...",
  "ownerId": "host-uuid",
  "address": "Calle Gran Vía 28, Madrid",
  "lat": 40.4200,
  "lon": -3.7050,
  "capacity": 15,
  "basePriceCents": 3500,
  "areaSqm": 50.5,
  "amenities": ["wifi", "parking", "bar"],
  "rules": {"smoking": false, "pets": true}
}

// Response 201 Created
{
  "id": "uuid",
  "title": "Terraza con vistas",
  "status": "ACTIVE",
  ...
}
```

**GET /api/catalog/spaces**
```bash
curl http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer {token}"

# Response 200 OK
[
  {
    "id": "uuid",
    "title": "Terraza...",
    "basePriceCents": 3500,
    "capacity": 15,
    "status": "ACTIVE",
    "images": [...]
  },
  ...
]
```

**GET /api/catalog/spaces/{id}**
```bash
curl http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa \
  -H "Authorization: Bearer {token}"

# Response 200 OK con SpaceDTO completo + imágenes
```

**PUT /api/catalog/spaces/{id}**
```json
// Request
{
  "title": "Nuevo título",
  "basePriceCents": 4000,
  ...
}
```

**POST /api/catalog/spaces/{id}/images**
```bash
curl -X POST http://localhost:8080/api/catalog/spaces/{id}/images \
  -H "Authorization: Bearer {token}" \
  -F "file=@imagen.jpg"

# Response 200 OK con SpaceImageDTO
```

---

### 7.3 Booking Service (12 endpoints)

**POST /api/booking/bookings**
```json
// Request
{
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTs": "2025-12-01T10:00:00",
  "endTs": "2025-12-01T14:00:00",
  "numGuests": 8
}

// Response 201 Created
{
  "id": "booking-uuid",
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTs": "2025-12-01T10:00:00",
  "endTs": "2025-12-01T14:00:00",
  "numGuests": 8,
  "totalPriceCents": 14000,
  "status": "pending",
  "paymentStatus": "pending"
}
```

**POST /api/booking/bookings/{id}/confirm**
```bash
curl -X POST "http://localhost:8080/api/booking/bookings/{id}/confirm?paymentIntentId=pi_xxx" \
  -H "Authorization: Bearer {token}"

# Response 200 OK (status cambia a "confirmed")
```

**POST /api/booking/reviews**
```json
// Request (solo para bookings "completed")
{
  "bookingId": "uuid",
  "rating": 5,
  "comment": "Excelente espacio!"
}

// Response 201 Created
```

---

### 7.4 Search Service (3 endpoints)

**GET /api/search/spaces (búsqueda geoespacial)**
```bash
# Público (sin JWT)
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5&minCapacity=10&page=0&pageSize=20"

# Response 200 OK
{
  "content": [
    {
      "spaceId": "uuid",
      "title": "Terraza Retiro",
      "basePriceCents": 3500,
      "capacity": 15,
      "avgRating": 4.8,
      "totalReviews": 12,
      "distanceKm": 1.2
    },
    ...
  ],
  "totalElements": 45,
  "totalPages": 3,
  "currentPage": 0
}
```

**POST /api/search/spaces/filter (búsqueda con filtros avanzados)**
```json
// Request
{
  "lat": 40.4168,
  "lon": -3.7038,
  "radiusKm": 10,
  "minCapacity": 5,
  "maxPrice": 10000,
  "minRating": 4.0,
  "amenities": ["wifi", "parking"],
  "page": 0,
  "pageSize": 20
}
```

---

## 8. AUTENTICACIÓN Y SEGURIDAD

### 8.1 Flujo de Autenticación Completo

```
┌─────────┐                ┌──────────────┐              ┌──────────────┐
│ Cliente │                │ API Gateway  │              │ Auth Service │
└────┬────┘                └──────┬───────┘              └──────┬───────┘
     │                            │                             │
     │ 1. POST /api/auth/login    │                             │
     │ {"email","password"}       │                             │
     ├───────────────────────────>│ 2. Forward request          │
     │                            ├────────────────────────────>│
     │                            │                             │ 3. Validar
     │                            │                             │    credenciales
     │                            │                             │    (BCrypt)
     │                            │                             │
     │                            │ 4. JWT generado             │
     │                            │    (HS512, 24h exp)         │
     │                            │<────────────────────────────┤
     │ 5. {"accessToken",         │                             │
     │     "refreshToken"}        │                             │
     │<───────────────────────────┤                             │
     │                            │                             │
     │ 6. GET /api/catalog/spaces │                             │
     │    Header: Authorization:  │                             │
     │    Bearer {token}          │                             │
     ├───────────────────────────>│ 7. Validar JWT              │
     │                            │    - Verificar firma (HS512)│
     │                            │    - Check expiration       │
     │                            │    - Extraer claims         │
     │                            │                             │
     │                            │ 8. Forward + Headers        │
     │                            │    X-User-Id: {userId}      │
     │                            │    X-User-Role: {role}      │
┌────▼─────────┐                  └──────┬───────┘              │
│   Catalog    │                         │                      │
│   Service    │<────────────────────────┘                      │
└──────┬───────┘                                                │
       │ 9. Usar headers para lógica                            │
       │    de negocio (ownership, etc)                         │
       │                                                        │
       │ 10. Response                                           │
       └────────────────────────────────────────────────────────┘
```

### 8.2 Configuración de Seguridad

**API Gateway (SecurityConfig.java):**
```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {
    
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .authorizeExchange(exchanges -> exchanges
                .pathMatchers("/", "/actuator/**").permitAll()
                .pathMatchers("/api/auth/**").permitAll()
                .pathMatchers("/api/search/**").permitAll()
                .anyExchange().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt.jwtDecoder(jwtDecoder()))
            )
            .build();
    }
    
    @Bean
    public ReactiveJwtDecoder jwtDecoder() {
        SecretKey key = new SecretKeySpec(
            jwtSecret.getBytes(StandardCharsets.UTF_8),
            "HmacSHA512"
        );
        return NimbusReactiveJwtDecoder
            .withSecretKey(key)
            .macAlgorithm(MacAlgorithm.HS512)
            .build();
    }
}
```

**Microservicios (SecurityConfig.java):**
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    private final JwtAuthenticationFilter jwtAuthFilter;
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**", "/error").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }
}
```

### 8.3 Roles y Permisos

| Rol | Puede hacer |
|-----|-------------|
| **GUEST** | - Buscar espacios<br>- Crear reservas<br>- Dejar reseñas<br>- Ver su perfil |
| **HOST** | - Todo lo de GUEST<br>- Crear/editar/eliminar espacios<br>- Gestionar reservas recibidas<br>- Responder reseñas |
| **ADMIN** | - Todo (futuro) |

---

## 9. GUÍA DE INICIO RÁPIDO

### 9.1 Requisitos Previos

```bash
# Java 21
java -version  # Debe ser 21.x

# Maven 3.9+
mvn -version

# Docker Desktop
docker --version
docker-compose --version

# Node.js 18+ (para frontend)
node --version
npm --version
```

### 9.2 Iniciar el Sistema (5 pasos)

**Paso 1: Clonar repositorio**
```bash
git clone https://github.com/amolrod/balconazo-scalable-marketplace.git
cd BalconazoApp
```

**Paso 2: Iniciar infraestructura Docker**
```bash
./start-infrastructure.sh

# Verificar contenedores
docker ps
# Debe mostrar: mysql-auth, pg-catalog, pg-booking, pg-search, redis, kafka, zookeeper
```

**Paso 3: Compilar microservicios**
```bash
./recompile-all.sh
# Tiempo estimado: 2-3 minutos
```

**Paso 4: Iniciar microservicios**
```bash
./start-all-services.sh
# Inicia en orden: Eureka → Gateway → Auth → Catalog → Booking → Search
# Tiempo de arranque: ~45 segundos
```

**Paso 5: Verificar estado**
```bash
./comprobacionmicroservicios.sh

# Salida esperada:
# ✅ API Gateway UP (200)
# ✅ Eureka Server UP (200)
# ✅ Auth Service UP (200)
# ✅ Catalog Service UP (200)
# ✅ Booking Service UP (200)
# ✅ Search Service UP (200)
```

### 9.3 Insertar Datos de Prueba

```bash
# Datos en Auth + Catalog
./insert-test-data.sh

# Datos en Search
./insert-search-test-data.sh

# Datos de Bookings
./reset-bookings-test-data.sh
```

### 9.4 Probar el Sistema

```bash
# Obtener token JWT
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

echo "Token: ${TOKEN:0:50}..."

# Buscar espacios (público, sin token)
curl -s "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5" | jq

# Obtener perfil
curl -s http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN" | jq

# Listar espacios
curl -s http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN" | jq
```

### 9.5 Iniciar Frontend (opcional)

```bash
cd balconazo-frontend

# Instalar dependencias (primera vez)
npm install

# Iniciar dev server
ng serve

# Abrir http://localhost:4200
```

---

## 10. VARIABLES DE ENTORNO

### 10.1 Auth Service

```properties
# application.properties
server.port=8084
spring.application.name=auth-service

# MySQL
spring.datasource.url=jdbc:mysql://localhost:3307/auth_db
spring.datasource.username=root
spring.datasource.password=root

# JWT
jwt.secret=${JWT_SECRET:VerySecureSecretKeyForHS512AtLeast64CharactersLongForProduction}
jwt.expiration=86400000
jwt.refresh-expiration=604800000

# Eureka
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
```

### 10.2 Catalog Service

```properties
server.port=8085
spring.application.name=catalog-service

# PostgreSQL
spring.datasource.url=jdbc:postgresql://localhost:5433/catalog_db
spring.datasource.username=postgres
spring.datasource.password=postgres

# Redis
spring.data.redis.host=localhost
spring.data.redis.port=6379

# Kafka
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer

# Upload de imágenes
file.upload.dir=/Users/angel/Desktop/BalconazoApp/catalog_microservice/uploads
file.max-size=5MB

# Eureka
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
```

### 10.3 Booking Service

```properties
server.port=8082
spring.application.name=booking-service

# PostgreSQL
spring.datasource.url=jdbc:postgresql://localhost:5434/booking_db
spring.datasource.username=postgres
spring.datasource.password=postgres

# Kafka
spring.kafka.bootstrap-servers=localhost:9092

# Políticas de cancelación
booking.cancellation.deadline-hours=1

# Eureka
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
```

### 10.4 Search Service

```properties
server.port=8083
spring.application.name=search-service

# PostgreSQL + PostGIS
spring.datasource.url=jdbc:postgresql://localhost:5435/search_db
spring.datasource.username=postgres
spring.datasource.password=postgres

# Kafka Consumer
spring.kafka.bootstrap-servers=localhost:9092
spring.kafka.consumer.group-id=search-service
spring.kafka.consumer.auto-offset-reset=earliest

# Eureka
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
```

### 10.5 Variables de Entorno para Producción

```bash
# .env (NO commitear)
# JWT
JWT_SECRET=SuperSecureProductionSecretKeyAtLeast64CharactersForHS512Algorithm

# MySQL Auth
AUTH_DB_HOST=prod-mysql.example.com
AUTH_DB_PORT=3306
AUTH_DB_NAME=auth_db
AUTH_DB_USER=balconazo_user
AUTH_DB_PASSWORD=super_secure_password

# PostgreSQL Catalog
CATALOG_DB_HOST=prod-pg-catalog.example.com
CATALOG_DB_PORT=5432
CATALOG_DB_NAME=catalog_db
CATALOG_DB_USER=catalog_user
CATALOG_DB_PASSWORD=super_secure_password

# Redis
REDIS_HOST=prod-redis.example.com
REDIS_PORT=6379
REDIS_PASSWORD=redis_password

# Kafka
KAFKA_BOOTSTRAP_SERVERS=prod-kafka-1:9092,prod-kafka-2:9092,prod-kafka-3:9092

# Stripe (pagos)
STRIPE_API_KEY=sk_live_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx

# Frontend
VITE_API_URL=https://api.balconazo.com
```

---

## 11. DATOS DE PRUEBA

### 11.1 Usuarios de Prueba

| Email | Password | Role | ID |
|-------|----------|------|----|
| host1@balconazo.com | password123 | HOST | 11111111-1111-1111-1111-111111111111 |
| host2@balconazo.com | password123 | HOST | 22222222-2222-2222-2222-222222222222 |
| guest1@balconazo.com | password123 | GUEST | 33333333-3333-3333-3333-333333333333 |
| guest2@balconazo.com | password123 | GUEST | 44444444-4444-4444-4444-444444444444 |
| admin@balconazo.com | password123 | ADMIN | 55555555-5555-5555-5555-555555555555 |

### 11.2 Espacios de Prueba

| Título | ID | Owner | Precio/h | Capacidad | Estado |
|--------|----|-|----------|-----------|--------|
| Ático con terraza | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa | host1 | 35€ | 15 | ACTIVE |
| Loft industrial | bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb | host1 | 50€ | 20 | ACTIVE |
| Azotea Retiro | cccccccc-cccc-cccc-cccc-cccccccccccc | host2 | 75€ | 30 | ACTIVE |
| Sala reuniones | dddddddd-dddd-dddd-dddd-dddddddddddd | host2 | 25€ | 10 | ACTIVE |
| Jardín Chamberí | eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee | admin | 100€ | 50 | ACTIVE |
| Estudio foto | ffffffff-ffff-ffff-ffff-ffffffffffff | host1 | 40€ | 8 | DRAFT |

### 11.3 Reservas de Prueba

| ID | Space | Guest | Fecha | Estado |
|----|-------|-------|-------|--------|
| 10000000-0000-0000-0000-000000000001 | Ático | guest1 | 2025-11-05 10:00-14:00 | confirmed |
| 10000000-0000-0000-0000-000000000002 | Loft | guest1 | 2025-11-10 16:00-20:00 | confirmed |
| 10000000-0000-0000-0000-000000000003 | Azotea | guest2 | 2025-11-15 18:00-23:00 | pending |
| 10000000-0000-0000-0000-000000000005 | Ático | guest2 | 2025-10-25 15:00-19:00 | completed |

---

## 12. ROADMAP Y PRÓXIMOS PASOS

### 12.1 Estado Actual (Noviembre 2025)

#### ✅ Backend: 100% Completado
- [x] Arquitectura de microservicios
- [x] Autenticación JWT
- [x] CRUD de espacios con imágenes
- [x] Búsqueda geoespacial con PostGIS
- [x] Sistema de reservas con estados
- [x] Sistema de reseñas
- [x] Eventos asíncronos con Kafka
- [x] Caché con Redis
- [x] API Gateway con rate limiting
- [x] Service Discovery con Eureka
- [x] Exception handling centralizado
- [x] Tests E2E automatizados

#### 🟡 Frontend: 70% Completado
- [x] Design System completo
- [x] Autenticación (Login/Logout)
- [x] Home page con búsqueda
- [x] Página Explore con mapa
- [x] Space Detail con galería
- [x] Host Dashboard (CRUD espacios)
- [x] Sistema de imágenes
- [ ] Sistema de reservas (guest view)
- [ ] Host: gestionar reservas recibidas
- [ ] Sistema de reviews real
- [ ] Perfil de usuario
- [ ] Notificaciones

### 12.2 Prioridad CRÍTICA (MVP - 40-50 horas)

#### 1. Sistema de Reservas Completo 🔴
**Tiempo:** 15-18 horas  
**Componentes:**
- Calendario de selección de fechas (DateRangePicker)
- Vista de reservas para Guest (`/bookings`)
- Vista de reservas para Host (Dashboard)
- Estados: Pending → Confirmed → Completed
- Políticas de cancelación

**Backend:** Ya implementado ✅  
**Frontend:** Pendiente ⏳

#### 2. Sistema de Pagos con Stripe 🔴
**Tiempo:** 18-22 horas  
**Componentes:**
- Integración Stripe (API Keys, Webhooks)
- Checkout Page (`/checkout/:bookingId`)
- Confirmación de pago
- Dashboard de pagos para Host
- Gestión de reembolsos

**Dependencias:**
- `@stripe/stripe-js` (frontend)
- `stripe` SDK (backend - nuevo microservicio)

#### 3. Sistema de Reviews Real 🔴
**Tiempo:** 8-10 horas  
**Componentes:**
- Crear review (solo completed bookings)
- Rating por categorías
- Responder reviews (host)
- Mostrar reviews en Space Detail
- Actualización de avg_rating

**Backend:** Implementado ✅  
**Frontend:** Pendiente ⏳

### 12.3 Prioridad IMPORTANTE (30-40 horas)

#### 4. Perfil de Usuario
- Editar información personal
- Avatar/foto de perfil
- Verificación de email/teléfono
- Historial de actividad
- Trust score visualización

#### 5. Sistema de Notificaciones
- Notificaciones en tiempo real (WebSocket)
- Email notifications (SendGrid)
- Push notifications (PWA)
- Tipos: Nueva reserva, Confirmación, Cancelación, Review

#### 6. Mensajería entre Host/Guest
- Chat en tiempo real
- Historial de conversaciones
- Notificaciones de mensajes nuevos

#### 7. Búsqueda Avanzada
- Autocompletado de direcciones (Google Places)
- Filtros guardados
- Historial de búsquedas
- Búsqueda por mapa (drag to search)

### 12.4 Features Deseables (Futuro)

- **Pricing Dinámico:** Activar algoritmo existente
- **Calendario de Disponibilidad:** Vista mensual para hosts
- **Favoritos/Wishlist:** Guardar espacios preferidos
- **Promociones:** Descuentos, cupones
- **Verificación de Identidad:** KYC con documento
- **Reportes:** Dashboard de analytics para hosts
- **App Móvil:** React Native o Flutter
- **Multi-idioma:** i18n en frontend
- **Multi-moneda:** Conversión de precios
- **Blog/CMS:** Contenido de marketing

---

## 13. DECISIONES ARQUITECTÓNICAS (ADRs)

### ADR-001: API Gateway sin Persistencia

**Fecha:** 28 Octubre 2025  
**Estado:** ✅ Aprobado

**Contexto:**  
Se necesitaba un API Gateway para enrutamiento y seguridad.

**Decisión:**  
Gateway NO tiene base de datos propia. Es un proxy ligero.

**Razones:**
1. Gateway con BD viola Single Responsibility
2. Conflicto técnico: WebFlux (reactive) vs JPA (blocking)
3. Impacto en performance (latencia adicional)
4. Gateway debe ser el componente MÁS estable
5. Escalabilidad: stateless es mejor

**Consecuencias:**
- ✅ Gateway ultra rápido (<10ms overhead)
- ✅ Fácil escalar horizontalmente
- ✅ Sin punto único de fallo
- ❌ Autenticación delegada a Auth Service

**Documento:** `/docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md`

---

### ADR-002: Modelo de Roles Dinámicos

**Fecha:** 5 Noviembre 2025  
**Estado:** ✅ Aprobado

**Contexto:**  
Sistema inicial tenía roles fijos (HOST o GUEST) al registrarse.

**Decisión:**  
Un usuario puede ser HOST y GUEST simultáneamente (modelo Airbnb).

**Razones:**
1. Flexibilidad: usuario puede reservar Y publicar espacios
2. UX mejorada: no forzar elección inicial
3. Onboarding más simple
4. Modelo de negocio más amplio

**Implementación:**
```typescript
interface User {
  id: string;
  email: string;
  isHost: boolean;    // Puede publicar espacios
  isGuest: boolean;   // Puede hacer reservas (siempre true)
  ...
}
```

**Consecuencias:**
- ✅ Mayor flexibilidad
- ✅ Mejor UX
- ✅ Modelo de negocio más amplio
- ⚠️ Lógica de permisos más compleja

**Documento:** `/docs/ADR_MODELO_ROLES_DINAMICOS.md`

---

### ADR-003: CQRS Parcial con Search Service

**Fecha:** Octubre 2025  
**Estado:** ✅ Implementado

**Decisión:**  
Separar lecturas (Search) de escrituras (Catalog).

**Razones:**
1. Búsquedas geoespaciales requieren PostGIS
2. Queries de lectura muy diferentes a escritura
3. Escalabilidad: read replicas independientes
4. Performance: índices optimizados para búsqueda

**Trade-offs:**
- ✅ Queries ultra rápidas
- ✅ Escalable independientemente
- ❌ Consistencia eventual (Kafka delay ~100ms)
- ❌ Complejidad adicional

---

## 14. ESTADO ACTUAL DEL DESARROLLO

### 14.1 Features Completados

| Feature | Backend | Frontend | Tests | Docs |
|---------|---------|----------|-------|------|
| Autenticación JWT | ✅ | ✅ | ✅ | ✅ |
| CRUD Espacios | ✅ | ✅ | ✅ | ✅ |
| Upload Imágenes | ✅ | ✅ | ✅ | ✅ |
| Búsqueda Geo | ✅ | ✅ | ✅ | ✅ |
| Crear Reservas | ✅ | ❌ | ✅ | ✅ |
| Gestionar Reservas | ✅ | ❌ | ✅ | ✅ |
| Sistema Reviews | ✅ | ❌ | ✅ | ✅ |
| Host Dashboard | - | ✅ | - | ✅ |
| Design System | - | ✅ | - | ✅ |

### 14.2 Deuda Técnica

| Item | Prioridad | Esfuerzo |
|------|-----------|----------|
| Tests unitarios microservicios | Media | 20h |
| Integración Stripe real | Alta | 15h |
| Logging estructurado (ELK) | Baja | 10h |
| Métricas con Prometheus | Media | 8h |
| CI/CD pipeline | Alta | 12h |
| Documentación OpenAPI | Media | 6h |
| Containerizar frontend | Baja | 4h |
| Healthchecks avanzados | Media | 5h |

### 14.3 Bugs Conocidos

Actualmente: **0 bugs críticos** 🎉

Mejoras pendientes:
- Frontend: Optimizar carga de imágenes (lazy loading)
- Backend: Mejorar manejo de transacciones en Outbox pattern
- Search: Caché de queries frecuentes

---

## 15. CONVENCIONES DE CÓDIGO

### 15.1 Backend (Java)

**Nombres de Paquetes:**
```
com.balconazo.<servicio>.<capa>

Ejemplos:
com.balconazo.catalog_microservice.controller
com.balconazo.catalog_microservice.service.impl
com.balconazo.catalog_microservice.repository
```

**Nombres de Clases:**
```java
// Entidades: sin sufijo
public class User {}
public class Space {}

// DTOs: con sufijo DTO
public class UserDTO {}
public class CreateSpaceDTO {}
public class UpdateBookingDTO {}

// Repositories: con sufijo Repository
public interface UserRepository extends JpaRepository<User, UUID> {}

// Services: interface sin sufijo, impl con Impl
public interface SpaceService {}
public class SpaceServiceImpl implements SpaceService {}

// Controllers: con sufijo Controller
@RestController
public class SpaceController {}

// Excepciones: con sufijo Exception
public class UserNotFoundException extends RuntimeException {}
```

**Constantes:**
```java
public class CatalogConstants {
    public static final String SPACE_STATUS_ACTIVE = "ACTIVE";
    public static final String SPACE_STATUS_SNOOZED = "SNOOZED";
    public static final String SPACE_STATUS_DELETED = "DELETED";
}
```

### 15.2 Frontend (Angular/TypeScript)

**Archivos:** kebab-case
```
auth-login.component.ts
space-detail.component.ts
booking-card.component.ts
```

**Clases:** PascalCase
```typescript
export class AuthLoginComponent {}
export class SpaceDetailComponent {}
```

**Interfaces:** PascalCase (sin I prefix)
```typescript
export interface User {}
export interface LoginRequest {}
export interface Space {}
```

**Services:** PascalCase + Service
```typescript
export class AuthService {}
export class SpaceService {}
```

**Estructura de Componentes:**
```typescript
@Component({
  selector: 'app-space-card',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './space-card.component.html',
  styleUrl: './space-card.component.scss'
})
export class SpaceCardComponent {
  @Input() space!: Space;
  @Output() bookClicked = new EventEmitter<string>();
  
  // Properties
  // Constructor
  // Lifecycle hooks (ngOnInit, etc)
  // Public methods
  // Private methods
}
```

---

## 16. TESTING

### 16.1 Tests E2E Automatizados

**Script:** `./test-e2e-completo.sh`

**Suite incluye:**
1. Health checks (6 servicios)
2. Registro en Eureka
3. Flujo de autenticación
4. CRUD de espacios
5. Búsqueda geoespacial
6. Flujo completo de reservas
7. Sistema de reseñas
8. Validación de seguridad

**Ejecutar:**
```bash
./test-e2e-completo.sh

# Resultado esperado:
# ✅ 29 tests ejecutados
# ✅ 29 tests exitosos
# ❌ 0 tests fallidos
# Tasa de éxito: 100%
```

### 16.2 Tests Unitarios (Pendiente)

```bash
# Por servicio
cd catalog_microservice
mvn test

# Coverage report
mvn jacoco:report
open target/site/jacoco/index.html
```

**Meta:** >80% coverage

---

## 17. TROUBLESHOOTING

### 17.1 Servicios no inician

```bash
# Verificar Docker
docker ps

# Ver logs
tail -f /tmp/auth-service.log
tail -f /tmp/catalog-service.log

# Verificar puertos libres
lsof -i:8080  # API Gateway
lsof -i:8761  # Eureka
lsof -i:8084  # Auth

# Matar proceso en puerto
lsof -ti:8080 | xargs kill -9
```

### 17.2 Error conexión BD

```bash
# Verificar contenedores
docker ps | grep postgres
docker ps | grep mysql

# Reiniciar contenedor
docker-compose restart pg-catalog
docker-compose restart mysql-auth

# Ver logs de contenedor
docker logs balconazo-pg-catalog
```

### 17.3 Error "Service Unavailable"

```bash
# Verificar Eureka
curl http://localhost:8761/eureka/apps

# Reiniciar servicios en orden
./stop-all.sh
./start-all-services.sh
```

### 17.4 JWT Inválido

```bash
# Verificar secret en application.properties
# Debe ser el mismo en todos los servicios

# Re-generar token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

---

## 18. FRONTEND

### 18.1 Estructura

```
balconazo-frontend/src/app/
├── core/
│   ├── guards/
│   │   └── auth.guard.ts
│   ├── interceptors/
│   │   └── auth.interceptor.ts
│   ├── models/
│   │   ├── user.model.ts
│   │   ├── space.model.ts
│   │   └── booking.model.ts
│   └── services/
│       ├── auth.service.ts
│       ├── space.service.ts
│       └── booking.service.ts
├── features/
│   ├── auth/
│   │   ├── login/
│   │   └── register/
│   ├── home/
│   ├── spaces/
│   │   ├── space-detail/
│   │   └── space-card/
│   ├── host/
│   │   └── dashboard/
│   └── bookings/
└── shared/
    ├── components/
    │   ├── navbar/
    │   └── footer/
    └── pipes/
```

### 18.2 Design System

**Variables CSS:**
```scss
// _tokens.scss
:root {
  --primary-500: #ef4444;
  --gray-700: #374151;
  --space-4: 1rem;
  --radius-lg: 0.75rem;
  --text-sm: 0.875rem;
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}
```

**Componentes:**
- Buttons (primary, secondary, danger)
- Cards
- Forms (inputs, selects, textareas)
- Badges (success, warning, error)
- Modals
- Toasts/Notifications

**Documento:** `balconazo-frontend/DESIGN-SYSTEM.md`

---

## 📌 RESUMEN EJECUTIVO

**BalconazoApp** es un marketplace de alquiler de espacios con arquitectura de microservicios completamente funcional.

**Estado:** Backend 100% | Frontend 70%

**Stack:** Java 21 + Spring Boot 3.5.7 + Angular 20 + PostgreSQL + MySQL + Redis + Kafka

**Próximos Pasos Críticos:**
1. Sistema de reservas (frontend)
2. Integración Stripe
3. Sistema de reviews (frontend)

**Para continuar el desarrollo:**
1. Leer este documento completo
2. Ejecutar `./start-all-services.sh`
3. Verificar con `./test-e2e-completo.sh`
4. Revisar `/docs/ROADMAP-FRONTEND.md`
5. Consultar `NEXT-STEPS.md` para tareas priorizadas

---

**Documento creado:** 20 Noviembre 2025  
**Última actualización:** 20 Noviembre 2025  
**Mantenido por:** Equipo de Desarrollo BalconazoApp

**Este documento debe ser la ÚNICA referencia necesaria para entender y continuar el proyecto.**
