# 🔍 DIAGNÓSTICO COMPLETO DEL ERROR 403

**Fecha:** 29 de Octubre de 2025  
**Análisis:** Sistema completo - Auth Service + API Gateway

---

## 1️⃣ MÓDULOS Y PUERTOS

| Módulo | Puerto | Tipo | Estado Config |
|--------|--------|------|---------------|
| **Eureka Server** | 8761 | Service Discovery | ✅ OK |
| **API Gateway** | 8080 | WebFlux Gateway | ⚠️ **PROBLEMA DETECTADO** |
| **Auth Service** | 8084 | MVC REST | ✅ OK (corregido) |
| **Catalog Service** | 8085 | MVC REST | ✅ OK |
| **Booking Service** | 8082 | MVC REST | ✅ OK |
| **Search Service** | 8083 | MVC REST | ✅ OK |

---

## 2️⃣ SECURITY CONFIGS ANALIZADOS

### ✅ Auth Service SecurityConfig (MVC) - CORRECTO

**Ubicación:** `/auth-service/src/main/java/com/balconazo/auth/config/SecurityConfig.java`

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // ✅ CSRF DESHABILITADO
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/login", "/api/auth/register").permitAll() // ✅ PERMITALL CORRECTO
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

**Análisis:**
- ✅ CSRF: **Deshabilitado**
- ✅ `/api/auth/login`: **permitAll() con HttpMethod.POST explícito**
- ✅ `/api/auth/register`: **permitAll() con HttpMethod.POST explícito**
- ✅ Session: **STATELESS**
- ✅ Logging: **DEBUG habilitado en application.yml**

**Conclusión:** ✅ **CONFIGURACIÓN PERFECTA**

---

### ✅ API Gateway SecurityConfig (WebFlux) - CORRECTO

**Ubicación:** `/api-gateway/src/main/java/com/balconazo/gateway/config/SecurityConfig.java`

```java
@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable) // ✅ CSRF DESHABILITADO
            .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
            .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
            .authorizeExchange(exchanges -> exchanges
                .anyExchange().permitAll() // ✅ TODO PERMITIDO (micros validan)
            )
            .build();
    }
}
```

**Análisis:**
- ✅ CSRF: **Deshabilitado**
- ✅ Estrategia: **Gateway NO valida JWT, solo enruta**
- ✅ Seguridad: **Delegada a los microservicios**

**Conclusión:** ✅ **CONFIGURACIÓN CORRECTA**

---

## 3️⃣ AUTH CONTROLLER - PATHS CONFIRMADOS

**Ubicación:** `/auth-service/src/main/java/com/balconazo/auth/controller/AuthController.java`

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @PostMapping("/login")  // ← URL REAL: POST /api/auth/login
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("POST /api/auth/login - Email: {}", request.getEmail());
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")  // ← URL REAL: POST /api/auth/register
    // ...
}
```

**URLs Confirmadas:**
- ✅ Login: `POST /api/auth/login`
- ✅ Register: `POST /api/auth/register`
- ✅ Refresh: `POST /api/auth/refresh`
- ✅ Logout: `POST /api/auth/logout`
- ✅ Me: `GET /api/auth/me`

**Conclusión:** ✅ **PATHS CORRECTOS - Coinciden con SecurityConfig**

---

## 4️⃣ @PreAuthorize - NO ENCONTRADO

**Búsqueda realizada en:**
- `auth-service/**/*.java`

**Resultado:** ✅ **NO hay @PreAuthorize en el login**

---

## 5️⃣ 🚨 PROBLEMA ENCONTRADO: GATEWAY APPLICATION.YML

**Ubicación:** `/api-gateway/src/main/resources/application.yml`

### ❌ PROBLEMA CRÍTICO: RequestRateLimiter sin KeyResolver configurado

```yaml
routes:
  - id: auth-service
    uri: lb://auth-service
    predicates:
      - Path=/api/auth/**
    filters:
      - StripPrefix=0
      - name: RequestRateLimiter  # ⚠️ PROBLEMA AQUÍ
        args:
          redis-rate-limiter.replenishRate: 5
          redis-rate-limiter.burstCapacity: 10
          redis-rate-limiter.requestedTokens: 1
          # ❌ FALTA: deny-empty-key: false
          # ❌ FALTA: key-resolver: "#{@userKeyResolver}"
```

**CAUSA DEL 403:**

El `RequestRateLimiter` está configurado en la ruta de auth, pero:
1. ❌ **NO tiene `key-resolver` especificado** en los args
2. ❌ **NO tiene `deny-empty-key: false`**
3. ❌ **Por defecto**, cuando no puede resolver la key → **DENIEGA la petición con 403**

Aunque existe `RateLimitConfig.java` con un `userKeyResolver()`, no está siendo usado en la ruta.

---

### 🔧 RateLimitConfig.java - Bean EXISTE pero NO SE USA

**Ubicación:** `/api-gateway/src/main/java/com/balconazo/gateway/config/RateLimitConfig.java`

```java
@Configuration
public class RateLimitConfig {

    @Bean
    public KeyResolver userKeyResolver() {  // ← Bean existe
        return exchange -> {
            String ipAddress = Objects.requireNonNull(
                exchange.getRequest().getRemoteAddress()
            ).getAddress().getHostAddress();
            return Mono.just(ipAddress);
        };
    }
}
```

**Problema:** El bean `userKeyResolver` existe, pero **NO está referenciado** en el filtro del YAML.

---

## 6️⃣ OTROS HALLAZGOS

### ✅ CircuitBreaker
```yaml
- name: CircuitBreaker
  args:
    name: authServiceCircuitBreaker
    fallbackUri: forward:/fallback/auth
```

**Análisis:** ✅ Circuit Breaker configurado correctamente, NO causa el 403.

### ✅ CORS
```yaml
globalcors:
  cors-configurations:
    '[/**]':
      allowed-origins:
        - "http://localhost:4200"
        - "http://localhost:3000"
      allowed-methods:
        - GET
        - POST
        - PUT
        - DELETE
        - OPTIONS
```

**Análisis:** ✅ CORS permite POST y el origen, NO causa el 403.

### ✅ StripPrefix
```yaml
- StripPrefix=0
```

**Análisis:** ✅ No modifica el path, `/api/auth/login` llega intacto al Auth Service.

---

## 📋 RESUMEN DEL DIAGNÓSTICO

### ✅ CORRECTO:
1. ✅ Auth Service SecurityConfig - CSRF off, permitAll configurado
2. ✅ Gateway SecurityConfig - permitAll para todo
3. ✅ AuthController paths - `/api/auth/login` correcto
4. ✅ No hay @PreAuthorize bloqueando
5. ✅ CORS configurado correctamente
6. ✅ Circuit Breaker no interfiere
7. ✅ Bean KeyResolver existe

### 🚨 PROBLEMA RAÍZ:

**RequestRateLimiter en Gateway NO tiene key-resolver configurado**

Cuando una petición llega a `/api/auth/login`:
1. Gateway aplica el filtro `RequestRateLimiter`
2. Intenta obtener una "key" para el rate limiting
3. **NO encuentra el key-resolver** (no está en args)
4. **Por defecto, DENIEGA** la petición
5. Devuelve **403 Forbidden**

---

## ✅ SOLUCIÓN

### Opción 1: Añadir key-resolver al filtro (RECOMENDADO)

```yaml
- name: RequestRateLimiter
  args:
    key-resolver: "#{@userKeyResolver}"  # ← AÑADIR ESTO
    deny-empty-key: false                 # ← AÑADIR ESTO
    redis-rate-limiter.replenishRate: 5
    redis-rate-limiter.burstCapacity: 10
    redis-rate-limiter.requestedTokens: 1
```

### Opción 2: Quitar RequestRateLimiter de auth-service route

```yaml
- id: auth-service
  uri: lb://auth-service
  predicates:
    - Path=/api/auth/**
  filters:
    - StripPrefix=0
    # ← ELIMINAR RequestRateLimiter completamente
    - name: CircuitBreaker
      args:
        name: authServiceCircuitBreaker
        fallbackUri: forward:/fallback/auth
```

---

## 🎯 PLAN DE ACCIÓN

1. **CORREGIR** `application.yml` del Gateway añadiendo `key-resolver` y `deny-empty-key`
2. **RECOMPILAR** API Gateway
3. **REINICIAR** API Gateway
4. **PROBAR** el login

---

## 📊 TABLA DE VERIFICACIÓN

| Componente | Estado | Causa 403 |
|------------|--------|-----------|
| Auth SecurityConfig | ✅ OK | ❌ No |
| Gateway SecurityConfig | ✅ OK | ❌ No |
| AuthController paths | ✅ OK | ❌ No |
| @PreAuthorize | ✅ Ausente | ❌ No |
| CORS | ✅ OK | ❌ No |
| Circuit Breaker | ✅ OK | ❌ No |
| **RequestRateLimiter** | ❌ **MAL CONFIGURADO** | ✅ **SÍ - CAUSA RAÍZ** |

---

## 🎉 CONCLUSIÓN

**EL PROBLEMA NO ESTÁ EN AUTH SERVICE.**

**EL PROBLEMA ESTÁ EN EL API GATEWAY:**

El `RequestRateLimiter` del Gateway está bloqueando las peticiones anónimas porque:
1. No tiene `key-resolver` configurado en los args
2. No tiene `deny-empty-key: false`
3. Por defecto, cuando falla la resolución de key → 403

**SOLUCIÓN:** Actualizar el `application.yml` del API Gateway.

