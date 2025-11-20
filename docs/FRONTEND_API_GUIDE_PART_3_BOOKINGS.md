# Guía de Integración API Frontend - Parte 3: Gestión de Reservas

## 📋 Índice
1. [Introducción](#introducción)
2. [Ciclo de Vida de una Reserva](#ciclo-de-vida-de-una-reserva)
3. [Endpoints de Reservas](#endpoints-de-reservas)
4. [Gestión de Pagos](#gestión-de-pagos)
5. [Validación de Conflictos](#validación-de-conflictos)
6. [Ejemplos de Código](#ejemplos-de-código)
7. [Casos de Uso](#casos-de-uso)

---

## Introducción

El módulo de **Reservas (Bookings)** permite:
- **Crear** reservas de espacios con fechas y número de huéspedes
- **Listar** reservas del usuario (como guest)
- **Listar** reservas de un espacio (como host)
- **Confirmar** reservas (solo el host del espacio)
- **Cancelar** reservas (guest o host)
- **Ver** reservas en diferentes estados (pending, confirmed, cancelled)

**Base URL**: `http://localhost:8080/api/bookings` (vía API Gateway)

**Servicio**: Booking Microservice (Puerto 8082)

---

## Ciclo de Vida de una Reserva

### Estados de una Reserva

```
┌─────────┐
│ PENDING │ ← Estado inicial al crear reserva
└────┬────┘
     │
     ├──→ ┌───────────┐
     │    │ CONFIRMED │ ← Host confirma (con paymentIntentId)
     │    └───────────┘
     │
     └──→ ┌───────────┐
          │ CANCELLED │ ← Guest o Host cancela (con reason)
          └───────────┘
```

### Flujo Típico

1. **GUEST crea reserva** → Estado: `pending`
2. **HOST revisa reserva** → Ve reserva en lista de su espacio
3. **HOST confirma reserva** → Estado: `confirmed`, requiere `paymentIntentId`
4. **GUEST ve confirmación** → Reserva aparece como confirmada
5. **Opcional: Cancelación** → Estado: `cancelled`, requiere `reason`

---

## Endpoints de Reservas

### 1. Crear Reserva

```
POST /api/bookings
```

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "startTs": "2025-12-01T15:00:00",
  "endTs": "2025-12-01T20:00:00",
  "numGuests": 8
}
```

**Campos**:
- `spaceId`: UUID del espacio a reservar (required)
- `startTs`: Fecha/hora de inicio en formato ISO 8601 (required)
- `endTs`: Fecha/hora de fin en formato ISO 8601 (required)
- `numGuests`: Número de huéspedes (required, > 0)

**Validaciones**:
- `startTs` debe ser anterior a `endTs`
- `numGuests` debe ser ≤ `space.capacity`
- No debe haber conflictos de fechas con otras reservas del mismo espacio

**Response 201 Created**:
```json
{
  "id": "b3c4d5e6-f7a8-9012-cdef-345678901234",
  "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "startTs": "2025-12-01T15:00:00",
  "endTs": "2025-12-01T20:00:00",
  "numGuests": 8,
  "status": "pending",
  "totalPrice": 225.00,
  "createdAt": "2025-11-20T10:30:00",
  "paymentIntentId": null,
  "cancellationReason": null
}
```

**Campos de respuesta**:
- `id`: UUID de la reserva
- `guestId`: UUID del usuario que creó la reserva (extraído del token)
- `status`: Estado de la reserva (`pending`, `confirmed`, `cancelled`)
- `totalPrice`: Precio total calculado (horas × pricePerHour del espacio)
- `paymentIntentId`: ID del pago (null hasta confirmar)
- `cancellationReason`: Razón de cancelación (null si no está cancelada)

**Response Codes**:
- `201 Created`: Reserva creada exitosamente
- `400 Bad Request`: Datos inválidos o conflicto de fechas
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Espacio no existe
- `409 Conflict`: Conflicto de fechas con otra reserva

**Errores comunes**:
```json
// Conflicto de fechas
{
  "message": "Space is already booked for the selected dates"
}

// Capacidad excedida
{
  "message": "Number of guests exceeds space capacity"
}

// Fechas inválidas
{
  "message": "End date must be after start date"
}
```

### 2. Listar Reservas del Usuario (Guest)

```
GET /api/bookings/my-bookings
```

**Headers**:
```
Authorization: Bearer {token}
```

**Descripción**: Devuelve todas las reservas creadas por el usuario autenticado.

**Response 200 OK**:
```json
[
  {
    "id": "b3c4d5e6-f7a8-9012-cdef-345678901234",
    "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "startTs": "2025-12-01T15:00:00",
    "endTs": "2025-12-01T20:00:00",
    "numGuests": 8,
    "status": "confirmed",
    "totalPrice": 225.00,
    "createdAt": "2025-11-20T10:30:00",
    "paymentIntentId": "pi_123456789",
    "cancellationReason": null
  },
  {
    "id": "c4d5e6f7-a8b9-0123-def4-567890123456",
    "spaceId": "7f31f234-c3ae-5733-bd26-e5e1c81a7bf1",
    "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "startTs": "2025-12-05T10:00:00",
    "endTs": "2025-12-05T14:00:00",
    "numGuests": 5,
    "status": "pending",
    "totalPrice": 140.00,
    "createdAt": "2025-11-20T11:00:00",
    "paymentIntentId": null,
    "cancellationReason": null
  }
]
```

**Response Codes**:
- `200 OK`: Lista de reservas (puede ser vacía `[]`)
- `401 Unauthorized`: Token inválido

### 3. Listar Reservas de un Espacio (Host)

```
GET /api/bookings/space/{spaceId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `spaceId`: UUID del espacio

**Descripción**: Devuelve todas las reservas de un espacio específico. Útil para que el HOST gestione las reservas de sus espacios.

**Importante**: Este endpoint ahora devuelve **todas las reservas** (pending, confirmed, cancelled) para que el HOST tenga visibilidad completa.

**Response 200 OK**:
```json
[
  {
    "id": "b3c4d5e6-f7a8-9012-cdef-345678901234",
    "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "startTs": "2025-12-01T15:00:00",
    "endTs": "2025-12-01T20:00:00",
    "numGuests": 8,
    "status": "pending",
    "totalPrice": 225.00,
    "createdAt": "2025-11-20T10:30:00",
    "paymentIntentId": null,
    "cancellationReason": null
  },
  {
    "id": "d5e6f7g8-b9c0-1234-efg5-678901234567",
    "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "guestId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "startTs": "2025-12-03T09:00:00",
    "endTs": "2025-12-03T13:00:00",
    "numGuests": 10,
    "status": "confirmed",
    "totalPrice": 180.00,
    "createdAt": "2025-11-20T12:00:00",
    "paymentIntentId": "pi_987654321",
    "cancellationReason": null
  }
]
```

**Response Codes**:
- `200 OK`: Lista de reservas (puede ser vacía `[]`)
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Espacio no existe

**Nota**: No valida ownership del espacio, cualquier usuario autenticado puede ver las reservas de cualquier espacio. Si quieres restringir esto, implementa validación de ownership en el frontend.

### 4. Confirmar Reserva (Host)

```
POST /api/bookings/{bookingId}/confirm?paymentIntentId={paymentIntentId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `bookingId`: UUID de la reserva

**Query Parameters**:
- `paymentIntentId`: ID del intento de pago (required, string)

**Descripción**: El HOST confirma una reserva pendiente, indicando que se ha procesado el pago.

**Ejemplo de URL completa**:
```
POST /api/bookings/b3c4d5e6-f7a8-9012-cdef-345678901234/confirm?paymentIntentId=pi_123456789
```

**Response 200 OK**:
```json
{
  "id": "b3c4d5e6-f7a8-9012-cdef-345678901234",
  "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "startTs": "2025-12-01T15:00:00",
  "endTs": "2025-12-01T20:00:00",
  "numGuests": 8,
  "status": "confirmed",
  "totalPrice": 225.00,
  "createdAt": "2025-11-20T10:30:00",
  "paymentIntentId": "pi_123456789",
  "cancellationReason": null
}
```

**Response Codes**:
- `200 OK`: Reserva confirmada exitosamente
- `400 Bad Request`: Reserva no está en estado `pending` o falta `paymentIntentId`
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Reserva no existe

**Errores comunes**:
```json
// Reserva ya confirmada
{
  "message": "Booking is not in pending status"
}

// Falta paymentIntentId
{
  "message": "Payment intent ID is required"
}
```

### 5. Cancelar Reserva

```
POST /api/bookings/{bookingId}/cancel?reason={reason}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `bookingId`: UUID de la reserva

**Query Parameters**:
- `reason`: Razón de la cancelación (required, string)

**Descripción**: El GUEST o el HOST puede cancelar una reserva. La razón es obligatoria.

**Ejemplo de URL completa**:
```
POST /api/bookings/b3c4d5e6-f7a8-9012-cdef-345678901234/cancel?reason=Cambio+de+planes
```

**Response 200 OK**:
```json
{
  "id": "b3c4d5e6-f7a8-9012-cdef-345678901234",
  "spaceId": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "guestId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "startTs": "2025-12-01T15:00:00",
  "endTs": "2025-12-01T20:00:00",
  "numGuests": 8,
  "status": "cancelled",
  "totalPrice": 225.00,
  "createdAt": "2025-11-20T10:30:00",
  "paymentIntentId": "pi_123456789",
  "cancellationReason": "Cambio de planes"
}
```

**Response Codes**:
- `200 OK`: Reserva cancelada exitosamente
- `400 Bad Request`: Reserva ya está cancelada o falta `reason`
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Reserva no existe

**Errores comunes**:
```json
// Reserva ya cancelada
{
  "message": "Booking is already cancelled"
}

// Falta reason
{
  "message": "Cancellation reason is required"
}
```

---

## Gestión de Pagos

### Integración con Stripe (Conceptual)

El sistema está preparado para integración con **Stripe Payment Intents**:

1. **Frontend crea Payment Intent** (llamada a Stripe API)
2. **Usuario completa pago** (Stripe Checkout)
3. **Frontend obtiene `paymentIntentId`** (ej: `pi_3MtwBwLkdIwHu7ix28a3tqPa`)
4. **HOST confirma reserva** con `paymentIntentId`

**Flujo completo**:
```typescript
async function createAndPayBooking(bookingData) {
  // 1. Crear reserva (status: pending)
  const booking = await createBooking(token, bookingData);
  
  // 2. Crear Payment Intent en Stripe
  const paymentIntent = await stripe.paymentIntents.create({
    amount: booking.totalPrice * 100, // Stripe usa centavos
    currency: 'eur',
    metadata: { bookingId: booking.id }
  });
  
  // 3. Mostrar Stripe Checkout al usuario
  const { error } = await stripe.confirmCardPayment(
    paymentIntent.client_secret,
    { payment_method: cardElement }
  );
  
  if (!error) {
    // 4. Pago exitoso → HOST confirma reserva
    // (En producción, usar webhook de Stripe)
    await confirmBooking(token, booking.id, paymentIntent.id);
  }
}
```

**Nota**: La implementación actual acepta cualquier string como `paymentIntentId` para testing. En producción, validar con Stripe API.

---

## Validación de Conflictos

### Detección de Conflictos de Fechas

El backend valida automáticamente conflictos al crear una reserva:

**Conflicto existe si**:
```
Nueva reserva: [startTs, endTs]
Reserva existente: [existingStart, existingEnd]

Conflicto = (startTs < existingEnd) && (endTs > existingStart)
```

**Ejemplos**:

✅ **No hay conflicto**:
```
Existente: 2025-12-01 10:00 - 14:00
Nueva:     2025-12-01 15:00 - 19:00  ← OK (después)
```

❌ **Conflicto (overlap parcial)**:
```
Existente: 2025-12-01 10:00 - 14:00
Nueva:     2025-12-01 12:00 - 16:00  ← CONFLICTO (overlap)
```

❌ **Conflicto (contenida)**:
```
Existente: 2025-12-01 10:00 - 18:00
Nueva:     2025-12-01 12:00 - 14:00  ← CONFLICTO (contenida)
```

### Validación en Frontend

```typescript
async function validateBookingDates(
  spaceId: string,
  startTs: string,
  endTs: string
): Promise<boolean> {
  // Obtener reservas existentes del espacio
  const bookings = await getBookingsBySpace(token, spaceId);
  
  // Filtrar solo reservas confirmadas o pendientes
  const activeBookings = bookings.filter(
    b => b.status === 'confirmed' || b.status === 'pending'
  );
  
  const newStart = new Date(startTs);
  const newEnd = new Date(endTs);
  
  // Verificar conflictos
  for (const booking of activeBookings) {
    const existingStart = new Date(booking.startTs);
    const existingEnd = new Date(booking.endTs);
    
    if (newStart < existingEnd && newEnd > existingStart) {
      return false; // Hay conflicto
    }
  }
  
  return true; // No hay conflicto
}
```

---

## Ejemplos de Código

### Service de Reservas

```typescript
// services/bookingService.ts
const API_BASE = 'http://localhost:8080/api/bookings';

export interface CreateBookingDTO {
  spaceId: string;
  startTs: string; // ISO 8601 format
  endTs: string;   // ISO 8601 format
  numGuests: number;
}

export interface Booking {
  id: string;
  spaceId: string;
  guestId: string;
  startTs: string;
  endTs: string;
  numGuests: number;
  status: 'pending' | 'confirmed' | 'cancelled';
  totalPrice: number;
  createdAt: string;
  paymentIntentId: string | null;
  cancellationReason: string | null;
}

function getAuthHeaders(token: string) {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
}

export async function createBooking(
  token: string,
  data: CreateBookingDTO
): Promise<Booking> {
  const response = await fetch(API_BASE, {
    method: 'POST',
    headers: getAuthHeaders(token),
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to create booking');
  }
  
  return response.json();
}

export async function getMyBookings(token: string): Promise<Booking[]> {
  const response = await fetch(`${API_BASE}/my-bookings`, {
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch bookings');
  }
  
  return response.json();
}

export async function getBookingsBySpace(
  token: string,
  spaceId: string
): Promise<Booking[]> {
  const response = await fetch(`${API_BASE}/space/${spaceId}`, {
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch bookings for space');
  }
  
  return response.json();
}

export async function confirmBooking(
  token: string,
  bookingId: string,
  paymentIntentId: string
): Promise<Booking> {
  const response = await fetch(
    `${API_BASE}/${bookingId}/confirm?paymentIntentId=${encodeURIComponent(paymentIntentId)}`,
    {
      method: 'POST',
      headers: getAuthHeaders(token)
    }
  );
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to confirm booking');
  }
  
  return response.json();
}

export async function cancelBooking(
  token: string,
  bookingId: string,
  reason: string
): Promise<Booking> {
  const response = await fetch(
    `${API_BASE}/${bookingId}/cancel?reason=${encodeURIComponent(reason)}`,
    {
      method: 'POST',
      headers: getAuthHeaders(token)
    }
  );
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to cancel booking');
  }
  
  return response.json();
}
```

### Componente de Creación de Reserva

```typescript
// CreateBookingForm.tsx
import { useState } from 'react';
import { useAuth } from './AuthContext';
import { useNavigate } from 'react-router-dom';
import { createBooking, Space } from './services';

interface CreateBookingFormProps {
  space: Space;
}

function CreateBookingForm({ space }: CreateBookingFormProps) {
  const { token } = useAuth();
  const navigate = useNavigate();
  
  const [formData, setFormData] = useState({
    startDate: '',
    startTime: '',
    endDate: '',
    endTime: '',
    numGuests: 1
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      // Construir timestamps ISO 8601
      const startTs = `${formData.startDate}T${formData.startTime}:00`;
      const endTs = `${formData.endDate}T${formData.endTime}:00`;
      
      // Validar fechas
      if (new Date(startTs) >= new Date(endTs)) {
        throw new Error('La fecha de fin debe ser posterior a la de inicio');
      }
      
      // Validar capacidad
      if (formData.numGuests > space.capacity) {
        throw new Error(`El espacio tiene capacidad máxima de ${space.capacity} personas`);
      }
      
      // Crear reserva
      const booking = await createBooking(token!, {
        spaceId: space.id,
        startTs,
        endTs,
        numGuests: formData.numGuests
      });
      
      // Redirigir a página de pago o confirmación
      navigate(`/bookings/${booking.id}/payment`);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }
  
  // Calcular precio estimado
  const calculatePrice = () => {
    if (!formData.startDate || !formData.endDate) return 0;
    
    const start = new Date(`${formData.startDate}T${formData.startTime}:00`);
    const end = new Date(`${formData.endDate}T${formData.endTime}:00`);
    const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
    
    return hours * space.pricePerHour;
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <h2>Reservar: {space.name}</h2>
      
      {error && <div className="error">{error}</div>}
      
      <div className="date-range">
        <div>
          <label>Fecha de Inicio</label>
          <input
            type="date"
            value={formData.startDate}
            onChange={e => setFormData({ ...formData, startDate: e.target.value })}
            min={new Date().toISOString().split('T')[0]}
            required
          />
          <input
            type="time"
            value={formData.startTime}
            onChange={e => setFormData({ ...formData, startTime: e.target.value })}
            required
          />
        </div>
        
        <div>
          <label>Fecha de Fin</label>
          <input
            type="date"
            value={formData.endDate}
            onChange={e => setFormData({ ...formData, endDate: e.target.value })}
            min={formData.startDate}
            required
          />
          <input
            type="time"
            value={formData.endTime}
            onChange={e => setFormData({ ...formData, endTime: e.target.value })}
            required
          />
        </div>
      </div>
      
      <div>
        <label>Número de Huéspedes</label>
        <input
          type="number"
          value={formData.numGuests}
          onChange={e => setFormData({ ...formData, numGuests: parseInt(e.target.value) })}
          min="1"
          max={space.capacity}
          required
        />
        <small>Capacidad máxima: {space.capacity} personas</small>
      </div>
      
      {formData.startDate && formData.endDate && (
        <div className="price-estimate">
          <h3>Precio Total Estimado</h3>
          <p className="price">{calculatePrice().toFixed(2)}€</p>
        </div>
      )}
      
      <button type="submit" disabled={loading}>
        {loading ? 'Creando reserva...' : 'Continuar al Pago'}
      </button>
    </form>
  );
}
```

### Componente de Lista de Reservas (Guest)

```typescript
// MyBookings.tsx
import { useEffect, useState } from 'react';
import { useAuth } from './AuthContext';
import { getMyBookings, cancelBooking, Booking } from './services';

function MyBookings() {
  const { token } = useAuth();
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    loadBookings();
  }, []);
  
  async function loadBookings() {
    try {
      const data = await getMyBookings(token!);
      setBookings(data.sort((a, b) => 
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      ));
    } catch (err) {
      console.error('Error loading bookings:', err);
    } finally {
      setLoading(false);
    }
  }
  
  async function handleCancel(bookingId: string) {
    const reason = prompt('¿Por qué deseas cancelar esta reserva?');
    if (!reason) return;
    
    try {
      await cancelBooking(token!, bookingId, reason);
      await loadBookings(); // Recargar lista
    } catch (err) {
      alert('Error al cancelar la reserva: ' + (err as Error).message);
    }
  }
  
  if (loading) return <div>Cargando reservas...</div>;
  
  return (
    <div className="my-bookings">
      <h2>Mis Reservas</h2>
      
      {bookings.length === 0 ? (
        <p>No tienes reservas todavía</p>
      ) : (
        <div className="bookings-list">
          {bookings.map(booking => (
            <BookingCard
              key={booking.id}
              booking={booking}
              onCancel={handleCancel}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function BookingCard({ 
  booking, 
  onCancel 
}: { 
  booking: Booking; 
  onCancel: (id: string) => void;
}) {
  const statusBadge = {
    pending: { text: 'Pendiente', class: 'status-pending' },
    confirmed: { text: 'Confirmada', class: 'status-confirmed' },
    cancelled: { text: 'Cancelada', class: 'status-cancelled' }
  }[booking.status];
  
  const formatDate = (ts: string) => {
    return new Date(ts).toLocaleString('es-ES', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };
  
  return (
    <div className="booking-card">
      <div className="booking-header">
        <h3>Reserva #{booking.id.slice(0, 8)}</h3>
        <span className={statusBadge.class}>{statusBadge.text}</span>
      </div>
      
      <div className="booking-details">
        <p><strong>Inicio:</strong> {formatDate(booking.startTs)}</p>
        <p><strong>Fin:</strong> {formatDate(booking.endTs)}</p>
        <p><strong>Huéspedes:</strong> {booking.numGuests}</p>
        <p><strong>Precio Total:</strong> {booking.totalPrice.toFixed(2)}€</p>
      </div>
      
      {booking.status === 'cancelled' && booking.cancellationReason && (
        <div className="cancellation-reason">
          <strong>Razón de cancelación:</strong> {booking.cancellationReason}
        </div>
      )}
      
      {booking.status !== 'cancelled' && (
        <button 
          onClick={() => onCancel(booking.id)}
          className="btn-cancel"
        >
          Cancelar Reserva
        </button>
      )}
    </div>
  );
}
```

### Componente de Gestión de Reservas (Host)

```typescript
// HostBookings.tsx
import { useEffect, useState } from 'react';
import { useAuth } from './AuthContext';
import { getBookingsBySpace, confirmBooking, Booking, Space } from './services';

interface HostBookingsProps {
  space: Space;
}

function HostBookings({ space }: HostBookingsProps) {
  const { token } = useAuth();
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    loadBookings();
  }, [space.id]);
  
  async function loadBookings() {
    try {
      const data = await getBookingsBySpace(token!, space.id);
      setBookings(data.sort((a, b) => 
        new Date(a.startTs).getTime() - new Date(b.startTs).getTime()
      ));
    } catch (err) {
      console.error('Error loading bookings:', err);
    } finally {
      setLoading(false);
    }
  }
  
  async function handleConfirm(bookingId: string) {
    // En producción, obtener paymentIntentId de Stripe
    const paymentIntentId = `pi_test_${Date.now()}`;
    
    try {
      await confirmBooking(token!, bookingId, paymentIntentId);
      await loadBookings(); // Recargar lista
    } catch (err) {
      alert('Error al confirmar reserva: ' + (err as Error).message);
    }
  }
  
  if (loading) return <div>Cargando reservas...</div>;
  
  // Agrupar por estado
  const pending = bookings.filter(b => b.status === 'pending');
  const confirmed = bookings.filter(b => b.status === 'confirmed');
  const cancelled = bookings.filter(b => b.status === 'cancelled');
  
  return (
    <div className="host-bookings">
      <h2>Reservas de: {space.name}</h2>
      
      {bookings.length === 0 ? (
        <p>No hay reservas para este espacio</p>
      ) : (
        <>
          {pending.length > 0 && (
            <section>
              <h3>Pendientes de Confirmación ({pending.length})</h3>
              {pending.map(booking => (
                <HostBookingCard
                  key={booking.id}
                  booking={booking}
                  onConfirm={handleConfirm}
                />
              ))}
            </section>
          )}
          
          {confirmed.length > 0 && (
            <section>
              <h3>Confirmadas ({confirmed.length})</h3>
              {confirmed.map(booking => (
                <HostBookingCard key={booking.id} booking={booking} />
              ))}
            </section>
          )}
          
          {cancelled.length > 0 && (
            <section>
              <h3>Canceladas ({cancelled.length})</h3>
              {cancelled.map(booking => (
                <HostBookingCard key={booking.id} booking={booking} />
              ))}
            </section>
          )}
        </>
      )}
    </div>
  );
}

function HostBookingCard({
  booking,
  onConfirm
}: {
  booking: Booking;
  onConfirm?: (id: string) => void;
}) {
  const formatDate = (ts: string) => {
    return new Date(ts).toLocaleString('es-ES', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };
  
  return (
    <div className={`booking-card booking-${booking.status}`}>
      <div className="booking-info">
        <p><strong>Guest ID:</strong> {booking.guestId.slice(0, 8)}...</p>
        <p><strong>Inicio:</strong> {formatDate(booking.startTs)}</p>
        <p><strong>Fin:</strong> {formatDate(booking.endTs)}</p>
        <p><strong>Huéspedes:</strong> {booking.numGuests}</p>
        <p><strong>Total:</strong> {booking.totalPrice.toFixed(2)}€</p>
      </div>
      
      {booking.status === 'pending' && onConfirm && (
        <button onClick={() => onConfirm(booking.id)} className="btn-confirm">
          Confirmar Reserva
        </button>
      )}
      
      {booking.status === 'confirmed' && booking.paymentIntentId && (
        <p className="payment-info">
          <strong>Pago:</strong> {booking.paymentIntentId}
        </p>
      )}
      
      {booking.status === 'cancelled' && booking.cancellationReason && (
        <p className="cancellation">
          <strong>Cancelada:</strong> {booking.cancellationReason}
        </p>
      )}
    </div>
  );
}
```

---

## Casos de Uso

### 1. Flujo Completo de Reserva

```typescript
async function completeBookingFlow(spaceId: string) {
  // 1. Usuario selecciona fechas y crea reserva
  const booking = await createBooking(token, {
    spaceId,
    startTs: '2025-12-01T15:00:00',
    endTs: '2025-12-01T20:00:00',
    numGuests: 8
  });
  
  console.log('Reserva creada:', booking);
  console.log('Estado:', booking.status); // 'pending'
  console.log('Precio:', booking.totalPrice); // Calculado automáticamente
  
  // 2. (En producción) Procesar pago con Stripe
  // const paymentIntent = await stripe.paymentIntents.create(...)
  
  // 3. HOST confirma reserva
  const confirmed = await confirmBooking(
    hostToken,
    booking.id,
    'pi_123456789'
  );
  
  console.log('Estado actualizado:', confirmed.status); // 'confirmed'
  console.log('Payment Intent:', confirmed.paymentIntentId); // 'pi_123456789'
}
```

### 2. Cancelar Reserva con Razón

```typescript
async function cancelMyBooking(bookingId: string) {
  try {
    const cancelled = await cancelBooking(
      token,
      bookingId,
      'Cambio de planes debido a emergencia familiar'
    );
    
    console.log('Estado:', cancelled.status); // 'cancelled'
    console.log('Razón:', cancelled.cancellationReason);
    
    // Notificar al HOST (en producción, enviar email)
    alert('Reserva cancelada exitosamente');
  } catch (err) {
    alert('Error: ' + err.message);
  }
}
```

### 3. Dashboard de HOST con Estadísticas

```typescript
async function getHostDashboardStats(spaceId: string) {
  const bookings = await getBookingsBySpace(token, spaceId);
  
  const stats = {
    total: bookings.length,
    pending: bookings.filter(b => b.status === 'pending').length,
    confirmed: bookings.filter(b => b.status === 'confirmed').length,
    cancelled: bookings.filter(b => b.status === 'cancelled').length,
    totalRevenue: bookings
      .filter(b => b.status === 'confirmed')
      .reduce((sum, b) => sum + b.totalPrice, 0)
  };
  
  console.log('Estadísticas:', stats);
  return stats;
}
```

### 4. Validar Disponibilidad antes de Crear

```typescript
async function checkAvailability(
  spaceId: string,
  startTs: string,
  endTs: string
): Promise<{ available: boolean; conflictingBookings?: Booking[] }> {
  const bookings = await getBookingsBySpace(token, spaceId);
  
  const activeBookings = bookings.filter(
    b => b.status === 'confirmed' || b.status === 'pending'
  );
  
  const newStart = new Date(startTs);
  const newEnd = new Date(endTs);
  
  const conflicts = activeBookings.filter(booking => {
    const existingStart = new Date(booking.startTs);
    const existingEnd = new Date(booking.endTs);
    return newStart < existingEnd && newEnd > existingStart;
  });
  
  return {
    available: conflicts.length === 0,
    conflictingBookings: conflicts
  };
}

// Uso
const result = await checkAvailability(
  'space-id',
  '2025-12-01T15:00:00',
  '2025-12-01T20:00:00'
);

if (!result.available) {
  alert(`No disponible. Conflictos con ${result.conflictingBookings?.length} reservas`);
} else {
  await createBooking(...);
}
```

---

## Resumen de Conceptos Clave

1. **Estados de reserva**: `pending` → `confirmed` o `cancelled`
2. **Cálculo automático**: `totalPrice` calculado por backend (horas × pricePerHour)
3. **Confirmar reserva**: Requiere `paymentIntentId` (integración con Stripe)
4. **Cancelar reserva**: Requiere `reason` obligatoria
5. **Validación de conflictos**: Backend verifica overlap de fechas
6. **Listado completo**: Endpoint `/space/{id}` devuelve todas las reservas (pending/confirmed/cancelled)
7. **Control de acceso**: Guest ve sus reservas, Host ve reservas de sus espacios

---

## Siguiente Documento

Continuar con: **[FRONTEND_API_GUIDE_PART_4_SEARCH.md](./FRONTEND_API_GUIDE_PART_4_SEARCH.md)** - Búsqueda de Espacios

