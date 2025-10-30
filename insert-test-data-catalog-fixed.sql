-- Insertar datos de prueba en Catalog DB - CORREGIDO
-- Espacios con IDs conocidos para Postman

\c catalog_db;

-- Limpiar datos existentes
DELETE FROM catalog.spaces WHERE true;
DELETE FROM catalog.users WHERE true;

-- Insertar usuarios (hosts) - Con password_hash válido (BCrypt hash de "password123")
INSERT INTO catalog.users (id, email, password_hash, role, status, trust_score, created_at) VALUES
('11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'HOST', 'active', 100, NOW()),
('22222222-2222-2222-2222-222222222222', 'host2@balconazo.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'HOST', 'active', 95, NOW()),
('55555555-5555-5555-5555-555555555555', 'admin@balconazo.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'HOST', 'active', 100, NOW());

-- Insertar guests
INSERT INTO catalog.users (id, email, password_hash, role, status, trust_score, created_at) VALUES
('33333333-3333-3333-3333-333333333333', 'guest1@balconazo.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'GUEST', 'active', 85, NOW()),
('44444444-4444-4444-4444-444444444444', 'guest2@balconazo.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'GUEST', 'active', 90, NOW());

-- Insertar espacios con IDs conocidos - Arrays como texto con sintaxis PostgreSQL
INSERT INTO catalog.spaces (id, owner_id, title, description, capacity, area_sqm, address, lat, lon, base_price_cents, status, amenities, created_at) VALUES
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'Ático con terraza en el centro',
    'Amplio ático de 80m² con terraza privada de 40m² en pleno centro de Madrid. Vistas panorámicas a Gran Vía.',
    15,
    80.5,
    'Calle Gran Vía 28, Madrid',
    40.4200,
    -3.7040,
    3500,
    'active',
    ARRAY['wifi', 'terraza', 'cocina', 'baño', 'proyector', 'aire_acondicionado'],
    NOW()
),
(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '11111111-1111-1111-1111-111111111111',
    'Loft industrial en Malasaña',
    'Loft de estilo industrial con techos altos y grandes ventanales.',
    20,
    120.0,
    'Calle Velarde 15, Madrid',
    40.4250,
    -3.7010,
    5000,
    'active',
    ARRAY['wifi', 'cocina', 'baño', 'luz_natural', 'parking'],
    NOW()
),
(
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '22222222-2222-2222-2222-222222222222',
    'Azotea con vistas al Retiro',
    'Espacio único en azotea con vistas directas al Parque del Retiro.',
    30,
    150.0,
    'Calle Alcalá 123, Madrid',
    40.4170,
    -3.6840,
    7500,
    'active',
    ARRAY['wifi', 'terraza', 'vistas', 'sonido', 'iluminacion'],
    NOW()
),
(
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    '22222222-2222-2222-2222-222222222222',
    'Sala de reuniones ejecutiva',
    'Sala equipada con tecnología de última generación.',
    10,
    40.0,
    'Paseo de la Castellana 95, Madrid',
    40.4480,
    -3.6890,
    2500,
    'active',
    ARRAY['wifi', 'proyector', 'pizarra', 'aire_acondicionado', 'cafe'],
    NOW()
),
(
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    '55555555-5555-5555-5555-555555555555',
    'Jardín privado en Chamberí',
    'Precioso jardín privado de 200m² en zona residencial.',
    50,
    200.0,
    'Calle Santa Engracia 78, Madrid',
    40.4380,
    -3.7010,
    10000,
    'active',
    ARRAY['jardin', 'wifi', 'baño', 'cocina_exterior', 'parking'],
    NOW()
),
(
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    '11111111-1111-1111-1111-111111111111',
    'Estudio de fotografía profesional',
    'Estudio completamente equipado con fondos e iluminación profesional.',
    8,
    60.0,
    'Calle Fuencarral 45, Madrid',
    40.4260,
    -3.7020,
    4000,
    'draft',
    ARRAY['wifi', 'fondos', 'iluminacion', 'vestuario', 'baño'],
    NOW()
);

-- Verificar inserción
SELECT
    LEFT(id::text, 8) as space_id,
    title,
    status,
    capacity,
    base_price_cents/100.0 as price_euros,
    LEFT(owner_id::text, 8) as owner
FROM catalog.spaces
ORDER BY created_at;

