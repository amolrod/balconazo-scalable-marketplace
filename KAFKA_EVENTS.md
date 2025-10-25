# Eventos de Kafka - Balconazo

Este documento define el contrato completo de eventos publicados en los tópicos de Kafka. Todos los microservicios productores y consumidores deben adherirse estrictamente a estos schemas.

---

## 📋 Resumen de Tópicos

| Tópico | Key | Eventos | Productor | Consumidores | Particiones | Retención | Compactación |
|--------|-----|---------|-----------|--------------|-------------|-----------|--------------|
| `space.events.v1` | space_id | SpaceCreated, SpaceUpdated, SpaceDeactivated | catalog-service | search-pricing-service | 12 | 14 días | No |
| `availability.events.v1` | space_id | AvailabilityAdded, AvailabilityRemoved, AvailabilityChanged | catalog-service | search-pricing-service | 12 | 14 días | No |
| `booking.events.v1` | booking_id | BookingRequested, BookingHeld, BookingConfirmed, BookingCancelled, BookingExpired | booking-service | search-pricing-service, catalog-service (ratings) | 12 | 14 días | No |
| `payment.events.v1` | booking_id | PaymentIntentCreated, PaymentAuthorized, PaymentCaptured, PaymentFailed, RefundIssued | booking-service | booking-service (self-consume async) | 12 | 14 días | No |
| `review.events.v1` | booking_id | ReviewSubmitted, DisputeOpened, DisputeResolved | booking-service | catalog-service (actualiza ratings) | 12 | 14 días | No |
| `pricing.events.v1` | space_id | PriceRecomputeRequested, PriceUpdated | search-pricing-service | catalog-service (opcional, para admin dashboard) | 12 | 7 días | No |
| `analytics.search.v1` | tile_id | SearchQueryLogged | search-pricing-service | search-pricing-service (Kafka Streams) | 12 | 48 horas | No |

---

## 🔧 Configuración General de Tópicos

### Comandos de Creación (Docker)
```bash
# Crear todos los tópicos con 12 particiones y retención configurada
docker exec -it kafka kafka-topics.sh --create \
  --topic space.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000  # 14 días

docker exec -it kafka kafka-topics.sh --create \
  --topic availability.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

docker exec -it kafka kafka-topics.sh --create \
  --topic booking.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

docker exec -it kafka kafka-topics.sh --create \
  --topic payment.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

docker exec -it kafka kafka-topics.sh --create \
  --topic review.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

docker exec -it kafka kafka-topics.sh --create \
  --topic pricing.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=604800000  # 7 días

docker exec -it kafka kafka-topics.sh --create \
  --topic analytics.search.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=172800000  # 48 horas
```

### Dead Letter Topics (DLT)
Cada tópico debe tener su DLT correspondiente para eventos que fallan tras retries:
```bash
docker exec -it kafka kafka-topics.sh --create \
  --topic space.events.v1.DLT \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=2592000000  # 30 días (más largo para investigación)

# Repetir para: availability.events.v1.DLT, booking.events.v1.DLT, etc.
```

---

## 📨 Schemas de Eventos

### Estructura Común (Headers + Metadata)

Todos los eventos incluyen estos campos obligatorios:

```json
{
  "eventId": "uuid-único-del-evento",
  "eventType": "TipoDelEvento",
  "version": 1,
  "occurredAt": "2025-10-25T19:30:00.123Z",
  "metadata": {
    "source": "nombre-del-servicio-productor",
    "traceId": "correlacion-para-tracing-distribuido",
    "correlationId": "id-de-correlacion-de-request-original",
    "userId": "uuid-del-usuario-que-origino-la-accion"
  },
  // ... campos específicos del evento
}
```

**Headers Kafka (adicionales al payload):**
```
Key: {aggregate_id}  (ej: space_id, booking_id)
Headers:
  - event-type: TipoDelEvento
  - event-version: 1
  - occurred-at: 2025-10-25T19:30:00.123Z
  - trace-id: correlacion-id
```

---

## 1️⃣ space.events.v1

### SpaceCreated

**Cuándo:** Un host publica un nuevo espacio en el catálogo.

**Productor:** catalog-service  
**Consumidores:** search-pricing-service (crea proyección), analytics (opcional)

**Schema JSON:**
```json
{
  "eventId": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
  "eventType": "SpaceCreated",
  "version": 1,
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "ownerId": "e5f6g7h8-9012-3456-7890-abcd12345678",
  "title": "Terraza con vistas al Retiro",
  "capacity": 15,
  "basePriceCents": 3500,
  "address": "Calle Alcalá 123, Madrid",
  "lat": 40.4168,
  "lon": -3.7038,
  "rules": {
    "noSmoking": true,
    "maxNoise": "moderate",
    "petsAllowed": false
  },
  "status": "active",
  "occurredAt": "2025-10-25T19:30:00.123Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "7c8e9d0a-1234-5678-90ab-cdef11111111",
    "correlationId": "b2c3d4e5-5678-9012-3456-789012345678",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

**Campos Obligatorios:**
- `eventId`, `eventType`, `version`, `spaceId`, `ownerId`, `title`, `capacity`, `basePriceCents`, `lat`, `lon`, `status`, `occurredAt`, `metadata`

**Valores Permitidos:**
- `status`: `"draft" | "active" | "snoozed"`
- `capacity`: entero > 0
- `basePriceCents`: entero >= 0
- `lat`: -90 a 90, `lon`: -180 a 180

---

### SpaceUpdated

**Cuándo:** Un host edita detalles de un espacio existente (título, capacidad, precio, etc.).

**Schema JSON:**
```json
{
  "eventId": "b2c3d4e5-f6g7-4890-ab12-3456789abcde",
  "eventType": "SpaceUpdated",
  "version": 1,
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "ownerId": "e5f6g7h8-9012-3456-7890-abcd12345678",
  "changedFields": {
    "title": "Terraza Premium con vistas al Retiro",
    "capacity": 20,
    "basePriceCents": 4200
  },
  "occurredAt": "2025-10-26T10:15:00.456Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "8d9e0f1a-2345-6789-01bc-def222222222",
    "correlationId": "c3d4e5f6-6789-0123-4567-890123456789",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

**Notas:**
- `changedFields` es un objeto con solo los campos modificados (delta).
- Consumidores deben aplicar merge con datos existentes.

---

### SpaceDeactivated

**Cuándo:** Un host desactiva temporalmente (snoozed) o permanentemente un espacio.

**Schema JSON:**
```json
{
  "eventId": "c3d4e5f6-g7h8-4901-bc23-456789abcdef",
  "eventType": "SpaceDeactivated",
  "version": 1,
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "ownerId": "e5f6g7h8-9012-3456-7890-abcd12345678",
  "status": "snoozed",
  "reason": "Renovations scheduled for December",
  "occurredAt": "2025-11-01T08:00:00.000Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "9e0f1a2b-3456-7890-12cd-ef3333333333",
    "correlationId": "d4e5f6g7-7890-1234-5678-901234567890",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

**Valores Permitidos:**
- `status`: `"snoozed"` (temporal) | `"deleted"` (permanente, soft delete)
- `reason`: string opcional (max 500 chars)

---

## 2️⃣ availability.events.v1

### AvailabilityAdded

**Cuándo:** Un host añade nuevos slots de disponibilidad a un espacio.

**Productor:** catalog-service  
**Consumidores:** search-pricing-service (actualiza disponibilidad en proyección)

**Schema JSON:**
```json
{
  "eventId": "d4e5f6g7-h8i9-5012-cd34-56789abcdef0",
  "eventType": "AvailabilityAdded",
  "version": 1,
  "slotId": "a9b8c7d6-5432-1098-fedc-ba9876543210",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "maxGuests": 15,
  "occurredAt": "2025-10-25T20:00:00.789Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "0f1a2b3c-4567-8901-23de-f44444444444",
    "correlationId": "e5f6g7h8-8901-2345-6789-012345678901",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

**Campos Obligatorios:**
- `slotId`, `spaceId`, `startTs`, `endTs`, `maxGuests`

**Validaciones:**
- `endTs` > `startTs`
- `maxGuests` <= `space.capacity`
- Formato ISO 8601 UTC para timestamps

---

### AvailabilityRemoved

**Cuándo:** Un host elimina slots (ej: por mantenimiento, bloqueo personal).

**Schema JSON:**
```json
{
  "eventId": "e5f6g7h8-i9j0-6123-de45-6789abcdef12",
  "eventType": "AvailabilityRemoved",
  "version": 1,
  "slotId": "a9b8c7d6-5432-1098-fedc-ba9876543210",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "reason": "Host personal use",
  "occurredAt": "2025-11-15T14:30:00.000Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "1a2b3c4d-5678-9012-34ef-555555555555",
    "correlationId": "f6g7h8i9-9012-3456-7890-123456789012",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

---

### AvailabilityChanged

**Cuándo:** Un host modifica detalles de un slot existente (ej: cambia maxGuests, ajusta horario).

**Schema JSON:**
```json
{
  "eventId": "f6g7h8i9-j0k1-7234-ef56-789abcdef123",
  "eventType": "AvailabilityChanged",
  "version": 1,
  "slotId": "a9b8c7d6-5432-1098-fedc-ba9876543210",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "changedFields": {
    "endTs": "2026-01-01T08:00:00Z",
    "maxGuests": 20
  },
  "occurredAt": "2025-11-20T09:00:00.000Z",
  "metadata": {
    "source": "catalog-service",
    "traceId": "2b3c4d5e-6789-0123-45f0-666666666666",
    "correlationId": "g7h8i9j0-0123-4567-8901-234567890123",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

---

## 3️⃣ booking.events.v1

### BookingRequested

**Cuándo:** Un guest inicia el proceso de reserva (antes de hold, para analytics).

**Productor:** booking-service  
**Consumidores:** analytics-service (futuro), search-pricing-service (input para demanda)

**Schema JSON:**
```json
{
  "eventId": "g7h8i9j0-k1l2-8345-fg67-89abcdef1234",
  "eventType": "BookingRequested",
  "version": 1,
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "requestedGuests": 12,
  "occurredAt": "2025-10-25T21:00:00.111Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "3c4d5e6f-7890-1234-56g1-777777777777",
    "correlationId": "h8i9j0k1-1234-5678-9012-345678901234",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

---

### BookingHeld

**Cuándo:** La reserva pasa validaciones y queda en estado `held` con lock Redis (TTL 10 min).

**Schema JSON:**
```json
{
  "eventId": "h8i9j0k1-l2m3-9456-gh78-9abcdef12345",
  "eventType": "BookingHeld",
  "version": 1,
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "priceCents": 4200,
  "depositCents": 0,
  "status": "held",
  "expiresAt": "2025-10-25T21:10:00.000Z",
  "occurredAt": "2025-10-25T21:00:00.222Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "4d5e6f7g-8901-2345-67h2-888888888888",
    "correlationId": "i9j0k1l2-2345-6789-0123-456789012345",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

**Campos Importantes:**
- `expiresAt`: Timestamp UTC de expiración del hold (now + 10 min)
- `priceCents`: Precio calculado por search-pricing (desde Redis o DB)
- `depositCents`: Depósito requerido (si aplica, 0 por defecto en MVP)

---

### BookingConfirmed

**Cuándo:** El guest confirma la reserva y el pago es capturado exitosamente.

**Schema JSON:**
```json
{
  "eventId": "i9j0k1l2-m3n4-0567-hi89-abcdef123456",
  "eventType": "BookingConfirmed",
  "version": 1,
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "priceCents": 4200,
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "status": "confirmed",
  "confirmedAt": "2025-10-25T21:05:00.000Z",
  "occurredAt": "2025-10-25T21:05:00.333Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "5e6f7g8h-9012-3456-78i3-999999999999",
    "correlationId": "j0k1l2m3-3456-7890-1234-567890123456",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

**Impacto:**
- search-pricing actualiza demanda (confirmación cuenta más que hold en scoring)
- catalog-service puede enviar notificación al host
- Lock Redis es liberado

---

### BookingCancelled

**Cuándo:** 
- Payment falla tras hold
- Guest cancela explícitamente
- Host cancela por fuerza mayor

**Schema JSON:**
```json
{
  "eventId": "j0k1l2m3-n4o5-1678-ij90-bcdef1234567",
  "eventType": "BookingCancelled",
  "version": 1,
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "previousStatus": "held",
  "reason": "payment_failed",
  "cancelledBy": "system",
  "occurredAt": "2025-10-25T21:03:00.444Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "6f7g8h9i-0123-4567-89j4-aaaaaaaaaaaa",
    "correlationId": "k1l2m3n4-4567-8901-2345-678901234567",
    "userId": "system"
  }
}
```

**Valores Permitidos:**
- `reason`: `"payment_failed" | "guest_cancellation" | "host_cancellation" | "policy_violation"`
- `cancelledBy`: `"guest" | "host" | "admin" | "system"`

---

### BookingExpired

**Cuándo:** El hold TTL expira sin confirmación (worker ejecuta cada 30s).

**Schema JSON:**
```json
{
  "eventId": "k1l2m3n4-o5p6-2789-jk01-cdef12345678",
  "eventType": "BookingExpired",
  "version": 1,
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "heldAt": "2025-10-25T21:00:00.222Z",
  "expiredAt": "2025-10-25T21:10:05.000Z",
  "occurredAt": "2025-10-25T21:10:05.555Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "7g8h9i0j-1234-5678-90k5-bbbbbbbbbbbb",
    "correlationId": "l2m3n4o5-5678-9012-3456-789012345678",
    "userId": "system"
  }
}
```

---

## 4️⃣ payment.events.v1

### PaymentIntentCreated

**Cuándo:** Tras crear booking held, se genera un payment intent en la pasarela (Stripe mock).

**Productor:** booking-service  
**Consumidores:** booking-service (self-consume para orquestar siguiente paso)

**Schema JSON:**
```json
{
  "eventId": "l2m3n4o5-p6q7-3890-kl12-def123456789",
  "eventType": "PaymentIntentCreated",
  "version": 1,
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "amountCents": 4200,
  "currency": "EUR",
  "status": "requires_authorization",
  "occurredAt": "2025-10-25T21:00:01.000Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "8h9i0j1k-2345-6789-01l6-cccccccccccc",
    "correlationId": "m3n4o5p6-6789-0123-4567-890123456789",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

---

### PaymentAuthorized

**Cuándo:** La pasarela autoriza el pago (pre-auth exitosa).

**Schema JSON:**
```json
{
  "eventId": "m3n4o5p6-q7r8-4901-lm23-ef1234567890",
  "eventType": "PaymentAuthorized",
  "version": 1,
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "amountCents": 4200,
  "authorizationCode": "AUTH-123456",
  "occurredAt": "2025-10-25T21:00:03.000Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "9i0j1k2l-3456-7890-12m7-dddddddddddd",
    "correlationId": "n4o5p6q7-7890-1234-5678-901234567890",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

---

### PaymentCaptured

**Cuándo:** El guest confirma la reserva y el pago es capturado (charge final).

**Schema JSON:**
```json
{
  "eventId": "n4o5p6q7-r8s9-5012-mn34-f12345678901",
  "eventType": "PaymentCaptured",
  "version": 1,
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "amountCents": 4200,
  "capturedAt": "2025-10-25T21:05:00.000Z",
  "occurredAt": "2025-10-25T21:05:00.111Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "0j1k2l3m-4567-8901-23n8-eeeeeeeeeeee",
    "correlationId": "o5p6q7r8-8901-2345-6789-012345678901",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

---

### PaymentFailed

**Cuándo:** La autorización/captura falla (tarjeta rechazada, fondos insuficientes).

**Schema JSON:**
```json
{
  "eventId": "o5p6q7r8-s9t0-6123-no45-123456789012",
  "eventType": "PaymentFailed",
  "version": 1,
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "amountCents": 4200,
  "errorCode": "card_declined",
  "errorMessage": "Your card was declined",
  "failedAt": "2025-10-25T21:00:04.000Z",
  "occurredAt": "2025-10-25T21:00:04.222Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "1k2l3m4n-5678-9012-34o9-ffffffffffff",
    "correlationId": "p6q7r8s9-9012-3456-7890-123456789012",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

**Valores Comunes de errorCode:**
- `card_declined`, `insufficient_funds`, `expired_card`, `processing_error`, `authentication_required`

---

### RefundIssued

**Cuándo:** Cancelación post-confirmación con política de reembolso aplicable.

**Schema JSON:**
```json
{
  "eventId": "p6q7r8s9-t0u1-7234-op56-234567890123",
  "eventType": "RefundIssued",
  "version": 1,
  "refundId": "re_3XyzAbcDefGhijk",
  "paymentIntentId": "pi_3AbcDefGhiJklMno",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "amountCents": 4200,
  "reason": "guest_cancellation_within_policy",
  "issuedAt": "2025-12-15T10:00:00.000Z",
  "occurredAt": "2025-12-15T10:00:00.333Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "2l3m4n5o-6789-0123-45p0-000000000000",
    "correlationId": "q7r8s9t0-0123-4567-8901-234567890123",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

---

## 5️⃣ review.events.v1

### ReviewSubmitted

**Cuándo:** Post-estancia, guest o host deja una review (rating + texto).

**Productor:** booking-service  
**Consumidores:** catalog-service (actualiza rating agregado de space/user)

**Schema JSON:**
```json
{
  "eventId": "q7r8s9t0-u1v2-8345-pq67-345678901234",
  "eventType": "ReviewSubmitted",
  "version": 1,
  "reviewId": "r1s2t3u4-5678-9012-3456-789012345678",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "authorId": "h8i9j0k1-2345-6789-0123-456789012345",
  "targetUserId": "e5f6g7h8-9012-3456-7890-abcd12345678",
  "targetType": "host",
  "rating": 5,
  "text": "Amazing terrace, perfect for our New Year celebration!",
  "occurredAt": "2026-01-02T12:00:00.000Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "3m4n5o6p-7890-1234-56q1-111111111111",
    "correlationId": "r8s9t0u1-1234-5678-9012-345678901234",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

**Campos:**
- `targetType`: `"host" | "guest" | "space"`
- `rating`: 1-5 (entero)
- `text`: string opcional (max 2000 chars)

---

### DisputeOpened

**Cuándo:** Guest o host abre una disputa (daños, comportamiento inapropiado, etc.).

**Schema JSON:**
```json
{
  "eventId": "r8s9t0u1-v2w3-9456-qr78-456789012345",
  "eventType": "DisputeOpened",
  "version": 1,
  "disputeId": "d1e2f3g4-5678-9012-3456-789012345678",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "reporterId": "e5f6g7h8-9012-3456-7890-abcd12345678",
  "reportedId": "h8i9j0k1-2345-6789-0123-456789012345",
  "category": "property_damage",
  "description": "Guest left significant damage to outdoor furniture",
  "evidenceUrls": [
    "https://s3.amazonaws.com/balconazo/evidence/d1e2f3g4/photo1.jpg",
    "https://s3.amazonaws.com/balconazo/evidence/d1e2f3g4/photo2.jpg"
  ],
  "occurredAt": "2026-01-02T18:00:00.000Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "4n5o6p7q-8901-2345-67r2-222222222222",
    "correlationId": "s9t0u1v2-2345-6789-0123-456789012345",
    "userId": "e5f6g7h8-9012-3456-7890-abcd12345678"
  }
}
```

**Categorías:**
- `property_damage`, `noise_complaint`, `unauthorized_guests`, `cleaning_issues`, `payment_dispute`

---

### DisputeResolved

**Cuándo:** Admin cierra la disputa con decisión (favor guest/host, parcial, etc.).

**Schema JSON:**
```json
{
  "eventId": "s9t0u1v2-w3x4-0567-rs89-567890123456",
  "eventType": "DisputeResolved",
  "version": 1,
  "disputeId": "d1e2f3g4-5678-9012-3456-789012345678",
  "bookingId": "1a2b3c4d-5678-9012-3456-789012345678",
  "resolution": "favor_host",
  "compensationCents": 15000,
  "adminNotes": "Evidence supports host claim. Guest charged for damages.",
  "resolvedAt": "2026-01-05T14:00:00.000Z",
  "occurredAt": "2026-01-05T14:00:00.444Z",
  "metadata": {
    "source": "booking-service",
    "traceId": "5o6p7q8r-9012-3456-78s3-333333333333",
    "correlationId": "t0u1v2w3-3456-7890-1234-567890123456",
    "userId": "admin-user-uuid"
  }
}
```

**Valores resolution:**
- `favor_guest`, `favor_host`, `partial_guest`, `partial_host`, `no_fault`, `cancelled`

---

## 6️⃣ pricing.events.v1

### PriceRecomputeRequested

**Cuándo:** Admin o sistema programa recálculo manual de precios (ej: cambio en algoritmo).

**Productor:** search-pricing-service (admin endpoint)  
**Consumidores:** search-pricing-service (Kafka Streams o worker)

**Schema JSON:**
```json
{
  "eventId": "t0u1v2w3-x4y5-1678-st90-678901234567",
  "eventType": "PriceRecomputeRequested",
  "version": 1,
  "scope": "all",
  "spaceIds": [],
  "timeslotRange": {
    "start": "2025-11-01T00:00:00Z",
    "end": "2026-01-31T23:59:59Z"
  },
  "occurredAt": "2025-10-26T08:00:00.000Z",
  "metadata": {
    "source": "search-pricing-service",
    "traceId": "6p7q8r9s-0123-4567-89t4-444444444444",
    "correlationId": "u1v2w3x4-4567-8901-2345-678901234567",
    "userId": "admin-user-uuid"
  }
}
```

**Valores scope:**
- `"all"`: Todos los espacios
- `"specific"`: Solo `spaceIds` especificados
- `"region"`: Por bounding box geográfico (futuro)

---

### PriceUpdated

**Cuándo:** Kafka Streams recalcula precio dinámico por slot basado en demanda.

**Schema JSON:**
```json
{
  "eventId": "u1v2w3x4-y5z6-2789-tu01-789012345678",
  "eventType": "PriceUpdated",
  "version": 1,
  "spaceId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "timeslotStart": "2025-12-31T22:00:00Z",
  "priceCents": 4200,
  "basePriceCents": 3500,
  "multiplier": 1.20,
  "demandScore": 0.75,
  "factors": {
    "searches": 45,
    "holds": 8,
    "bookings": 3,
    "tileId": "tile_40.41_-3.70"
  },
  "occurredAt": "2025-10-25T21:30:00.000Z",
  "metadata": {
    "source": "search-pricing-service",
    "traceId": "7q8r9s0t-1234-5678-90u5-555555555555",
    "correlationId": "v2w3x4y5-5678-9012-3456-789012345678",
    "userId": "system"
  }
}
```

**Campos:**
- `multiplier`: Factor aplicado a `basePriceCents` (rango [1.0–2.5])
- `demandScore`: Score normalizado 0-1 basado en `factors`
- `factors`: Métricas utilizadas en el cálculo (transparencia para auditoría)

---

## 7️⃣ analytics.search.v1

### SearchQueryLogged

**Cuándo:** Cada búsqueda geoespacial ejecutada por un usuario.

**Productor:** search-pricing-service  
**Consumidores:** search-pricing-service (Kafka Streams para demanda), analytics (futuro)

**Schema JSON:**
```json
{
  "eventId": "v2w3x4y5-z6a7-3890-uv12-890123456789",
  "eventType": "SearchQueryLogged",
  "version": 1,
  "queryId": "q1w2e3r4-5678-9012-3456-789012345678",
  "userId": "h8i9j0k1-2345-6789-0123-456789012345",
  "lat": 40.4168,
  "lon": -3.7038,
  "radiusMeters": 5000,
  "capacity": 10,
  "dateRange": {
    "start": "2025-12-31T22:00:00Z",
    "end": "2026-01-01T06:00:00Z"
  },
  "filters": {
    "maxPriceCents": 5000,
    "amenities": ["wifi", "outdoor_speakers"]
  },
  "resultsCount": 12,
  "tileId": "tile_40.41_-3.70",
  "occurredAt": "2025-10-25T21:15:00.000Z",
  "metadata": {
    "source": "search-pricing-service",
    "traceId": "8r9s0t1u-2345-6789-01v6-666666666666",
    "correlationId": "w3x4y5z6-6789-0123-4567-890123456789",
    "userId": "h8i9j0k1-2345-6789-0123-456789012345"
  }
}
```

**Campos:**
- `tileId`: Identificador de celda geoespacial (ej: H3, S2, o custom grid)
- `resultsCount`: Número de espacios devueltos en response
- `filters`: Objeto opcional con filtros adicionales aplicados

**Uso en Kafka Streams:**
- Ventana tumbling 5 min por `tileId`
- Agrega count de searches → `demandScore` por tile
- Join con bookings del mismo tile para scoring final

---

## 🔒 Políticas de Idempotencia

Todos los consumidores **DEBEN** implementar idempotencia para manejar duplicados (Kafka garantiza at-least-once):

### Opción 1: Tabla processed_events
```sql
CREATE TABLE processed_events (
    event_id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_processed_events_aggregate ON processed_events(aggregate_id, event_type);
```

**Lógica en consumidor:**
```java
@KafkaListener(topics = "space.events.v1")
public void onSpaceEvent(ConsumerRecord<String, String> record) {
    var event = parseEvent(record.value());
    
    if (processedEventRepository.existsById(event.eventId())) {
        log.debug("Event {} already processed, skipping", event.eventId());
        return;
    }
    
    processEvent(event);
    processedEventRepository.save(new ProcessedEvent(event.eventId(), event.spaceId(), event.eventType()));
}
```

### Opción 2: Unique constraint en aggregate
Si el evento modifica un agregado con campo único (ej: `space_id`), usar UPSERT:
```java
spaceProjectionRepository.upsert(projection);  // ON CONFLICT DO UPDATE
```

---

## 📊 Monitoreo de Tópicos

### Métricas Clave por Tópico

| Métrica | Umbral de Alerta | Acción |
|---------|------------------|--------|
| **Lag del consumidor** | >10,000 mensajes | Escalar réplicas del consumer |
| **Mensajes en DLT** | >100 en 1 hora | Investigar errores, corregir consumidor |
| **Throughput** | <100 msg/s (bajo demanda) | Verificar productores, revisar outbox publisher |
| **Retención alcanzada** | Mensajes >14 días | Ajustar retención o limpiar históricos |

### Comandos de Monitoreo
```bash
# Ver lag por consumer group
kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group search-pricing-consumer

# Contar mensajes en tópico
kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic booking.events.v1 --time -1

# Consumir últimos 10 mensajes de DLT
kafka-console-consumer --bootstrap-server localhost:9092 \
  --topic booking.events.v1.DLT \
  --from-beginning \
  --max-messages 10 \
  --property print.timestamp=true
```

---

## 🚀 Versionado de Eventos

Cuando necesites cambiar un evento (ej: añadir campo):

1. **Backward compatible (minor):** Añade campo opcional, incrementa `version: 2`.
   - Consumidores v1 ignoran campo nuevo
   - Productores emiten `version: 2`

2. **Breaking change (major):** Crea nuevo tópico `booking.events.v2`.
   - Migra consumidores gradualmente
   - Mantén productores emitiendo a ambos tópicos durante transición
   - Depreca v1 tras 6 meses

**Ejemplo (backward compatible):**
```json
{
  "eventType": "BookingConfirmed",
  "version": 2,  // Incrementado
  "bookingId": "...",
  // ... campos existentes
  "loyaltyPointsEarned": 42  // NUEVO campo opcional
}
```

---

**Última actualización:** 25 de octubre de 2025  
**Mantenido por:** Equipo de Backend Balconazo


