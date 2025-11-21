# Arquitectura Backend de BalconazoApp

## 📋 Índice
1. [Visión General](#visión-general)
2. [Arquitectura de Microservicios](#arquitectura-de-microservicios)
3. [Tecnologías Utilizadas](#tecnologías-utilizadas)
4. [Servicios y Responsabilidades](#servicios-y-responsabilidades)
5. [Comunicación entre Servicios](#comunicación-entre-servicios)
6. [Base de Datos](#base-de-datos)
7. [Seguridad y Autenticación](#seguridad-y-autenticación)
8. [Flujos de Datos Principales](#flujos-de-datos-principales)
9. [Decisiones de Arquitectura (ADRs)](#decisiones-de-arquitectura-adrs)
10. [Despliegue y Operaciones](#despliegue-y-operaciones)

---

## Visión General

**BalconazoApp** es una plataforma marketplace tipo Airbnb para alquiler de espacios (terrazas, jardines, salones) construida con arquitectura de microservicios.

### Características Principales

- **Arquitectura de Microservicios**: Servicios independientes y escalables
- **API Gateway**: Punto de entrada único para todas las peticiones
- **Autenticación JWT**: Seguridad basada en tokens
- **Sistema de Roles Dinámico**: Usuarios pueden ser GUEST y/o HOST
- **Service Discovery**: Eureka Server para registro de servicios
- **Persistencia Distribuida**: Base de datos PostgreSQL por servicio
- **100% Tests Pasando**: Suite completa de tests end-to-end

### Arquitectura de Alto Nivel

```
                           ┌─────────────────┐
                           │   Cliente Web   │
                           │   (Frontend)    │
                           └────────┬────────┘
                                    │
                                    │ HTTP
                                    ▼
                           ┌─────────────────┐
                           │  API Gateway    │
                           │   (Port 8080)   │
                           └────────┬────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
          ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
          │Auth Service  │  │Catalog       │  │Booking       │
          │(Port 8084)   │  │Service       │  │Service       │
          │              │  │(Port 8085)   │  │(Port 8082)   │
          └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                 │                 │                  │
                 │                 │                  │
          ┌──────▼─────────────────▼──────────────────▼──────┐
          │         PostgreSQL (Containers)                  │
          │  - auth_db  - catalog_db  - booking_db          │
          └─────────────────────────────────────────────────┘

                           ┌──────────────┐
                           │Search Service│
                           │(Port 8083)   │
                           └──────┬───────┘
                                  │
                           ┌──────▼───────┐
                           │  search_db   │
                           └──────────────┘

                    ┌──────────────────────┐
                    │   Eureka Server      │
                    │   (Port 8761)        │
                    │ (Service Discovery)  │
                    └──────────────────────┘
```

---

## Arquitectura de Microservicios

### Principios de Diseño

1. **Single Responsibility**: Cada servicio tiene una responsabilidad única y bien definida
2. **Loose Coupling**: Servicios independientes con bajo acoplamiento
3. **High Cohesion**: Funcionalidades relacionadas agrupadas dentro del mismo servicio
4. **Database per Service**: Cada servicio tiene su propia base de datos
5. **API First**: Contratos de API bien definidos (REST)
6. **Stateless**: Servicios sin estado, escalables horizontalmente

### Ventajas de la Arquitectura Actual

✅ **Escalabilidad Independiente**: Cada servicio puede escalar según su carga
✅ **Despliegue Independiente**: Cambios en un servicio no afectan a otros
✅ **Tecnología Flexible**: Cada servicio puede usar diferentes tecnologías
✅ **Resiliencia**: Fallo en un servicio no tumba todo el sistema
✅ **Mantenibilidad**: Código organizado y fácil de mantener
✅ **Testing**: Tests aislados por servicio

---

## Tecnologías Utilizadas

### Stack Principal

| Componente | Tecnología | Versión | Propósito |
|------------|------------|---------|-----------|
| **Framework** | Spring Boot | 3.5.7 | Framework de aplicación |
| **Lenguaje** | Java | 17+ | Lenguaje de programación |
| **Build Tool** | Maven | 3.9+ | Gestión de dependencias |
| **Base de Datos** | PostgreSQL | 16 | Persistencia de datos |
| **Service Discovery** | Eureka Server | 4.2.0 | Registro de servicios |
| **API Gateway** | Spring Cloud Gateway | 4.2.0 | Enrutamiento de peticiones |
| **Seguridad** | Spring Security | 6.4.2 | Autenticación y autorización |
| **JWT** | java-jwt | 4.4.0 | Tokens de autenticación |
| **ORM** | Spring Data JPA | 3.5.7 | Acceso a base de datos |
| **Containerización** | Docker | - | Contenedores de BD |

### Librerías Clave

```xml
<!-- Spring Boot Parent -->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.5.7</version>
</parent>

<!-- Spring Cloud Dependencies -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-dependencies</artifactId>
    <version>2024.0.0</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>

<!-- JWT -->
<dependency>
    <groupId>com.auth0</groupId>
    <artifactId>java-jwt</artifactId>
    <version>4.4.0</version>
</dependency>

<!-- PostgreSQL Driver -->
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Lombok (reducción de boilerplate) -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.30</version>
    <scope>provided</scope>
</dependency>
```

---

## Servicios y Responsabilidades

### 1. API Gateway (Port 8080)

**Responsabilidad**: Punto de entrada único, enrutamiento y balance de carga.

**Funcionalidades**:
- Enrutamiento de peticiones a microservicios
- Balance de carga entre instancias
- Validación de JWT (excepto endpoints públicos)
- CORS configuration
- Rate limiting (futuro)

**Rutas**:
```yaml
/api/auth/**      → Auth Service (8084)
/api/spaces/**    → Catalog Service (8085)
/api/bookings/**  → Booking Service (8082)
/api/search/**    → Search Service (8083)
```

**Tecnologías**:
- Spring Cloud Gateway
- Spring Security
- Eureka Client

**Archivo principal**: `api-gateway/src/main/resources/application.properties`

```properties
spring.application.name=api-gateway
server.port=8080
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/

# Rutas
spring.cloud.gateway.routes[0].id=auth-service
spring.cloud.gateway.routes[0].uri=lb://auth-service
spring.cloud.gateway.routes[0].predicates[0]=Path=/api/auth/**
```

### 2. Auth Service (Port 8084)

**Responsabilidad**: Autenticación, autorización y gestión de usuarios.

**Funcionalidades**:
- Registro de usuarios
- Login con JWT
- Gestión de roles dinámicos (isGuest, isHost)
- Validación de tokens
- Promoción automática a HOST

**Endpoints**:
```
POST   /api/auth/register  - Registrar usuario
POST   /api/auth/login     - Iniciar sesión
GET    /api/auth/me        - Obtener perfil actual
POST   /api/auth/promote   - Promover usuario a HOST (interno)
```

**Base de Datos**: `auth_db` (PostgreSQL, port 5433)

**Tablas**:
- `users`: id, username, email, password_hash, full_name, is_host, is_guest, created_at

**Tecnologías**:
- Spring Boot
- Spring Security
- Spring Data JPA
- BCrypt (password hashing)
- JWT (java-jwt)

**Archivo principal**: `auth-service/src/main/java/com/balconazo/auth_service/`

**Flujo de Registro**:
```
1. POST /api/auth/register
2. Validar datos (username único, email único, password >= 8 chars)
3. Hash password con BCrypt
4. Crear usuario con isGuest=true, isHost=false
5. Guardar en BD
6. Retornar usuario creado
```

**Flujo de Login**:
```
1. POST /api/auth/login
2. Buscar usuario por username
3. Verificar password con BCrypt
4. Generar JWT con claims: sub (userId), isGuest, isHost
5. Retornar token + información de usuario
```

**JWT Claims**:
```json
{
  "sub": "user-uuid",
  "isGuest": true,
  "isHost": false,
  "exp": 1735689530
}
```

### 3. Catalog Service (Port 8085)

**Responsabilidad**: Gestión de espacios e imágenes.

**Funcionalidades**:
- CRUD de espacios
- Validación de ownership (solo el owner puede editar/borrar)
- Gestión de múltiples imágenes por espacio
- Promoción automática a HOST al crear primer espacio

**Endpoints**:
```
POST   /api/spaces                          - Crear espacio
GET    /api/spaces                          - Listar todos los espacios
GET    /api/spaces/{id}                     - Obtener espacio por ID
PUT    /api/spaces/{id}                     - Actualizar espacio (owner only)
DELETE /api/spaces/{id}                     - Eliminar espacio (owner only)
GET    /api/spaces/my-spaces                - Listar espacios del usuario actual

POST   /api/spaces/{id}/images              - Subir imagen
GET    /api/spaces/{id}/images/{imageId}    - Obtener imagen
DELETE /api/spaces/{id}/images/{imageId}    - Eliminar imagen
PUT    /api/spaces/{id}/images/{imageId}/primary - Marcar como primaria
```

**Base de Datos**: `catalog_db` (PostgreSQL, port 5432)

**Tablas**:
- `spaces`: id, name, description, location, price_per_hour, capacity, owner_id, available, created_at
- `space_amenities`: space_id, amenity
- `space_images`: id, space_id, file_name, is_primary, uploaded_at

**Tecnologías**:
- Spring Boot
- Spring Data JPA
- Multipart File Upload
- File System Storage (uploads/)

**Validación de Ownership**:
```java
@PreAuthorize("#ownerId == authentication.principal.userId")
public SpaceDTO updateSpace(UUID spaceId, UpdateSpaceDTO dto, UUID ownerId) {
    Space space = spaceRepository.findById(spaceId)
        .orElseThrow(() -> new NotFoundException("Space not found"));
    
    if (!space.getOwnerId().equals(ownerId)) {
        throw new ForbiddenException("You are not the owner of this space");
    }
    
    // Actualizar espacio...
}
```

**Promoción a HOST**:
```java
@Transactional
public SpaceDTO createSpace(CreateSpaceDTO dto, UUID ownerId) {
    Space space = spaceMapper.toEntity(dto);
    space.setOwnerId(ownerId);
    space.setAvailable(true);
    
    Space saved = spaceRepository.save(space);
    
    // Llamar a Auth Service para promover a HOST
    authServiceClient.promoteToHost(ownerId);
    
    return spaceMapper.toDTO(saved);
}
```

### 4. Booking Service (Port 8082)

**Responsabilidad**: Gestión de reservas y su ciclo de vida.

**Funcionalidades**:
- Crear reservas con validación de conflictos
- Listar reservas del usuario (guest)
- Listar reservas de un espacio (host)
- Confirmar reservas (con paymentIntentId)
- Cancelar reservas (con reason)
- Cálculo automático de precio total

**Endpoints**:
```
POST   /api/bookings                     - Crear reserva
GET    /api/bookings/my                  - Listar reservas del usuario
GET    /api/bookings/space/{spaceId}     - Listar reservas de un espacio
POST   /api/bookings/{id}/confirm        - Confirmar reserva (host)
POST   /api/bookings/{id}/cancel         - Cancelar reserva
```

**Base de Datos**: `booking_db` (PostgreSQL, port 5434)

**Tablas**:
- `bookings`: id, space_id, guest_id, start_ts, end_ts, num_guests, status, total_price, payment_intent_id, cancellation_reason, created_at

**Estados de Reserva**:
```java
public enum BookingStatus {
    pending,    // Recién creada
    confirmed,  // Confirmada por HOST con pago
    cancelled   // Cancelada por GUEST o HOST
}
```

**Validación de Conflictos**:
```java
private boolean hasConflict(UUID spaceId, LocalDateTime start, LocalDateTime end) {
    List<BookingEntity> existingBookings = bookingRepository
        .findBySpaceIdAndStatusOrderByStartTsAsc(spaceId, BookingStatus.confirmed);
    
    for (BookingEntity existing : existingBookings) {
        // Conflicto si hay overlap
        if (start.isBefore(existing.getEndTs()) && end.isAfter(existing.getStartTs())) {
            return true;
        }
    }
    
    return false;
}
```

**Cálculo de Precio**:
```java
private BigDecimal calculateTotalPrice(UUID spaceId, LocalDateTime start, LocalDateTime end) {
    // Obtener precio del espacio desde Catalog Service
    BigDecimal pricePerHour = catalogServiceClient.getSpacePrice(spaceId);
    
    // Calcular horas
    long hours = ChronoUnit.HOURS.between(start, end);
    
    return pricePerHour.multiply(BigDecimal.valueOf(hours));
}
```

**Tecnologías**:
- Spring Boot
- Spring Data JPA
- Manual Mappers (BookingMapperImpl, ReviewMapperImpl)
- **Nota**: MapStruct fue eliminado debido a conflictos con Lombok

### 5. Search Service (Port 8083)

**Responsabilidad**: Búsqueda y filtrado de espacios.

**Funcionalidades**:
- Búsqueda por ubicación (parcial, case-insensitive)
- Filtro por precio máximo
- Filtro por capacidad mínima
- Combinación de filtros (AND lógico)
- Endpoint público (sin autenticación)

**Endpoints**:
```
GET /api/search?location={location}&maxPrice={price}&minCapacity={capacity}
```

**Base de Datos**: `search_db` (PostgreSQL, port 5435)

**Tablas**:
- `search_spaces`: id, name, description, location, price_per_hour, capacity, owner_id, available, created_at
- `search_amenities`: space_id, amenity

**Sincronización de Datos**:
```java
// Catalog Service publica eventos al crear/actualizar espacios
@EventListener
public void onSpaceCreated(SpaceCreatedEvent event) {
    searchServiceClient.indexSpace(event.getSpace());
}

// Search Service escucha y actualiza su BD
@PostMapping("/api/search/index")
public void indexSpace(@RequestBody SpaceDTO space) {
    SearchSpaceEntity entity = mapper.toEntity(space);
    searchSpaceRepository.save(entity);
}
```

**Query de Búsqueda**:
```java
@Query("""
    SELECT s FROM SearchSpaceEntity s
    WHERE (:location IS NULL OR LOWER(s.location) LIKE LOWER(CONCAT('%', :location, '%')))
    AND (:maxPrice IS NULL OR s.pricePerHour <= :maxPrice)
    AND (:minCapacity IS NULL OR s.capacity >= :minCapacity)
    ORDER BY s.createdAt DESC
""")
List<SearchSpaceEntity> search(
    @Param("location") String location,
    @Param("maxPrice") BigDecimal maxPrice,
    @Param("minCapacity") Integer minCapacity
);
```

**Tecnologías**:
- Spring Boot
- Spring Data JPA
- JPQL (Java Persistence Query Language)

### 6. Eureka Server (Port 8761)

**Responsabilidad**: Service Discovery y registro de servicios.

**Funcionalidades**:
- Registro automático de microservicios
- Health checks de servicios
- Balanceo de carga
- Dashboard de servicios activos

**Configuración**:
```properties
spring.application.name=eureka-server
server.port=8761
eureka.client.register-with-eureka=false
eureka.client.fetch-registry=false
```

**Dashboard**: `http://localhost:8761`

**Servicios Registrados**:
- API-GATEWAY
- AUTH-SERVICE
- CATALOG-SERVICE
- BOOKING-SERVICE
- SEARCH-SERVICE

---

## Comunicación entre Servicios

### 1. Cliente → API Gateway (HTTP)

```
Cliente (Frontend) → HTTP → API Gateway:8080
```

**Ejemplo**:
```javascript
fetch('http://localhost:8080/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'user', password: 'pass' })
});
```

### 2. API Gateway → Microservicios (Load Balanced)

```
API Gateway → Eureka (descubrimiento) → Microservicio (instancia)
```

**Configuración**:
```properties
# Usar load balancing (lb://)
spring.cloud.gateway.routes[0].uri=lb://auth-service
```

### 3. Microservicio → Microservicio (RestTemplate / WebClient)

**Ejemplo**: Catalog Service → Auth Service

```java
@Service
public class AuthServiceClient {
    private final RestTemplate restTemplate;
    
    public void promoteToHost(UUID userId) {
        String url = "http://auth-service/api/auth/promote/" + userId;
        restTemplate.postForObject(url, null, Void.class);
    }
}
```

**Configuración**:
```java
@Configuration
public class RestTemplateConfig {
    @Bean
    @LoadBalanced // Habilita balanceo de carga con Eureka
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

### 4. Eventos (Futuro - Event-Driven)

**Opción**: Usar Apache Kafka / RabbitMQ para eventos asíncronos

```java
// Catalog Service publica evento
@Autowired
private KafkaTemplate<String, SpaceCreatedEvent> kafkaTemplate;

public void createSpace(CreateSpaceDTO dto) {
    Space space = spaceRepository.save(...);
    
    // Publicar evento
    SpaceCreatedEvent event = new SpaceCreatedEvent(space);
    kafkaTemplate.send("space-events", event);
}

// Search Service consume evento
@KafkaListener(topics = "space-events")
public void handleSpaceCreated(SpaceCreatedEvent event) {
    searchSpaceRepository.save(toSearchEntity(event.getSpace()));
}
```

---

## Base de Datos

### Estrategia: Database per Service

Cada microservicio tiene su propia base de datos PostgreSQL aislada.

### Contenedores Docker

```yaml
# docker-compose.yml
services:
  postgres-auth:
    image: postgres:16
    container_name: balconazo-pg-auth
    ports:
      - "5433:5432"
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./ddl/test-data-auth.sql:/docker-entrypoint-initdb.d/init.sql

  postgres-catalog:
    image: postgres:16
    container_name: balconazo-pg-catalog
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: catalog_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./ddl/catalog.sql:/docker-entrypoint-initdb.d/catalog.sql

  postgres-booking:
    image: postgres:16
    container_name: balconazo-pg-booking
    ports:
      - "5434:5432"
    environment:
      POSTGRES_DB: booking_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

  postgres-search:
    image: postgres:16
    container_name: balconazo-pg-search
    ports:
      - "5435:5432"
    environment:
      POSTGRES_DB: search_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
```

### Esquema de Bases de Datos

#### auth_db

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    is_host BOOLEAN DEFAULT FALSE,
    is_guest BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
```

#### catalog_db

```sql
CREATE TABLE spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(200) NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    capacity INTEGER NOT NULL,
    owner_id UUID NOT NULL,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE space_amenities (
    space_id UUID REFERENCES spaces(id) ON DELETE CASCADE,
    amenity VARCHAR(100) NOT NULL,
    PRIMARY KEY (space_id, amenity)
);

CREATE TABLE space_images (
    id VARCHAR(100) PRIMARY KEY,
    space_id UUID REFERENCES spaces(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_spaces_owner ON spaces(owner_id);
CREATE INDEX idx_images_space ON space_images(space_id);
```

#### booking_db

```sql
CREATE SCHEMA IF NOT EXISTS booking;

CREATE TABLE booking.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP NOT NULL,
    num_guests INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_price DECIMAL(10,2) NOT NULL,
    payment_intent_id VARCHAR(255),
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_dates CHECK (end_ts > start_ts),
    CONSTRAINT chk_status CHECK (status IN ('pending', 'confirmed', 'cancelled'))
);

CREATE INDEX idx_bookings_space ON booking.bookings(space_id);
CREATE INDEX idx_bookings_guest ON booking.bookings(guest_id);
CREATE INDEX idx_bookings_status ON booking.bookings(status);
```

#### search_db

```sql
CREATE TABLE search_spaces (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(200) NOT NULL,
    price_per_hour DECIMAL(10,2) NOT NULL,
    capacity INTEGER NOT NULL,
    owner_id UUID NOT NULL,
    available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE search_amenities (
    space_id UUID REFERENCES search_spaces(id) ON DELETE CASCADE,
    amenity VARCHAR(100) NOT NULL,
    PRIMARY KEY (space_id, amenity)
);

CREATE INDEX idx_search_location ON search_spaces(location);
CREATE INDEX idx_search_price ON search_spaces(price_per_hour);
CREATE INDEX idx_search_capacity ON search_spaces(capacity);
```

---

## Seguridad y Autenticación

### JWT (JSON Web Tokens)

**Secret Key** (256 bits, mismo en todos los servicios):
```
BalconazoSecretKeyForJWTGenerationMustBe256BitsLongMinimumForHS256AlgorithmSecureKey2025
```

**Generación de Token** (Auth Service):
```java
@Service
public class JwtService {
    private final String secret = "BalconazoSecretKeyForJWTGenerationMustBe256BitsLongMinimumForHS256AlgorithmSecureKey2025";
    private final Algorithm algorithm = Algorithm.HMAC256(secret);
    
    public String generateToken(User user) {
        return JWT.create()
            .withSubject(user.getId().toString())
            .withClaim("isGuest", user.isGuest())
            .withClaim("isHost", user.isHost())
            .withExpiresAt(Date.from(Instant.now().plus(365, ChronoUnit.DAYS)))
            .sign(algorithm);
    }
}
```

**Validación de Token** (API Gateway, Microservicios):
```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final String secret = "BalconazoSecretKeyForJWTGenerationMustBe256BitsLongMinimumForHS256AlgorithmSecureKey2025";
    
    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        String token = extractToken(request);
        
        if (token != null) {
            try {
                Algorithm algorithm = Algorithm.HMAC256(secret);
                JWTVerifier verifier = JWT.require(algorithm).build();
                DecodedJWT jwt = verifier.verify(token);
                
                String userId = jwt.getSubject();
                boolean isGuest = jwt.getClaim("isGuest").asBoolean();
                boolean isHost = jwt.getClaim("isHost").asBoolean();
                
                // Crear Authentication y establecer en SecurityContext
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                    userId, null, getAuthorities(isGuest, isHost)
                );
                
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (JWTVerificationException e) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }
        
        filterChain.doFilter(request, response);
    }
    
    private String extractToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }
        return null;
    }
}
```

### Configuración de Seguridad

**Endpoints Públicos**:
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/search` (todos los parámetros)

**Endpoints Protegidos**:
- Todos los demás requieren `Authorization: Bearer {token}`

**Security Config** (ejemplo en API Gateway):
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/register", "/api/auth/login").permitAll()
                .requestMatchers("/api/search/**").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);
        
        return http.build();
    }
}
```

### CORS Configuration

```java
@Configuration
public class CorsConfig {
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("http://localhost:4200")); // Angular
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
```

---

## Flujos de Datos Principales

### 1. Registro y Login

```
┌─────────┐                                      ┌──────────────┐
│ Cliente │                                      │ Auth Service │
└────┬────┘                                      └──────┬───────┘
     │                                                   │
     │ POST /api/auth/register                          │
     │ { username, email, password, fullName }          │
     ├──────────────────────────────────────────────────>│
     │                                                   │
     │                       Validar datos               │
     │                       Hash password (BCrypt)      │
     │                       Crear usuario (isGuest=true)│
     │                                                   │
     │ 201 Created                                       │
     │ { id, username, isHost=false, isGuest=true }     │
     │<──────────────────────────────────────────────────┤
     │                                                   │
     │ POST /api/auth/login                             │
     │ { username, password }                           │
     ├──────────────────────────────────────────────────>│
     │                                                   │
     │                       Buscar usuario              │
     │                       Verificar password          │
     │                       Generar JWT                 │
     │                                                   │
     │ 200 OK                                            │
     │ { token, userId, username, isHost, isGuest }     │
     │<──────────────────────────────────────────────────┤
     │                                                   │
     │ [Cliente guarda token en localStorage]           │
     │                                                   │
```

### 2. Crear Espacio (Primera vez → Promoción a HOST)

```
┌─────────┐     ┌───────────┐     ┌────────────────┐     ┌──────────────┐
│ Cliente │     │API Gateway│     │ Catalog Service│     │ Auth Service │
└────┬────┘     └─────┬─────┘     └────────┬───────┘     └──────┬───────┘
     │                │                     │                    │
     │ POST /api/spaces                    │                    │
     │ Authorization: Bearer {token}        │                    │
     ├────────────────>│                     │                    │
     │                │ Validar JWT         │                    │
     │                │ Extraer userId      │                    │
     │                │                     │                    │
     │                │ POST (internal)     │                    │
     │                ├─────────────────────>│                    │
     │                │                     │ Crear espacio      │
     │                │                     │ ownerId = userId   │
     │                │                     │                    │
     │                │                     │ POST /promote      │
     │                │                     ├────────────────────>│
     │                │                     │                    │ Actualizar
     │                │                     │                    │ isHost=true
     │                │                     │                    │
     │                │                     │ 200 OK             │
     │                │                     │<────────────────────┤
     │                │                     │                    │
     │                │ 201 Created         │                    │
     │                │ { id, name, ..., ownerId }              │
     │                │<─────────────────────┤                    │
     │ 201 Created    │                     │                    │
     │<────────────────┤                     │                    │
     │                │                     │                    │
     │ GET /api/auth/me                    │                    │
     ├────────────────>│                     │                    │
     │                ├─────────────────────────────────────────>│
     │                │                     │                    │
     │                │ 200 OK { isHost=true }                  │
     │                │<─────────────────────────────────────────┤
     │ 200 OK         │                     │                    │
     │<────────────────┤                     │                    │
     │                │                     │                    │
```

### 3. Crear y Confirmar Reserva

```
┌─────────┐     ┌───────────┐     ┌────────────────┐     ┌────────────────┐
│  GUEST  │     │API Gateway│     │Booking Service │     │Catalog Service │
└────┬────┘     └─────┬─────┘     └────────┬───────┘     └────────┬───────┘
     │                │                     │                      │
     │ POST /api/bookings                  │                      │
     │ { spaceId, startTs, endTs, numGuests }                    │
     ├────────────────>│                     │                      │
     │                │ Validar JWT         │                      │
     │                │ (guestId = userId)  │                      │
     │                │                     │                      │
     │                │ POST (internal)     │                      │
     │                ├─────────────────────>│                      │
     │                │                     │ GET /api/spaces/{id} │
     │                │                     ├──────────────────────>│
     │                │                     │                      │
     │                │                     │ { pricePerHour }     │
     │                │                     │<──────────────────────┤
     │                │                     │                      │
     │                │                     │ Validar conflictos   │
     │                │                     │ Calcular totalPrice  │
     │                │                     │ status = 'pending'   │
     │                │                     │                      │
     │                │ 201 Created         │                      │
     │                │ { id, ..., status='pending' }              │
     │                │<─────────────────────┤                      │
     │ 201 Created    │                     │                      │
     │<────────────────┤                     │                      │
     │                │                     │                      │
     
┌─────────┐     ┌───────────┐     ┌────────────────┐
│  HOST   │     │API Gateway│     │Booking Service │
└────┬────┘     └─────┬─────┘     └────────┬───────┘
     │                │                     │
     │ GET /api/bookings/space/{spaceId}   │
     ├────────────────>│                     │
     │                ├─────────────────────>│
     │                │                     │ findBySpaceId()
     │                │                     │
     │                │ 200 OK [{ status='pending', ... }]
     │                │<─────────────────────┤
     │ 200 OK         │                     │
     │<────────────────┤                     │
     │                │                     │
     │ POST /api/bookings/{id}/confirm?paymentIntentId=pi_123
     ├────────────────>│                     │
     │                ├─────────────────────>│
     │                │                     │ Actualizar status='confirmed'
     │                │                     │ paymentIntentId='pi_123'
     │                │                     │
     │                │ 200 OK { status='confirmed' }
     │                │<─────────────────────┤
     │ 200 OK         │                     │
     │<────────────────┤                     │
     │                │                     │
```

### 4. Búsqueda de Espacios (Sin Autenticación)

```
┌─────────┐     ┌───────────┐     ┌───────────────┐
│ Cliente │     │API Gateway│     │Search Service │
│(Anónimo)│     │           │     │               │
└────┬────┘     └─────┬─────┘     └───────┬───────┘
     │                │                    │
     │ GET /api/search?location=Barcelona&maxPrice=50
     ├────────────────>│                    │
     │                │ (Sin validación    │
     │                │  de JWT)           │
     │                │                    │
     │                │ GET (internal)     │
     │                ├────────────────────>│
     │                │                    │ Query:
     │                │                    │ SELECT *
     │                │                    │ WHERE location LIKE '%Barcelona%'
     │                │                    │ AND pricePerHour <= 50
     │                │                    │
     │                │ 200 OK             │
     │                │ [{ id, name, location, pricePerHour, ... }]
     │                │<────────────────────┤
     │ 200 OK         │                    │
     │<────────────────┤                    │
     │                │                    │
```

---

## Decisiones de Arquitectura (ADRs)

### ADR-001: Eliminación de MapStruct

**Contexto**: MapStruct y Lombok generaban conflictos en la generación de bytecode, causando errores "InconsistentHierarchy" en BookingMapperImpl.

**Decisión**: Eliminar MapStruct y crear mappers manuales con `@Component`.

**Consecuencias**:
- ✅ Eliminación de errores de compilación
- ✅ Mayor control sobre el mapeo
- ✅ Código más explícito y fácil de depurar
- ❌ Más código boilerplate
- ❌ Necesidad de mantener mappers manualmente

**Implementación**:
```java
@Component
public class BookingMapperImpl implements BookingMapper {
    @Override
    public BookingEntity toEntity(CreateBookingDTO dto) {
        return BookingEntity.builder()
            .spaceId(dto.getSpaceId())
            .guestId(dto.getGuestId())
            .startTs(dto.getStartTs())
            .endTs(dto.getEndTs())
            .numGuests(dto.getNumGuests())
            .build();
    }
    
    @Override
    public BookingDTO toDTO(BookingEntity entity) {
        return BookingDTO.builder()
            .id(entity.getId())
            .spaceId(entity.getSpaceId())
            .guestId(entity.getGuestId())
            .startTs(entity.getStartTs())
            .endTs(entity.getEndTs())
            .numGuests(entity.getNumGuests())
            .status(entity.getStatus().name())
            .totalPrice(entity.getTotalPrice())
            .createdAt(entity.getCreatedAt())
            .paymentIntentId(entity.getPaymentIntentId())
            .cancellationReason(entity.getCancellationReason())
            .build();
    }
}
```

### ADR-002: API Gateway sin Persistencia

**Contexto**: El API Gateway debe enrutar peticiones sin lógica de negocio compleja.

**Decisión**: El API Gateway NO tiene base de datos propia. Solo valida JWT y enruta.

**Consecuencias**:
- ✅ Gateway más ligero y rápido
- ✅ Escalabilidad horizontal sin estado
- ✅ Separación clara de responsabilidades
- ❌ No puede cachear información de usuario

**Archivo**: [docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md](./ADR_API_GATEWAY_SIN_PERSISTENCIA.md)

### ADR-003: JWT Secret Unificado

**Contexto**: Todos los servicios deben poder validar tokens JWT generados por Auth Service.

**Decisión**: Usar el mismo secret de 256 bits en todos los servicios.

**Secret**:
```
BalconazoSecretKeyForJWTGenerationMustBe256BitsLongMinimumForHS256AlgorithmSecureKey2025
```

**Consecuencias**:
- ✅ Validación descentralizada (cada servicio valida)
- ✅ No necesidad de llamar a Auth Service para cada request
- ❌ Cambiar el secret requiere actualizar todos los servicios
- ❌ Compromiso de secret afecta a todo el sistema

**Recomendación futura**: Usar asymmetric keys (RS256) con public/private key pair.

### ADR-004: Database per Service

**Contexto**: Microservicios deben ser independientes y escalables.

**Decisión**: Cada servicio tiene su propia base de datos PostgreSQL.

**Consecuencias**:
- ✅ Independencia de datos
- ✅ Escalabilidad por servicio
- ✅ Aislamiento de fallos
- ❌ Duplicación de datos (ej: spaces en catalog_db y search_db)
- ❌ Complejidad en transacciones distribuidas

**Mitigación**: Usar eventos para sincronizar datos entre servicios.

### ADR-005: Búsqueda sin Autenticación

**Contexto**: Los usuarios deben poder explorar espacios antes de registrarse.

**Decisión**: El endpoint `/api/search` es público (sin JWT).

**Consecuencias**:
- ✅ Mejor UX (usuarios anónimos pueden buscar)
- ✅ Más conversiones (registro después de ver espacios)
- ❌ Riesgo de scraping
- ❌ Necesidad de rate limiting

**Mitigación futura**: Implementar rate limiting por IP.

---

## Despliegue y Operaciones

### Scripts de Gestión

Ubicados en la raíz del proyecto:

```bash
# Iniciar infraestructura (PostgreSQL containers)
./start-infrastructure.sh

# Iniciar todos los microservicios
./start-all-services.sh

# Iniciar con Eureka Server
./start-all-with-eureka.sh

# Detener todos los servicios
./stop-all.sh

# Recompilar todos los servicios
./recompile-all.sh

# Verificar estado del sistema
./verify-system.sh

# Ejecutar tests end-to-end
./test-e2e-completo.sh
```

### Orden de Inicio

1. **PostgreSQL Containers** (docker-compose up)
2. **Eureka Server** (port 8761)
3. **Auth Service** (port 8084)
4. **Catalog Service** (port 8085)
5. **Booking Service** (port 8082)
6. **Search Service** (port 8083)
7. **API Gateway** (port 8080)

### Health Checks

Cada servicio expone endpoints de actuator:

```
GET /actuator/health
GET /actuator/info
```

**Verificar todos los servicios**:
```bash
#!/bin/bash
services=("8080:Gateway" "8084:Auth" "8085:Catalog" "8082:Booking" "8083:Search")

for service in "${services[@]}"; do
  port=$(echo $service | cut -d: -f1)
  name=$(echo $service | cut -d: -f2)
  
  status=$(curl -s http://localhost:$port/actuator/health | jq -r '.status')
  
  if [ "$status" = "UP" ]; then
    echo "✅ $name ($port): UP"
  else
    echo "❌ $name ($port): DOWN"
  fi
done
```

### Logs

**Ubicación**:
```
/tmp/gateway.log
/tmp/auth-service.log
/tmp/catalog-service.log
/tmp/booking-service.log
/tmp/search-service.log
```

**Ver logs en tiempo real**:
```bash
tail -f /tmp/booking-service.log
```

**Buscar errores**:
```bash
grep -i "error" /tmp/*.log
```

### Monitoreo (Futuro)

**Recomendaciones**:

1. **Prometheus + Grafana**: Métricas y dashboards
2. **ELK Stack**: Logs centralizados (Elasticsearch, Logstash, Kibana)
3. **Jaeger / Zipkin**: Distributed tracing
4. **Spring Boot Admin**: Dashboard de microservicios

---

## Testing

### Suite de Tests End-to-End

**Archivo**: `test-roles-usuarios-completo.sh`

**Cobertura**: 45 tests (100% passing)

**Test Suites**:
1. Registro de Usuarios (3 tests)
2. Autenticación (7 tests)
3. Gestión de Espacios (15 tests)
4. Búsqueda de Espacios (3 tests)
5. Creación de Reservas (3 tests)
6. Listado de Reservas (3 tests)
7. Gestión de Reservas (3 tests)

**Ejecución**:
```bash
./test-roles-usuarios-completo.sh
```

**Resultado esperado**:
```
Tests ejecutados:     45
Tests exitosos:       45 ✅
Tests fallidos:       0 ❌
Tasa de éxito:        100,00%

🎉 ¡TODOS LOS TESTS PASARON!
```

### Tests Unitarios (Futuro)

**Recomendación**: Agregar tests unitarios con JUnit 5 y Mockito

```java
@SpringBootTest
class BookingServiceTest {
    @MockBean
    private BookingRepository bookingRepository;
    
    @Autowired
    private BookingService bookingService;
    
    @Test
    void shouldCreateBookingSuccessfully() {
        // Given
        CreateBookingDTO dto = new CreateBookingDTO(...);
        
        // When
        BookingDTO result = bookingService.createBooking(dto, userId);
        
        // Then
        assertNotNull(result.getId());
        assertEquals("pending", result.getStatus());
    }
}
```

---

## Resumen de Puertos

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| **API Gateway** | 8080 | Punto de entrada único |
| **Eureka Server** | 8761 | Service Discovery |
| **Auth Service** | 8084 | Autenticación y usuarios |
| **Catalog Service** | 8085 | Gestión de espacios |
| **Booking Service** | 8082 | Gestión de reservas |
| **Search Service** | 8083 | Búsqueda de espacios |
| **PostgreSQL Auth** | 5433 | BD de autenticación |
| **PostgreSQL Catalog** | 5432 | BD de catálogo |
| **PostgreSQL Booking** | 5434 | BD de reservas |
| **PostgreSQL Search** | 5435 | BD de búsqueda |

---

## Próximos Pasos

### Mejoras Técnicas

1. **Caching**: Implementar Redis para cachear espacios y búsquedas
2. **Event-Driven**: Usar Kafka/RabbitMQ para comunicación asíncrona
3. **API Docs**: Generar documentación con Swagger/OpenAPI
4. **Circuit Breaker**: Resilience4j para manejar fallos en cascada
5. **Rate Limiting**: Limitar requests por IP/usuario

### Funcionalidades

1. **Reviews**: Sistema de reseñas y valoraciones
2. **Mensajería**: Chat entre guest y host
3. **Calendario**: Disponibilidad y bloqueo de fechas
4. **Pagos**: Integración completa con Stripe
5. **Notificaciones**: Email/SMS para eventos importantes

### DevOps

1. **CI/CD**: GitHub Actions para build y deploy automático
2. **Kubernetes**: Orquestación de contenedores
3. **Monitoring**: Prometheus + Grafana
4. **Logging**: ELK Stack
5. **Backup**: Snapshots automáticos de BD

---

## Referencias

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- [Eureka Server](https://spring.io/projects/spring-cloud-netflix)
- [JWT Best Practices](https://jwt.io/introduction)
- [Microservices Patterns](https://microservices.io/patterns/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Última actualización**: 20 de noviembre de 2025

**Versión**: 1.0.0

**Estado**: 100% tests pasando ✅

