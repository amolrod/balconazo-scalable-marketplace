package com.balconazo.booking_microservice.constants;

public final class BookingConstants {

    private BookingConstants() {
        throw new UnsupportedOperationException("Esta es una clase de utilidad y no puede ser instanciada");
    }

    // ============================================
    // KAFKA TOPICS
    // ============================================
    public static final String TOPIC_BOOKING_EVENTS = "booking.events.v1";
    public static final String TOPIC_REVIEW_EVENTS = "review.events.v1";
    public static final String TOPIC_PAYMENT_EVENTS = "payment.events.v1";

    // Escuchar eventos de otros servicios
    public static final String TOPIC_SPACE_EVENTS = "space.events.v1";
    public static final String TOPIC_AVAILABILITY_EVENTS = "availability.events.v1";

    // ============================================
    // EVENT TYPES
    // ============================================
    public static final String EVENT_BOOKING_CREATED = "BookingCreated";
    public static final String EVENT_BOOKING_CONFIRMED = "BookingConfirmed";
    public static final String EVENT_BOOKING_CANCELLED = "BookingCancelled";
    public static final String EVENT_BOOKING_COMPLETED = "BookingCompleted";

    public static final String EVENT_PAYMENT_INITIATED = "PaymentInitiated";
    public static final String EVENT_PAYMENT_SUCCEEDED = "PaymentSucceeded";
    public static final String EVENT_PAYMENT_FAILED = "PaymentFailed";

    public static final String EVENT_REVIEW_CREATED = "ReviewCreated";

    // ============================================
    // REDIS KEYS
    // ============================================
    public static final String REDIS_BOOKING_LOCK_PREFIX = "booking:lock:";
    public static final String REDIS_IDEMPOTENCY_PREFIX = "booking:idempotency:";
    public static final int REDIS_LOCK_TTL_SECONDS = 600; // 10 minutos

    // ============================================
    // BUSINESS RULES
    // ============================================
    public static final int MIN_BOOKING_HOURS = 1;
    public static final int MAX_BOOKING_DAYS = 365;
    public static final int MIN_ADVANCE_HOURS = 0; // Permitir reservas inmediatas
    public static final int CANCELLATION_DEADLINE_HOURS = 1; // Cancelar con 1h de antelación (para pruebas)

    // ============================================
    // PAYMENT
    // ============================================
    public static final String PAYMENT_CURRENCY = "EUR";
    public static final int PLATFORM_FEE_PERCENT = 15; // 15% comisión de plataforma
}

