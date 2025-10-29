# 📋 GUÍA COMPLETA DE ENDPOINTS - POSTMAN

## 🔑 CREDENCIALES DE PRUEBA

```
Email: host1@balconazo.com
Password: password123

IDs de Prueba:
- Host 1: 11111111-1111-1111-1111-111111111111
- Guest 1: 22222222-2222-2222-2222-222222222222
- Host 2: 33333333-3333-3333-3333-333333333333
- Espacio 1: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
- Espacio 2: bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
- Booking 1: 11111111-1111-1111-1111-111111111111
```

---

## 🔐 AUTH SERVICE (Puerto 8084)

### 1. Registro de Usuario
**POST** `http://localhost:8080/api/auth/register`

```json
{
  "email": "nuevo@test.com",
  "password": "password123",
  "role": "HOST"
}
```

**Respuesta esperada:** 201 Created
```json
{
  "id": "uuid-generado",
  "email": "nuevo@test.com",
  "role": "HOST",
  "active": true,
  "createdAt": "2025-10-29T..."
}
```

---

### 2. Login
**POST** `http://localhost:8080/api/auth/login`

```json
{
  "email": "host1@balconazo.com",
  "password": "password123"
}
```

**Respuesta esperada:** 200 OK
```json
{
  "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
  "tokenType": "Bearer",
  "userId": "11111111-1111-1111-1111-111111111111",
  "role": "HOST",
  "expiresIn": 86400
}
```

**⚠️ IMPORTANTE:** Guarda el `accessToken` para usar en los siguientes endpoints

---

### 3. Obtener Usuario Actual
**GET** `http://localhost:8080/api/auth/me`

**Headers:**
```
Authorization: Bearer {accessToken}
```

**Respuesta esperada:** 200 OK

---

### 4. Refresh Token
**POST** `http://localhost:8080/api/auth/refresh`

```json
{
  "refreshToken": "{tu-refresh-token}"
}
```

---

### 5. Logout
**POST** `http://localhost:8080/api/auth/logout`

**Headers:**
```
Authorization: Bearer {accessToken}
```

---

## 🏠 CATALOG SERVICE (Puerto 8085)

**⚠️ Todos los endpoints requieren JWT en header:**
```
Authorization: Bearer {accessToken}
```

### USUARIOS

#### 6. Crear Usuario en Catalog
**POST** `http://localhost:8080/api/catalog/users`

```json
{
  "email": "nuevo@test.com",
  "password": "password123",
  "role": "host"
}
```

---

#### 7. Obtener Usuario por ID
**GET** `http://localhost:8080/api/catalog/users/11111111-1111-1111-1111-111111111111`

---

#### 8. Obtener Usuario por Email
**GET** `http://localhost:8080/api/catalog/users/email/host1@balconazo.com`

---

#### 9. Listar Usuarios
**GET** `http://localhost:8080/api/catalog/users`

---

#### 10. Listar Usuarios por Rol
**GET** `http://localhost:8080/api/catalog/users?role=host`

---

#### 11. Actualizar Trust Score
**PATCH** `http://localhost:8080/api/catalog/users/11111111-1111-1111-1111-111111111111/trust-score?score=95`

---

#### 12. Suspender Usuario
**POST** `http://localhost:8080/api/catalog/users/22222222-2222-2222-2222-222222222222/suspend`

---

#### 13. Activar Usuario
**POST** `http://localhost:8080/api/catalog/users/22222222-2222-2222-2222-222222222222/activate`

---

### ESPACIOS

#### 14. Crear Espacio
**POST** `http://localhost:8080/api/catalog/spaces`

```json
{
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "title": "Mi Balcón de Prueba",
  "description": "Balcón acogedor para eventos",
  "address": "Calle Test 123, Madrid",
  "lat": 40.4168,
  "lon": -3.7038,
  "capacity": 8,
  "areaSqm": 20.5,
  "basePriceCents": 2500,
  "amenities": ["wifi", "mesa", "sillas"],
  "rules": {
    "no_fumar": true,
    "mascotas": false
  }
}
```

---

#### 15. Obtener Espacio por ID
**GET** `http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`

---

#### 16. Listar Espacios Activos
**GET** `http://localhost:8080/api/catalog/spaces/active`

---

#### 17. Listar Espacios por Owner
**GET** `http://localhost:8080/api/catalog/spaces/owner/11111111-1111-1111-1111-111111111111`

---

#### 18. Actualizar Espacio
**PUT** `http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`

```json
{
  "ownerId": "11111111-1111-1111-1111-111111111111",
  "title": "Balcón Céntrico Madrid ACTUALIZADO",
  "description": "Descripción actualizada",
  "address": "Calle Gran Vía 28, Madrid",
  "lat": 40.4200,
  "lon": -3.7050,
  "capacity": 12,
  "areaSqm": 28.0,
  "basePriceCents": 3500,
  "amenities": ["wifi", "mesa", "sillas", "calefaccion"],
  "rules": {
    "no_fumar": true,
    "mascotas": true
  }
}
```

---

#### 19. Activar Espacio
**POST** `http://localhost:8080/api/catalog/spaces/dddddddd-dddd-dddd-dddd-dddddddddddd/activate`

---

#### 20. Desactivar Espacio
**POST** `http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/deactivate`

---

#### 21. Eliminar Espacio
**DELETE** `http://localhost:8080/api/catalog/spaces/dddddddd-dddd-dddd-dddd-dddddddddddd`

---

### DISPONIBILIDAD

#### 22. Crear Slot de Disponibilidad
**POST** `http://localhost:8080/api/catalog/availability`

```json
{
  "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "startTime": "2025-11-15T10:00:00",
  "endTime": "2025-11-15T18:00:00",
  "isAvailable": true
}
```

---

#### 23. Obtener Disponibilidad por Espacio
**GET** `http://localhost:8080/api/catalog/availability/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`

---

#### 24. Obtener Disponibilidad Futura
**GET** `http://localhost:8080/api/catalog/availability/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/future`

---

#### 25. Obtener Disponibilidad por Rango
**GET** `http://localhost:8080/api/catalog/availability/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/range?start=2025-11-01T00:00:00&end=2025-11-30T23:59:59`

---

#### 26. Eliminar Slot de Disponibilidad
**DELETE** `http://localhost:8080/api/catalog/availability/{slotId}`

*(Usa un ID de los que obtengas en GET)*

---

## 🎫 BOOKING SERVICE (Puerto 8082)

**⚠️ Todos los endpoints requieren JWT**

### 27. Crear Reserva
**POST** `http://localhost:8080/api/booking/bookings`

```json
{
  "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "guestId": "22222222-2222-2222-2222-222222222222",
  "startTs": "2025-11-20T14:00:00",
  "endTs": "2025-11-20T18:00:00",
  "numGuests": 6,
  "priceCents": 3000
}
```

---

### 28. Obtener Reserva por ID
**GET** `http://localhost:8080/api/booking/bookings/11111111-1111-1111-1111-111111111111`

---

### 29. Listar Reservas por Guest
**GET** `http://localhost:8080/api/booking/bookings/guest/22222222-2222-2222-2222-222222222222`

---

### 30. Listar Reservas por Space
**GET** `http://localhost:8080/api/booking/bookings/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`

---

### 31. Confirmar Reserva
**POST** `http://localhost:8080/api/booking/bookings/33333333-3333-3333-3333-333333333333/confirm?paymentIntentId=pi_test_333`

---

### 32. Cancelar Reserva
**POST** `http://localhost:8080/api/booking/bookings/11111111-1111-1111-1111-111111111111/cancel`

---

### 33. Obtener Eventos de Reserva
**GET** `http://localhost:8080/api/booking/bookings/11111111-1111-1111-1111-111111111111/events`

---

### 34. Verificar Disponibilidad
**GET** `http://localhost:8080/api/booking/bookings/check-availability?spaceId=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa&start=2025-11-25T10:00:00&end=2025-11-25T14:00:00`

---

## 🔍 SEARCH SERVICE (Puerto 8083)

**✅ Los endpoints de búsqueda NO requieren autenticación**

### 35. Búsqueda Geoespacial (Cercanos)
**GET** `http://localhost:8080/api/search/spaces?lat=40.4200&lon=-3.7050&radius=5000`

**Parámetros:**
- `lat`: Latitud (Madrid centro: 40.4200)
- `lon`: Longitud (Madrid centro: -3.7050)
- `radius`: Radio en metros (5000 = 5km)

---

### 36. Búsqueda por Ciudad
**GET** `http://localhost:8080/api/search/spaces/city?city=Madrid`

---

### 37. Obtener Espacio por ID (Search)
**GET** `http://localhost:8080/api/search/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`

---

### 38. Búsqueda Avanzada con Filtros
**POST** `http://localhost:8080/api/search/spaces/search`

```json
{
  "lat": 40.4200,
  "lon": -3.7050,
  "radius": 10000,
  "minCapacity": 8,
  "maxPriceCents": 5000,
  "amenities": ["wifi", "piscina"]
}
```

---

## 🎯 EUREKA SERVER (Puerto 8761)

### 39. Dashboard Eureka
**GET** `http://localhost:8761`

*(Abre en navegador para ver interfaz gráfica)*

---

### 40. Listar Servicios Registrados
**GET** `http://localhost:8761/eureka/apps`

**Headers:**
```
Accept: application/json
```

---

## 🏥 HEALTH CHECKS

### 41. API Gateway Health
**GET** `http://localhost:8080/actuator/health`

---

### 42. Eureka Health
**GET** `http://localhost:8761/actuator/health`

---

### 43. Auth Service Health
**GET** `http://localhost:8084/actuator/health`

---

### 44. Catalog Service Health
**GET** `http://localhost:8085/actuator/health`

---

### 45. Booking Service Health
**GET** `http://localhost:8082/actuator/health`

---

### 46. Search Service Health
**GET** `http://localhost:8083/actuator/health`

---

## 📊 MÉTRICAS Y ACTUATOR

### 47. Gateway Routes
**GET** `http://localhost:8080/actuator/gateway/routes`

---

### 48. Métricas Prometheus (Gateway)
**GET** `http://localhost:8080/actuator/prometheus`

---

### 49. Métricas (Catalog)
**GET** `http://localhost:8085/actuator/metrics`

---

## 🧪 ORDEN RECOMENDADO DE PRUEBAS

1. **Health Checks** (41-46) - Verificar que todo está UP
2. **Login** (2) - Obtener JWT
3. **Crear Usuario en Catalog** (6) - Sincronizar con Catalog
4. **Crear Espacio** (14) - Crear tu propio espacio
5. **Listar Espacios** (16) - Ver espacios activos
6. **Búsqueda Geoespacial** (35) - Buscar espacios cercanos
7. **Crear Reserva** (27) - Reservar un espacio
8. **Confirmar Reserva** (31) - Confirmar con payment intent
9. **Listar Reservas** (29) - Ver tus reservas

---

## 💡 TIPS PARA POSTMAN

### Configurar Variable de Entorno

1. Crea un Environment en Postman llamado "BalconazoApp"
2. Agrega estas variables:
   - `baseUrl`: `http://localhost:8080`
   - `token`: (vacío, se llenará después del login)
   - `userId`: (vacío, se llenará después del login)

3. Después del login, en la pestaña "Tests" del request, agrega:

```javascript
var jsonData = pm.response.json();
pm.environment.set("token", jsonData.accessToken);
pm.environment.set("userId", jsonData.userId);
```

4. En los headers de los requests protegidos, usa:
```
Authorization: Bearer {{token}}
```

---

## 🐛 CÓDIGOS DE RESPUESTA ESPERADOS

- `200 OK` - Petición exitosa
- `201 Created` - Recurso creado
- `204 No Content` - Eliminado exitosamente
- `400 Bad Request` - Error en los datos enviados
- `401 Unauthorized` - Sin JWT o JWT inválido
- `403 Forbidden` - Sin permisos
- `404 Not Found` - Recurso no encontrado
- `500 Internal Server Error` - Error del servidor

---

## 📝 NOTAS IMPORTANTES

1. **JWT Expira en 24 horas** - Usa refresh token si caduca
2. **IDs deben ser UUID válidos** - Usa los de prueba proporcionados
3. **Fechas en formato ISO-8601** - `2025-11-20T14:00:00`
4. **Coordenadas:** Madrid centro (40.4200, -3.7050)
5. **Precios en centavos:** 3000 = 30.00€
6. **Rol en minúsculas en Catalog:** "host", "guest", "admin"
7. **Rol en mayúsculas en Auth:** "HOST", "GUEST", "ADMIN"

---

**Total de Endpoints Documentados:** 49  
**Fecha:** 29 de Octubre de 2025  
**Versión API:** 1.0.0

