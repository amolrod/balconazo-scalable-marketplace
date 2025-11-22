# Guía de Prueba - Sistema de Reviews con Verificación de Elegibilidad

## 🎯 Objetivo
Probar que solo los usuarios con reservas completadas pueden escribir reseñas.

---

## 📋 Prerrequisitos

### Servicios Activos
✅ Todos los microservicios UP:
- Eureka: http://localhost:8761
- Gateway: http://localhost:8080
- Auth: http://localhost:8084
- Catalog: http://localhost:8085
- Booking: http://localhost:8082
- Search: http://localhost:8083

✅ Frontend Angular: http://localhost:4200

✅ Bases de datos:
- MySQL (Auth): localhost:3307
- PostgreSQL (Booking): localhost:5434

---

## 🧪 Escenario de Prueba

### Usuario de Prueba
- **Email**: guest1@balconazo.com
- **Password**: password123
- **ID**: 33333333-3333-3333-3333-333333333333

### Espacio de Prueba
- **Nombre**: Terraza con Vista
- **ID**: e3ab2d08-db34-48d7-bdeb-bf37bb4d3458
- **URL**: http://localhost:4200/explore/e3ab2d08-db34-48d7-bdeb-bf37bb4d3458

### Reserva Completada (Datos de Prueba Insertados)
- **Booking ID**: 99999999-aaaa-bbbb-cccc-111111111111
- **Estado**: COMPLETED
- **Fecha**: 15 Nov 2025, 10:00 - 18:00
- **Precio**: 150.00 EUR

---

## 🚀 Pasos de Prueba

### 1. Verificar Sin Login (Usuario Anónimo)

1. Abre el navegador en **modo incógnito**
2. Ve a: http://localhost:4200/explore/e3ab2d08-db34-48d7-bdeb-bf37bb4d3458
3. Scroll hasta la sección "Reseñas"

**✅ Resultado Esperado**:
- ❌ NO debe aparecer el botón "✍️ Escribir una reseña"
- ✅ Debe mostrar: "Este espacio aún no tiene reseñas"
- ✅ Las reseñas existentes (si hay) deben ser visibles

---

### 2. Login con Usuario SIN Reservas

1. Login con un usuario diferente (ejemplo: guest2@balconazo.com / password123)
2. Ve al mismo espacio: http://localhost:4200/explore/e3ab2d08-db34-48d7-bdeb-bf37bb4d3458
3. Scroll hasta "Reseñas"

**✅ Resultado Esperado**:
- ❌ NO debe aparecer el botón "✍️ Escribir una reseña"
- ✅ Mensaje: "Este espacio aún no tiene reseñas"

---

### 3. Login con Usuario CON Reserva Completada ⭐

1. **Logout** si estás logueado
2. Login con:
   - Email: **guest1@balconazo.com**
   - Password: **password123**
3. Ve al espacio: http://localhost:4200/explore/e3ab2d08-db34-48d7-bdeb-bf37bb4d3458
4. Scroll hasta "Reseñas"

**✅ Resultado Esperado**:
- ✅ DEBE aparecer el botón **"✍️ Escribir una reseña"**
- ✅ Mensaje: "Este espacio aún no tiene reseñas"

---

### 4. Crear una Reseña

1. Haz clic en **"✍️ Escribir una reseña"**
2. Se despliega el formulario:
   - Selecciona **5 estrellas** (haciendo clic en la 5ª estrella)
   - Escribe un comentario: _"Excelente espacio, muy recomendado. La terraza tiene una vista increíble y el anfitrión fue muy atento."_
3. Haz clic en **"Publicar reseña"**

**✅ Resultado Esperado**:
- ✅ Mensaje de éxito (console.log)
- ✅ El formulario se cierra automáticamente
- ✅ La nueva reseña aparece en la lista
- ✅ El promedio de rating se actualiza a 5.0
- ✅ "1 reseñas" aparece en el contador

---

### 5. Intentar Crear Segunda Reseña (Duplicado)

1. Haz scroll hasta "Reseñas"
2. Intenta hacer clic en **"✍️ Escribir una reseña"** de nuevo

**✅ Resultado Esperado**:
- ❌ El botón **NO debe aparecer** (porque ya creaste una reseña)
- ✅ Tu reseña debe estar visible en la lista

---

### 6. Verificar Visibilidad Pública de la Reseña

1. **Logout** de guest1@balconazo.com
2. Ve al mismo espacio **sin login** (modo incógnito)
3. Scroll hasta "Reseñas"

**✅ Resultado Esperado**:
- ✅ La reseña de guest1 debe ser **visible públicamente**
- ✅ Rating: 5 estrellas
- ✅ Comentario completo visible
- ❌ Botón "Escribir reseña" NO visible (no estás logueado)

---

## 🔍 Verificaciones Técnicas

### Backend - Endpoint Público
```bash
# Ver reseñas del espacio (sin auth)
curl http://localhost:8080/api/bookings/reviews/space/e3ab2d08-db34-48d7-bdeb-bf37bb4d3458

# Resultado esperado: Array con la reseña creada
```

### Backend - Verificar Reserva Completada
```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

# Ver mis reservas
curl -s http://localhost:8080/api/bookings/my \
  -H "Authorization: Bearer $TOKEN" | jq .

# Debe mostrar la reserva 99999999-aaaa-bbbb-cccc-111111111111 con status: "COMPLETED"
```

### Base de Datos - PostgreSQL
```bash
docker exec -i balconazo-pg-booking psql -U postgres -d booking_db << 'EOF'
-- Ver reserva completada
SELECT id, space_id, guest_id, status, start_ts, end_ts 
FROM booking.bookings 
WHERE id = '99999999-aaaa-bbbb-cccc-111111111111';

-- Ver reviews creadas
SELECT id, booking_id, rating, comment, created_at 
FROM booking.reviews 
WHERE booking_id = '99999999-aaaa-bbbb-cccc-111111111111';
EOF
```

---

## 🐛 Troubleshooting

### Problema: "Botón no aparece aunque tengo reserva completada"

**Posibles causas**:
1. El token JWT no está en localStorage
2. La reserva no tiene status = 'COMPLETED'
3. Error en el servicio de backend

**Solución**:
```javascript
// En DevTools Console (F12)
console.log('Token:', localStorage.getItem('authToken'));
console.log('UserId:', localStorage.getItem('userId'));

// Verificar manualmente la elegibilidad
fetch('http://localhost:8080/api/bookings/my', {
  headers: { 'Authorization': 'Bearer ' + localStorage.getItem('authToken') }
})
.then(r => r.json())
.then(bookings => {
  console.log('Reservas:', bookings);
  const completed = bookings.filter(b => 
    b.spaceId === 'e3ab2d08-db34-48d7-bdeb-bf37bb4d3458' && 
    b.status === 'COMPLETED'
  );
  console.log('Reservas completadas para este espacio:', completed);
});
```

### Problema: "Error 403 al crear reseña"

**Causa**: El usuario no es el dueño de la reserva (validación de backend)

**Verificar**:
```bash
# Decodificar JWT
echo $TOKEN | cut -d. -f2 | base64 -d | jq .

# Debe coincidir con guest_id en la reserva
```

### Problema: "Error 409 al crear reseña"

**Causa**: Ya existe una reseña para esa reserva

**Solución**: Borrar la reseña existente o usar otra reserva

---

## ✅ Checklist de Validación

- [ ] Usuario anónimo NO ve botón de escribir reseña
- [ ] Usuario sin reserva NO ve botón de escribir reseña
- [ ] Usuario CON reserva completada SÍ ve botón
- [ ] Formulario se despliega al hacer clic en el botón
- [ ] Rating es obligatorio (1-5 estrellas)
- [ ] Comentario es obligatorio (min 10 caracteres)
- [ ] Reseña se crea exitosamente
- [ ] Reseña aparece en la lista inmediatamente
- [ ] Botón desaparece después de crear reseña
- [ ] Reseñas son visibles públicamente (sin login)
- [ ] Promedio de rating se calcula correctamente
- [ ] Contador de reseñas se actualiza

---

## 🎉 Resultado Final

Si todos los pasos se completan exitosamente:

✅ **Sistema de Reviews 100% Funcional**
- Seguridad: Solo usuarios con reservas completadas
- Validación: Backend verifica ownership
- UX: Botón solo visible cuando corresponde
- Transparencia: Mensaje claro cuando no hay reseñas

---

**Fecha**: 21 de noviembre de 2025  
**Branch**: feature/reviews-security-system  
**Commits**: 4 (seguridad backend + UI frontend + fix DTO + verificación elegibilidad)
