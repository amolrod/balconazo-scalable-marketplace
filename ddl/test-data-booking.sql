-- ==========================================
-- DATOS DE PRUEBA - BOOKING SERVICE (PostgreSQL)
-- ==========================================

\c booking_db

-- Limpiar datos existentes
TRUNCATE TABLE bookings.booking_events CASCADE;
TRUNCATE TABLE bookings.bookings CASCADE;

-- Insertar reservas de prueba
INSERT INTO bookings.bookings (id, space_id, guest_id, start_ts, end_ts, num_guests, price_cents, payment_method, payment_intent_id, status, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', NOW() + INTERVAL '10 days', NOW() + INTERVAL '10 days 4 hours', 5, 3000, 'STRIPE', 'pi_test_111', 'CONFIRMED', NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '44444444-4444-4444-4444-444444444444', NOW() + INTERVAL '15 days', NOW() + INTERVAL '15 days 8 hours', 12, 8000, 'STRIPE', 'pi_test_222', 'CONFIRMED', NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', NOW() + INTERVAL '7 days', NOW() + INTERVAL '7 days 3 hours', 8, 4500, 'STRIPE', NULL, 'PENDING', NOW(), NOW());

-- Insertar eventos de booking
INSERT INTO bookings.booking_events (id, booking_id, event_type, old_status, new_status, event_data, created_at) VALUES
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'BOOKING_CREATED', NULL, 'PENDING', '{"initial": true}', NOW() - INTERVAL '1 hour'),
(gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'BOOKING_CONFIRMED', 'PENDING', 'CONFIRMED', '{"payment_intent_id": "pi_test_111"}', NOW() - INTERVAL '30 minutes'),
(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'BOOKING_CREATED', NULL, 'PENDING', '{"initial": true}', NOW() - INTERVAL '2 hours'),
(gen_random_uuid(), '22222222-2222-2222-2222-222222222222', 'BOOKING_CONFIRMED', 'PENDING', 'CONFIRMED', '{"payment_intent_id": "pi_test_222"}', NOW() - INTERVAL '1 hour'),
(gen_random_uuid(), '33333333-3333-3333-3333-333333333333', 'BOOKING_CREATED', NULL, 'PENDING', '{"initial": true}', NOW() - INTERVAL '30 minutes');

SELECT 'Booking Service: 3 reservas insertadas con eventos' AS resultado;

