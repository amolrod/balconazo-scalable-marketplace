# 📋 DATOS DE PRUEBA INSERTADOS - IDS PARA POSTMAN

**Fecha:** 29 de Octubre de 2025  
**Estado:** ✅ DATOS INSERTADOS CORRECTAMENTE

---

## 👥 USUARIOS

### Hosts:
```
host1@balconazo.com  → 11111111-1111-1111-1111-111111111111
host2@balconazo.com  → 22222222-2222-2222-2222-222222222222
admin@balconazo.com  → 55555555-5555-5555-5555-555555555555
```

### Guests:
```
guest1@balconazo.com → 33333333-3333-3333-3333-333333333333
guest2@balconazo.com → 44444444-4444-4444-4444-444444444444
```

**Password para todos:** `password123`

---

## 🏠 ESPACIOS (SPACES)

### Space 1: Ático con terraza en el centro
```
ID: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
Owner: 11111111-1111-1111-1111-111111111111 (host1)
Price: 35€/hora (3500 cents)
Capacity: 15
Status: active
```

### Space 2: Loft industrial en Malasaña
```
ID: bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
Owner: 11111111-1111-1111-1111-111111111111 (host1)
Price: 50€/hora (5000 cents)
Capacity: 20
Status: active
```

### Space 3: Azotea con vistas al Retiro
```
ID: cccccccc-cccc-cccc-cccc-cccccccccccc
Owner: 22222222-2222-2222-2222-222222222222 (host2)
Price: 75€/hora (7500 cents)
Capacity: 30
Status: active
```

### Space 4: Sala de reuniones ejecutiva
```
ID: dddddddd-dddd-dddd-dddd-dddddddddddd
Owner: 22222222-2222-2222-2222-222222222222 (host2)
Price: 25€/hora (2500 cents)
Capacity: 10
Status: active
```

### Space 5: Jardín privado en Chamberí
```
ID: eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
Owner: 55555555-5555-5555-5555-555555555555 (admin)
Price: 100€/hora (10000 cents)
Capacity: 50
Status: active
```

### Space 6: Estudio de fotografía profesional
```
ID: ffffffff-ffff-ffff-ffff-ffffffffffff
Owner: 11111111-1111-1111-1111-111111111111 (host1)
Price: 40€/hora (4000 cents)
Capacity: 8
Status: draft
```

---

## 🎫 RESERVAS (BOOKINGS)

### Booking 1: Confirmada
```
ID: 10000000-0000-0000-0000-000000000001
Space: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Ático)
Guest: 33333333-3333-3333-3333-333333333333 (guest1)
Fecha: 2025-11-05 10:00 - 14:00
Status: confirmed
Price: 140€ (14000 cents)
Guests: 5
```

### Booking 2: Confirmada
```
ID: 10000000-0000-0000-0000-000000000002
Space: bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb (Loft)
Guest: 33333333-3333-3333-3333-333333333333 (guest1)
Fecha: 2025-11-10 16:00 - 20:00
Status: confirmed
Price: 200€ (20000 cents)
Guests: 8
```

### Booking 3: Pendiente
```
ID: 10000000-0000-0000-0000-000000000003
Space: cccccccc-cccc-cccc-cccc-cccccccccccc (Azotea)
Guest: 44444444-4444-4444-4444-444444444444 (guest2)
Fecha: 2025-11-15 18:00 - 23:00
Status: pending
Price: 375€ (37500 cents)
Guests: 15
```

### Booking 4: Confirmada
```
ID: 10000000-0000-0000-0000-000000000004
Space: dddddddd-dddd-dddd-dddd-dddddddddddd (Sala reuniones)
Guest: 44444444-4444-4444-4444-444444444444 (guest2)
Fecha: 2025-11-20 09:00 - 13:00
Status: confirmed
Price: 100€ (10000 cents)
Guests: 6
```

### Booking 5: Completada
```
ID: 10000000-0000-0000-0000-000000000005
Space: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Ático)
Guest: 44444444-4444-4444-4444-444444444444 (guest2)
Fecha: 2025-10-25 15:00 - 19:00
Status: completed
Price: 140€ (14000 cents)
Guests: 4
```

---

## ⭐ RESEÑAS (REVIEWS)

### Review 1:
```
ID: 20000000-0000-0000-0000-000000000001
Booking: 10000000-0000-0000-0000-000000000005
Space: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Ático)
Guest: 44444444-4444-4444-4444-444444444444 (guest2)
Rating: 5 ⭐
Comment: "Espacio increíble! Perfecto para nuestro evento."
```

### Review 2:
```
ID: 20000000-0000-0000-0000-000000000002
Booking: 10000000-0000-0000-0000-000000000001
Space: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Ático)
Guest: 33333333-3333-3333-3333-333333333333 (guest1)
Rating: 4 ⭐
Comment: "Muy buen espacio, excelente ubicación."
```

---

## 📦 VARIABLES PARA POSTMAN ENVIRONMENT

Copiar estos valores en el environment de Postman:

```javascript
baseUrl = http://localhost:8080

// Users
userId = 11111111-1111-1111-1111-111111111111
host1Id = 11111111-1111-1111-1111-111111111111
host2Id = 22222222-2222-2222-2222-222222222222
adminId = 55555555-5555-5555-5555-555555555555
guest1Id = 33333333-3333-3333-3333-333333333333
guest2Id = 44444444-4444-4444-4444-444444444444

// Spaces
spaceId = aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
spaceId2 = bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
spaceId3 = cccccccc-cccc-cccc-cccc-cccccccccccc
spaceId4 = dddddddd-dddd-dddd-dddd-dddddddddddd
spaceId5 = eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee
spaceId6 = ffffffff-ffff-ffff-ffff-ffffffffffff

// Bookings
bookingId = 10000000-0000-0000-0000-000000000001
bookingId2 = 10000000-0000-0000-0000-000000000002
bookingId3 = 10000000-0000-0000-0000-000000000003
bookingId4 = 10000000-0000-0000-0000-000000000004
bookingId5 = 10000000-0000-0000-0000-000000000005

// Reviews
reviewId = 20000000-0000-0000-0000-000000000001
reviewId2 = 20000000-0000-0000-0000-000000000002
```

---

## 🧪 PRUEBAS RÁPIDAS EN POSTMAN

### 1. Login
```
POST http://localhost:8080/api/auth/login
{
  "email": "host1@balconazo.com",
  "password": "password123"
}
```
✅ Guarda automáticamente accessToken

### 2. Get All Spaces
```
GET http://localhost:8080/api/catalog/spaces
Authorization: Bearer {{accessToken}}
```
✅ Debe devolver 6 spaces

### 3. Get Space by ID
```
GET http://localhost:8080/api/catalog/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
Authorization: Bearer {{accessToken}}
```
✅ Debe devolver el Ático

### 4. Get Bookings by Guest
```
GET http://localhost:8080/api/booking/bookings/guest/33333333-3333-3333-3333-333333333333
Authorization: Bearer {{accessToken}}
```
✅ Debe devolver 2 bookings de guest1

### 5. Get Reviews by Space
```
GET http://localhost:8080/api/booking/reviews/space/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
Authorization: Bearer {{accessToken}}
```
✅ Debe devolver 2 reviews

### 6. Create Booking (nuevo)
```
POST http://localhost:8080/api/booking/bookings
Authorization: Bearer {{accessToken}}
{
  "spaceId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "guestId": "{{userId}}",
  "startTime": "2025-12-01T10:00:00",
  "endTime": "2025-12-01T14:00:00",
  "numGuests": 10,
  "paymentMethod": "CREDIT_CARD"
}
```
✅ Crea nueva reserva

---

## 📊 RESUMEN

- ✅ **5 usuarios** insertados (3 hosts, 2 guests)
- ✅ **6 espacios** insertados (5 active, 1 draft)
- ✅ **5 reservas** insertadas (3 confirmed, 1 pending, 1 completed)
- ✅ **2 reseñas** insertadas

**Todos los datos tienen IDs fijos y conocidos para facilitar las pruebas en Postman.**

---

## 🎯 SIGUIENTE PASO

1. Importar colección actualizada: `Balconazo_API.postman_collection.json`
2. Importar environment actualizado: `Balconazo_Local.postman_environment.json`
3. Hacer Login para obtener token
4. ¡Probar todos los endpoints con datos reales!

**Última actualización:** 29 de Octubre de 2025

