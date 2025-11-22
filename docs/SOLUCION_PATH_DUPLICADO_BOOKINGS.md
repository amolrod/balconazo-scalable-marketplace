# Solución: Duplicación de Path en BookingsService

**Fecha**: 21 de noviembre de 2025  
**Branch**: `feature/frontend-cors-fix`  
**Commits**: 547ef66

## Problema Identificado

El frontend Angular estaba generando errores **500 Internal Server Error** al intentar cargar las reservas del usuario en la página "Mis Reservas".

### Root Cause

**Duplicación sistemática de `/bookings` en las rutas** del servicio `BookingsService` del frontend.

#### ¿Qué pasaba?

```typescript
// En bookings.service.ts (ANTES - INCORRECTO ❌)
private readonly baseUrl = `${environment.apiUrl}/bookings`;  // = "http://localhost:8080/api/bookings"

getMyBookings(): Observable<Booking[]> {
  return this.http.get<Booking[]>(`${this.baseUrl}/bookings/my`);
  // Genera: http://localhost:8080/api/bookings/bookings/my ❌❌❌
}
```

La ruta generada era **`/api/bookings/bookings/my`** cuando el backend esperaba **`/api/bookings/my`**.

### Causa Raíz

Cuando se cambió el `baseUrl` de `/booking` (singular) a `/bookings` (plural), **no se actualizaron los métodos** que ya tenían `/bookings/` como prefijo en sus paths.

## Síntomas

1. ✅ **Backend funcionaba correctamente**:
   ```bash
   curl http://localhost:8080/api/bookings/my -H "Authorization: Bearer $TOKEN"
   # Respuesta: [] (array vacío, correcto)
   ```

2. ❌ **Frontend generaba error 500**:
   ```
   Failed to load resource: the server responded with a status of 500 (Internal Server Error)
   http://localhost:8080/api/bookings/bookings/my
   ```

3. **Gateway no tenía ruta** para `/api/bookings/bookings/**` (path malformado)

## Solución Implementada

### 1. Identificación del Problema

Búsqueda con `grep` encontró **9 métodos** con el patrón `${this.baseUrl}/bookings/...`:

```bash
grep -n "baseUrl}/bookings" bookings.service.ts
# 58: createBooking
# 65: getBookingById
# 72: getMyBookings          ← Principal problema
# 79: getBookingsBySpace
# 87: confirmBooking
# 98: cancelBooking
# 108: completeBooking
# 142: calculatePrice
# 154: checkAvailability
```

### 2. Fix Aplicado

**Eliminación de `/bookings` después de `${this.baseUrl}` en todos los métodos**:

```typescript
// CORRECTO ✅ (DESPUÉS)
private readonly baseUrl = `${environment.apiUrl}/bookings`;  // = "http://localhost:8080/api/bookings"

// Método 1: Crear reserva
createBooking(data: CreateBookingDTO): Observable<Booking> {
  return this.http.post<Booking>(`${this.baseUrl}`, data);
  // Genera: /api/bookings ✅
}

// Método 2: Obtener por ID
getBookingById(id: string): Observable<Booking> {
  return this.http.get<Booking>(`${this.baseUrl}/${id}`);
  // Genera: /api/bookings/{id} ✅
}

// Método 3: Mis reservas (principal fix)
getMyBookings(): Observable<Booking[]> {
  return this.http.get<Booking[]>(`${this.baseUrl}/my`);
  // Genera: /api/bookings/my ✅
}

// Método 4: Reservas por espacio
getBookingsBySpace(spaceId: string): Observable<Booking[]> {
  return this.http.get<Booking[]>(`${this.baseUrl}/space/${spaceId}`);
  // Genera: /api/bookings/space/{spaceId} ✅
}

// Método 5: Confirmar reserva
confirmBooking(bookingId: string, paymentIntentId: string): Observable<Booking> {
  return this.http.post<Booking>(
    `${this.baseUrl}/${bookingId}/confirm`,
    null,
    { params: { paymentIntentId } }
  );
  // Genera: /api/bookings/{id}/confirm ✅
}

// Método 6: Cancelar reserva
cancelBooking(bookingId: string, reason: string): Observable<Booking> {
  return this.http.post<Booking>(
    `${this.baseUrl}/${bookingId}/cancel`,
    null,
    { params: { reason } }
  );
  // Genera: /api/bookings/{id}/cancel ✅
}

// Método 7: Completar reserva
completeBooking(bookingId: string): Observable<Booking> {
  return this.http.post<Booking>(`${this.baseUrl}/${bookingId}/complete`, {});
  // Genera: /api/bookings/{id}/complete ✅
}

// Método 8: Calcular precio
calculatePrice(spaceId: string, startTs: string, endTs: string, numGuests: number): Observable<{ totalPriceCents: number }> {
  const params = new HttpParams()
    .set('spaceId', spaceId)
    .set('startTs', startTs)
    .set('endTs', endTs)
    .set('numGuests', numGuests.toString());

  return this.http.get<{ totalPriceCents: number }>(`${this.baseUrl}/calculate-price`, { params });
  // Genera: /api/bookings/calculate-price ✅
}

// Método 9: Verificar disponibilidad
checkAvailability(spaceId: string, startTs: string, endTs: string): Observable<{ available: boolean }> {
  const params = new HttpParams()
    .set('spaceId', spaceId)
    .set('startTs', startTs)
    .set('endTs', endTs);

  return this.http.get<{ available: boolean }>(`${this.baseUrl}/check-availability`, { params });
  // Genera: /api/bookings/check-availability ✅
}
```

### 3. Cambios Realizados

**Archivo**: `balconazo-frontend/src/app/core/services/bookings.service.ts`

| Método | Path ANTES (❌) | Path DESPUÉS (✅) |
|--------|----------------|-------------------|
| `createBooking` | `${baseUrl}/bookings` | `${baseUrl}` |
| `getBookingById` | `${baseUrl}/bookings/${id}` | `${baseUrl}/${id}` |
| `getMyBookings` | `${baseUrl}/bookings/my` | `${baseUrl}/my` |
| `getBookingsBySpace` | `${baseUrl}/bookings/space/${spaceId}` | `${baseUrl}/space/${spaceId}` |
| `confirmBooking` | `${baseUrl}/bookings/${id}/confirm` | `${baseUrl}/${id}/confirm` |
| `cancelBooking` | `${baseUrl}/bookings/${id}/cancel` | `${baseUrl}/${id}/cancel` |
| `completeBooking` | `${baseUrl}/bookings/${id}/complete` | `${baseUrl}/${id}/complete` |
| `calculatePrice` | `${baseUrl}/bookings/calculate-price` | `${baseUrl}/calculate-price` |
| `checkAvailability` | `${baseUrl}/bookings/check-availability` | `${baseUrl}/check-availability` |

## Verificación

### Backend (Funcionaba antes y después)

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

# Test directo a Booking Service (8082)
curl http://localhost:8082/api/bookings/my \
  -H "Authorization: Bearer $TOKEN"
# Resultado: [] ✅

# Test a través del Gateway (8080)
curl http://localhost:8080/api/bookings/my \
  -H "Authorization: Bearer $TOKEN"
# Resultado: [] ✅
```

### Frontend (Fijo después del cambio)

**ANTES (❌)**:
```
Request URL: http://localhost:8080/api/bookings/bookings/my
Status: 500 Internal Server Error
```

**DESPUÉS (✅)**:
```
Request URL: http://localhost:8080/api/bookings/my
Status: 200 OK
Response: []
```

## Configuración del Backend (Correcta desde el inicio)

### BookingController.java

```java
@RestController
@RequestMapping("/api/bookings")
public class BookingController {
    
    @GetMapping("/my")
    public ResponseEntity<List<BookingDTO>> getMyBookings(Authentication authentication) {
        String userId = authentication.getName();  // Extrae userId del JWT
        List<BookingDTO> bookings = bookingService.getBookingsByGuest(UUID.fromString(userId));
        return ResponseEntity.ok(bookings);
    }
}
```

### Gateway application.yml

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: booking-service-bookings
          uri: lb://booking-service
          predicates:
            - Path=/api/bookings/**
          filters:
            - StripPrefix=0  # No elimina ningún segmento
          # Ruta completa llega al backend: /api/bookings/my
```

## Lecciones Aprendidas

### 1. **Coherencia en Naming**

Cuando `baseUrl` incluye el recurso (`/bookings`), los métodos deben usar **paths relativos** sin repetir el recurso:

```typescript
// ✅ BIEN
baseUrl = '/bookings'
method: `${baseUrl}/my`  → /bookings/my

// ❌ MAL
baseUrl = '/bookings'
method: `${baseUrl}/bookings/my`  → /bookings/bookings/my
```

### 2. **Testing E2E vs Unit**

- ✅ Tests directos al backend (`curl`) funcionaban
- ❌ Frontend fallaba por paths incorrectos
- **Moraleja**: Siempre verificar la **red del navegador** (DevTools → Network) para ver paths reales

### 3. **Búsqueda Exhaustiva**

Cuando se cambia un `baseUrl`, usar `grep` para encontrar **todos los usos**:

```bash
grep -rn "baseUrl" src/app/core/services/
grep -rn "bookings/bookings" src/
```

### 4. **StripPrefix en Gateway**

- `StripPrefix=0`: No elimina nada, path completo llega al backend
- `StripPrefix=1`: Elimina primer segmento (`/api`)
- **Elegir valor según estructura de rutas en backend**

## Endpoints Finales Correctos

### Bookings API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/bookings` | Crear reserva |
| GET | `/api/bookings/my` | Mis reservas (como guest) |
| GET | `/api/bookings/space/{id}` | Reservas de mi espacio (como host) |
| GET | `/api/bookings/{id}` | Obtener reserva por ID |
| POST | `/api/bookings/{id}/confirm` | Confirmar reserva |
| POST | `/api/bookings/{id}/cancel` | Cancelar reserva |
| POST | `/api/bookings/{id}/complete` | Completar reserva |
| GET | `/api/bookings/calculate-price` | Calcular precio |
| GET | `/api/bookings/check-availability` | Verificar disponibilidad |

## Estado Final

✅ **Todos los servicios UP** (Eureka, Gateway, Auth, Catalog, Booking, Search)  
✅ **CORS configurado correctamente** (solo en Gateway)  
✅ **JWT funcionando** (extrae userId del token)  
✅ **Base de datos con test users** (guest1@balconazo.com / password123)  
✅ **Frontend con rutas corregidas**  
✅ **Gateway con rutas simplificadas**  
✅ **Página "Mis Reservas" funcional** (muestra array vacío sin errores)

## Referencias

- **Commit Fix**: `547ef66 - fix: eliminar duplicación de /bookings en todos los métodos del BookingsService`
- **Branch**: `feature/frontend-cors-fix`
- **Archivos Modificados**: 
  - `balconazo-frontend/src/app/core/services/bookings.service.ts`
  - `README.md`
  - `docs/INDEX.md`
  - `docs/FRONTEND_API_GUIDE_PART_3_BOOKINGS.md`
  - `docs/BACKEND_ARCHITECTURE.md`
