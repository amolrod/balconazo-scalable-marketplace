# 📮 COLECCIÓN DE ENDPOINTS POSTMAN - BALCONAZO API

**Fecha:** 20 Noviembre 2025  
**Base URL:** `http://localhost:8080`

---

## 📬 Guía de Uso Completa

Esta guía te ayudará a probar todos los endpoints del sistema usando Postman.

### 📦 Archivos Necesarios

1. **Colección**: `BalconazoApp.postman_collection.json` (29 endpoints)
2. **Entorno**: `Balconazo_Local.postman_environment.json`

---

## 🚀 CONFIGURACIÓN INICIAL

### 1. Importar la Colección

1. Abre Postman
2. Click en **Import** (botón superior izquierdo)
3. Arrastra el archivo `BalconazoApp.postman_collection.json` o selecciónalo
4. Click en **Import**
5. ✅ La colección completa con 29 endpoints estará lista

**La colección incluye:**
- ✅ Todos los endpoints organizados por servicio
- ✅ Scripts automáticos para guardar tokens
- ✅ Variables preconfiguradas (`{{baseUrl}}`, `{{token}}`, etc.)
- ✅ Headers y bodies ya configurados

### 2. Importar el Entorno

1. Click en el icono de **Environments** (⚙️)
2. Click en **Import**
3. Selecciona `Balconazo_Local.postman_environment.json`
4. Selecciona el entorno **Balconazo_Local** en el dropdown superior derecho

### 3. Variables de Entorno Incluidas

El entorno ya tiene configuradas:

| Variable | Initial Value | Descripción |
|----------|---------------|-------------|
| `baseUrl` | `http://localhost:8080` | URL base del API Gateway |
| `hostEmail` | `host1@balconazo.com` | Usuario host de prueba |
| `hostPassword` | `password123` | Contraseña host |
| `guestEmail` | `guest1@balconazo.com` | Usuario guest de prueba |
| `guestPassword` | `password123` | Contraseña guest |
| `token` | (vacío) | Se llena automáticamente tras login |
| `userId` | (vacío) | Se llena automáticamente tras login |
| `spaceId` | (vacío) | Se llena tras crear espacio |
| `bookingId` | (vacío) | Se llena tras crear reserva |

---

## 📋 FLUJO DE PRUEBAS RECOMENDADO

### Paso 1: Autenticación ✅

1. Abrir carpeta **Auth Service**
2. Ejecutar **Login**
   - ✅ Token JWT guardado automáticamente en `{{token}}`
   - ✅ UserId guardado en `{{userId}}`
3. Ejecutar **Get Me** para verificar token

### Paso 2: Catálogo de Espacios 🏠

1. Abrir carpeta **Catalog Service**
2. Secuencia:
   - **List All Spaces**: Ver espacios existentes
   - **Create Space**: Crear nuevo (guarda `{{spaceId}}`)
   - **Get Space by ID**: Ver detalles
   - **Update Space**: Editar (solo owner)
   - **Delete Space**: Eliminar (soft delete)

### Paso 3: Búsqueda Geoespacial 🗺️

1. Abrir carpeta **Search Service**
2. Ejecutar **Search Nearby Spaces** (público, no requiere token)
   - Busca espacios cerca de Madrid centro
3. Probar filtros avanzados (precio, capacidad, amenities)

### Paso 4: Reservas 📅

1. Abrir carpeta **Booking Service**
2. Secuencia:
   - **Create Booking**: Crear reserva (guarda `{{bookingId}}`)
   - **List Guest Bookings**: Ver reservas del usuario
   - **List Space Bookings**: Ver reservas de un espacio
   - **Confirm Booking**: Host acepta reserva
   - **Cancel Booking**: Cancelar

### Paso 5: Reviews ⭐

1. Tras completar una reserva:
   - **Create Review**: Guest deja reseña
   - **List Space Reviews**: Ver todas las reviews
   - **Respond to Review**: Host responde

---

## 📋 ALTERNATIVA: COPIAR ENDPOINTS MANUALMENTE

Si prefieres copiar los endpoints manualmente, aquí están con URLs completas:

---

## 🔐 AUTH SERVICE - Autenticación

### 1. Register (Registro de usuario)

**POST** `http://localhost:8080/api/auth/register`

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "email": "newuser@balconazo.com",
  "password": "password123",
  "role": "HOST"
}
```

**Response 201 Created:**
```json
{
  "id": "uuid",
  "email": "newuser@balconazo.com",
  "role": "HOST",
  "active": true,
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 2. Login

**POST** `http://localhost:8080/api/auth/login`

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "email": "host1@balconazo.com",
  "password": "password123"
}
```

**Response 200 OK:**
```json
{
  "accessToken": "eyJhbGci...",
  "refreshToken": "eyJhbGci...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "userId": "11111111-1111-1111-1111-111111111111",
  "email": "host1@balconazo.com",
  "role": "HOST"
}
```

---

### 3. Get Current User (Me)

**GET** `http://localhost:8080/api/auth/me`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Response 200 OK:**
```json
{
  "id": "11111111-1111-1111-1111-111111111111",
  "email": "host1@balconazo.com",
  "role": "HOST",
  "active": true,
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 4. Refresh Token

**POST** `http://localhost:8080/api/auth/refresh`

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "refreshToken": "eyJhbGci..."
}
```

**Response 200 OK:**
```json
{
  "accessToken": "eyJhbGci...",
  "refreshToken": "eyJhbGci...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "userId": "11111111-1111-1111-1111-111111111111",
  "email": "host1@balconazo.com",
  "role": "HOST"
}
```

---

### 5. Logout

**POST** `http://localhost:8080/api/auth/logout`

**Headers:**
```
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "userId": "11111111-1111-1111-1111-111111111111"
}
```

**Response 200 OK:**
```
(Empty response)
```

---

## 🏠 CATALOG SERVICE - Espacios

### 6. Get All Spaces (Listar espacios activos)

**GET** `/api/catalog/spaces/active`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "name": "Ático con terraza",
    "description": "Amplio ático con vistas",
    "ownerId": "uuid",
    "lat": 40.4168,
    "lon": -3.7038,
    "pricePerHour": 25.0,
    "capacity": 8,
    "active": true,
    "createdAt": "2025-10-29T10:00:00"
  }
]
```

---

### 7. Get Space by ID

**GET** `/api/catalog/spaces/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Response 200 OK:**
```json
{
  "id": "uuid",
  "name": "Ático con terraza",
  "description": "Amplio ático con vistas",
  "ownerId": "uuid",
  "lat": 40.4168,
  "lon": -3.7038,
  "pricePerHour": 25.0,
  "capacity": 8,
  "active": true,
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 8. Create Space

**POST** `/api/catalog/spaces`

**Headers:**
```
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "name": "Ático con terraza",
  "description": "Amplio ático con vistas panorámicas",
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "lat": 40.4168,
  "lon": -3.7038,
  "pricePerHour": 25.0,
  "capacity": 8
}
```

**Response 201 Created:**
```json
{
  "id": "uuid",
  "name": "Ático con terraza",
  "description": "Amplio ático con vistas panorámicas",
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "lat": 40.4168,
  "lon": -3.7038,
  "pricePerHour": 25.0,
  "capacity": 8,
  "active": true,
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 9. Update Space

**PUT** `/api/catalog/spaces/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Body (raw JSON):**
```json
{
  "name": "Ático Premium",
  "description": "Ático renovado con nuevas amenidades",
  "pricePerHour": 30.0,
  "capacity": 10
}
```

**Response 200 OK:**
```json
{
  "id": "uuid",
  "name": "Ático Premium",
  "description": "Ático renovado con nuevas amenidades",
  "ownerId": "uuid",
  "lat": 40.4168,
  "lon": -3.7038,
  "pricePerHour": 30.0,
  "capacity": 10,
  "active": true,
  "updatedAt": "2025-10-29T11:00:00"
}
```

---

### 10. Delete Space (Deactivate)

**DELETE** `/api/catalog/spaces/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Response 204 No Content**

---

### 11. Get Spaces by Owner

**GET** `/api/catalog/spaces/owner/{ownerId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `ownerId`: UUID del propietario

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "name": "Ático con terraza",
    "description": "Amplio ático con vistas",
    "ownerId": "uuid",
    "pricePerHour": 25.0,
    "capacity": 8,
    "active": true
  }
]
```

---

### 12. Check Space Availability

**GET** `/api/catalog/availability/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Query Parameters:**
- `startTime`: ISO 8601 datetime (ej: `2025-11-01T10:00:00Z`)
- `endTime`: ISO 8601 datetime (ej: `2025-11-01T12:00:00Z`)

**Example:**
```
GET /api/catalog/availability/uuid?startTime=2025-11-01T10:00:00Z&endTime=2025-11-01T12:00:00Z
```

**Response 200 OK:**
```json
{
  "spaceId": "uuid",
  "available": true,
  "startTime": "2025-11-01T10:00:00Z",
  "endTime": "2025-11-01T12:00:00Z"
}
```

---

## 🎫 BOOKING SERVICE - Reservas

### 13. Create Booking

**POST** `http://localhost:8080/api/booking/bookings`

**Headers:**
```
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTime": "2025-11-01T10:00:00Z",
  "endTime": "2025-11-01T12:00:00Z",
  "paymentMethod": "CREDIT_CARD"
}
```

**Response 201 Created:**
```json
{
  "id": "uuid",
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTime": "2025-11-01T10:00:00Z",
  "endTime": "2025-11-01T12:00:00Z",
  "status": "PENDING",
  "totalPrice": 50.0,
  "paymentMethod": "CREDIT_CARD",
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 14. Get Booking by ID

**GET** `http://localhost:8080/api/booking/bookings/{bookingId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `bookingId`: UUID de la reserva

**Response 200 OK:**
```json
{
  "id": "uuid",
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTime": "2025-11-01T10:00:00Z",
  "endTime": "2025-11-01T12:00:00Z",
  "status": "CONFIRMED",
  "totalPrice": 50.0,
  "paymentMethod": "CREDIT_CARD",
  "paymentIntentId": "pi_123456",
  "createdAt": "2025-10-29T10:00:00"
}
```

---

### 15. Get Bookings by Guest

**GET** `/api/booking/bookings/guest/{guestId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `guestId`: UUID del huésped

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "spaceId": "uuid",
    "guestId": "uuid",
    "startTime": "2025-11-01T10:00:00Z",
    "endTime": "2025-11-01T12:00:00Z",
    "status": "CONFIRMED",
    "totalPrice": 50.0
  }
]
```

---

### 16. Get Bookings by Space

**GET** `/api/booking/bookings/space/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "spaceId": "uuid",
    "guestId": "uuid",
    "startTime": "2025-11-01T10:00:00Z",
    "endTime": "2025-11-01T12:00:00Z",
    "status": "CONFIRMED",
    "totalPrice": 50.0
  }
]
```

---

### 17. Confirm Booking

**POST** `/api/booking/bookings/{bookingId}/confirm`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `bookingId`: UUID de la reserva

**Query Parameters:**
- `paymentIntentId`: ID de intención de pago de Stripe

**Example:**
```
POST /api/booking/bookings/uuid/confirm?paymentIntentId=pi_123456
```

**Response 200 OK:**
```json
{
  "id": "uuid",
  "status": "CONFIRMED",
  "paymentIntentId": "pi_123456",
  "confirmedAt": "2025-10-29T10:05:00"
}
```

---

### 18. Cancel Booking

**POST** `/api/booking/bookings/{bookingId}/cancel`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `bookingId`: UUID de la reserva

**Response 200 OK:**
```json
{
  "id": "uuid",
  "status": "CANCELLED",
  "cancelledAt": "2025-10-29T10:10:00"
}
```

---

### 19. Complete Booking

**POST** `/api/booking/bookings/{bookingId}/complete`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `bookingId`: UUID de la reserva

**Response 200 OK:**
```json
{
  "id": "uuid",
  "status": "COMPLETED",
  "completedAt": "2025-11-01T12:00:00"
}
```

---

## ⭐ BOOKING SERVICE - Reviews

### 20. Create Review

**POST** `/api/booking/reviews`

**Headers:**
```
Authorization: Bearer {{accessToken}}
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "bookingId": "uuid",
  "spaceId": "uuid",
  "reviewerId": "uuid",
  "rating": 5,
  "comment": "Excelente espacio, muy recomendable"
}
```

**Response 201 Created:**
```json
{
  "id": "uuid",
  "bookingId": "uuid",
  "spaceId": "uuid",
  "reviewerId": "uuid",
  "rating": 5,
  "comment": "Excelente espacio, muy recomendable",
  "createdAt": "2025-11-01T13:00:00"
}
```

---

### 21. Get Reviews by Space

**GET** `/api/booking/reviews/space/{spaceId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `spaceId`: UUID del espacio

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "bookingId": "uuid",
    "spaceId": "uuid",
    "reviewerId": "uuid",
    "reviewerName": "Juan Pérez",
    "rating": 5,
    "comment": "Excelente espacio",
    "createdAt": "2025-11-01T13:00:00"
  }
]
```

---

### 22. Get Reviews by Reviewer

**GET** `/api/booking/reviews/reviewer/{reviewerId}`

**Headers:**
```
Authorization: Bearer {{accessToken}}
```

**Path Variables:**
- `reviewerId`: UUID del revisor

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "bookingId": "uuid",
    "spaceId": "uuid",
    "spaceName": "Ático con terraza",
    "rating": 5,
    "comment": "Excelente espacio",
    "createdAt": "2025-11-01T13:00:00"
  }
]
```

---

## 🔍 SEARCH SERVICE - Búsqueda Geoespacial

### 23. Search Spaces by Location (Público)

**GET** `/api/search/spaces`

**Query Parameters:**
- `lat`: Latitud (ej: `40.4168`)
- `lon`: Longitud (ej: `-3.7038`)
- `radius`: Radio en kilómetros (ej: `5`)

**Example:**
```
GET /api/search/spaces?lat=40.4168&lon=-3.7038&radius=5
```

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "name": "Ático con terraza",
    "description": "Amplio ático con vistas",
    "lat": 40.4168,
    "lon": -3.7038,
    "pricePerHour": 25.0,
    "capacity": 8,
    "distance": 0.5,
    "averageRating": 4.8
  }
]
```

---

### 24. Search Spaces with Filters

**POST** `/api/search/spaces/filter`

**Headers:**
```
Content-Type: application/json
```

**Body (raw JSON):**
```json
{
  "lat": 40.4168,
  "lon": -3.7038,
  "radius": 10,
  "minPrice": 10.0,
  "maxPrice": 50.0,
  "minCapacity": 5,
  "startTime": "2025-11-01T10:00:00Z",
  "endTime": "2025-11-01T12:00:00Z"
}
```

**Response 200 OK:**
```json
[
  {
    "id": "uuid",
    "name": "Ático con terraza",
    "lat": 40.4168,
    "lon": -3.7038,
    "pricePerHour": 25.0,
    "capacity": 8,
    "distance": 0.5,
    "available": true
  }
]
```

---

### 25. Get Space Details from Search

**GET** `/api/search/spaces/{spaceId}`

**Path Variables:**
- `spaceId`: UUID del espacio

**Response 200 OK:**
```json
{
  "id": "uuid",
  "name": "Ático con terraza",
  "description": "Amplio ático con vistas",
  "ownerId": "uuid",
  "lat": 40.4168,
  "lon": -3.7038,
  "pricePerHour": 25.0,
  "capacity": 8,
  "active": true,
  "averageRating": 4.8,
  "totalReviews": 15
}
```

---

## 🏥 ACTUATOR - Monitoreo y Salud

### 26. Health Check (Gateway)

**GET** `http://localhost:8080/actuator/health`

**Response 200 OK:**
```json
{
  "status": "UP",
  "components": {
    "discoveryComposite": {
      "status": "UP"
    },
    "redis": {
      "status": "UP"
    }
  }
}
```

---

### 27. Gateway Routes

**GET** `http://localhost:8080/actuator/gateway/routes`

**Response 200 OK:**
```json
[
  {
    "route_id": "auth-service",
    "uri": "lb://auth-service",
    "order": 0,
    "predicates": [
      "Path: /api/auth/**"
    ],
    "filters": [
      "RequestRateLimiter",
      "CircuitBreaker"
    ]
  }
]
```

---

### 28. Metrics

**GET** `http://localhost:8080/actuator/metrics`

**Response 200 OK:**
```json
{
  "names": [
    "jvm.memory.used",
    "jvm.memory.max",
    "http.server.requests",
    "spring.cloud.gateway.requests"
  ]
}
```

---

### 29. Prometheus Metrics

**GET** `http://localhost:8080/actuator/prometheus`

**Response 200 OK:**
```
# HELP jvm_memory_used_bytes The amount of used memory
# TYPE jvm_memory_used_bytes gauge
jvm_memory_used_bytes{area="heap",id="PS Eden Space",} 1.234567E8
...
```

---

## 📝 VARIABLES DE ENTORNO POSTMAN

Para facilitar las pruebas, configura estas variables en Postman:

| Variable | Initial Value | Current Value |
|----------|---------------|---------------|
| `baseUrl` | `http://localhost:8080` | `http://localhost:8080` |
| `accessToken` | (vacío) | (se actualiza después del login) |
| `refreshToken` | (vacío) | (se actualiza después del login) |
| `userId` | (vacío) | (se actualiza después del login) |
| `spaceId` | (vacío) | (se actualiza después de crear espacio) |
| `bookingId` | (vacío) | (se actualiza después de crear reserva) |

---

## 🔄 SCRIPTS DE POSTMAN

### Script Post-Login (Tests tab):

```javascript
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("accessToken", jsonData.accessToken);
    pm.environment.set("refreshToken", jsonData.refreshToken);
    pm.environment.set("userId", jsonData.userId);
    console.log("Token guardado: " + jsonData.accessToken.substring(0, 20) + "...");
}
```

### Script Post-Create Space (Tests tab):

```javascript
if (pm.response.code === 201) {
    var jsonData = pm.response.json();
    pm.environment.set("spaceId", jsonData.id);
    console.log("Space ID guardado: " + jsonData.id);
}
```

### Script Post-Create Booking (Tests tab):

```javascript
if (pm.response.code === 201) {
    var jsonData = pm.response.json();
    pm.environment.set("bookingId", jsonData.id);
    console.log("Booking ID guardado: " + jsonData.id);
}
```

---

## 📊 ORDEN RECOMENDADO DE PRUEBAS

1. ✅ **Health Check** - Verificar que el sistema está UP
2. ✅ **Register** - Crear un usuario nuevo
3. ✅ **Login** - Obtener token JWT (guarda accessToken automáticamente)
4. ✅ **Get Me** - Verificar autenticación
5. ✅ **Create Space** - Crear un espacio (guarda spaceId)
6. ✅ **Get All Spaces** - Listar espacios
7. ✅ **Get Space by ID** - Ver detalle del espacio
8. ✅ **Search Spaces** - Búsqueda geoespacial
9. ✅ **Create Booking** - Crear reserva (guarda bookingId)
10. ✅ **Confirm Booking** - Confirmar reserva
11. ✅ **Create Review** - Dejar reseña
12. ✅ **Get Reviews** - Ver reseñas del espacio

---

## 🔐 USUARIOS DE PRUEBA

| Email | Password | Role | User ID |
|-------|----------|------|---------|
| `host1@balconazo.com` | `password123` | HOST | `11111111-1111-1111-1111-111111111111` |
| `host2@balconazo.com` | `password123` | HOST | `22222222-2222-2222-2222-222222222222` |
| `guest1@balconazo.com` | `password123` | GUEST | `33333333-3333-3333-3333-333333333333` |
| `guest2@balconazo.com` | `password123` | GUEST | `44444444-4444-4444-4444-444444444444` |
| `admin@balconazo.com` | `password123` | HOST | `55555555-5555-5555-5555-555555555555` |

---

## 🚀 IMPORTAR A POSTMAN

Puedes crear una colección en Postman e importar estos endpoints, o copiar manualmente cada uno siguiendo este formato.

**Última actualización:** 29 de Octubre de 2025

