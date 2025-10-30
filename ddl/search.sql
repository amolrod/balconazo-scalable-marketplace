-- ============================================
-- BALCONAZO - SEARCH DATABASE SCHEMA
-- Database: search_db
-- Schema: search
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS search;

-- ============================================
-- TABLA: spaces_projection
-- Proyección de espacios (read model CQRS)
-- ============================================

CREATE TABLE IF NOT EXISTS search.spaces_projection (
    space_id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    capacity INT NOT NULL,
    area_sqm NUMERIC(6,2),
    amenities TEXT[] DEFAULT '{}',
    address TEXT NOT NULL,
    geo GEOGRAPHY(POINT, 4326) NOT NULL,
    base_price_cents INT NOT NULL,
    avg_rating NUMERIC(3,2) DEFAULT 0,
    review_count INT DEFAULT 0,
    status TEXT NOT NULL,
    owner_id UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_spaces_geo ON search.spaces_projection USING GIST (geo);
CREATE INDEX idx_spaces_status ON search.spaces_projection(status);
CREATE INDEX idx_spaces_capacity ON search.spaces_projection(capacity);
CREATE INDEX idx_spaces_rating ON search.spaces_projection(avg_rating DESC);

-- ============================================
-- TABLA: price_surface
-- Precios precalculados por timeslot
-- ============================================

CREATE TABLE IF NOT EXISTS search.price_surface (
    space_id UUID NOT NULL,
    timeslot_start TIMESTAMPTZ NOT NULL,
    price_cents INT NOT NULL CHECK (price_cents >= 0),
    multiplier NUMERIC(4,2) NOT NULL CHECK (multiplier >= 1.0),
    demand_score NUMERIC(4,2) NOT NULL CHECK (demand_score >= 0),
    computed_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (space_id, timeslot_start)
);

CREATE INDEX idx_price_surface_space ON search.price_surface(space_id);
CREATE INDEX idx_price_surface_time ON search.price_surface(timeslot_start);

-- ============================================
-- TABLA: demand_agg
-- Agregación de demanda por tile geoespacial
-- ============================================

CREATE TABLE IF NOT EXISTS search.demand_agg (
    tile_id TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL,
    searches INT NOT NULL DEFAULT 0,
    holds INT NOT NULL DEFAULT 0,
    bookings INT NOT NULL DEFAULT 0,
    available_spaces INT NOT NULL DEFAULT 0,
    demand_score NUMERIC(4,2) NOT NULL DEFAULT 0,
    multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.0,
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tile_id, window_start)
);

CREATE INDEX idx_demand_agg_tile ON search.demand_agg(tile_id);
CREATE INDEX idx_demand_agg_window ON search.demand_agg(window_start);

-- ============================================
-- TABLA: processed_events
-- Idempotencia para eventos consumidos
-- ============================================

CREATE TABLE IF NOT EXISTS search.processed_events (
    event_id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_processed_events_aggregate ON search.processed_events(aggregate_id, event_type);

-- ============================================
-- FUNCIÓN: Cálculo de tile_id (H3 simulado)
-- ============================================

CREATE OR REPLACE FUNCTION search.get_tile_id(lat DOUBLE PRECISION, lon DOUBLE PRECISION)
RETURNS TEXT AS $$
BEGIN
    -- Simulación simple de tile_id (H3 requeriría extensión específica)
    -- Usa grid de 0.1° (~11km)
    RETURN 'tile_' || ROUND(lat::numeric, 1)::text || '_' || ROUND(lon::numeric, 1)::text;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

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

CREATE TRIGGER update_spaces_projection_updated_at
    BEFORE UPDATE ON search.spaces_projection
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_demand_agg_updated_at
    BEFORE UPDATE ON search.demand_agg
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA (desarrollo)
-- ============================================

-- Proyección del espacio de ejemplo
INSERT INTO search.spaces_projection (
    space_id, title, description, capacity, area_sqm,
    amenities, address, geo, base_price_cents, status, owner_id
)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
        'Terraza con vistas al Retiro',
        'Amplia terraza de 40m² con vistas espectaculares al Parque del Retiro.',
        15,
        40.00,
        ARRAY['wifi', 'sound_system', 'outdoor_power', 'heating'],
        'Calle Alcalá 123, Madrid',
        ST_GeogFromText('POINT(-3.7038 40.4168)'),
        3500,
        'active',
        '11111111-1111-1111-1111-111111111111'::uuid
    )
ON CONFLICT (space_id) DO NOTHING;

-- Precio inicial (sin demanda, multiplier = 1.0)
INSERT INTO search.price_surface (space_id, timeslot_start, price_cents, multiplier, demand_score)
SELECT
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    date_trunc('hour', now() + interval '1 day' * day),
    3500,
    1.0,
    0.0
FROM generate_series(1, 7) AS day
ON CONFLICT (space_id, timeslot_start) DO NOTHING;

-- Demanda inicial para tile de Madrid Centro
INSERT INTO search.demand_agg (tile_id, window_start, searches, holds, bookings, available_spaces, demand_score, multiplier)
VALUES
    (
        search.get_tile_id(40.4168, -3.7038),
        date_trunc('hour', now()),
        0,
        0,
        0,
        1,
        0.0,
        1.0
    )
ON CONFLICT (tile_id, window_start) DO NOTHING;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON SCHEMA search IS 'Schema para search-pricing-service (proyección de búsqueda + pricing)';
COMMENT ON TABLE search.spaces_projection IS 'Proyección de espacios optimizada para búsqueda (read model CQRS)';
COMMENT ON TABLE search.price_surface IS 'Precios dinámicos precalculados por timeslot';
COMMENT ON TABLE search.demand_agg IS 'Agregación de demanda por tile geoespacial (ventanas temporales)';
COMMENT ON TABLE search.processed_events IS 'Registro de eventos consumidos (idempotencia)';

-- ============================================
-- FINALIZADO
-- ============================================
-- ============================================
-- BALCONAZO - CATALOG DATABASE SCHEMA
-- Database: catalog_db
-- Schema: catalog
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS catalog;

-- ============================================
-- TABLA: users
-- Gestión de usuarios (hosts y guests)
-- ============================================

CREATE TABLE IF NOT EXISTS catalog.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('host', 'guest', 'admin')),
    trust_score INT DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_users_email ON catalog.users(email);
CREATE INDEX idx_users_role ON catalog.users(role);
CREATE INDEX idx_users_status ON catalog.users(status);

-- ============================================
-- TABLA: spaces
-- Catálogo de espacios publicados
-- ============================================

CREATE TABLE IF NOT EXISTS catalog.spaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES catalog.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    capacity INT NOT NULL CHECK (capacity > 0),
    area_sqm NUMERIC(6,2),
    rules JSONB DEFAULT '{}'::jsonb,
    amenities TEXT[] DEFAULT '{}',
    address TEXT NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    base_price_cents INT NOT NULL CHECK (base_price_cents >= 0),
    status TEXT CHECK (status IN ('draft', 'active', 'snoozed', 'deleted')) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_spaces_owner ON catalog.spaces(owner_id);
CREATE INDEX idx_spaces_geo ON catalog.spaces(lat, lon);
CREATE INDEX idx_spaces_status ON catalog.spaces(status);

-- ============================================
-- TABLA: availability_slots
-- Slots de disponibilidad por espacio
-- ============================================

CREATE TABLE IF NOT EXISTS catalog.availability_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    space_id UUID NOT NULL REFERENCES catalog.spaces(id) ON DELETE CASCADE,
    start_ts TIMESTAMPTZ NOT NULL,
    end_ts TIMESTAMPTZ NOT NULL,
    max_guests INT NOT NULL CHECK (max_guests > 0),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(space_id, start_ts, end_ts),
    CHECK (end_ts > start_ts)
);

CREATE INDEX idx_availability_space ON catalog.availability_slots(space_id);
CREATE INDEX idx_availability_time ON catalog.availability_slots(start_ts, end_ts);

-- ============================================
-- TABLA: processed_events
-- Idempotencia para eventos consumidos
-- ============================================

CREATE TABLE IF NOT EXISTS catalog.processed_events (
    event_id UUID PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_processed_events_aggregate ON catalog.processed_events(aggregate_id, event_type);

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

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON catalog.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_spaces_updated_at
    BEFORE UPDATE ON catalog.spaces
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SEED DATA (desarrollo)
-- ============================================

-- Usuario host de ejemplo
INSERT INTO catalog.users (id, email, password_hash, role, trust_score, status)
VALUES
    ('f3f2d5e0-1234-5678-90ab-cdef87654321',
     'host@balconazo.com',
     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- password: Test1234!
     'host',
     100,
     'active')
ON CONFLICT (email) DO NOTHING;

-- Usuario guest de ejemplo
INSERT INTO catalog.users (id, email, password_hash, role, trust_score, status)
VALUES
    ('a1b2c3d4-5678-9012-3456-789012345678',
     'guest@balconazo.com',
     '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', -- password: Test1234!
     'guest',
     50,
     'active')
ON CONFLICT (email) DO NOTHING;

-- Espacio de ejemplo
INSERT INTO catalog.spaces (id, owner_id, title, description, capacity, area_sqm, address, lat, lon, base_price_cents, status, amenities)
VALUES
    ('e5f6g7h8-9012-3456-7890-abcd12345678',
     'f3f2d5e0-1234-5678-90ab-cdef87654321',
     'Terraza con vistas al Retiro',
     'Amplia terraza de 40m² con vistas espectaculares al Parque del Retiro. Perfecta para eventos nocturnos, celebraciones y fiestas privadas. Incluye WiFi, sistema de sonido Bluetooth y enchufes exteriores.',
     15,
     40.00,
     'Calle Alcalá 123, Madrid',
     40.4168,
     -3.7038,
     3500,
     'active',
     ARRAY['wifi', 'sound_system', 'outdoor_power', 'heating'])
ON CONFLICT (id) DO NOTHING;

-- Disponibilidad de ejemplo (próximos 7 días)
INSERT INTO catalog.availability_slots (space_id, start_ts, end_ts, max_guests)
SELECT
    'e5f6g7h8-9012-3456-7890-abcd12345678',
    date_trunc('day', now() + interval '1 day' * day) + interval '18 hours',
    date_trunc('day', now() + interval '1 day' * day) + interval '23 hours',
    15
FROM generate_series(1, 7) AS day
ON CONFLICT (space_id, start_ts, end_ts) DO NOTHING;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON SCHEMA catalog IS 'Schema para catalog-service (usuarios y espacios)';
COMMENT ON TABLE catalog.users IS 'Usuarios de la plataforma (hosts, guests, admins)';
COMMENT ON TABLE catalog.spaces IS 'Catálogo de espacios publicados';
COMMENT ON TABLE catalog.availability_slots IS 'Slots de disponibilidad por espacio';
COMMENT ON TABLE catalog.processed_events IS 'Registro de eventos consumidos (idempotencia)';

-- ============================================
-- FINALIZADO
-- ============================================

