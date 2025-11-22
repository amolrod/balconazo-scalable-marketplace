# Sistema de Reviews y Ratings - Implementación Segura

**Fecha**: 21 de noviembre de 2025  
**Branch**: `feature/frontend-cors-fix`  
**Estado**: ✅ COMPLETADO

## 🚨 Problema Identificado

### Vulnerabilidad Crítica de Seguridad

El sistema de reviews tenía **graves problemas de seguridad** que permitían:

1. ✅ **Reseñas falsas** - Cualquier usuario podía crear reseñas para cualquier reserva
2. ✅ **No validación de ownership** - No se verificaba que el usuario autenticado fuera el dueño de la reserva
3. ✅ **Rutas no protegidas** - Las rutas de reviews no estaban bajo autenticación JWT
4. ✅ **Rutas inconsistentes** - Usaba `/api/booking/reviews` en lugar de `/api/bookings/reviews`

### Ejemplo del Problema

**ANTES** (❌ INSEGURO):
```typescript
// Frontend podía enviar CUALQUIER bookingId
createReview({
  bookingId: "uuid-de-otra-persona",  // ❌ Reserva de otro usuario
  rating: 5,
  comment: "Reseña falsa"
})
```

```java
// Backend NO VALIDABA ownership
public ReviewDTO createReview(CreateReviewDTO dto) {
    // ❌ No verifica quién está autenticado
    // ❌ No valida que el usuario sea el guest de la reserva
    ReviewEntity review = new ReviewEntity();
    review.setBookingId(dto.getBookingId());  // Acepta cualquier ID
    return reviewRepository.save(review);
}
```

**Resultado**: Cualquiera podía dejar reseñas en nombre de otros usuarios.

## ✅ Solución Implementada

### 1. Excepciones Custom

**Archivos creados**:
- `UnauthorizedReviewException.java` - Usuario no es dueño de la reserva (403 FORBIDDEN)
- `ReviewNotAllowedException.java` - Reserva no está en estado COMPLETED (400 BAD REQUEST)
- `DuplicateReviewException.java` - Ya existe reseña para esa reserva (409 CONFLICT)

```java
// Nuevas excepciones
public class UnauthorizedReviewException extends RuntimeException {
    public UnauthorizedReviewException(String message) {
        super(message);
    }
}

public class ReviewNotAllowedException extends RuntimeException {
    public ReviewNotAllowedException(String message) {
        super(message);
    }
}

public class DuplicateReviewException extends RuntimeException {
    public DuplicateReviewException(String message) {
        super(message);
    }
}
```

### 2. GlobalExceptionHandler Actualizado

```java
@ExceptionHandler(UnauthorizedReviewException.class)
public ResponseEntity<ErrorResponse> handleUnauthorizedReviewException(UnauthorizedReviewException ex) {
    log.warn("⚠️ Unauthorized review attempt: {}", ex.getMessage());
    
    ErrorResponse error = ErrorResponse.builder()
            .timestamp(LocalDateTime.now())
            .status(HttpStatus.FORBIDDEN.value())  // 403
            .error("Forbidden")
            .message(ex.getMessage())
            .build();
    
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
}

@ExceptionHandler(ReviewNotAllowedException.class)
public ResponseEntity<ErrorResponse> handleReviewNotAllowedException(ReviewNotAllowedException ex) {
    // Retorna 400 BAD REQUEST
}

@ExceptionHandler(DuplicateReviewException.class)
public ResponseEntity<ErrorResponse> handleDuplicateReviewException(DuplicateReviewException ex) {
    // Retorna 409 CONFLICT
}
```

### 3. ReviewService con Validación de Owner

**Cambio en interfaz**:
```java
public interface ReviewService {
    // ANTES
    ReviewDTO createReview(CreateReviewDTO createReviewDTO);
    
    // DESPUÉS
    ReviewDTO createReview(CreateReviewDTO createReviewDTO, UUID authenticatedUserId);
}
```

**Implementación con Seguridad**:
```java
@Override
@Transactional
public ReviewDTO createReview(CreateReviewDTO createReviewDTO, UUID authenticatedUserId) {
    log.info("🔵 Creando review para booking: {} por usuario: {}", 
             createReviewDTO.getBookingId(), authenticatedUserId);

    // 1. Validar que la reserva existe
    BookingEntity booking = bookingRepository.findById(createReviewDTO.getBookingId())
            .orElseThrow(() -> new BookingNotFoundException(createReviewDTO.getBookingId()));

    // 2. 🔒 SEGURIDAD: Validar que el usuario autenticado es el guest de la reserva
    if (!booking.getGuestId().equals(authenticatedUserId)) {
        log.warn("⛔ Usuario {} intentó crear review para reserva {} que pertenece a {}",
                authenticatedUserId, booking.getId(), booking.getGuestId());
        throw new UnauthorizedReviewException("Solo el huésped de la reserva puede crear una reseña");
    }

    // 3. Validar que la reserva está completada
    if (booking.getStatus() != BookingEntity.BookingStatus.completed) {
        throw new ReviewNotAllowedException(
            "Solo se pueden reseñar reservas completadas. Estado actual: " + booking.getStatus()
        );
    }

    // 4. Validar que no exista ya una review para esta reserva
    if (reviewRepository.existsByBookingId(createReviewDTO.getBookingId())) {
        throw new DuplicateReviewException("Ya existe una reseña para esta reserva");
    }

    // 5. Crear y guardar review
    ReviewEntity review = reviewMapper.toEntity(createReviewDTO);
    review.setSpaceId(booking.getSpaceId());
    review.setGuestId(booking.getGuestId());
    
    ReviewEntity savedReview = reviewRepository.save(review);
    log.info("✅ Review creada con ID: {} por usuario {}", savedReview.getId(), authenticatedUserId);

    // 6. Publicar evento
    publishReviewCreatedEvent(savedReview);

    return reviewMapper.toDTO(savedReview);
}
```

### 4. ReviewController con Autenticación JWT

**Cambios**:
1. ✅ Ruta cambiada: `/api/booking/reviews` → `/api/bookings/reviews`
2. ✅ Extrae `userId` del JWT (parámetro `Authentication`)
3. ✅ Valida autenticación antes de procesar
4. ✅ Pasa `authenticatedUserId` al service

```java
@RestController
@RequestMapping("/api/bookings/reviews")  // ✅ Ahora bajo /api/bookings/**
@RequiredArgsConstructor
@Slf4j
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * Crear una nueva reseña
     * 🔒 Requiere autenticación: Solo el guest de la reserva puede crear la reseña
     */
    @PostMapping
    public ResponseEntity<ReviewDTO> createReview(
            @Valid @RequestBody CreateReviewDTO createReviewDTO,
            Authentication authentication) {  // ✅ Inyecta JWT
        
        log.info("📥 POST /api/bookings/reviews - Crear review");
        
        // ✅ Validar autenticación
        if (authentication == null || authentication.getName() == null) {
            log.warn("⚠️ Usuario no autenticado intentando crear review");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // ✅ Extraer userId del JWT
        String userId = authentication.getName();
        log.info("✅ Usuario autenticado: {} creando review para booking: {}", 
                 userId, createReviewDTO.getBookingId());
        
        // ✅ Pasar userId al service para validación
        UUID authenticatedUserId = UUID.fromString(userId);
        ReviewDTO review = reviewService.createReview(createReviewDTO, authenticatedUserId);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(review);
    }

    @GetMapping("/space/{spaceId}")
    public ResponseEntity<List<ReviewDTO>> getReviewsBySpace(@PathVariable UUID spaceId) {
        // Público - no requiere autenticación
        List<ReviewDTO> reviews = reviewService.getReviewsBySpace(spaceId);
        return ResponseEntity.ok(reviews);
    }

    /**
     * Obtener las reseñas escritas por el usuario autenticado
     * 🔒 Requiere autenticación
     */
    @GetMapping("/my")
    public ResponseEntity<List<ReviewDTO>> getMyReviews(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        UUID guestId = UUID.fromString(authentication.getName());
        List<ReviewDTO> reviews = reviewService.getReviewsByGuest(guestId);
        
        return ResponseEntity.ok(reviews);
    }
}
```

### 5. Gateway Routes Simplificado

**ANTES**:
```yaml
- id: booking-service-bookings
  predicates:
    - Path=/api/bookings/**
  
- id: booking-service-reviews  # ❌ Ruta separada
  predicates:
    - Path=/api/reviews/**      # ❌ Path incorrecto
```

**DESPUÉS**:
```yaml
# ==========================================
# BOOKING SERVICE - Protected endpoints
# Incluye: /api/bookings/** (bookings + reviews)
# ==========================================
- id: booking-service-bookings
  uri: lb://booking-service
  predicates:
    - Path=/api/bookings/**  # ✅ Cubre /api/bookings/reviews también
  filters:
    - StripPrefix=0
    - RequestRateLimiter
    - CircuitBreaker
```

**Beneficios**:
- ✅ Una sola ruta para todo el Booking Service
- ✅ Reviews ahora protegidas por JWT (están bajo `/api/bookings/**`)
- ✅ Configuración más simple

### 6. Frontend Actualizado

```typescript
// bookings.service.ts
export class BookingsService {
  private readonly baseUrl = `${environment.apiUrl}/bookings`;

  /**
   * Crear una reseña para una reserva
   * Automáticamente incluye el token JWT en headers
   */
  createReview(data: CreateReviewDTO): Observable<Review> {
    return this.http.post<Review>(`${this.baseUrl}/reviews`, data);
    // Genera: POST http://localhost:8080/api/bookings/reviews
  }

  /**
   * Obtener reseñas de un espacio (público)
   */
  getReviewsBySpace(spaceId: string): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/reviews/space/${spaceId}`);
  }

  /**
   * Obtener mis reseñas (protegido)
   */
  getMyReviews(): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/reviews/my`);
    // ANTES: `${this.baseUrl}/reviews/reviewer/me` ❌
    // AHORA: `${this.baseUrl}/reviews/my` ✅
  }
}
```

## 🔒 Flujo de Seguridad

### Caso 1: Usuario Legítimo Creando Review

```
1. Usuario hace booking → bookingId = "abc-123", guestId = "user-456"
2. Booking se completa → status = COMPLETED
3. Usuario intenta crear review:
   
   POST /api/bookings/reviews
   Headers: Authorization: Bearer eyJhbGc...  (JWT con sub="user-456")
   Body: { bookingId: "abc-123", rating: 5, comment: "Excelente" }

4. Gateway → Valida JWT, extrae userId="user-456"
5. Booking Service SecurityFilter → Valida JWT, crea Authentication
6. ReviewController → Extrae userId del Authentication
7. ReviewService → 
   a. Busca booking "abc-123" → guestId = "user-456"
   b. Compara: authenticatedUserId (user-456) == booking.guestId (user-456) ✅
   c. Verifica status = COMPLETED ✅
   d. Verifica no existe review duplicada ✅
   e. Crea review y guarda

✅ ÉXITO: Review creada
```

### Caso 2: Usuario Malicioso Intentando Crear Review Falsa

```
1. Hacker autenticado como "user-999"
2. Intenta crear review para reserva de otra persona:

   POST /api/bookings/reviews
   Headers: Authorization: Bearer eyJhbGc...  (JWT con sub="user-999")
   Body: { bookingId: "abc-123", rating: 1, comment: "Reseña falsa" }
           ↑ Esta reserva pertenece a "user-456"

3. Gateway → Valida JWT, extrae userId="user-999"
4. Booking Service SecurityFilter → Valida JWT, crea Authentication
5. ReviewController → Extrae userId="user-999" del Authentication
6. ReviewService →
   a. Busca booking "abc-123" → guestId = "user-456"
   b. Compara: authenticatedUserId (user-999) == booking.guestId (user-456) ❌
   c. ⛔ LANZA UnauthorizedReviewException

❌ ERROR 403 FORBIDDEN: "Solo el huésped de la reserva puede crear una reseña"
```

### Caso 3: Usuario Intenta Reseñar Reserva No Completada

```
1. Usuario autenticado como "user-456"
2. Tiene booking "abc-789" en estado PENDING
3. Intenta crear review:

   POST /api/bookings/reviews
   Body: { bookingId: "abc-789", rating: 5 }

4. ReviewService →
   a. Busca booking "abc-789" → guestId = "user-456" ✅
   b. Compara userId ✅
   c. Verifica status = PENDING ❌
   d. ⛔ LANZA ReviewNotAllowedException

❌ ERROR 400 BAD REQUEST: "Solo se pueden reseñar reservas completadas. Estado actual: PENDING"
```

## 📊 Comparación: Antes vs Después

| Aspecto | ANTES (❌) | DESPUÉS (✅) |
|---------|-----------|-------------|
| **Validación de Owner** | No existía | Verifica que userId == booking.guestId |
| **Autenticación** | No requerida | JWT obligatorio en todas las rutas protegidas |
| **Rutas** | `/api/booking/reviews` | `/api/bookings/reviews` (consistente) |
| **Protección JWT** | No (path fuera de `/api/bookings/**`) | Sí (ahora bajo `/api/bookings/**`) |
| **Excepciones** | Generic RuntimeException | Excepciones específicas (403, 400, 409) |
| **Estado de Reserva** | Solo valida COMPLETED | Valida COMPLETED + ownership |
| **Duplicados** | Valida | Valida (sin cambios) |
| **Rating** | Público | Público (sin cambios) |
| **Mis Reviews** | `/reviews/reviewer/me` | `/reviews/my` (más simple) |

## 🎯 Endpoints Actualizados

### Reviews API

| Método | Endpoint | Autenticación | Descripción |
|--------|----------|---------------|-------------|
| POST | `/api/bookings/reviews` | 🔒 JWT | Crear reseña (solo owner de la reserva) |
| GET | `/api/bookings/reviews/{id}` | ❌ Público | Obtener reseña por ID |
| GET | `/api/bookings/reviews/space/{spaceId}` | ❌ Público | Listar reseñas de un espacio |
| GET | `/api/bookings/reviews/space/{spaceId}/rating` | ❌ Público | Obtener rating promedio |
| GET | `/api/bookings/reviews/my` | 🔒 JWT | Mis reseñas escritas |

### Reglas de Negocio

1. **Solo el guest de una reserva puede reseñarla** (validado con JWT)
2. **Solo reservas en estado COMPLETED pueden ser reseñadas**
3. **Una reserva solo puede tener una reseña** (no duplicados)
4. **Rating debe estar entre 1 y 5**
5. **Comentario máximo 2000 caracteres**

## 🧪 Testing

### Test 1: Crear Review Legítima

```bash
# 1. Login como guest1
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

# 2. Crear review para MI reserva completada
curl -X POST http://localhost:8080/api/bookings/reviews \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "mi-booking-id",
    "rating": 5,
    "comment": "Excelente espacio"
  }'

# Esperado: 201 CREATED con ReviewDTO
```

### Test 2: Intento de Review Falsa (Debe Fallar)

```bash
# 1. Login como guest1
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

# 2. Intentar crear review para reserva de OTRA persona
curl -X POST http://localhost:8080/api/bookings/reviews \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "booking-de-otro-usuario",
    "rating": 1,
    "comment": "Reseña falsa"
  }'

# Esperado: 403 FORBIDDEN
# {
#   "status": 403,
#   "error": "Forbidden",
#   "message": "Solo el huésped de la reserva puede crear una reseña"
# }
```

### Test 3: Sin Autenticación (Debe Fallar)

```bash
# Intentar crear review sin JWT
curl -X POST http://localhost:8080/api/bookings/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "cualquier-id",
    "rating": 5
  }'

# Esperado: 401 UNAUTHORIZED
```

### Test 4: Listar Reviews Públicas (Debe Funcionar)

```bash
# Obtener reviews de un espacio (no requiere auth)
curl http://localhost:8080/api/bookings/reviews/space/{spaceId}

# Esperado: 200 OK con array de ReviewDTO
```

## 📝 Archivos Modificados

### Backend (Booking Service)

1. **Nuevos**:
   - `exception/UnauthorizedReviewException.java`
   - `exception/ReviewNotAllowedException.java`
   - `exception/DuplicateReviewException.java`

2. **Modificados**:
   - `config/GlobalExceptionHandler.java` - Handlers para nuevas excepciones
   - `service/ReviewService.java` - Interface con parámetro `authenticatedUserId`
   - `service/impl/ReviewServiceImpl.java` - Validación de ownership y excepciones custom
   - `controller/ReviewController.java` - Extracción de userId del JWT, rutas actualizadas

### Gateway

1. **Modificado**:
   - `api-gateway/src/main/resources/application.yml` - Eliminada ruta duplicada de reviews

### Frontend

1. **Modificado**:
   - `balconazo-frontend/src/app/core/services/bookings.service.ts` - Ruta `/my` actualizada

## ✅ Resultado Final

### Seguridad Implementada

✅ **Autenticación Obligatoria** - Todas las operaciones de escritura requieren JWT  
✅ **Validación de Ownership** - Solo el guest puede reseñar su propia reserva  
✅ **Excepciones Específicas** - Errores claros (403, 400, 409)  
✅ **Rutas Consistentes** - Todo bajo `/api/bookings/**`  
✅ **Logs Detallados** - Auditoría de intentos no autorizados  

### Protección Contra

✅ **Reseñas falsas** - Usuario no puede reseñar reservas de otros  
✅ **Spam de reviews** - Una reserva = una review máximo  
✅ **Reviews sin booking** - Debe existir reserva COMPLETED  
✅ **Acceso no autenticado** - JWT obligatorio para crear/editar  

## 🚀 Próximos Pasos (Opcional)

### Mejoras Futuras

1. **Rate Limiting por Usuario** - Limitar reviews por usuario/día
2. **Moderación de Contenido** - Filtro de lenguaje inapropiado
3. **Respuestas de Hosts** - Permitir que hosts respondan a reviews
4. **Edición de Reviews** - Permitir editar review dentro de X días
5. **Reportar Reviews** - Sistema para reportar reviews inapropiadas
6. **Verificación de Estancia** - Badge "Estancia verificada" en reviews
7. **Media en Reviews** - Permitir subir fotos en las reseñas

## 📚 Referencias

- **Commit**: Ver commits de esta sesión en `feature/frontend-cors-fix`
- **Documentación API**: Ver `docs/BACKEND_ARCHITECTURE.md`
- **Testing**: Ver sección de testing en este documento
