#!/usr/bin/env bash
#
# reset-bookings-test-data.sh - Resetea y crea bookings de prueba en diferentes estados
#

set -euo pipefail

echo "🔄 Reseteando datos de bookings y creando estados de prueba..."
echo ""

# Verificar que el contenedor esté corriendo
CONTAINER_RUNNING=$(docker ps --format '{{.Names}}' | grep "balconazo-pg-booking" || echo "")
if [ -z "$CONTAINER_RUNNING" ]; then
    echo "❌ El contenedor balconazo-pg-booking no está corriendo"
    echo "ℹ️  Contenedores corriendo:"
    docker ps --format "   • {{.Names}}"
    exit 1
fi

echo "✅ Contenedor balconazo-pg-booking encontrado"

# Resetear y crear datos de prueba
docker exec -i -e PGPASSWORD=postgres balconazo-pg-booking psql -h 127.0.0.1 -U postgres -d booking_db << 'EOF'

-- Limpiar datos anteriores
TRUNCATE TABLE booking.reviews CASCADE;
TRUNCATE TABLE booking.bookings CASCADE;

-- Insertar bookings en diferentes estados para testing

-- 1. Booking en estado PENDING (para probar confirm)
INSERT INTO booking.bookings
(id, space_id, guest_id, start_ts, end_ts, num_guests, total_price_cents, status, payment_status, created_at)
VALUES
(
    'aaaaaaaa-1111-1111-1111-111111111111'::uuid,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    NOW() + INTERVAL '2 days',
    NOW() + INTERVAL '2 days' + INTERVAL '3 hours',
    2,
    7500,
    'pending',
    'pending',
    NOW()
);

-- 2. Booking en estado CONFIRMED (para probar complete)
INSERT INTO booking.bookings
(id, space_id, guest_id, start_ts, end_ts, num_guests, total_price_cents, status, payment_status, payment_intent_id, created_at)
VALUES
(
    'bbbbbbbb-2222-2222-2222-222222222222'::uuid,
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    NOW() + INTERVAL '3 days',
    NOW() + INTERVAL '3 days' + INTERVAL '4 hours',
    4,
    10000,
    'confirmed',
    'succeeded',
    'pi_confirmed_test_123',
    NOW()
);

-- 3. Booking en estado COMPLETED (para probar create review)
INSERT INTO booking.bookings
(id, space_id, guest_id, start_ts, end_ts, num_guests, total_price_cents, status, payment_status, payment_intent_id, created_at)
VALUES
(
    'cccccccc-3333-3333-3333-333333333333'::uuid,
    'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
    3,
    6000,
    'completed',
    'succeeded',
    'pi_completed_test_456',
    NOW()
);

-- 4. Booking adicional en PENDING (para probar cancel)
INSERT INTO booking.bookings
(id, space_id, guest_id, start_ts, end_ts, num_guests, total_price_cents, status, payment_status, created_at)
VALUES
(
    'dddddddd-4444-4444-4444-444444444444'::uuid,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    NOW() + INTERVAL '5 days',
    NOW() + INTERVAL '5 days' + INTERVAL '5 hours',
    6,
    15000,
    'pending',
    'pending',
    NOW()
);

-- Verificar inserción
SELECT
    id,
    status,
    payment_status,
    CASE
        WHEN status = 'pending' THEN '✅ Usar para CONFIRM'
        WHEN status = 'confirmed' THEN '✅ Usar para COMPLETE'
        WHEN status = 'completed' THEN '✅ Usar para CREATE REVIEW'
    END as accion_disponible
FROM booking.bookings
ORDER BY created_at;

-- Contar
SELECT COUNT(*) as total_bookings FROM booking.bookings;
SELECT COUNT(*) as total_reviews FROM booking.reviews;

EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Datos reseteados e insertados correctamente"
    echo ""
    echo "================================================================"
    echo "IDs DE BOOKINGS POR ESTADO:"
    echo "================================================================"
    echo ""
    echo "1. Para CONFIRMAR (status: pending):"
    echo "   ID: aaaaaaaa-1111-1111-1111-111111111111"
    echo "   POST /api/booking/bookings/aaaaaaaa-1111-1111-1111-111111111111/confirm?paymentIntentId=pi_test_123"
    echo ""
    echo "2. Para COMPLETAR (status: confirmed):"
    echo "   ID: bbbbbbbb-2222-2222-2222-222222222222"
    echo "   POST /api/booking/bookings/bbbbbbbb-2222-2222-2222-222222222222/complete"
    echo ""
    echo "3. Para CREAR REVIEW (status: completed):"
    echo "   ID: cccccccc-3333-3333-3333-333333333333"
    echo "   POST /api/booking/reviews"
    echo "   Body: {\"bookingId\": \"cccccccc-3333-3333-3333-333333333333\", \"rating\": 5, \"comment\": \"Excelente\"}"
    echo ""
    echo "4. Para CANCELAR (status: pending):"
    echo "   ID: dddddddd-4444-4444-4444-444444444444"
    echo "   POST /api/booking/bookings/dddddddd-4444-4444-4444-444444444444/cancel?reason=Test"
    echo ""
    echo "================================================================"
    echo ""
    echo "IMPORTANTE: Cada operacion solo funciona UNA VEZ por booking"
    echo "Si quieres probar de nuevo, ejecuta este script otra vez"
    echo ""
else
    echo "❌ Error al resetear datos"
    exit 1
fi

