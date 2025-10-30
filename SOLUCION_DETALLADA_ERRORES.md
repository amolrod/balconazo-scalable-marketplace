# 🎯 SOLUCIONES APLICADAS - ANÁLISIS TÉCNICO DETALLADO

**Fecha:** 30 de Octubre de 2025  
**Análisis:** Arquitectura Limpia y Buenas Prácticas Java/JPA

---

## 📋 RESUMEN EJECUTIVO

Se identificaron y corrigieron **3 errores críticos** en la API:
1. ✅ ERROR 400 - Confirm Booking (problema de mapeo de enums)
2. ✅ ERROR 400 - Complete Booking (mismo problema de mapeo)
3. ✅ ERROR 404 - Space not found (falta de datos de prueba)

---

## 🔍 ERROR 1 y 2: Estados de Booking (400 Bad Request)

### **DIAGNÓSTICO TÉCNICO**

#### Causa Raíz
El problema estaba en `BookingMapper.java` (líneas 13-14):

```java
@Mapping(target = "status", constant = "pending")
@Mapping(target = "paymentStatus", constant = "pending")
```

**¿Qué estaba pasando?**

MapStruct mapeaba los enums con **valores constantes fijos** en lugar de usar el valor real del enum al convertir de Entity a DTO.

**Flujo del Error:**
```
1. createBooking() → status = BookingStatus.pending ✅
2. guardas en BD → status = "pending" ✅
3. confirmBooking() → status cambia a BookingStatus.confirmed ✅
4. guardas en BD → status = "confirmed" ✅
5. bookingMapper.toDTO() → devuelve status = "pending" ❌ (constante fija)
6. Cliente recibe status = "pending" aunque en BD está "confirmed" ❌
7. Cliente intenta confirmar de nuevo → validación falla porque ya está "confirmed" ❌
```

#### Archivos Afectados
```
booking_microservice/
├── mapper/BookingMapper.java
├── service/impl/BookingServiceImpl.java
├── exception/BookingStateException.java (NUEVO)
├── exception/BookingNotFoundException.java (NUEVO)
└── config/GlobalExceptionHandler.java
```

### **SOLUCIÓN IMPLEMENTADA**

#### 1. Corrección del Mapper (BookingMapper.java)

**Antes (INCORRECTO):**
```java
@Mapping(target = "status", constant = "pending")
@Mapping(target = "paymentStatus", constant = "pending")
BookingDTO toDTO(BookingEntity entity);
```

**Después (CORRECTO):**
```java
@Mapping(target = "status", expression = "java(entity.getStatus() != null ? entity.getStatus().name() : null)")
@Mapping(target = "paymentStatus", expression = "java(entity.getPaymentStatus() != null ? entity.getPaymentStatus().name() : null)")
BookingDTO toDTO(BookingEntity entity);
```

**¿Por qué funciona?**
- Usa `expression` de MapStruct para ejecutar código Java
- Llama a `entity.getStatus().name()` que convierte el enum a String
- Maneja null safety con operador ternario

#### 2. Excepciones Personalizadas (Arquitectura Limpia)

**BookingStateException.java:**
```java
public class BookingStateException extends RuntimeException {
    private final String currentState;
    private final String requiredState;

    public BookingStateException(String currentState, String requiredState) {
        super(String.format("Estado inválido: la reserva está en estado '%s', se requiere '%s'", 
            currentState, requiredState));
        this.currentState = currentState;
        this.requiredState = requiredState;
    }
}
```

**Ventajas:**
- ✅ Mensaje de error descriptivo
- ✅ Información semántica (currentState vs requiredState)
- ✅ Facilita debugging
- ✅ Permite tratamiento específico en handlers

**BookingNotFoundException.java:**
```java
public class BookingNotFoundException extends RuntimeException {
    private final UUID bookingId;

    public BookingNotFoundException(UUID bookingId) {
        super("Reserva no encontrada con ID: " + bookingId);
        this.bookingId = bookingId;
    }
}
```

#### 3. Refactorización del Servicio (Buenas Prácticas)

**Antes (confirmBooking):**
```java
if (booking.getStatus() != BookingStatus.pending) {
    throw new RuntimeException("La reserva no está en estado pendiente");
}
```

**Después:**
```java
if (booking.getStatus() != BookingEntity.BookingStatus.pending) {
    throw new BookingStateException(
        booking.getStatus().name(), 
        BookingEntity.BookingStatus.pending.name()
    );
}
```

**Mejoras aplicadas:**
- ✅ Excepción específica en lugar de genérica
- ✅ Log mejorado con información de transición de estados
- ✅ Separación de responsabilidades
- ✅ Código autodocumentado

#### 4. Exception Handler (GlobalExceptionHandler.java)

```java
@ExceptionHandler(BookingStateException.class)
public ResponseEntity<ErrorResponse> handleBookingStateException(BookingStateException ex) {
    log.warn("⚠️ Invalid booking state: {}", ex.getMessage());

    ErrorResponse error = ErrorResponse.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.BAD_REQUEST.value())
            .error("Invalid State")
            .message(ex.getMessage())
            .build();

    return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
}

@ExceptionHandler(BookingNotFoundException.class)
public ResponseEntity<ErrorResponse> handleBookingNotFoundException(BookingNotFoundException ex) {
    log.warn("⚠️ Booking not found: {}", ex.getMessage());

    ErrorResponse error = ErrorResponse.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.NOT_FOUND.value())
            .error("Not Found")
            .message(ex.getMessage())
            .build();

    return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
}
```

### **VALIDACIÓN DE LA SOLUCIÓN**

#### Test Manual (Postman/curl)

**1. Crear booking:**
```bash
TOKEN="tu_jwt_token"
BOOKING_RESPONSE=$(curl -s -X POST http://localhost:8080/api/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "guestId": "11111111-1111-1111-1111-111111111111",
    "startTs": "2025-11-01T10:00:00",
    "endTs": "2025-11-01T12:00:00",
    "numGuests": 2
  }')

BOOKING_ID=$(echo $BOOKING_RESPONSE | jq -r '.id')
STATUS=$(echo $BOOKING_RESPONSE | jq -r '.status')

echo "Booking ID: $BOOKING_ID"
echo "Status: $STATUS"  # Debe ser "pending"
```

**2. Confirmar booking:**
```bash
CONFIRM_RESPONSE=$(curl -s -X POST \
  "http://localhost:8080/api/booking/bookings/$BOOKING_ID/confirm?paymentIntentId=pi_test_123" \
  -H "Authorization: Bearer $TOKEN")

STATUS=$(echo $CONFIRM_RESPONSE | jq -r '.status')
echo "Status después de confirmar: $STATUS"  # Debe ser "confirmed"
```

**3. Completar booking:**
```bash
COMPLETE_RESPONSE=$(curl -s -X POST \
  "http://localhost:8080/api/booking/bookings/$BOOKING_ID/complete" \
  -H "Authorization: Bearer $TOKEN")

STATUS=$(echo $COMPLETE_RESPONSE | jq -r '.status')
echo "Status después de completar: $STATUS"  # Debe ser "completed"
```

**4. Intentar confirmar de nuevo (debe fallar con mensaje claro):**
```bash
curl -s -X POST \
  "http://localhost:8080/api/booking/bookings/$BOOKING_ID/confirm?paymentIntentId=pi_test_456" \
  -H "Authorization: Bearer $TOKEN" | jq

# Respuesta esperada:
# {
#   "timestamp": "2025-10-30T...",
#   "status": 400,
#   "error": "Invalid State",
#   "message": "Estado inválido: la reserva está en estado 'completed', se requiere 'pending'"
# }
```

#### Test Unitario Recomendado

```java
@Test
void confirmBooking_whenStatusIsNotPending_shouldThrowBookingStateException() {
    // Given
    UUID bookingId = UUID.randomUUID();
    BookingEntity booking = BookingEntity.builder()
        .id(bookingId)
        .status(BookingEntity.BookingStatus.confirmed)
        .build();
    
    when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
    
    // When & Then
    BookingStateException exception = assertThrows(
        BookingStateException.class,
        () -> bookingService.confirmBooking(bookingId, "pi_test_123")
    );
    
    assertEquals("confirmed", exception.getCurrentState());
    assertEquals("pending", exception.getRequiredState());
    verify(bookingRepository, never()).save(any());
}

@Test
void toDTO_shouldMapEnumsCorrectly() {
    // Given
    BookingEntity entity = BookingEntity.builder()
        .status(BookingEntity.BookingStatus.confirmed)
        .paymentStatus(BookingEntity.PaymentStatus.succeeded)
        .build();
    
    // When
    BookingDTO dto = bookingMapper.toDTO(entity);
    
    // Then
    assertEquals("confirmed", dto.getStatus());
    assertEquals("succeeded", dto.getPaymentStatus());
}
```

---

## 🔍 ERROR 3: Space not found (404 Not Found)

### **DIAGNÓSTICO TÉCNICO**

#### Causa Raíz
El espacio con ID `2a91650c-759d-434d-9daa-1c99560a2ee8` **no existía** en la tabla `search.spaces_projection`.

**Posibles causas:**
1. Kafka no propagó el evento de creación desde Catalog a Search
2. El espacio fue creado pero no indexado
3. ID incorrecto en la petición
4. **BD vacía por falta de datos de prueba** ← Era este

#### Archivos Afectados
```
search_microservice/
├── exception/SpaceNotFoundException.java (ya existía)
├── config/GlobalExceptionHandler.java (handler agregado)
└── service/SearchService.java (uso de excepción específica)

Nuevo:
insert-search-test-data.sh (script de inserción)
```

### **SOLUCIÓN IMPLEMENTADA**

#### 1. Script de Inserción de Datos de Prueba

**Problema encontrado:** PostgreSQL en el contenedor usaba autenticación "peer" que solo funciona con socket Unix local, no con conexiones TCP.

**Solución:**
```bash
# Usar conexión TCP (-h 127.0.0.1) con password por variable de entorno
docker exec -i -e PGPASSWORD=postgres balconazo-pg-search \
  psql -h 127.0.0.1 -U postgres -d search_db << 'EOF'
  -- SQL aquí
EOF
```

#### 2. Datos de Prueba Insertados

```sql
INSERT INTO search.spaces_projection VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', ..., 'Ático con terraza en Madrid Centro', ...),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', ..., 'Loft moderno en Malasaña', ...),
('cccccccc-cccc-cccc-cccc-cccccccccccc', ..., 'Estudio en Chueca', ...);
```

#### 3. Excepción ya implementada (de correcciones anteriores)

El `SpaceNotFoundException` ya existía con status 404 correcto.

### **VALIDACIÓN DE LA SOLUCIÓN**

```bash
# 1. Insertar datos
./insert-search-test-data.sh

# 2. Verificar que existen
curl http://localhost:8080/api/search/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa | jq

# 3. Buscar por ubicación
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5" | jq

# 4. Probar ID inexistente (debe devolver 404)
curl -i http://localhost:8080/api/search/spaces/00000000-0000-0000-0000-000000000000
# HTTP/1.1 404 Not Found
# {"status":404,"message":"Space not found: 00000000-0000-0000-0000-000000000000"}
```

---

## 📊 MEJORAS DE ARQUITECTURA IMPLEMENTADAS

### 1. **Separación de Responsabilidades**
- ✅ Excepciones específicas por dominio
- ✅ Handlers centralizados en GlobalExceptionHandler
- ✅ Lógica de negocio en el servicio
- ✅ Mapeo delegado a MapStruct

### 2. **Principios SOLID**
- ✅ **Single Responsibility**: Cada excepción maneja un caso específico
- ✅ **Open/Closed**: Fácil agregar nuevos handlers sin modificar existentes
- ✅ **Dependency Inversion**: Servicios dependen de abstracciones

### 3. **Manejo de Errores (Best Practices)**
- ✅ Status HTTP semánticos (400, 404, 500)
- ✅ Mensajes de error descriptivos
- ✅ Logs con nivel apropiado (warn vs error)
- ✅ Información de contexto en excepciones

### 4. **Testing**
- ✅ Métodos fácilmente testables
- ✅ Excepciones con getters para assertions
- ✅ Logging para debugging

---

## 🚀 COMANDOS DE VALIDACIÓN COMPLETA

```bash
# 1. Recompilar
cd /Users/angel/Desktop/BalconazoApp
./recompile-all.sh

# 2. Detener servicios
./stop-all.sh

# 3. Insertar datos de prueba
./insert-search-test-data.sh

# 4. Iniciar servicios
./start-all-services.sh

# 5. Esperar 30 segundos
sleep 30

# 6. Verificar health
curl http://localhost:8080/actuator/health | jq '.status'

# 7. Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

# 8. Crear booking
BOOKING_ID=$(curl -s -X POST http://localhost:8080/api/booking/bookings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "guestId": "11111111-1111-1111-1111-111111111111",
    "startTs": "2025-11-01T10:00:00",
    "endTs": "2025-11-01T12:00:00",
    "numGuests": 2
  }' | jq -r '.id')

echo "Booking creado: $BOOKING_ID"

# 9. Confirmar booking
curl -s -X POST "http://localhost:8080/api/booking/bookings/$BOOKING_ID/confirm?paymentIntentId=pi_test_123" \
  -H "Authorization: Bearer $TOKEN" | jq '.status'
# Debe devolver: "confirmed"

# 10. Completar booking
curl -s -X POST "http://localhost:8080/api/booking/bookings/$BOOKING_ID/complete" \
  -H "Authorization: Bearer $TOKEN" | jq '.status'
# Debe devolver: "completed"

# 11. Buscar espacio
curl -s http://localhost:8080/api/search/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa | jq '.title'
# Debe devolver: "Ático con terraza en Madrid Centro"
```

---

## ✅ CHECKLIST DE VALIDACIÓN

- [x] BookingMapper mapea enums correctamente
- [x] confirmBooking acepta solo status "pending"
- [x] completeBooking acepta solo status "confirmed"
- [x] Excepciones personalizadas con mensajes claros
- [x] GlobalExceptionHandler maneja todas las excepciones
- [x] Datos de prueba insertados en Search
- [x] Script de inserción funciona con autenticación TCP
- [x] IDs de espacios documentados
- [x] Tests manuales documentados
- [x] Logs informativos en transiciones de estado

---

## 📚 LECCIONES APRENDIDAS

### 1. **MapStruct con Enums**
❌ NO usar `constant` para enums  
✅ Usar `expression` con `.name()`

### 2. **PostgreSQL en Docker**
❌ `psql -U postgres` (socket Unix, autenticación peer)  
✅ `psql -h 127.0.0.1 -U postgres` (TCP, autenticación md5/trust)

### 3. **Excepciones**
❌ `throw new RuntimeException("mensaje genérico")`  
✅ `throw new DomainSpecificException(contextData)`

### 4. **Arquitectura Limpia**
✅ Excepciones de dominio en paquete `exception/`  
✅ Handlers centralizados en `config/`  
✅ Mensajes descriptivos orientados al desarrollador

---

**Estado Final:** ✅ **TODOS LOS ERRORES RESUELTOS**  
**Compilación:** ✅ **BUILD SUCCESS**  
**Tests:** ✅ **Validados manualmente**  
**Documentación:** ✅ **Completa y detallada**

