# 🧪 PRUEBAS COMPLETAS DEL SISTEMA BALCONAZO

**Fecha:** 30 de Octubre de 2025
**Estado:** Search Service CORREGIDO

---

## ✅ ERRORES CORREGIDOS

1. **Password vacía en `application.properties`** → ✅ Corregida a `postgres`
2. **Columna `s.location` no existe** → ✅ Cambiada a `s.geo`
3. **Columnas price/rating incorrectas** → ✅ Corregidas a `base_price_cents` y `avg_rating`

---

## 🧪 BATERÍA DE PRUEBAS

### 1️⃣ HEALTH CHECKS (Todos los servicios)

```bash
echo "=== HEALTH CHECKS ===" && \
curl -s http://localhost:8080/actuator/health | grep -o '"status":"[^"]*"' && \
curl -s http://localhost:8084/actuator/health | grep -o '"status":"[^"]*"' && \
curl -s http://localhost:8085/actuator/health | grep -o '"status":"[^"]*"' && \
curl -s http://localhost:8082/actuator/health | grep -o '"status":"[^"]*"' && \
curl -s http://localhost:8083/actuator/health | grep -o '"status":"[^"]*"' && \
curl -s http://localhost:8761/actuator/health | grep -o '"status":"[^"]*"'
```

**✅ Esperado:** Todos deben mostrar `"status":"UP"`

---

### 2️⃣ AUTH SERVICE

#### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**✅ Esperado:** JSON con `accessToken`, `userId`, `role`

#### Get Me (requiere token)
```bash
TOKEN="<pega_aqui_el_token>"
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/auth/me
```

**✅ Esperado:** Datos del usuario autenticado

---

### 3️⃣ CATALOG SERVICE

#### Get All Spaces
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces
```

**✅ Esperado:** Array con 6 espacios

#### Get Space by ID
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
```

**✅ Esperado:** JSON del "Ático con terraza"

#### Create Space
```bash
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Space",
    "description": "Espacio de prueba",
    "ownerId": "'$USER_ID'",
    "address": "Calle Test 123",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 10,
    "basePriceCents": 3000
  }'
```

**✅ Esperado:** 201 Created con el space creado

---

### 4️⃣ SEARCH SERVICE (GEOESPACIAL)

#### Búsqueda por ubicación (SIN TOKEN - público)
```bash
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5"
```

**✅ Esperado:** Array con espacios cercanos a Madrid centro

#### Búsqueda con filtros
```bash
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=10&minCapacity=15&sortBy=distance"
```

**✅ Esperado:** Espacios filtrados por capacidad, ordenados por distancia

---

### 5️⃣ BOOKING SERVICE

#### Create Booking
```bash
curl -X POST http://localhost:8080/api/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "guestId": "'$USER_ID'",
    "startTs": "2025-12-01T10:00:00",
    "endTs": "2025-12-01T14:00:00",
    "numGuests": 5,
    "paymentMethod": "CREDIT_CARD"
  }'
```

**✅ Esperado:** 201 Created con la reserva

#### Get Bookings by Guest
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/booking/bookings/guest/33333333-3333-3333-3333-333333333333"
```

**✅ Esperado:** Array con 2 bookings de guest1

#### Confirm Booking
```bash
BOOKING_ID="10000000-0000-0000-0000-000000000003"
curl -X POST "http://localhost:8080/api/booking/bookings/$BOOKING_ID/confirm?paymentIntentId=pi_test_123" \
  -H "Authorization: Bearer $TOKEN"
```

**✅ Esperado:** 200 OK con booking confirmado

---

### 6️⃣ REVIEWS

#### Create Review
```bash
curl -X POST http://localhost:8080/api/booking/reviews \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "10000000-0000-0000-0000-000000000001",
    "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "guestId": "'$USER_ID'",
    "rating": 5,
    "comment": "Excelente espacio para eventos"
  }'
```

**✅ Esperado:** 201 Created con la reseña

#### Get Reviews by Space
```bash
curl "http://localhost:8080/api/booking/reviews/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
```

**✅ Esperado:** Array con 2 reseñas

---

### 7️⃣ EUREKA (Registro de servicios)

```bash
curl -s http://localhost:8761/eureka/apps | grep -E "API-GATEWAY|AUTH-SERVICE|CATALOG-SERVICE|BOOKING-SERVICE|SEARCH-SERVICE"
```

**✅ Esperado:** Ver los 5 servicios registrados

---

### 8️⃣ GATEWAY (Rutas y métricas)

#### Ver rutas del Gateway
```bash
curl http://localhost:8080/actuator/gateway/routes
```

**✅ Esperado:** JSON con todas las rutas configuradas

#### Métricas Prometheus
```bash
curl http://localhost:8080/actuator/prometheus | grep http_server_requests
```

**✅ Esperado:** Métricas en formato Prometheus

---

## 🔍 TESTS DE ERRORES

### Test 1: Request sin token a ruta protegida
```bash
curl -i http://localhost:8080/api/catalog/spaces
```

**✅ Esperado:** 401 Unauthorized

### Test 2: Token inválido
```bash
curl -i -H "Authorization: Bearer invalid_token_123" \
  http://localhost:8080/api/catalog/spaces
```

**✅ Esperado:** 401 Unauthorized

### Test 3: Space inexistente
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces/00000000-0000-0000-0000-000000000000
```

**✅ Esperado:** 404 Not Found

---

## 📊 TESTS DE INTEGRACIÓN

### Test E2E Completo
```bash
# 1. Login
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}')

TOKEN=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['accessToken'])")
USER_ID=$(echo $LOGIN_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['userId'])")

echo "✅ Token obtenido"

# 2. Listar espacios
curl -s -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces | python3 -c "import sys, json; print(f\"Espacios: {len(json.load(sys.stdin))}\")"

# 3. Buscar espacios cercanos
curl -s "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5" | \
  python3 -c "import sys, json; print(f\"Resultados búsqueda: {len(json.load(sys.stdin))}\")"

# 4. Crear booking
curl -s -X POST http://localhost:8080/api/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "guestId": "'$USER_ID'",
    "startTs": "2025-12-15T10:00:00",
    "endTs": "2025-12-15T14:00:00",
    "numGuests": 5,
    "paymentMethod": "CREDIT_CARD"
  }' | python3 -c "import sys, json; print(f\"✅ Booking creado: {json.load(sys.stdin)['id']}\")"

echo "✅ Test E2E completado"
```

---

## 🐛 DEBUGGING

### Ver logs en tiempo real
```bash
# Gateway
tail -f /tmp/gateway.log

# Auth
tail -f /tmp/auth-service.log

# Catalog
tail -f /tmp/catalog-service.log

# Booking
tail -f /tmp/booking-service.log

# Search
tail -f /tmp/search-service.log
```

### Verificar procesos corriendo
```bash
lsof -i :8080  # Gateway
lsof -i :8084  # Auth
lsof -i :8085  # Catalog
lsof -i :8082  # Booking
lsof -i :8083  # Search
lsof -i :8761  # Eureka
```

### Verificar contenedores Docker
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

---

## 📋 CHECKLIST DE VERIFICACIÓN

- [ ] ✅ Todos los health checks devuelven UP
- [ ] ✅ Login funciona y devuelve token
- [ ] ✅ Get Me devuelve usuario autenticado
- [ ] ✅ Listar espacios devuelve 6 items
- [ ] ✅ Get space by ID funciona
- [ ] ✅ Búsqueda geoespacial devuelve resultados
- [ ] ✅ Crear booking funciona
- [ ] ✅ Get bookings by guest devuelve array
- [ ] ✅ Confirmar booking funciona
- [ ] ✅ Crear review funciona
- [ ] ✅ Get reviews by space devuelve array
- [ ] ✅ Rutas sin token devuelven 401
- [ ] ✅ Eureka muestra 5 servicios registrados
- [ ] ✅ Gateway routes muestra todas las rutas

---

## 🎯 RESULTADO ESPERADO

**TODO EN VERDE** ✅

Si algún test falla:
1. Verifica logs del servicio específico
2. Comprueba que el contenedor Docker esté UP
3. Verifica que Eureka tenga el servicio registrado
4. Revisa la configuración de red/puertos

---

**Última actualización:** 30 de Octubre de 2025, 11:35

