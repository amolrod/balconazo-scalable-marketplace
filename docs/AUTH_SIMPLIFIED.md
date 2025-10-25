# Autenticación Simplificada para MVP - Balconazo

## 🎯 Objetivo

Implementar autenticación JWT **sin Keycloak** para MVP, con migración fácil a IdP externo (Keycloak/Cognito) en el futuro.

---

## 🔐 Arquitectura Simplificada

```
┌─────────────────┐
│  Frontend       │
│  (Angular 20)   │
└────────┬────────┘
         │ POST /auth/login {email, password}
         ↓
┌─────────────────────────────────┐
│  API Gateway :8080              │
│  (Auth Endpoints)               │
│                                 │
│  /auth/login    → AuthService   │
│  /auth/register → AuthService   │
│  /auth/refresh  → AuthService   │
└────────┬────────────────────────┘
         │ JWT generated with HS256
         │ Secret: "balconazo-secret-key-change-in-prod"
         ↓
┌─────────────────────────────────┐
│  catalog-service :8081          │
│  (User Management)              │
│                                 │
│  GET /users/{id}                │
│  POST /users (register)         │
└─────────────────────────────────┘
```

---

## 📋 Flujo Completo

### 1. **Registro de Usuario**

```bash
POST /api/auth/register
Content-Type: application/json

{
  "email": "host@balconazo.com",
  "password": "SecurePass123!",
  "role": "host"
}
```

**Response:**
```json
{
  "userId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "email": "host@balconazo.com",
  "role": "host",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "7c8e9d0a-refresh-token-uuid",
  "expiresIn": 3600
}
```

**Backend (api-gateway):**
1. Valida email único (call a catalog-service)
2. Hash password con BCrypt
3. Crea usuario en catalog-service
4. Genera JWT con claims: `{sub: userId, email, role, exp}`
5. Guarda refresh token en Redis (TTL 7 días)

---

### 2. **Login**

```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "host@balconazo.com",
  "password": "SecurePass123!"
}
```

**Response:** Mismo que registro

**Backend:**
1. Busca usuario por email en catalog-service
2. Verifica password con BCrypt
3. Genera nuevo JWT + refresh token
4. Guarda refresh token en Redis

---

### 3. **Acceso a Recursos Protegidos**

```bash
GET /api/catalog/spaces
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**API Gateway:**
1. Extrae JWT del header `Authorization`
2. Valida signature con secret HS256
3. Verifica `exp` (expiración)
4. Extrae `sub` (userId) y `role`
5. Propaga headers a microservicio:
   - `X-User-Id: f3f2d5e0-...`
   - `X-User-Role: host`
6. Microservicio lee headers y aplica autorización

---

### 4. **Refresh Token**

```bash
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "7c8e9d0a-refresh-token-uuid"
}
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

**Backend:**
1. Verifica que refresh token existe en Redis
2. Obtiene userId asociado
3. Genera nuevo JWT
4. Mantiene mismo refresh token (o rota opcionalmente)

---

## 🔧 Implementación

### 1. JWT Generator (api-gateway)

```java
package com.balconazo.gateway.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtTokenGenerator {
    
    @Value("${balconazo.jwt.secret}")
    private String secret;  // "balconazo-secret-key-change-in-prod"
    
    @Value("${balconazo.jwt.expiration-ms}")
    private long expirationMs;  // 3600000 (1 hora)
    
    public String generateToken(String userId, String email, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("sub", userId);
        claims.put("email", email);
        claims.put("role", role);
        claims.put("iat", System.currentTimeMillis() / 1000);
        
        return Jwts.builder()
            .setClaims(claims)
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + expirationMs))
            .signWith(SignatureAlgorithm.HS256, secret)
            .compact();
    }
    
    public String validateTokenAndGetUserId(String token) {
        try {
            var claims = Jwts.parser()
                .setSigningKey(secret)
                .parseClaimsJws(token)
                .getBody();
            
            return claims.get("sub", String.class);
        } catch (Exception e) {
            throw new UnauthorizedException("Invalid or expired token");
        }
    }
    
    public Map<String, Object> extractClaims(String token) {
        return Jwts.parser()
            .setSigningKey(secret)
            .parseClaimsJws(token)
            .getBody();
    }
}
```

---

### 2. Auth Controller (api-gateway)

```java
package com.balconazo.gateway.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }
    
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
    
    @PostMapping("/refresh")
    public ResponseEntity<RefreshResponse> refresh(@RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request));
    }
    
    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestHeader("Authorization") String token) {
        authService.logout(token);
        return ResponseEntity.noContent().build();
    }
}
```

---

### 3. JWT Filter (api-gateway)

```java
package com.balconazo.gateway.security;

import lombok.RequiredArgsConstructor;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {
    
    private final JwtTokenGenerator jwtTokenGenerator;
    
    private static final List<String> PUBLIC_PATHS = List.of(
        "/auth/login", 
        "/auth/register", 
        "/auth/refresh"
    );
    
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String path = exchange.getRequest().getURI().getPath();
        
        // Skip authentication for public paths
        if (PUBLIC_PATHS.stream().anyMatch(path::startsWith)) {
            return chain.filter(exchange);
        }
        
        // Extract token from Authorization header
        String authHeader = exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        
        String token = authHeader.substring(7);
        
        try {
            // Validate token and extract claims
            var claims = jwtTokenGenerator.extractClaims(token);
            String userId = (String) claims.get("sub");
            String role = (String) claims.get("role");
            
            // Add headers for downstream services
            var mutatedRequest = exchange.getRequest().mutate()
                .header("X-User-Id", userId)
                .header("X-User-Role", role)
                .build();
            
            return chain.filter(exchange.mutate().request(mutatedRequest).build());
            
        } catch (Exception e) {
            exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }
    
    @Override
    public int getOrder() {
        return -100; // Run before other filters
    }
}
```

---

### 4. Password Hashing

```java
package com.balconazo.gateway.security;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class PasswordEncoder {
    
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
    
    public String encode(String rawPassword) {
        return encoder.encode(rawPassword);
    }
    
    public boolean matches(String rawPassword, String encodedPassword) {
        return encoder.matches(rawPassword, encodedPassword);
    }
}
```

---

### 5. Redis Refresh Token Storage

```java
package com.balconazo.gateway.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {
    
    private final StringRedisTemplate redisTemplate;
    private static final Duration REFRESH_TOKEN_TTL = Duration.ofDays(7);
    
    public String createRefreshToken(String userId) {
        String refreshToken = UUID.randomUUID().toString();
        String key = "refresh_token:" + refreshToken;
        
        redisTemplate.opsForValue().set(key, userId, REFRESH_TOKEN_TTL);
        
        return refreshToken;
    }
    
    public String validateAndGetUserId(String refreshToken) {
        String key = "refresh_token:" + refreshToken;
        String userId = redisTemplate.opsForValue().get(key);
        
        if (userId == null) {
            throw new UnauthorizedException("Invalid or expired refresh token");
        }
        
        return userId;
    }
    
    public void revokeRefreshToken(String refreshToken) {
        String key = "refresh_token:" + refreshToken;
        redisTemplate.delete(key);
    }
}
```

---

## 📝 Configuración

### application.yml (api-gateway)

```yaml
balconazo:
  jwt:
    secret: ${JWT_SECRET:balconazo-secret-key-change-in-prod-with-env-var}
    expiration-ms: 3600000  # 1 hora
    
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: 6379
```

### Variables de Entorno (Producción)

```bash
# .env.prod
JWT_SECRET=<generate-random-256-bit-key>
REDIS_HOST=redis-prod.cache.amazonaws.com
```

**Generar secret seguro:**
```bash
openssl rand -base64 32
# Output: Ky8vR3mT9pL2nQ5wX7jZ1aB4cD6eF8gH
```

---

## 🔄 Estructura JWT

### Payload Example

```json
{
  "sub": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "email": "host@balconazo.com",
  "role": "host",
  "iat": 1729872000,
  "exp": 1729875600
}
```

**Decodificar en https://jwt.io:**
```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload: (ver arriba)

Signature:
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  "balconazo-secret-key-change-in-prod"
)
```

---

## 🚀 Migración Futura a Keycloak/Cognito

### Cambios Necesarios

1. **Reemplazar JwtTokenGenerator:**
   ```java
   // Antes (MVP):
   String token = jwtTokenGenerator.generateToken(userId, email, role);
   
   // Después (Keycloak):
   @Autowired
   private ReactiveOAuth2AuthorizedClientService authorizedClientService;
   // Delegar a Keycloak para generar tokens
   ```

2. **Cambiar validación en Filter:**
   ```yaml
   # application.yml
   spring:
     security:
       oauth2:
         resourceserver:
           jwt:
             jwk-set-uri: http://keycloak:8080/realms/balconazo/protocol/openid-connect/certs
   ```

3. **Mantener `/auth/*` endpoints como proxy:**
   - `/auth/login` → Redirect a Keycloak OAuth2 flow
   - `/auth/register` → Keycloak Admin API

**Ventaja:** Los microservicios **NO cambian** (siguen leyendo `X-User-Id` y `X-User-Role` headers).

---

## ✅ Testing

### 1. Test de Registro

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "Test1234!",
    "role": "guest"
  }'
```

### 2. Test de Login

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "Test1234!"
  }'
```

### 3. Test de Endpoint Protegido

```bash
# Guardar token de login
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN"
```

### 4. Test de Refresh

```bash
curl -X POST http://localhost:8080/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "7c8e9d0a-..."
  }'
```

---

## 🔐 Seguridad Adicional (Opcional para MVP)

### 1. Rate Limiting en Login

```java
// Prevenir brute force
@RateLimiter(name = "login", fallbackMethod = "loginRateLimitFallback")
public AuthResponse login(LoginRequest request) {
    // ...
}
```

### 2. Blacklist de Tokens (Logout)

```java
public void logout(String token) {
    String userId = jwtTokenGenerator.validateTokenAndGetUserId(token);
    
    // Añadir a blacklist en Redis
    long remainingTtl = // calcular tiempo hasta exp
    redisTemplate.opsForValue().set("blacklist:" + token, "revoked", Duration.ofMillis(remainingTtl));
}

// En JwtAuthenticationFilter:
if (redisTemplate.hasKey("blacklist:" + token)) {
    // Token revocado
    exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
    return exchange.getResponse().setComplete();
}
```

---

## 📊 Comparación MVP vs Keycloak

| Aspecto | MVP (JWT Simple) | Keycloak |
|---------|------------------|----------|
| **Complejidad** | ⭐☆☆☆☆ Muy simple | ⭐⭐⭐⭐☆ Complejo |
| **Tiempo implementación** | 2-3 días | 1-2 semanas |
| **Features** | Login, Register, Refresh | SSO, OAuth2, OIDC, 2FA, Social Login |
| **Mantenimiento** | Bajo (50 líneas código) | Alto (contenedor + config) |
| **Escalabilidad** | Suficiente <10k usuarios | Enterprise-ready |
| **Migración futura** | Fácil (cambiar Gateway) | N/A |

**Recomendación:** Usar MVP simple ahora, migrar a Keycloak cuando:
- Necesites SSO (login con Google/Facebook)
- Tengas >10k usuarios activos
- Requieras 2FA obligatorio
- Necesites gestión de roles compleja (RBAC avanzado)

---

**Última actualización:** 25 de octubre de 2025  
**Autor:** Equipo de Seguridad Balconazo

