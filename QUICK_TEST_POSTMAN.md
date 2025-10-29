# 🚀 QUICK TEST - Postman

## ✅ DATOS INSERTADOS

Los datos de prueba ya están en las bases de datos:

- **5 usuarios** (Auth + Catalog)
- **4 espacios** (Catalog + Search)
- **3 reservas** (Booking)
- **5 slots disponibilidad** (Catalog)

## 🔑 CREDENCIALES

```
Email: host1@balconazo.com
Password: password123
```

## 📥 IMPORTAR EN POSTMAN

1. Abre Postman
2. Click en "Import"
3. Arrastra el archivo: `BalconazoApp.postman_collection.json`
4. ¡Listo! Colección con 20+ endpoints preconfigurados

## 🧪 TEST RÁPIDO (5 pasos)

### 1. Health Check
```
GET http://localhost:8080/actuator/health
```
**Esperado:** `{"status":"UP"}`

---

### 2. Login
```
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "host1@balconazo.com",
  "password": "password123"
}
```
**Esperado:** Recibirás un `accessToken`

**⚠️ GUARDA EL TOKEN** para los siguientes pasos

---

### 3. Listar Espacios
```
GET http://localhost:8080/api/catalog/spaces/active
Authorization: Bearer {TU_TOKEN_AQUI}
```
**Esperado:** Array con 3 espacios

---

### 4. Búsqueda Geoespacial (SIN TOKEN)
```
GET http://localhost:8080/api/search/spaces?lat=40.4200&lon=-3.7050&radius=5000
```
**Esperado:** Array con espacios cercanos a Madrid

---

### 5. Listar Reservas
```
GET http://localhost:8080/api/booking/bookings/guest/22222222-2222-2222-2222-222222222222
Authorization: Bearer {TU_TOKEN_AQUI}
```
**Esperado:** Array con 2 reservas

---

## 📚 DOCUMENTACIÓN COMPLETA

Ver archivo completo con los 49 endpoints:
**`docs/POSTMAN_ENDPOINTS.md`**

---

## 🆔 IDs DE PRUEBA

```javascript
// Usuarios
host1_id:  "11111111-1111-1111-1111-111111111111"
guest1_id: "22222222-2222-2222-2222-222222222222"
host2_id:  "33333333-3333-3333-3333-333333333333"

// Espacios
espacio1_id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"  // Balcón Céntrico Madrid
espacio2_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"  // Terraza con Piscina
espacio3_id: "cccccccc-cccc-cccc-cccc-cccccccccccc"  // Patio Andaluz

// Reservas
booking1_id: "11111111-1111-1111-1111-111111111111"
booking2_id: "22222222-2222-2222-2222-222222222222"
booking3_id: "33333333-3333-3333-3333-333333333333"
```

---

## 🔧 CONFIGURAR VARIABLES EN POSTMAN

1. Crea un Environment "BalconazoApp"
2. Variables:
   - `baseUrl`: `http://localhost:8080`
   - `token`: (se llenará automáticamente después del login)

3. En el request de Login, pestaña "Tests":
```javascript
var jsonData = pm.response.json();
pm.environment.set("token", jsonData.accessToken);
pm.environment.set("userId", jsonData.userId);
```

4. En los requests protegidos, usa:
```
Authorization: Bearer {{token}}
```

---

## 📊 ENDPOINTS POR SERVICIO

- **Auth:** 5 endpoints
- **Catalog Usuarios:** 8 endpoints
- **Catalog Espacios:** 8 endpoints
- **Catalog Disponibilidad:** 5 endpoints
- **Booking:** 8 endpoints
- **Search:** 4 endpoints
- **Health Checks:** 6 endpoints
- **Actuator/Métricas:** 5 endpoints

**Total:** 49 endpoints documentados

---

## ❓ TROUBLESHOOTING

**Error 401 Unauthorized:**
- Verifica que el token no haya expirado (24h)
- Haz login nuevamente

**Error 404 Not Found:**
- Verifica que el ID sea correcto (UUID)
- Usa los IDs de prueba de arriba

**Error 500:**
- Verifica que todos los servicios estén UP
- Ejecuta: `./verify-system.sh`

---

**¡Todo listo para testear!** 🎉

