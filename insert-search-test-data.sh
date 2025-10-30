#!/usr/bin/env bash
#
# insert-search-test-data.sh - Inserta datos de prueba en Search Service
#

set -euo pipefail

echo "📊 Insertando datos de prueba en Search Service..."

# Verificar que el contenedor esté corriendo
if ! docker ps | grep -q balconazo-pg-search; then
    echo "❌ El contenedor balconazo-pg-search no está corriendo"
    exit 1
fi

# Insertar datos de prueba usando conexión TCP
docker exec -i -e PGPASSWORD=postgres balconazo-pg-search psql -h 127.0.0.1 -U postgres -d search_db << 'EOF'

-- Limpiar datos anteriores
TRUNCATE TABLE search.spaces_projection CASCADE;

-- Insertar espacios de prueba
INSERT INTO search.spaces_projection
(space_id, owner_id, owner_email, title, description, address, geo, capacity, area_sqm, base_price_cents, amenities, status, avg_rating, total_reviews, created_at)
VALUES
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'host1@balconazo.com',
    'Ático con terraza en Madrid Centro',
    'Amplio ático con vistas panorámicas al centro de Madrid',
    'Calle Gran Vía 28, Madrid',
    ST_SetSRID(ST_MakePoint(-3.7038, 40.4168), 4326),
    8,
    50.5,
    2500,
    ARRAY['wifi', 'terraza', 'cocina', 'baño'],
    'active',
    4.5,
    12,
    NOW()
),
(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'host1@balconazo.com',
    'Loft moderno en Malasaña',
    'Loft de diseño en el corazón de Malasaña',
    'Calle Pez 15, Madrid',
    ST_SetSRID(ST_MakePoint(-3.7055, 40.4250), 4326),
    6,
    45.0,
    2000,
    ARRAY['wifi', 'aire_acondicionado', 'cocina'],
    'active',
    4.8,
    25,
    NOW()
),
(
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'host1@balconazo.com',
    'Estudio en Chueca',
    'Acogedor estudio en el barrio de Chueca',
    'Calle Hortaleza 50, Madrid',
    ST_SetSRID(ST_MakePoint(-3.6987, 40.4220), 4326),
    4,
    30.0,
    1500,
    ARRAY['wifi', 'cocina'],
    'active',
    4.2,
    8,
    NOW()
);

-- Verificar inserción
SELECT COUNT(*) as total_spaces FROM search.spaces_projection;

EOF

if [ $? -eq 0 ]; then
    echo "✅ Datos insertados correctamente en Search Service"
    echo ""
    echo "📋 IDs de espacios disponibles:"
    echo "   • aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa (Ático Madrid Centro)"
    echo "   • bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb (Loft Malasaña)"
    echo "   • cccccccc-cccc-cccc-cccc-cccccccccccc (Estudio Chueca)"
    echo ""
    echo "🧪 Prueba los endpoints:"
    echo "   curl http://localhost:8080/api/search/spaces/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    echo "   curl \"http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5\""
else
    echo "❌ Error al insertar datos"
    exit 1
fi

