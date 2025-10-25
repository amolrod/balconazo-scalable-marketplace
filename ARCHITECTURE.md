# Arquitectura de Balconazo

Este documento describe las decisiones arquitectónicas, patrones implementados y flujos de datos del sistema Balconazo.

---

## 📐 Diagrama C4 - Nivel 2 (Contenedores)

```
                                    ┌─────────────────────────────────┐
                                    │   Usuario Final (Guest/Host)    │
                                    │   (Navegador Web / Mobile)      │
                                    └────────────────┬────────────────┘
                                                     │ HTTPS + JWT
                                                     ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                 FRONTEND LAYER                                       │
│  ┌────────────────────────────────────────────────────────────────────────────┐     │
│  │  Angular 20 SPA :4200                                                      │     │
│  │  • Standalone Components + Signals                                         │     │
│  │  • Tailwind CSS                                                            │     │
│  │  • HttpClient + JWT Interceptor                                            │     │
│  │  • Services: SearchService, BookingService, AuthService                    │     │
│  └────────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────┬───────────────────────────────────────────┘
                                           │ HTTP
                                           ↓
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY LAYER                                       │
│  ┌────────────────────────────────────────────────────────────────────────────┐     │
│  │  Spring Cloud Gateway :8080                                                │     │
│  │  • JWT Validation (Keycloak JWKs)                                          │     │
│  │  • Rate Limiting (RedisRateLimiter → 100 req/min/user)                     │     │
│  │  • CORS Configuration                                                      │     │
│  │  • Request Routing:                                                        │     │
│  │    /api/catalog/**     → catalog-service:8081                              │     │
│  │    /api/bookings/**    → booking-service:8082                              │     │
│  │    /api/search/**      → search-pricing-service:8083                       │     │
│  │  • Correlation ID injection (X-Correlation-Id)                             │     │
│  └────────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────┬───────────────────────────────────────────┘
                                           │
            ┌──────────────────────────────┼──────────────────────────────┐
            │                              │                              │
            ↓                              ↓                              ↓
┌───────────────────────┐      ┌───────────────────────┐      ┌────────────────────────┐
│ CATALOG SERVICE :8081 │      │ BOOKING SERVICE :8082 │      │ SEARCH-PRICING :8083   │
│                       │      │                       │      │                        │
│ Bounded Context:      │      │ Bounded Context:      │      │ Bounded Context:       │
│ • Identity & Trust    │      │ • Reservations        │      │ • Search               │
│ • Spaces Catalog      │      │ • Payments            │      │ • Dynamic Pricing      │
│ • Availability        │      │ • Reviews & Disputes  │      │                        │
│                       │      │ • Notifications       │      │ Read Model (CQRS)      │
│ Layers:               │      │                       │      │                        │
│ • domain/             │      │ Layers:               │      │ Layers:                │
│ • application/        │      │ • domain/             │      │ • domain/              │
│ • infrastructure/     │      │ • application/        │      │ • application/         │
│ • interfaces/         │      │ • infrastructure/     │      │ • infrastructure/      │
│                       │      │ • interfaces/         │      │   - Kafka Streams      │
│ Publica:              │      │                       │      │   - PostGIS queries    │
│ • space.events.v1     │      │ Publica:              │      │ • interfaces/          │
│ • availability.v1     │      │ • booking.events.v1   │      │                        │
│                       │      │ • payment.events.v1   │      │ Consume:               │
│                       │      │ • review.events.v1    │      │ • space.events.v1      │
│                       │      │                       │      │ • availability.v1      │
│                       │      │ Consume:              │      │ • booking.events.v1    │
│                       │      │ • payment.events.v1   │      │                        │
│                       │      │   (propio, async)     │      │ Publica:               │
│                       │      │                       │      │ • pricing.events.v1    │
│                       │      │                       │      │ • analytics.search.v1  │
└──────────┬────────────┘      └──────────┬────────────┘      └───────────┬────────────┘
           │                              │                               │
           ↓                              ↓                               ↓
    ┌────────────┐              ┌────────────────┐               ┌─────────────┐
    │PostgreSQL  │              │ PostgreSQL     │               │ PostgreSQL  │
    │:5433       │              │ :5434          │               │ :5435       │
    │            │              │                │               │ (PostGIS)   │
    │catalog_db  │              │ booking_db     │               │             │
    │            │              │                │               │ search_db   │
    │Schema:     │              │ Schema:        │               │             │
    │• users     │              │ • bookings     │               │ Schema:     │
    │• spaces    │              │ • reviews      │               │ • spaces_   │
    │• avail_    │              │ • outbox       │               │   projection│
    │  slots     │              │ • processed_   │               │ • price_    │
    │            │              │   events       │               │   surface   │
    │            │              │                │               │ • demand_agg│
    └────────────┘              └────────────────┘               └─────────────┘
           │                              │                               │
           └──────────────────────────────┼───────────────────────────────┘
                                          │
                                          ↓
           ┌──────────────────────────────────────────────────────────────┐
           │              APACHE KAFKA :29092 (Bitnami)                   │
           │                                                              │
           │  Tópicos (12 particiones c/u, retención 7-14 días):         │
           │  • space.events.v1                                           │
           │  • availability.events.v1                                    │
           │  • booking.events.v1                                         │
           │  • payment.events.v1                                         │
           │  • review.events.v1                                          │
           │  • pricing.events.v1                                         │
           │  • analytics.search.v1                                       │
           │                                                              │
           │  Formato: JSON + headers (traceId, correlationId, eventType) │
           │  Idempotencia: event_id único en payload                     │
           │  DLT: *.DLT por cada tópico                                  │
           └──────────────────────────────────────────────────────────────┘
                                          │
                                          ↓
                                 ┌─────────────────┐
                                 │  REDIS :6379    │
                                 │                 │
                                 │  Keys:          │
                                 │  • lock:booking:│
                                 │    {space}:{ts} │
                                 │    (TTL 10 min) │
                                 │                 │
                                 │  • price:{space}│
                                 │    :{slot}      │
                                 │    (TTL 15 min) │
                                 │                 │
                                 │  • ratelimit:   │
                                 │    {user}:{win} │
                                 │                 │
                                 │  • search:hot:  │
                                 │    {bbox}:{date}│
                                 │    (TTL 60-180s)│
                                 └─────────────────┘
```

---

## 🎯 Decisiones Arquitectónicas (ADRs)

### ADR-001: ¿Por qué EXACTAMENTE 3 microservicios?

**Contexto:**
Teníamos 8 bounded contexts originales (Identidad, Catálogo, Búsqueda, Precios, Reservas, Pagos, Reputación, Notificaciones). Necesitábamos encontrar el balance entre:
- **Complejidad operacional:** Más servicios = más despliegues, logs, monitoreo
- **Cohesión de dominios:** Agrupar contextos con acoplamiento natural
- **Independencia de escalado:** Separar read-heavy (búsqueda) de write-heavy (booking)

**Decisión:**
Redistribuir en **3 microservicios**:

1. **catalog-service** (Identidad + Catálogo + Availability)
   - **Justificación:** El host y su inventario están naturalmente acoplados. Compartir transacciones simplifica invariantes como "un espacio solo puede ser publicado por su dueño" y permite emitir eventos consistentes (`SpaceCreated` + `AvailabilityAdded`) en la misma transacción.
   - **Ventaja:** Menor complejidad de coreografía en el camino crítico de publicación de espacios.

2. **booking-service** (Reservas + Pagos + Reviews + Notificaciones)
   - **Justificación:** La saga de reserva requiere consistencia estricta entre booking, payment capture y habilitación de reviews. Tenerlos en el mismo servicio permite orquestación centralizada con rollback controlado.
   - **Ventaja:** Transacciones ACID en flujos críticos (money + confirmación), menor latencia al evitar round-trips entre servicios.

3. **search-pricing-service** (Búsqueda + Precios)
   - **Justificación:** El precio efectivo **forma parte del read-model de búsqueda**. Precalcular y servir desde el mismo servicio reduce latencia a <100-200ms P95.
   - **Ventaja:** Escalado horizontal independiente del write-model, permite añadir verticales (PoolNazo) reutilizando catalog + booking mientras search solo indexa nuevo tipo.

**Consecuencias:**
- ✅ 3 servicios son manejables operacionalmente (vs 8 servicios con overhead de infra)
- ✅ Fronteras estables con bajo acoplamiento
- ✅ Permite añadir nuevos bounded contexts sin reestructurar (ej: Analytics como 4to servicio)
- ⚠️ catalog-service agrupa Identity + Catalog, si Identity crece mucho puede requerir split futuro

**Simplificaciones MVP aplicadas (sin sacrificar arquitectura):**
- ✅ Auth JWT simple en Gateway (vs IdP externo) → -1 semana desarrollo
- ✅ Pricing con scheduler (vs Kafka Streams) → -2 semanas desarrollo
- ✅ Ver [docs/MVP_STATUS.md](../docs/MVP_STATUS.md) para detalles completos

**Alternativas consideradas:**
- **1 monolito modular:** Rechazado por limitar escalado independiente y despliegues
- **8 microservicios (1:1 bounded context):** Rechazado por complejidad operacional excesiva para MVP
- **2 microservicios (write + read):** Rechazado porque agrupa domains con diferentes SLAs (catalog vs booking)

---

### ADR-002: ¿Por qué Orquestación en vez de Coreografía para Booking Saga?

**Contexto:**
La saga de reserva tiene múltiples pasos:
1. Validar disponibilidad
2. Crear booking en estado `held`
3. Generar payment intent
4. Autorizar pago (pasarela externa)
5. Capturar pago
6. Confirmar booking
7. Liberar lock Redis

Con compensaciones en caso de fallo (cancel booking, refund payment).

**Decisión:**
Implementar **saga orquestada** con `BookingSaga` como coordinador central en `booking-service`.

**Justificación:**
- **Consistencia crítica:** Booking + Payment son transacciones monetarias que requieren visibilidad centralizada del estado completo.
- **Rollback controlado:** La compensación (cancel + refund) es compleja y requiere coordinación estricta. Un orquestador facilita rastrear en qué paso falló.
- **Debugging:** Con orquestación, el flujo completo está en los logs de `BookingSaga`. En coreografía, el flujo emerge de múltiples consumidores y es difícil rastrear.
- **Timeouts:** El orquestador puede implementar TTL (10 min para `held`) con worker de expiry centralizado.

**Implementación:**
```java
// booking-service/application/service/BookingSaga.java
@Service
public class BookingSaga {
    public BookingDto executeBooking(CreateBookingCommand cmd) {
        // 1. Lock Redis
        redisLock.acquire(cmd.spaceId(), cmd.timeRange());
        
        // 2. Create booking (held)
        var booking = bookingRepository.save(Booking.createHeld(cmd));
        outbox.publish(new BookingHeld(booking));
        
        // 3. Create payment intent
        var paymentIntent = paymentGateway.createIntent(booking.priceCents());
        outbox.publish(new PaymentIntentCreated(booking.id(), paymentIntent.id()));
        
        // 4. Autorizar (async via PaymentEventConsumer)
        // 5-7. Confirm endpoint + worker expiry
        
        return mapper.toDto(booking);
    }
    
    @Transactional
    public void handlePaymentAuthorized(PaymentAuthorizedEvent evt) {
        // Mantener en held, esperar confirm del cliente
    }
    
    @Transactional
    public void handlePaymentFailed(PaymentFailedEvent evt) {
        // Compensate: cancel booking + release lock
        var booking = bookingRepository.findById(evt.bookingId());
        booking.cancel();
        redisLock.release(booking.spaceId(), booking.timeRange());
        outbox.publish(new BookingCancelled(booking));
    }
}
```

**Consecuencias:**
- ✅ Estado del flujo fácil de rastrear (tabla bookings.status)
- ✅ Compensaciones controladas en un solo lugar
- ✅ Menor latencia que coreografía multi-hop
- ⚠️ Acoplamiento: todo en booking-service (pero es el bounded context correcto)
- ⚠️ Single point of failure (mitigado con HA: 2 replicas en prod)

**Alternativas consideradas:**
- **Coreografía pura:** Rechazado por complejidad de debugging y compensación distribuida
- **Saga framework (Axon, Eventuate):** Rechazado para MVP, overhead de nueva tecnología

---

### ADR-003: ¿Por qué Outbox Pattern?

**Contexto:**
Necesitamos garantizar que cuando se persiste un cambio en la DB (ej: nuevo booking), el evento correspondiente **siempre** se publique a Kafka, sin posibilidad de:
- Escribir en DB pero fallar en Kafka → inconsistencia (booking creado pero ningún servicio se entera)
- Publicar a Kafka pero fallar en DB → evento de entidad inexistente

**Decisión:**
Implementar **Outbox Pattern** con tabla `outbox` en cada base de datos transaccional (catalog_db, booking_db).

**Flujo:**
```
1. API Request (POST /bookings)
         ↓
2. @Transactional method
   ├─ INSERT INTO booking.bookings (status='held', ...)
   └─ INSERT INTO booking.outbox (event_type='BookingHeld', payload={...}, published=false)
         ↓
3. COMMIT (atomicidad DB garantizada)
         ↓
4. OutboxPublisher (@Scheduled cada 500ms)
   ├─ SELECT * FROM outbox WHERE published=false ORDER BY occurred_at LIMIT 100
   ├─ FOR EACH event:
   │    ├─ kafkaTemplate.send(topic, event)
   │    └─ UPDATE outbox SET published=true WHERE id=event.id
   └─ (Si Kafka falla, el evento queda en outbox y se reintenta)
```

**Implementación (extracto):**
```java
// domain/model/Outbox.java
@Entity
@Table(name = "outbox", schema = "booking")
public class Outbox {
    @Id private UUID id;
    private UUID aggregateId;
    private String eventType;
    @Column(columnDefinition = "jsonb") private String payload;
    private Instant occurredAt;
    private Boolean published;
}

// application/service/OutboxPublisher.java
@Service
public class OutboxPublisher {
    @Scheduled(fixedDelay = 500)
    @Transactional
    public void publishPendingEvents() {
        var events = outboxRepository.findTop100ByPublishedFalseOrderByOccurredAt();
        
        for (var event : events) {
            kafkaTemplate.send(
                topicName(event.eventType()), 
                event.aggregateId().toString(), 
                event.payload()
            );
            event.markPublished();
        }
    }
}
```

**Ventajas:**
- ✅ **Atomicidad:** DB write + event publish en misma transacción lógica (2-phase commit simulado)
- ✅ **At-least-once delivery:** Si Kafka falla, el evento persiste en outbox y se reintenta
- ✅ **Auditoría:** Tabla outbox es un log de todos los eventos emitidos
- ✅ **No requiere Kafka Transactions** (más simple que transactional producers)

**Consecuencias:**
- ⚠️ Latencia adicional de 0-500ms (tiempo de polling del scheduler)
- ⚠️ Requiere limpieza periódica de outbox (`published=true AND occurred_at < now() - interval '7 days'`)
- ⚠️ Si OutboxPublisher falla, eventos se acumulan (mitigado con alertas en row count)

**Alternativas consideradas:**
- **Dual writes (DB + Kafka directo):** Rechazado, no garantiza atomicidad
- **Kafka Transactions:** Más complejo, requiere exactly-once semántica que no necesitamos (at-least-once + idempotencia en consumidores es suficiente)
- **Change Data Capture (Debezium):** Overhead operacional para MVP, considerado para futuro

---

### ADR-004: ¿Por qué Database-per-Service?

**Contexto:**
Arquitectura de microservicios permite varias opciones de persistencia:
1. **Shared database:** Todos los servicios acceden a la misma DB con schemas separados
2. **Database-per-service:** Cada servicio tiene su propia instancia de DB
3. **Hybrid:** Algunos servicios comparten, otros no

**Decisión:**
Implementar **database-per-service** estricto:
- `catalog-service` → `pg-catalog:5433/catalog_db`
- `booking-service` → `pg-booking:5434/booking_db`
- `search-pricing-service` → `pg-search:5435/search_db`

**Justificación:**
- **Aislamiento de datos:** Cada servicio es dueño exclusivo de su modelo de datos. No hay riesgo de que booking-service acceda directamente a `catalog.spaces` y rompa encapsulación.
- **Escalado independiente:** `search_db` puede necesitar más recursos (queries PostGIS complejas) que `catalog_db`. Con instancias separadas, escalamos solo lo necesario.
- **Schema evolution sin coordinación:** Cambiar `booking.bookings` no requiere coordinar con otros equipos. Versionado de eventos Kafka desacopla contratos.
- **Failure isolation:** Si `catalog_db` cae, `booking-service` y `search-pricing-service` siguen operativos (degradación parcial).

**Implementación en Dev (simplificación):**
En desarrollo usamos **3 contenedores PostgreSQL** en vez de 3 schemas en 1 contenedor, para simular aislamiento de prod:
```yaml
# docker-compose.yml
pg-catalog:
  image: postgres:16
  environment: { POSTGRES_DB: catalog_db }
  ports: ["5433:5432"]

pg-booking:
  image: postgres:16
  environment: { POSTGRES_DB: booking_db }
  ports: ["5434:5432"]

pg-search:
  image: postgis/postgis:16-3.4
  environment: { POSTGRES_DB: search_db }
  ports: ["5435:5432"]
```

**Consecuencias:**
- ✅ Independencia de despliegue y escalado
- ✅ Failure isolation
- ✅ Permite usar diferentes engines por servicio (ej: search usa PostGIS, otros podrían usar MySQL)
- ⚠️ **No foreign keys entre servicios:** `booking.bookings.space_id` no puede tener FK a `catalog.spaces.id`. Requiere validación por eventos/API.
- ⚠️ **Joins imposibles:** Queries que cruzan servicios deben hacerse por composición en API Gateway o CQRS read-model.
- ⚠️ Transacciones distribuidas requieren saga pattern

**Alternativas consideradas:**
- **Shared database:** Rechazado, viola bounded contexts y acopla servicios
- **Schemas separados en 1 DB:** Rechazado, comparten recursos (connections, memory) y dificulta migración a prod

---

### ADR-005: ¿Por qué Read-Model Separado (CQRS en SearchPricing)?

**Contexto:**
La búsqueda de espacios requiere:
- Queries geoespaciales (proximidad por lat/lon)
- Precio dinámico por timeslot
- Filtros complejos (capacity, rating, amenities)
- Latencia <200ms P95 (requisito UX)

Hacer esto directamente en `catalog_db` implicaría:
- JOINs complejos entre `spaces`, `availability_slots` y cálculo de precio en runtime
- Bloquear tablas de escritura con queries pesadas
- Precio dinámico requeriría computar demanda en cada query (imposible sub-200ms)

**Decisión:**
Implementar **CQRS (Command Query Responsibility Segregation)** con read-model especializado en `search-pricing-service`:

**Write Model (catalog-service):**
- Maneja comandos: `CreateSpace`, `UpdateSpace`, `AddAvailability`
- Escribe en `catalog_db` (normalized, transaccional)
- Publica eventos: `SpaceCreated`, `AvailabilityAdded`

**Read Model (search-pricing-service):**
- Consume eventos de Kafka
- Mantiene proyección desnormalizada en `search_db`:
  - `spaces_projection`: espacios con geo (PostGIS), rating agregado
  - `price_surface`: precio precalculado por space + timeslot
  - `demand_agg`: métricas de demanda por tile geoespacial
- Queries optimizadas con índices GIST (geo) y compound (space_id + timeslot)

**Flujo de Sincronización:**
```
1. POST /api/catalog/spaces
         ↓
2. catalog-service escribe en catalog_db
         ↓
3. Publica SpaceCreated a space.events.v1
         ↓
4. search-pricing-service consume evento
         ↓
5. INSERT INTO search.spaces_projection (space_id, geo, ...)
**Pricing Dinámico (MVP con @Scheduled, migrable a Kafka Streams):**
6. GET /api/search?lat=...&lon=... consulta proyección (con índice GIST)
   Latencia: ~50-150ms
```

**Pricing Dinámico con Kafka Streams:**
                      Consumidores Kafka escriben
                      métricas en demand_agg table
booking.events.v1 (holds)      ────┤
                  ┌────────────────▼───────────────┐
                  │ @Scheduled cada 5 min          │
                  │ Lee demand_agg (last 24h)      │
                  │                                │
                  │ Fórmula (ver PRICING_ALGORITHM):│
                  │ demandScore = (searches*0.01   │
                  │   + holds*0.1 + bookings*0.5)  │
                  │   / available_spaces           │
                  │                                │
                  │ multiplier = 1.0+(score*1.5)   │
                  │ Range: [1.0 - 2.5]             │
                                   │
                  ┌────────────────┴───────────────┐
                  │ Calcula demandScore            │
                  │ Aplica multiplier [1.0–2.5]    │
                  │ Emite PriceUpdated             │
                  └────────────────┬───────────────┘
                                   ↓
              INSERT INTO search.price_surface (space_id, timeslot, price_cents)
**Ver algoritmo completo:** [docs/PRICING_ALGORITHM.md](../docs/PRICING_ALGORITHM.md)

              SET Redis price:{space}:{slot} = {price} PX 900000  # 15 min
                                   ↓
              GET /search incluye precio desde Redis (cache hit) o price_surface
```

**Ventajas:**
- ✅ **Latencia ultra-baja:** Queries contra proyección precalculada, no cómputo en runtime
- ✅ **Escalado independiente:** search-pricing puede tener 5 réplicas mientras catalog tiene 2
- ✅ **Especialización:** PostGIS + índices GIST optimizados para geo, sin afectar catalog
- ✅ **Resiliencia:** Si search-pricing cae, catalog y booking siguen funcionando (búsqueda degrada pero no bloquea bookings)

**Consecuencias:**
- ⚠️ **Eventual consistency:** Delay de ~500ms-2s entre crear espacio y aparecer en búsqueda (mitigado con outbox rápido + consumer con bajo lag)
- ⚠️ **Duplicación de datos:** `spaces` existe en catalog_db y search_db (trade-off aceptable para performance)
- ⚠️ **Complejidad operacional:** Monitorear Kafka lag, rebuild de proyección si se corrompe

**Rebuild de Proyección (disaster recovery):**
```bash
# Truncar proyección
TRUNCATE search.spaces_projection;

# Republicar eventos desde catalog (admin endpoint)
curl -X POST http://localhost:8081/admin/republish-all-spaces

# O restore desde backup de catalog_db + replay Kafka (si retención lo permite)
```

**Alternativas consideradas:**
- **Queries directas a catalog_db:** Rechazado por latencia inaceptable (>500ms con JOINs + pricing)
- **Materialized views en catalog_db:** No soportan PostGIS eficientemente, acoplamiento con write-model
- **Elasticsearch:** Overhead de nueva tecnología para MVP, considerado para fase 2

---

## 🔄 Flujo de Datos Completo: Booking Saga (Secuencia ASCII)

```
┌──────┐          ┌─────────┐         ┌─────────┐        ┌───────┐        ┌───────┐
│Client│          │Gateway  │         │Booking  │        │ Redis │        │ Kafka │
│      │          │         │         │Service  │        │       │        │       │
└──┬───┘          └────┬────┘         └────┬────┘        └───┬───┘        └───┬───┘
   │                   │                   │                 │                │
   │ POST /bookings    │                   │                 │                │
   ├──────────────────>│                   │                 │                │
   │ (+ JWT)           │                   │                 │                │
   │                   │ Validate JWT      │                 │                │
   │                   │ Rate limit check  │                 │                │
   │                   ├──────────────────>│                 │                │
   │                   │                   │ 1. Lock Redis   │                │
   │                   │                   ├────────────────>│                │
   │                   │                   │ SET lock:..NX PX│                │
   │                   │                   │<────────────────┤                │
   │                   │                   │ OK (acquired)   │                │
   │                   │                   │                 │                │
   │                   │                   │ 2. Calculate    │                │
   │                   │                   │    price from   │                │
   │                   │                   │    Redis/DB     │                │
   │                   │                   │                 │                │
   │                   │                   │ 3. @Transactional {             │
   │                   │                   │   INSERT bookings (status=held) │
   │                   │                   │   INSERT outbox (BookingHeld)   │
   │                   │                   │ } COMMIT                         │
   │                   │                   │                 │                │
   │                   │   201 Created     │                 │                │
   │                   │<──────────────────┤                 │                │
   │<──────────────────┤  {id, status:held}│                 │                │
   │                   │                   │                 │                │
   │                   │                   │ 4. OutboxPublisher (@Scheduled) │
   │                   │                   ├────────────────────────────────>│
   │                   │                   │ Produce BookingHeld              │
   │                   │                   │                 │                │
   │                   │                   │ 5. Create       │                │
   │                   │                   │    PaymentIntent│                │
   │                   │                   │    (Stripe Mock)│                │
   │                   │                   │                 │                │
   │                   │                   │ 6. @Transactional {             │
   │                   │                   │   UPDATE bookings               │
   │                   │                   │     SET payment_intent_id       │
   │                   │                   │   INSERT outbox                 │
   │                   │                   │     (PaymentIntentCreated)      │
   │                   │                   │ } COMMIT        │                │
   │                   │                   │                 │                │
   │                   │                   ├────────────────────────────────>│
   │                   │                   │ Produce PaymentIntentCreated     │
   │                   │                   │                 │                │
   │                   │                   │ 7. Async call to│                │
   │                   │                   │    PaymentGateway.authorize()   │
   │                   │                   │    (simulated delay 2s)         │
   │                   │                   │                 │                │
   ╔═══════════════════╧═══════════════════╧═════════════════╧════════════════╧═══╗
   ║                        ASYNC: Payment Processing (2-5 seconds)                ║
   ╚═══════════════════╤═══════════════════╤═════════════════╤════════════════╤═══╝
   │                   │                   │ PaymentGateway  │                │
   │                   │                   │ calls webhook   │                │
   │                   │                   │<────────────────┤                │
   │                   │                   │ PaymentAuthorized                │
   │                   │                   │                 │                │
   │                   │                   │ 8. @Transactional {             │
   │                   │                   │   (no DB change,│                │
   │                   │                   │    keep held)   │                │
   │                   │                   │   INSERT outbox │                │
   │                   │                   │    (PaymentAuth)│                │
   │                   │                   │ } COMMIT        │                │
   │                   │                   ├────────────────────────────────>│
   │                   │                   │ Produce PaymentAuthorized        │
   │                   │                   │                 │                │
   ╔═══════════════════╧═══════════════════╧═════════════════╧════════════════╧═══╗
   ║                   CLIENT CONFIRMS BOOKING (within 10 min TTL)                 ║
   ╚═══════════════════╤═══════════════════╤═════════════════╤════════════════╤═══╝
   │ POST /bookings/   │                   │                 │                │
   │      {id}/confirm │                   │                 │                │
   ├──────────────────>│                   │                 │                │
   │                   ├──────────────────>│                 │                │
   │                   │                   │ 9. Capture      │                │
   │                   │                   │    Payment      │                │
   │                   │                   │    (final)      │                │
   │                   │                   │                 │                │
   │                   │                   │ 10. @Transactional {            │
   │                   │                   │   UPDATE bookings               │
   │                   │                   │     SET status=confirmed        │
   │                   │                   │   INSERT outbox                 │
   │                   │                   │    (BookingConfirmed)           │
   │                   │                   │    (PaymentCaptured)            │
   │                   │                   │ } COMMIT        │                │
   │                   │                   │                 │                │
   │                   │                   │ 11. Release Lock│                │
   │                   │                   ├────────────────>│                │
   │                   │                   │ DEL lock:...    │                │
   │                   │                   │<────────────────┤                │
   │                   │                   │                 │                │
   │                   │   200 OK          │                 │                │
   │<──────────────────┤<──────────────────┤                 │                │
   │ {status:confirmed}│                   │                 │                │
   │                   │                   ├────────────────────────────────>│
   │                   │                   │ Produce BookingConfirmed         │
   │                   │                   │ Produce PaymentCaptured          │
   └───────────────────┴───────────────────┴─────────────────┴────────────────┴───
```

### Compensaciones (Failure Scenarios)

**A. Payment Failed:**
```
PaymentGateway.authorize() → fails
  ↓
PaymentFailed event published
  ↓
BookingSaga.handlePaymentFailed():
  - UPDATE bookings SET status='cancelled'
  - DEL lock:booking:...
  - INSERT outbox (BookingCancelled)
  - (No refund needed, only pre-auth)
```

**B. Booking Expired (10 min TTL):**
```
BookingExpiryWorker (@Scheduled every 30s):
  - SELECT * FROM bookings WHERE status='held' AND created_at < now() - interval '10 min'
  - FOR EACH expired:
      - UPDATE status='expired'
      - DEL lock:booking:...
      - INSERT outbox (BookingExpired)
      - (Payment intent cancelled in gateway)
```

---

## 🛡️ Resiliencia

### Circuit Breakers (Resilience4j)
```java
// booking-service/infrastructure/payment/StripeGatewayAdapter.java
@CircuitBreaker(name = "payment-gateway", fallbackMethod = "paymentFallback")
public PaymentIntent createIntent(int amountCents) {
    return stripeClient.paymentIntents.create(params);
}

private PaymentIntent paymentFallback(int amountCents, Exception ex) {
    log.error("Payment gateway circuit open, using fallback", ex);
    // Opción 1: Return mock intent (dev/test)
    // Opción 2: Throw custom exception → BookingCancelled
    throw new PaymentUnavailableException("Payment service temporarily unavailable");
}
```

**Configuración (application.yml):**
```yaml
resilience4j:
  circuitbreaker:
    instances:
      payment-gateway:
        failure-rate-threshold: 50          # Abre si >50% requests fallan
        wait-duration-in-open-state: 30s    # Espera 30s antes de half-open
        sliding-window-size: 10             # Ventana de 10 requests
        permitted-number-of-calls-in-half-open-state: 3
```

### Retries con Backoff Exponencial
```java
@Retryable(
    value = { KafkaException.class },
    maxAttempts = 3,
    backoff = @Backoff(delay = 1000, multiplier = 2)  // 1s, 2s, 4s
)
public void publishEvent(DomainEvent event) {
    kafkaTemplate.send(topic, event);
}
```

### Dead Letter Topics (DLT)
**Configuración Kafka Consumer:**
```java
@KafkaListener(
    topics = "space.events.v1",
    groupId = "search-pricing-consumer",
    containerFactory = "kafkaListenerContainerFactory"
)
public void onSpaceEvent(ConsumerRecord<String, String> record) {
    try {
        processEvent(record.value());
    } catch (RecoverableException e) {
        // Retry automático por Kafka (max 3 attempts)
        throw e;
    } catch (NonRecoverableException e) {
        // Enviar a DLT manualmente
        dltProducer.send("space.events.v1.DLT", record);
        log.error("Event sent to DLT", e);
    }
}
```

**Monitoreo de DLT:**
```bash
# Alerta si DLT tiene >100 mensajes
kafka-consumer-groups --bootstrap-server kafka:9092 \
  --describe --group dlt-monitor | grep space.events.v1.DLT
```

### Redis Locks con TTL Automático
```java
public boolean acquireLock(String spaceId, DateRange range, long ttlMs) {
    String key = "lock:booking:" + spaceId + ":" + range.start() + "-" + range.end();
    Boolean acquired = redisTemplate.opsForValue()
        .setIfAbsent(key, "locked", Duration.ofMillis(ttlMs));
    return Boolean.TRUE.equals(acquired);
}

// Uso en BookingSaga:
if (!redisLock.acquire(cmd.spaceId(), cmd.range(), 600_000)) {  // 10 min
    throw new BookingConflictException("Slot already locked");
}
```

**Ventaja:** Si el servicio crashea antes de `releaseLock()`, Redis expira automáticamente el lock tras 10 min.

### Idempotencia
**Client-side (Idempotency-Key header):**
```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Idempotency-Key: 7c8e9d0a-unique-uuid" \
  -d '{...}'
```

**Server-side (tabla processed_events):**
```java
@Transactional
public BookingDto createBooking(CreateBookingCommand cmd, String idempotencyKey) {
    // Check if already processed
    if (processedEventRepository.existsByIdempotencyKey(idempotencyKey)) {
        return bookingRepository.findByIdempotencyKey(idempotencyKey);
    }
    
    var booking = // ... create booking
    processedEventRepository.save(new ProcessedEvent(idempotencyKey, booking.id()));
    return mapper.toDto(booking);
}
```

---

## 🔐 Seguridad

### JWT RS256 (Keycloak en Dev, Cognito en Prod)
**Flujo de autenticación:**
```
1. User login → POST /realms/balconazo/protocol/openid-connect/token
   Keycloak valida credenciales
     ↓
2. Response: { access_token: "eyJhbGc...", refresh_token: "..." }
     ↓
3. Frontend guarda access_token en localStorage/sessionStorage
     ↓
4. Cada request al Gateway incluye: Authorization: Bearer eyJhbGc...
     ↓
5. Gateway valida JWT con JWKs públicas de Keycloak:
   - Signature válida?
   - exp (expiration) > now()?
   - iss (issuer) == http://keycloak:8080/realms/balconazo?
     ↓
6. Extrae claims (sub, realm_access.roles) y propaga en headers internos:
   X-User-Id: {sub}
   X-User-Roles: host,guest
     ↓
7. Microservicio recibe headers y aplica autorización:
   if (!roles.contains("host")) throw new ForbiddenException();
```

**Estructura JWT (payload):**
```json
{
  "sub": "f3f2d5e0-1234-5678-90ab-cdef12345678",
  "email": "host@balconazo.com",
  "realm_access": {
    "roles": ["host", "offline_access"]
  },
  "iss": "http://keycloak:8080/realms/balconazo",
  "exp": 1730000000,
  "iat": 1729996400
}
```

### Rate Limiting con Redis
**Configuración Gateway:**
```java
@Bean
public RedisRateLimiter redisRateLimiter() {
    return new RedisRateLimiter(
        100,  // replenishRate: 100 tokens/min
        200,  // burstCapacity: hasta 200 requests en burst
        1     // requestedTokens: 1 token por request
    );
}

@Bean
public KeyResolver userKeyResolver() {
    return exchange -> {
        String userId = exchange.getAttribute("userId");  // Extraído de JWT
        return Mono.just(userId != null ? userId : exchange.getRequest().getRemoteAddress().toString());
    };
}
```

**Redis keys generadas:**
```
ratelimit:{userId}:tokens → current tokens available
ratelimit:{userId}:timestamp → last refill timestamp
```

### HTTPS + Secrets Manager (Prod)
```yaml
# api-gateway application-prod.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          jwk-set-uri: ${JWT_JWK_SET_URI}  # From AWS Secrets Manager
          
# Secrets en AWS Secrets Manager:
# - prod/balconazo/jwt-jwk-uri
# - prod/balconazo/db-password-catalog
# - prod/balconazo/stripe-api-key
```

---

## 📊 Observabilidad

### Spring Boot Actuator Endpoints
Todos los servicios exponen:
- `GET /actuator/health` → Liveness/readiness probes (Kubernetes)
- `GET /actuator/metrics` → Métricas JVM, HTTP, custom
- `GET /actuator/prometheus` → Scraping por Prometheus

**Custom Metrics (ejemplo):**
```java
@Service
public class BookingApplicationService {
    private final MeterRegistry meterRegistry;
    
    public BookingDto createBooking(CreateBookingCommand cmd) {
        meterRegistry.counter("bookings.created", "status", "held").increment();
        // ... business logic
    }
}
```

### Tracing: X-Correlation-Id
**Gateway inyecta header:**
```java
@Component
public class CorrelationIdFilter implements GlobalFilter {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String correlationId = UUID.randomUUID().toString();
        exchange.getRequest().mutate().header("X-Correlation-Id", correlationId);
        MDC.put("correlationId", correlationId);
        return chain.filter(exchange);
    }
}
```

**Microservicios propagan:**
```java
@Component
public class CorrelationInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, ...) {
        String corrId = request.getHeader("X-Correlation-Id");
        if (corrId != null) MDC.put("correlationId", corrId);
        return true;
    }
}
```

**Logging estructurado (JSON):**
```json
{
  "timestamp": "2025-10-25T19:30:00.123Z",
  "level": "INFO",
  "service": "booking-service",
  "traceId": "7c8e9d0a-...",
  "correlationId": "b2c3d4e5-...",
  "message": "Booking created",
  "bookingId": "f3f2d5e0-...",
  "userId": "a1b2c3d4-..."
}
```

**Query en CloudWatch Logs Insights:**
```sql
fields @timestamp, message, bookingId
| filter correlationId = "b2c3d4e5-..."
| sort @timestamp asc
```

---

## 🚀 Próximos Pasos

1. **Implementar API Gateway:** Configurar Spring Cloud Gateway con JWT + rate limiting
2. **Scaffolding de capas hexagonales:** domain/ → application/ → infrastructure/ → interfaces/ en cada servicio
3. **DDL y migrations:** Flyway/Liquibase para versionado de schemas
4. **Kafka Streams topology:** Motor de pricing con ventanas tumbling
5. **Tests de integración:** Testcontainers para Postgres, Kafka, Redis
6. **CI/CD:** GitHub Actions → build → test → push ECR → deploy ECS
7. **Monitoreo:** Grafana dashboards + alertas (PagerDuty) en errores >5%

---

**Última actualización:** 25 de octubre de 2025  
**Mantenido por:** Equipo de Arquitectura Balconazo

