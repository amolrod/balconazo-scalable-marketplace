-- ==========================================
-- DATOS DE PRUEBA - CATALOG SERVICE (PostgreSQL)
-- ==========================================

\c catalog_db

-- Limpiar datos existentes
TRUNCATE TABLE catalog.availability_slots CASCADE;
TRUNCATE TABLE catalog.spaces CASCADE;
TRUNCATE TABLE catalog.users CASCADE;

-- Insertar usuarios (deben coincidir con Auth)
INSERT INTO catalog.users (id, email, password_hash, role, status, trust_score, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'host', 'active', 100, NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'guest1@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'guest', 'active', 90, NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'host2@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3YxH8KzLc7QK8m', 'host', 'active', 95, NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', 'guest2@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'guest', 'active', 85, NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', 'admin@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'admin', 'active', 100, NOW(), NOW());

-- Insertar espacios
INSERT INTO catalog.spaces (id, owner_id, title, description, address, lat, lon, capacity, area_sqm, base_price_cents, amenities, rules, status, created_at, updated_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Balcón Céntrico Madrid', 'Hermoso balcón con vistas al centro de Madrid', 'Calle Gran Vía 28, Madrid', 40.4200, -3.7050, 10, 25.5, 3000, ARRAY['wifi', 'mesa', 'sillas'], '{"no_fumar": true, "mascotas": false}', 'active', NOW(), NOW()),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'Terraza con Piscina', 'Terraza amplia con piscina y barbacoa', 'Paseo de la Castellana 100, Madrid', 40.4400, -3.6900, 20, 80.0, 8000, ARRAY['piscina', 'barbacoa', 'wifi', 'parking'], '{"no_fumar": false, "mascotas": true}', 'active', NOW(), NOW()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'Patio Andaluz', 'Patio típico andaluz con macetas', 'Calle Sierpes 15, Sevilla', 37.3886, -5.9953, 15, 40.0, 4500, ARRAY['plantas', 'fuente', 'sombra'], '{"no_fumar": true, "mascotas": true}', 'active', NOW(), NOW()),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333', 'Balcón Minimalista', 'Espacio moderno y minimalista', 'Calle Valencia 200, Barcelona', 41.3874, 2.1686, 8, 18.0, 3500, ARRAY['wifi', 'vistas'], '{"no_fumar": true, "mascotas": false}', 'draft', NOW(), NOW());

-- Insertar slots de disponibilidad
INSERT INTO catalog.availability_slots (id, space_id, start_time, end_time, is_available, created_at) VALUES
(gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days 4 hours', true, NOW()),
(gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NOW() + INTERVAL '3 days', NOW() + INTERVAL '3 days 6 hours', true, NOW()),
(gen_random_uuid(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 8 hours', true, NOW()),
(gen_random_uuid(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NOW() + INTERVAL '5 days', NOW() + INTERVAL '5 days 10 hours', true, NOW()),
(gen_random_uuid(), 'cccccccc-cccc-cccc-cccc-cccccccccccc', NOW() + INTERVAL '4 days', NOW() + INTERVAL '4 days 5 hours', true, NOW());

SELECT 'Catalog Service: Datos insertados - 5 usuarios, 4 espacios, 5 slots disponibilidad' AS resultado;

