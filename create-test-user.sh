#!/bin/bash

echo "🚀 Creando usuario de prueba con reservas completadas..."
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Crear usuario en Auth Service (MySQL)
echo -e "${BLUE}📝 Paso 1: Creando usuario en Auth Service (MySQL)...${NC}"
docker exec -i balconazo-mysql-auth mysql -uroot -proot auth_db <<EOF
INSERT INTO users (id, email, password_hash, name, active, is_guest, is_host, created_at)
VALUES (
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',
    'test@test.com',
    '\$2a\$10\$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq',
    'Usuario de Prueba',
    1,
    1,
    0,
    NOW()
) ON DUPLICATE KEY UPDATE email = email;

SELECT '✅ Usuario creado/verificado' as resultado, email, name 
FROM users 
WHERE id = 'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890';
EOF

echo ""
echo -e "${BLUE}📝 Paso 2: Creando reservas completadas en Booking Service (Postgres)...${NC}"

# 2. Crear reservas en Booking Service (Postgres)
docker exec -i balconazo-pg-booking psql -U postgres -d booking_db <<EOF
-- Reserva 1: En "Terraza con vistas al mar" (COMPLETED - pasada)
INSERT INTO booking.bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, payment_intent_id, created_at, updated_at
)
VALUES (
    'b1111111-1111-1111-1111-111111111111',
    'e3ab2d08-db34-48d7-9f62-1c8e5a7b9d3f',
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',
    NOW() - INTERVAL '20 days',
    NOW() - INTERVAL '18 days',
    4,
    12000,
    'completed',
    'succeeded',
    'pi_test_1',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '18 days'
) ON CONFLICT (id) DO NOTHING;

-- Reserva 2: En "Balcón urbano moderno" (COMPLETED - pasada)
INSERT INTO booking.bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, payment_intent_id, created_at, updated_at
)
VALUES (
    'b2222222-2222-2222-2222-222222222222',
    'f4bc3e19-ec45-59e8-af73-2d9f6b8c0e4a',
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '13 days',
    2,
    8000,
    'completed',
    'succeeded',
    'pi_test_2',
    NOW() - INTERVAL '16 days',
    NOW() - INTERVAL '13 days'
) ON CONFLICT (id) DO NOTHING;

-- Reserva 3: En "Azotea con jardín" (COMPLETED - pasada)
INSERT INTO booking.bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, payment_intent_id, created_at, updated_at
)
VALUES (
    'b3333333-3333-3333-3333-333333333333',
    'a7d94f2b-3c81-4a6e-8b5f-9e2d1c4a6b8d',
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '8 days',
    6,
    18000,
    'completed',
    'succeeded',
    'pi_test_3',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '8 days'
) ON CONFLICT (id) DO NOTHING;

-- Resumen
SELECT 
    '✅ Reservas creadas' as resultado,
    COUNT(*) as total,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completadas
FROM booking.bookings 
WHERE guest_id = 'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890';
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Usuario de prueba creado con éxito${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Credenciales de acceso:${NC}"
echo -e "  📧 Email: ${BLUE}test@test.com${NC}"
echo -e "  🔑 Password: ${BLUE}password123${NC}"
echo ""
echo -e "${YELLOW}Reservas completadas:${NC}"
echo "  ✅ 3 reservas pasadas (puede dejar reseñas)"
echo ""
echo -e "${YELLOW}Espacios donde puede dejar reseñas:${NC}"
echo "  1. Terraza con vistas al mar"
echo "  2. Balcón urbano moderno"
echo "  3. Azotea con jardín"
echo ""
echo -e "${GREEN}🎉 Ahora puedes iniciar sesión y probar el sistema de reseñas${NC}"
