# 🚀 SIGUIENTES PASOS - IMPLEMENTACIÓN API GATEWAY & AUTH SERVICE

**Fecha:** 28 de octubre de 2025, 14:15  
**Fase:** 4 de 6 - API Gateway & Autenticación  
**Objetivo:** Crear punto de entrada único con seguridad centralizada

---

## 📋 RESUMEN DE LA DECISIÓN ARQUITECTÓNICA

**✅ SE DECIDIÓ:**
- API Gateway **SIN JPA/MySQL** (solo reactive, stateless)
- Auth Service **CON JPA/MySQL** (separado, especializado en autenticación)

**📄 Documento de referencia:** `docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md`

---

## 🎯 ORDEN DE IMPLEMENTACIÓN

### PASO 1: Crear Eureka Server (Service Discovery)
**Duración:** 30 minutos  
**Prioridad:** 🔴 CRÍTICA (necesario para todo lo demás)

**Acciones:**
1. Crear proyecto `eureka-server`
2. Configurar `application.yml`
3. Iniciar servidor en puerto 8761
4. Verificar dashboard en `http://localhost:8761`

**Comando rápido:**
```bash
cd /Users/angel/Desktop/BalconazoApp
mkdir eureka-server
# Crear pom.xml y código base
```

**Resultado esperado:** Dashboard de Eureka accesible

---

### PASO 2: Registrar Microservicios Existentes en Eureka
**Duración:** 20 minutos  
**Prioridad:** 🔴 CRÍTICA

**Microservicios a registrar:**
- ✅ Catalog Service (8085)
- ✅ Booking Service (8082)
- ✅ Search Service (8083)

**Acciones por cada servicio:**
1. Agregar dependencia de Eureka Client en `pom.xml`
2. Agregar `@EnableDiscoveryClient` en clase principal
3. Configurar `eureka.client.service-url.defaultZone` en `application.properties`
4. Reiniciar servicio

**Archivo a modificar (ejemplo Catalog):**
```yaml
# catalog_microservice/src/main/resources/application.properties
spring.application.name=catalog-service
eureka.client.service-url.defaultZone=http://localhost:8761/eureka/
eureka.client.register-with-eureka=true
eureka.client.fetch-registry=true
```

**Resultado esperado:** 3 servicios visibles en dashboard de Eureka

---

### PASO 3: Crear Auth Service
**Duración:** 2-3 horas  
**Prioridad:** 🔴 CRÍTICA (necesario para que Gateway valide tokens)

**Estructura del proyecto:**
```
auth-service/
├── pom.xml
└── src/main/
    ├── java/com/balconazo/auth/
    │   ├── AuthServiceApplication.java
    │   ├── entity/
    │   │   ├── User.java
    │   │   └── RefreshToken.java
    │   ├── repository/
    │   │   ├── UserRepository.java
    │   │   └── RefreshTokenRepository.java
    │   ├── service/
    │   │   ├── AuthService.java
    │   │   └── JwtService.java
    │   ├── dto/
    │   │   ├── RegisterRequest.java
    │   │   ├── LoginRequest.java
    │   │   ├── LoginResponse.java
    │   │   └── UserDTO.java
    │   ├── controller/
    │   │   └── AuthController.java
    │   └── config/
    │       ├── SecurityConfig.java
    │       └── JwtConfig.java
    └── resources/
        └── application.yml
```

**Dependencias clave (pom.xml):**
```xml
<dependencies>
    <!-- Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    
    <!-- JPA + MySQL -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
    </dependency>
    
    <!-- JWT -->
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.12.3</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-impl</artifactId>
        <version>0.12.3</version>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-jackson</artifactId>
        <version>0.12.3</version>
    </dependency>
    
    <!-- Eureka Client -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
</dependencies>
```

**Endpoints a implementar:**
```java
POST   /api/auth/register      - Registro de usuario
POST   /api/auth/login         - Login (devuelve JWT)
POST   /api/auth/refresh       - Renovar token
POST   /api/auth/logout        - Invalidar refresh token
GET    /api/auth/me            - Info del usuario autenticado
```

**Resultado esperado:** 
- Auth Service corriendo en puerto 8084
- Puede registrar usuarios
- Puede hacer login y devuelve JWT válido
- Registrado en Eureka

---

### PASO 4: Crear MySQL para Auth Service
**Duración:** 10 minutos  
**Prioridad:** 🔴 CRÍTICA

**Comando Docker:**
```bash
docker run -d --name balconazo-mysql-auth \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=auth_db \
  mysql:8.0

# Esperar 30 segundos
sleep 30

# Crear schema
docker exec balconazo-mysql-auth mysql -uroot -proot -e "
CREATE SCHEMA IF NOT EXISTS auth;
USE auth;

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('GUEST', 'HOST', 'ADMIN') NOT NULL DEFAULT 'GUEST',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id)
);
"
```

**Verificar:**
```bash
docker exec balconazo-mysql-auth mysql -uroot -proot auth -e "SHOW TABLES;"
```

**Resultado esperado:** Tablas `users` y `refresh_tokens` creadas

---

### PASO 5: Crear API Gateway
**Duración:** 2 horas  
**Prioridad:** 🟡 ALTA (depende de Auth Service para JWT)

**Estructura del proyecto:**
```
api-gateway/
├── pom.xml
└── src/main/
    ├── java/com/balconazo/gateway/
    │   ├── ApiGatewayApplication.java
    │   ├── config/
    │   │   ├── SecurityConfig.java
    │   │   ├── RouteConfig.java (opcional)
    │   │   └── CorsConfig.java
    │   └── filter/
    │       ├── AuthenticationFilter.java (opcional)
    │       └── LoggingFilter.java
    └── resources/
        └── application.yml
```

**Dependencias clave (pom.xml):**
```xml
<dependencies>
    <!-- Gateway (reactive) -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-gateway</artifactId>
    </dependency>
    
    <!-- Security + OAuth2 Resource Server (JWT) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>
    
    <!-- Redis reactive (rate limiting) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis-reactive</artifactId>
    </dependency>
    
    <!-- Eureka Client -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    
    <!-- Actuator -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>
</dependencies>
```

**⚠️ NO INCLUIR:**
```xml
<!-- ❌ NO incluir estas dependencias -->
<dependency>spring-boot-starter-data-jpa</dependency>
<dependency>mysql-connector-j</dependency>
<dependency>spring-boot-starter-web</dependency> <!-- Gateway usa WebFlux -->
```

**Configuración application.yml:**
```yaml
server:
  port: 8080

spring:
  application:
    name: api-gateway
  
  cloud:
    gateway:
      routes:
        # Auth Service (público)
        - id: auth-service
          uri: lb://auth-service
          predicates:
            - Path=/api/auth/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 5
                redis-rate-limiter.burstCapacity: 10
        
        # Catalog Service
        - id: catalog-service
          uri: lb://catalog-service
          predicates:
            - Path=/api/catalog/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10
                redis-rate-limiter.burstCapacity: 20
        
        # Booking Service
        - id: booking-service
          uri: lb://booking-service
          predicates:
            - Path=/api/bookings/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10
                redis-rate-limiter.burstCapacity: 20
        
        # Search Service
        - id: search-service
          uri: lb://search-service
          predicates:
            - Path=/api/search/**
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 50
                redis-rate-limiter.burstCapacity: 100
  
  # Redis
  data:
    redis:
      host: localhost
      port: 6379
  
  # JWT Validation (sin BD)
  security:
    oauth2:
      resourceserver:
        jwt:
          # Opción 1: JWK endpoint del Auth Service
          jwk-set-uri: http://localhost:8084/.well-known/jwks.json
          # Opción 2: Keycloak
          # issuer-uri: http://localhost:9090/realms/balconazo

# Eureka
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
```

**Resultado esperado:**
- Gateway corriendo en puerto 8080
- Enruta correctamente a 4 servicios
- Valida JWT de Auth Service
- Rate limiting funciona con Redis
- Registrado en Eureka

---

### PASO 6: Actualizar Rutas de los Microservicios
**Duración:** 15 minutos  
**Prioridad:** 🟡 MEDIA

**Cambios necesarios:**

Todos los microservicios ahora se acceden a través del Gateway:

**ANTES:**
```
http://localhost:8085/api/catalog/spaces  (directo a Catalog)
http://localhost:8082/api/bookings        (directo a Booking)
http://localhost:8083/api/search/spaces   (directo a Search)
```

**DESPUÉS:**
```
http://localhost:8080/api/catalog/spaces  (a través del Gateway)
http://localhost:8080/api/bookings        (a través del Gateway)
http://localhost:8080/api/search/spaces   (a través del Gateway)
http://localhost:8080/api/auth/login      (a través del Gateway)
```

**Actualizar scripts de prueba:**
- `test-e2e.sh` → cambiar localhost:8085 por localhost:8080
- Frontend → configurar API base URL a `http://localhost:8080`

---

### PASO 7: Pruebas de Integración
**Duración:** 1 hora  
**Prioridad:** 🟢 VERIFICACIÓN

**Flujo completo a probar:**

```bash
# 1. Registrar usuario
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "Password123!",
    "role": "host"
  }'

# 2. Login (obtener JWT)
JWT=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "Password123!"
  }' | jq -r '.accessToken')

echo "JWT obtenido: $JWT"

# 3. Acceder a recurso protegido (crear espacio)
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT" \
  -d '{
    "ownerId": "...",
    "title": "Test Space",
    "description": "Espacio de prueba",
    "address": "Calle Test, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 4,
    "basePriceCents": 5000,
    "amenities": ["wifi"],
    "rules": {}
  }'

# 4. Probar rate limiting (debe fallar después de N requests)
for i in {1..15}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/search/spaces
done
# Esperado: primeros 10 devuelven 200, siguientes 429 (Too Many Requests)

# 5. Probar sin JWT (debe fallar con 401)
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{...}'
# Esperado: HTTP 401 Unauthorized
```

**Resultado esperado:** Todos los flujos funcionan correctamente

---

## 📦 INFRAESTRUCTURA NECESARIA

### Contenedores Docker a levantar:

```bash
# Verificar servicios existentes
docker ps --filter "name=balconazo"

# Debería mostrar:
# - balconazo-pg-catalog (5433)
# - balconazo-pg-booking (5434)
# - balconazo-pg-search (5435)
# - balconazo-zookeeper (2181)
# - balconazo-kafka (9092)
# - balconazo-redis (6379)

# Agregar MySQL para Auth Service
docker run -d --name balconazo-mysql-auth \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=auth_db \
  mysql:8.0
```

### Puertos utilizados:

| Puerto | Servicio |
|--------|----------|
| 8080 | API Gateway |
| 8084 | Auth Service |
| 8085 | Catalog Service |
| 8082 | Booking Service |
| 8083 | Search Service |
| 8761 | Eureka Server |
| 3307 | MySQL (Auth) |
| 5433 | PostgreSQL (Catalog) |
| 5434 | PostgreSQL (Booking) |
| 5435 | PostgreSQL (Search) |
| 6379 | Redis |
| 9092 | Kafka |
| 2181 | Zookeeper |

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Eureka Server
- [ ] Proyecto creado con estructura correcta
- [ ] `pom.xml` configurado
- [ ] `application.yml` configurado
- [ ] Servidor inicia en puerto 8761
- [ ] Dashboard accesible en http://localhost:8761

### Auth Service
- [ ] Proyecto creado con estructura correcta
- [ ] Dependencias correctas en `pom.xml`
- [ ] Entidades `User` y `RefreshToken` creadas
- [ ] Repositories creados
- [ ] `JwtService` implementado (generar y validar tokens)
- [ ] `AuthService` implementado (register, login, refresh)
- [ ] `AuthController` con endpoints REST
- [ ] `SecurityConfig` permite endpoints públicos
- [ ] MySQL corriendo en puerto 3307
- [ ] Tablas creadas en `auth_db`
- [ ] Servicio inicia en puerto 8084
- [ ] Registrado en Eureka
- [ ] Endpoint `/api/auth/register` funciona
- [ ] Endpoint `/api/auth/login` devuelve JWT válido
- [ ] Health check OK

### API Gateway
- [ ] Proyecto creado con estructura correcta
- [ ] Dependencias correctas (sin JPA/MySQL)
- [ ] `application.yml` con rutas configuradas
- [ ] `SecurityConfig` configurado para JWT
- [ ] Rate limiting configurado con Redis
- [ ] CORS configurado
- [ ] Gateway inicia en puerto 8080
- [ ] Registrado en Eureka
- [ ] Enruta correctamente a Auth Service
- [ ] Enruta correctamente a Catalog Service
- [ ] Enruta correctamente a Booking Service
- [ ] Enruta correctamente a Search Service
- [ ] Valida JWT correctamente (401 si inválido)
- [ ] Rate limiting funciona
- [ ] Health check OK

### Microservicios Existentes
- [ ] Catalog Service tiene dependencia Eureka Client
- [ ] Catalog Service registrado en Eureka
- [ ] Booking Service tiene dependencia Eureka Client
- [ ] Booking Service registrado en Eureka
- [ ] Search Service tiene dependencia Eureka Client
- [ ] Search Service registrado en Eureka

### Pruebas E2E
- [ ] Flujo completo de registro funciona
- [ ] Flujo completo de login funciona
- [ ] Acceso a recursos protegidos con JWT funciona
- [ ] Acceso sin JWT devuelve 401
- [ ] Rate limiting bloquea exceso de requests
- [ ] Scripts `test-e2e.sh` actualizados y funcionan

---

## 📚 DOCUMENTACIÓN A CONSULTAR

1. **ADR API Gateway:** `docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md`
2. **Hoja de Ruta:** `HOJA_DE_RUTA.md`
3. **Estado Actual:** `ESTADO_ACTUAL.md`
4. **Spring Cloud Gateway:** https://spring.io/projects/spring-cloud-gateway
5. **JWT con Spring Security:** https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html

---

## 🎯 CRITERIOS DE ÉXITO

**La Fase 4 estará completa cuando:**

- ✅ Eureka Server funciona y muestra todos los servicios
- ✅ Auth Service puede registrar usuarios y generar JWT
- ✅ API Gateway enruta correctamente a todos los servicios
- ✅ JWT se valida correctamente en el Gateway
- ✅ Rate limiting funciona con Redis
- ✅ Flujo E2E completo funciona: register → login → acceso protegido
- ✅ Documentación actualizada
- ✅ Scripts de inicio actualizados

---

## ⏱️ ESTIMACIÓN DE TIEMPO TOTAL

| Tarea | Tiempo Estimado |
|-------|-----------------|
| Eureka Server | 30 min |
| Registrar servicios en Eureka | 20 min |
| MySQL Auth | 10 min |
| Auth Service | 3 horas |
| API Gateway | 2 horas |
| Actualizar rutas | 15 min |
| Pruebas E2E | 1 hora |
| **TOTAL** | **~7 horas** |

**Distribución recomendada:**
- **Día 1 (4 horas):** Eureka + MySQL + Auth Service
- **Día 2 (3 horas):** API Gateway + Pruebas

---

## 🚀 COMANDO PARA EMPEZAR

```bash
# Paso 1: Crear Eureka Server
cd /Users/angel/Desktop/BalconazoApp
mkdir eureka-server
cd eureka-server

# Esperar confirmación para continuar con el código...
```

---

**Última actualización:** 28 de octubre de 2025, 14:15  
**Estado:** ✅ Documentación completa, listo para implementar

