-- ==========================================
-- DATOS DE PRUEBA - SEARCH SERVICE (PostgreSQL)
-- ==========================================

\c search_db

-- Limpiar datos existentes
TRUNCATE TABLE search.space_projections CASCADE;

-- Insertar proyecciones de espacios (con geometría PostGIS)
INSERT INTO search.space_projections (id, owner_id, owner_email, title, description, address, location, capacity, area_sqm, base_price_cents, current_price_cents, amenities, status, created_at, updated_at) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', 'Balcón Céntrico Madrid', 'Hermoso balcón con vistas al centro de Madrid', 'Calle Gran Vía 28, Madrid', ST_SetSRID(ST_MakePoint(-3.7050, 40.4200), 4326), 10, 25.5, 3000, 3000, ARRAY['wifi', 'mesa', 'sillas'], 'active', NOW(), NOW()),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', 'Terraza con Piscina', 'Terraza amplia con piscina y barbacoa', 'Paseo de la Castellana 100, Madrid', ST_SetSRID(ST_MakePoint(-3.6900, 40.4400), 4326), 20, 80.0, 8000, 8000, ARRAY['piscina', 'barbacoa', 'wifi', 'parking'], 'active', NOW(), NOW()),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'host2@balconazo.com', 'Patio Andaluz', 'Patio típico andaluz con macetas', 'Calle Sierpes 15, Sevilla', ST_SetSRID(ST_MakePoint(-5.9953, 37.3886), 4326), 15, 40.0, 4500, 4500, ARRAY['plantas', 'fuente', 'sombra'], 'active', NOW(), NOW());

SELECT 'Search Service: 3 espacios indexados con geolocalización' AS resultado;

