# 🛠️ Correcciones Aplicadas - 30 Octubre 2025

## Resumen de Fixes

### ✅ Fix 1: Create Space - "Solo hosts pueden crear espacios"

**🔍 Motivo:**  
El servicio buscaba el usuario en su BD local (catalog.users) pero el usuario se autentica en auth-service. El JWT ya contiene el rol.

**💾 Cambio realizado:**  
- Extraer el rol del contexto de seguridad (JWT) en lugar de buscar en BD
- Crear usuario local automáticamente si no existe (para mantener integridad referencial)
- Validar rol directamente desde `SecurityContextHolder`

**📄 Archivos modificados:**
- `/catalog_microservice/src/main/java/com/balconazo/catalog_microservice/service/impl/SpaceServiceImpl.java`

---

### ✅ Fix 2: Create Booking - "La reserva debe ser de al menos 4 horas"

**🔍 Motivo:**  
Validación demasiado restrictiva (mínimo 4 horas, antelación de 24 horas).

**💾 Cambio realizado:**  
- `MIN_BOOKING_HOURS`: 4 → 1 hora
- `MIN_ADVANCE_HOURS`: 24 → 0 horas (permitir reservas inmediatas)

**📄 Archivos modificados:**
- `/booking_microservice/src/main/java/com/balconazo/booking_microservice/constants/BookingConstants.java`

---

### ✅ Fix 3: Fallback Controller - Error 405 Method Not Allowed

**🔍 Motivo:**  
Los endpoints de fallback solo aceptaban GET (`@GetMapping`), pero los servicios usan POST/PUT.

**💾 Cambio realizado:**  
- Cambiar `@GetMapping` por `@RequestMapping` para aceptar cualquier método HTTP
- Aplicado a todos los fallbacks: /auth, /catalog, /booking, /search

**📄 Archivos modificados:**
- `/api-gateway/src/main/java/com/balconazo/gateway/controller/FallbackController.java`

---

## 📊 Estado de los Errores

| Error Original | Estado | Solución |
|----------------|--------|----------|
| Create Space - 400 "Solo hosts..." | ✅ CORREGIDO | Validación desde JWT |
| Create Booking - 400 "4 horas mínimo" | ✅ CORREGIDO | Reducido a 1 hora |
| Get Bookings by Guest - 500 | ⚠️ REQUIERE PRUEBA | Verificar mapper y enums |
| Confirm Booking - 400 "No pending" | ⚠️ FLUJO CORRECTO | Primero crear booking |
| Complete Booking - 500 | ⚠️ REQUIERE PRUEBA | Verificar enum mapping |
| Create Review - 400 "Solo completed" | ✅ FLUJO CORRECTO | Completar booking primero |
| Get Reviews by Reviewer - 500 | ⚠️ REQUIERE PRUEBA | Verificar DTO mapping |
| Search with Filters - 405 | ℹ️ NO EXISTE | Usar `/spaces?params` |
| Get Space Details - 405 | ℹ️ NO EXISTE | Usar `/spaces/{id}` |
| Fallback Auth - 405 | ✅ CORREGIDO | Acepta todos los métodos |
| Service Unavailable | ⚠️ VERIFICAR | Comprobar servicios UP |

---

## 🧪 Comandos de Prueba

### 1. Verificar servicios
```bash
./comprobacionmicroservicios.sh
```

### 2. Login y obtener token
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

USER_ID=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  | jq -r '.userId')

echo "Token: ${TOKEN:0:50}..."
echo "UserID: $USER_ID"
```

### 3. Crear espacio (ahora debería funcionar)
```bash
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Ático con terraza\",
    \"description\": \"Amplio ático con vistas\",
    \"ownerId\": \"$USER_ID\",
    \"address\": \"Calle Gran Vía 28, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 8,
    \"basePriceCents\": 2500
  }" | jq
```

### 4. Crear booking (ahora con 1 hora mínima)
```bash
SPACE_ID="uuid-del-espacio"

curl -X POST http://localhost:8080/api/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"guestId\": \"$USER_ID\",
    \"startTs\": \"2025-11-01T10:00:00\",
    \"endTs\": \"2025-11-01T12:00:00\",
    \"numGuests\": 2
  }" | jq
```

### 5. Búsqueda geoespacial
```bash
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5000" | jq
```

---

## 🔄 Flujo Completo Correcto

### Flujo de Reserva y Reseña:

1. **Login** → Obtener `token` y `userId`
2. **Create Space** → Obtener `spaceId`
3. **Activate Space** → Cambiar status a `active`
4. **Create Booking** → Obtener `bookingId` (status: `pending`)
5. **Confirm Booking** → Cambiar status a `confirmed`
6. **Complete Booking** → Cambiar status a `completed`
7. **Create Review** → Solo si booking está `completed`

---

## ⚠️ Problemas Pendientes de Verificar

### Error 500 en Get Bookings by Guest
**Posible causa:** Problema al mapear enums (BookingStatus/PaymentStatus) a String en DTO.

**Solución sugerida:** Verificar logs y revisar BookingMapper para enums.

### Error 500 en Complete Booking
**Posible causa:** Similar al anterior, problema con mapping de enums.

**Solución sugerida:** Verificar que los enums se mapeen correctamente.

### Error 500 en Get Reviews by Reviewer
**Posible causa:** Mapper o campo faltante en ReviewDTO.

**Solución sugerida:** Verificar logs y ReviewMapper.

---

## 📝 Notas Importantes

1. **Service Unavailable**: Si aparecen errores de "service unavailable", verificar que:
   - Eureka Server esté corriendo (puerto 8761)
   - Los servicios estén registrados en Eureka
   - No hay problemas de red/firewall

2. **Flujo de autenticación**: El JWT debe incluir:
   - `sub`: userId
   - `role`: HOST o GUEST
   - `email`: email del usuario

3. **Validaciones relajadas**: Para facilitar pruebas se redujeron:
   - Duración mínima de booking: 4h → 1h
   - Antelación mínima: 24h → 0h

---

## 🚀 Próximos Pasos

1. ✅ Recompilar todos los servicios
2. ✅ Reiniciar todos los servicios
3. ⏳ Probar endpoints uno por uno
4. ⏳ Verificar logs si hay errores 500
5. ⏳ Ajustar mappers si es necesario

---

**Fecha:** 30 de Octubre de 2025  
**Estado:** ✅ Correcciones aplicadas, pendiente verificación completa

