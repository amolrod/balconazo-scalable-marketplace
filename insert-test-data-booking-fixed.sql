-- Insertar datos de prueba en Booking DB - CORREGIDO
-- Reservas con IDs conocidos para Postman

\c booking_db;

-- Limpiar datos existentes
DELETE FROM booking.reviews WHERE true;
DELETE FROM booking.bookings WHERE true;

-- Insertar reservas - Con num_guests obligatorio
INSERT INTO booking.bookings (id, space_id, guest_id, start_ts, end_ts, status, total_price_cents, num_guests, payment_status, created_at) VALUES
(
    '10000000-0000-0000-0000-000000000001',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '33333333-3333-3333-3333-333333333333',
    '2025-11-05 10:00:00',
    '2025-11-05 14:00:00',
    'confirmed',
    14000,
    5,
    'succeeded',
    NOW()
),
(
    '10000000-0000-0000-0000-000000000002',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '33333333-3333-3333-3333-333333333333',
    '2025-11-10 16:00:00',
    '2025-11-10 20:00:00',
    'confirmed',
    20000,
    8,
    'succeeded',
    NOW()
),
(
    '10000000-0000-0000-0000-000000000003',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '44444444-4444-4444-4444-444444444444',
    '2025-11-15 18:00:00',
    '2025-11-15 23:00:00',
    'pending',
    37500,
    15,
    'pending',
    NOW()
),
(
    '10000000-0000-0000-0000-000000000004',
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    '44444444-4444-4444-4444-444444444444',
    '2025-11-20 09:00:00',
    '2025-11-20 13:00:00',
    'confirmed',
    10000,
    6,
    'succeeded',
    NOW()
),
(
    '10000000-0000-0000-0000-000000000005',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '44444444-4444-4444-4444-444444444444',
    '2025-10-25 15:00:00',
    '2025-10-25 19:00:00',
    'completed',
    14000,
    4,
    'succeeded',
    NOW() - INTERVAL '5 days'
);

-- Insertar reviews - Usar guest_id en lugar de user_id
INSERT INTO booking.reviews (id, booking_id, space_id, guest_id, rating, comment, created_at) VALUES
(
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000005',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '44444444-4444-4444-4444-444444444444',
    5,
    'Espacio increíble! Perfecto para nuestro evento.',
    NOW() - INTERVAL '4 days'
),
(
    '20000000-0000-0000-0000-000000000002',
    '10000000-0000-0000-0000-000000000001',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '33333333-3333-3333-3333-333333333333',
    4,
    'Muy buen espacio, excelente ubicación.',
    NOW() - INTERVAL '2 days'
);

-- Verificar inserción
SELECT
    LEFT(id::text, 8) as booking_id,
    LEFT(space_id::text, 8) as space,
    status,
    total_price_cents/100.0 as price_euros,
    start_ts
FROM booking.bookings
ORDER BY created_at;

SELECT
    LEFT(id::text, 8) as review_id,
    LEFT(space_id::text, 8) as space,
    rating,
    LEFT(comment, 50) as comment_preview
FROM booking.reviews;

