# 📬 Guía de Uso de Colecciones Postman - BalconazoApp
Esta guía te ayudará a probar todos los endpoints del sistema usando Postman.
## 📦 Archivos Necesarios
1. **Colección**: `BalconazoApp.postman_collection.json`
2. **Entorno**: `Balconazo_Local.postman_environment.json`
## 🚀 Configuración Inicial
### 1. Importar la Colección
1. Abre Postman
2. Click en **Import**
3. Selecciona `BalconazoApp.postman_collection.json`
4. La colección aparecerá en el panel izquierdo
### 2. Importar el Entorno
1. Click en el icono de **Environments** (⚙️)
2. Click en **Import**
3. Selecciona `Balconazo_Local.postman_environment.json`
4. Selecciona el entorno **Balconazo_Local** en el dropdown superior derecho
### 3. Variables de Entorno Configuradas
El entorno ya incluye:
```
baseUrl: http://localhost:8080
# Credenciales de prueba
hostEmail: host1@balconazo.com
hostPassword: password123
guestEmail: guest1@balconazo.com
guestPassword: password123
# Variables automáticas (se llenan tras login)
token: (JWT)
userId: (UUID)
spaceId: (UUID tras crear espacio)
bookingId: (UUID tras crear booking)
```
## 📋 Flujo de Pruebas Recomendado
### Paso 1: Autenticación ✅
1. Abrir carpeta **Auth Service**
2. Ejecutar **Login**
   - ✅ Token guardado automáticamente en {{token}}
   - ✅ UserId guardado en {{userId}}
3. Ejecutar **Get Me** para verificar
### Paso 2: Catálogo de Espacios 🏠
1. Abrir carpeta **Catalog Service**
2. Secuencia:
   - **List All Spaces**: Ver espacios existentes
   - **Create Space**: Crear nuevo (guarda {{spaceId}})
   - **Get Space by ID**: Ver detalles
   - **Activate Space**: Activar para reservas
### Paso 3: Búsqueda Geoespacial 🗺️
1. Abrir carpeta **Search Service**
2. Ejecutar **Search Nearby Spaces** (público, no requiere token)
   - Busca espacios cerca de Madrid centro
### Paso 4: Reservas 📅
1. Abrir carpeta **Booking Service**
2. Flujo:
   - **Create Booking**: Nueva reserva (guarda {{bookingId}})
   - **List Guest Bookings**: Ver reservas del usuario
   - **Confirm Booking**: Confirmar con paymentIntentId
   - **Complete Booking**: Marcar como completada
### Paso 5: Reseñas ⭐
1. Abrir carpeta **Reviews**
2. Después de completar booking:
   - **Create Review**: Dejar reseña (rating 1-5)
   - **Get Space Reviews**: Ver todas las reseñas
## 🔑 Autenticación Automática
Todas las requests protegidas incluyen:
```
Authorization: Bearer {{token}}
```
El token se obtiene al hacer login y se usa automáticamente.
## 🧪 Test Rápido Completo (5 minutos)
```
1. Login                → Obtener token ✅
2. Create Space         → spaceId guardado ✅
3. Search Nearby        → Verificar geoespacial ✅
4. Create Booking       → bookingId guardado ✅
5. Confirm Booking      → Estado CONFIRMED ✅
6. Complete Booking     → Estado COMPLETED ✅
7. Create Review        → Reseña creada ✅
8. Get Space Reviews    → Ver reseña ✅
```
## 📊 Endpoints Disponibles
### 🔐 Auth Service
- POST /api/auth/login - Login (obtiene JWT)
- GET /api/auth/me - Usuario actual
### 🏠 Catalog Service
- GET /api/catalog/spaces - Listar espacios
- POST /api/catalog/spaces - Crear espacio
- GET /api/catalog/spaces/{id} - Detalle
- PUT /api/catalog/spaces/{id} - Actualizar
- POST /api/catalog/spaces/{id}/activate - Activar
### 🗺️ Search Service (Público)
- GET /api/search/spaces?lat={lat}&lon={lon}&radius={km} - Búsqueda geoespacial
### 📅 Booking Service
- POST /api/booking/bookings - Crear reserva
- GET /api/booking/bookings/guest/{id} - Reservas del guest
- POST /api/booking/bookings/{id}/confirm - Confirmar
- POST /api/booking/bookings/{id}/complete - Completar
### ⭐ Reviews
- POST /api/booking/reviews - Crear reseña
- GET /api/booking/reviews/space/{id} - Reseñas del espacio
## 🐛 Troubleshooting
| Error | Solución |
|-------|----------|
| 401 Unauthorized | Haz login nuevamente, verifica {{token}} |
| 404 Not Found | Ejecuta ./comprobacionmicroservicios.sh |
| 500 Internal Server Error | Revisa logs del servicio específico |
| Token expirado | Login nuevamente (tokens expiran en 24h) |
## 📝 Notas Importantes
1. ✅ **Variables automáticas**: token, userId, spaceId, bookingId se guardan automáticamente
2. ✅ **Tests incluidos**: Cada request valida status code y estructura
3. ✅ **Gateway**: Todas las requests van a través del API Gateway (puerto 8080)
4. ⚠️ **Orden importa**: Sigue el flujo recomendado
## 🎯 Estado del Sistema
Verifica que todos los servicios estén UP:
```bash
./comprobacionmicroservicios.sh
```
Debe mostrar **200** en todos los servicios.
---
**Última actualización:** 30 de Octubre de 2025  
**Estado:** ✅ Sistema 100% Funcional
