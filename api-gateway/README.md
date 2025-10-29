# 🌐 API Gateway - Balconazo

**Puerto:** 8080  
**Tipo:** Spring Cloud Gateway (Reactive)  
**Estado:** ✅ Implementado

---

## 📋 Descripción

API Gateway es el **punto de entrada único** para todos los microservicios de Balconazo. Proporciona:

- ✅ Enrutamiento a microservicios
- ✅ Validación de JWT (sin BD)
- ✅ Rate Limiting con Redis
- ✅ Circuit Breaker con Resilience4j
- ✅ CORS para frontend
- ✅ Correlation ID para trazabilidad
- ✅ Fallback en caso de fallos

---

## 🏗️ Arquitectura

```
Frontend (Angular)
       ↓
API Gateway :8080 (Este servicio)
       ↓
   ┌───┴───┬───────┬─────────┐
   ↓       ↓       ↓         ↓
Auth    Catalog  Booking  Search
:8084   :8085    :8082    :8083
```

---

## 🛣️ Rutas Configuradas

### Públicas (sin JWT)

| Ruta | Destino | Rate Limit | Descripción |
|------|---------|------------|-------------|
| `/api/auth/**` | auth-service:8084 | 5 req/min | Login, registro, refresh |
| `/api/search/**` | search-service:8083 | 50 req/min | Búsqueda de espacios |

### Protegidas (requieren JWT)

| Ruta | Destino | Rate Limit | Descripción |
|------|---------|------------|-------------|
| `/api/catalog/spaces/**` | catalog-service:8085 | 20 req/min | CRUD de espacios |
| `/api/catalog/users/**` | catalog-service:8085 | 20 req/min | CRUD de usuarios |
| `/api/catalog/availability/**` | catalog-service:8085 | 20 req/min | Disponibilidad |
| `/api/booking/bookings/**` | booking-service:8082 | 15 req/min | Gestión de reservas |
| `/api/booking/reviews/**` | booking-service:8082 | 15 req/min | Sistema de reviews |

---

## 🔐 Autenticación

### Cómo funciona

1. **Cliente** hace login en `/api/auth/login`
2. **Auth Service** devuelve JWT token
3. **Cliente** envía token en header `Authorization: Bearer {token}` en peticiones protegidas
4. **API Gateway** valida JWT **sin consultar BD** (stateless)
5. Si JWT es válido, enruta la petición al microservicio

### Ejemplo de petición protegida

```bash
# 1. Obtener JWT
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@balconazo.com",
    "password": "password123"
  }' | jq -r '.token')

# 2. Usar JWT en peticiones protegidas
curl -X GET http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🚦 Rate Limiting

### Estrategia

- **Key:** IP Address
- **Almacenamiento:** Redis
- **Algoritmo:** Token Bucket

### Límites por servicio

| Servicio | Requests/min | Burst Capacity |
|----------|--------------|----------------|
| Auth | 5 | 10 |
| Catalog | 20 | 40 |
| Booking | 15 | 30 |
| Search | 50 | 100 |

### Respuesta cuando se excede el límite

```json
HTTP 429 Too Many Requests
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Has excedido el límite de peticiones. Intenta de nuevo más tarde."
}
```

---

## 🔄 Circuit Breaker

### Configuración

- **Sliding Window:** 10 requests
- **Failure Rate Threshold:** 50%
- **Wait Duration (Open):** 10 segundos
- **Half-Open Calls:** 3

### Estados

1. **CLOSED:** Normal, todas las peticiones pasan
2. **OPEN:** Servicio caído, se activa fallback inmediatamente
3. **HALF_OPEN:** Probando si el servicio se recuperó

### Fallback

Cuando un servicio no responde, devuelve:

```json
HTTP 503 Service Unavailable
{
  "error": "CATALOG_SERVICE_UNAVAILABLE",
  "message": "El servicio de catálogo no está disponible temporalmente...",
  "timestamp": "2025-10-29T15:30:00",
  "service": "catalog-service"
}
```

---

## 🔗 Correlation ID

Cada petición recibe un `X-Correlation-Id` único:

```
Request Headers:
  X-Correlation-Id: 550e8400-e29b-41d4-a716-446655440000

Response Headers:
  X-Correlation-Id: 550e8400-e29b-41d4-a716-446655440000
```

**Utilidad:**
- Rastrear peticiones a través de múltiples microservicios
- Debugging distribuido
- Logs correlacionados

---

## 📊 Métricas y Monitoreo

### Endpoints de Actuator

- `GET /actuator/health` - Estado del gateway
- `GET /actuator/metrics` - Métricas generales
- `GET /actuator/prometheus` - Métricas en formato Prometheus
- `GET /actuator/gateway/routes` - Rutas configuradas

### Ejemplo: Ver rutas

```bash
curl http://localhost:8080/actuator/gateway/routes | jq
```

---

## 🚀 Inicio Rápido

### Requisitos previos

- ✅ Java 21+
- ✅ Maven 3.9+
- ✅ Redis corriendo (puerto 6379)
- ✅ Eureka Server corriendo (puerto 8761)

### Opción 1: Script automatizado

```bash
./start-gateway.sh
```

### Opción 2: Manual

```bash
cd api-gateway
mvn clean package -DskipTests
java -jar target/api-gateway-1.0.0.jar
```

### Verificar que está corriendo

```bash
curl http://localhost:8080/actuator/health
```

Respuesta esperada:
```json
{
  "status": "UP",
  "components": {
    "eureka": {
      "status": "UP"
    },
    "redis": {
      "status": "UP"
    }
  }
}
```

---

## 🧪 Pruebas

### Test 1: Ruta pública (Search)

```bash
curl http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=10
```

### Test 2: Ruta protegida sin JWT (debe fallar)

```bash
curl http://localhost:8080/api/catalog/spaces
# Respuesta: HTTP 401 Unauthorized
```

### Test 3: Ruta protegida con JWT

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.token')

# 2. Usar token
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces
```

### Test 4: Rate Limiting

```bash
# Ejecutar esto 6 veces rápidamente (límite: 5 req/min para auth)
for i in {1..6}; do
  curl -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"wrong"}'
  echo ""
done

# La 6ta petición debería devolver HTTP 429
```

### Test 5: Circuit Breaker

```bash
# Detener Catalog Service
# Luego intentar acceder:
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces

# Debería devolver el fallback (HTTP 503)
```

---

## 🛠️ Configuración

### Variables de entorno importantes

| Variable | Descripción | Default |
|----------|-------------|---------|
| `SERVER_PORT` | Puerto del gateway | 8080 |
| `JWT_SECRET` | Secret compartido con Auth Service | (ver application.yml) |
| `SPRING_REDIS_HOST` | Host de Redis | localhost |
| `SPRING_REDIS_PORT` | Puerto de Redis | 6379 |
| `EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE` | URL de Eureka | http://localhost:8761/eureka/ |

### Personalizar rate limits

Editar `application.yml`:

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 10  # Cambiar aquí
                redis-rate-limiter.burstCapacity: 20  # Y aquí
```

---

## 📝 Logs

### Ubicación

- **Consola:** stdout
- **Archivo:** `logs/api-gateway.log`

### Formato

```
2025-10-29 15:30:00 - 🔗 [550e8400-e29b-41d4-a716-446655440000] GET /api/catalog/spaces - Remote: 127.0.0.1:52341
2025-10-29 15:30:01 - ✅ [550e8400-e29b-41d4-a716-446655440000] Request completed successfully
```

---

## 🐛 Troubleshooting

### Problema: Gateway no inicia

**Error:** `Port 8080 already in use`

**Solución:**
```bash
# Encontrar proceso
lsof -ti:8080

# Matar proceso
kill -9 $(lsof -ti:8080)
```

### Problema: JWT inválido

**Error:** `Error validando JWT: ...`

**Causas:**
1. Secret key diferente entre Auth Service y Gateway
2. Token expirado
3. Token malformado

**Solución:**
- Verificar que `jwt.secret` sea idéntico en ambos servicios
- Obtener un nuevo token

### Problema: Rate limit activado incorrectamente

**Error:** `HTTP 429 Too Many Requests`

**Solución:**
```bash
# Limpiar rate limits en Redis
redis-cli FLUSHDB
```

### Problema: Circuit breaker abierto

**Error:** `Service unavailable` inmediatamente

**Solución:**
1. Verificar que el microservicio esté corriendo
2. Esperar 10 segundos (wait-duration)
3. El circuit breaker pasará a HALF_OPEN automáticamente

---

## 📚 Referencias

- [Spring Cloud Gateway Docs](https://cloud.spring.io/spring-cloud-gateway/reference/html/)
- [Resilience4j Circuit Breaker](https://resilience4j.readme.io/docs/circuitbreaker)
- [Redis Rate Limiter](https://redis.io/docs/manual/patterns/distributed-locks/)

---

## 🎯 Próximos Pasos

- [ ] Agregar autenticación OAuth2 (Google, Facebook)
- [ ] Implementar API versioning
- [ ] Agregar request/response logging más detallado
- [ ] Integrar con Jaeger para distributed tracing
- [ ] Implementar rate limiting por usuario (no solo por IP)

