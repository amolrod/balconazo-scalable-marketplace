-- ============================================
-- BALCONAZO - BOOKING DATABASE SCHEMA
-- Database: booking_db
-- Schema: booking
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE SCHEMA IF NOT EXISTS booking;

-- ============================================
-- TABLA: bookings
-- Reservas de espacios
-- ============================================

CREATE TABLE IF NOT EXISTS booking.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    start_ts TIMESTAMPTZ NOT NULL,
    end_ts TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('held', 'confirmed', 'cancelled', 'expired')),
    price_cents INT NOT NULL CHECK (price_cents >= 0),
    deposit_cents INT DEFAULT 0 CHECK (deposit_cents >= 0),
    payment_intent_id TEXT,
    idempotency_key UUID UNIQUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    confirmed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    CHECK (end_ts > start_ts)
);

-- Exclusión para evitar solapes en 'held' o 'confirmed'
ALTER TABLE booking.bookings
ADD CONSTRAINT no_overlap
EXCLUDE USING GIST (
    space_id WITH =,
    tstzrange(start_ts, end_ts) WITH &&
)
WHERE (status IN ('held', 'confirmed'));

CREATE INDEX idx_bookings_space_time ON booking.bookings(space_id, start_ts, end_ts, status);
CREATE INDEX idx_bookings_guest ON booking.bookings(guest_id);
CREATE INDEX idx_bookings_status ON booking.bookings(status);
CREATE INDEX idx_bookings_created ON booking.bookings(created_at);

-- ============================================
-- TABLA: reviews
-- Reviews post-estancia
-- ============================================

CREATE TABLE IF NOT EXISTS booking.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID UNIQUE REFERENCES booking.bookings(id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    target_user_id UUID NOT NULL,
    target_type TEXT NOT NULL CHECK (target_type IN ('host', 'guest', 'space')),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    text TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_reviews_booking ON booking.reviews(booking_id);
CREATE INDEX idx_reviews_target ON booking.reviews(target_user_id, target_type);
CREATE INDEX idx_reviews_author ON booking.reviews(author_id);

-- ============================================
-- TABLA: outbox
-- Outbox pattern para eventos de dominio
-- ============================================

CREATE TABLE IF NOT EXISTS booking.outbox (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ DEFAULT now(),
    published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ
);

CREATE INDEX idx_outbox_published ON booking.outbox(published, occurred_at);
CREATE INDEX idx_outbox_aggregate ON booking.outbox(aggregate_id);

-- ============================================
-- TABLA: processed_events
-- Idempotencia para eventos consumidos
-- ============================================

CREATE TABLE IF NOT EXISTS booking.processed_events (
    event_id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_processed_events_aggregate ON booking.processed_events(aggregate_id, event_type);

-- ============================================
-- TRIGGER: updated_at automático
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_bookings_updated_at
    BEFORE UPDATE ON booking.bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- TRIGGER: published_at automático en outbox
-- ============================================

CREATE OR REPLACE FUNCTION update_published_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.published = TRUE AND OLD.published = FALSE THEN
        NEW.published_at = now();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_outbox_published_at
    BEFORE UPDATE ON booking.outbox
    FOR EACH ROW
    EXECUTE FUNCTION update_published_at();

-- ============================================
-- SEED DATA (desarrollo)
-- ============================================

-- Booking de ejemplo (held, listo para confirmar)
INSERT INTO booking.bookings (
    id, space_id, guest_id, start_ts, end_ts,
    status, price_cents, idempotency_key
)
VALUES
    (
        '1a2b3c4d-5678-9012-3456-789012345678',
        'e5f6g7h8-9012-3456-7890-abcd12345678',  -- espacio de catalog
        'a1b2c3d4-5678-9012-3456-789012345678',  -- guest de catalog
        now() + interval '2 days' + interval '18 hours',
        now() + interval '2 days' + interval '23 hours',
        'held',
        3500,
        gen_random_uuid()
    )
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON SCHEMA booking IS 'Schema para booking-service (reservas, pagos, reviews)';
COMMENT ON TABLE booking.bookings IS 'Reservas de espacios con estados held/confirmed/cancelled/expired';
COMMENT ON TABLE booking.reviews IS 'Reviews post-estancia (1 por booking)';
COMMENT ON TABLE booking.outbox IS 'Outbox pattern para garantizar atomicidad DB + Kafka';
COMMENT ON TABLE booking.processed_events IS 'Registro de eventos consumidos (idempotencia)';

-- ============================================
-- FINALIZADO
-- ============================================

