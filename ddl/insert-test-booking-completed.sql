-- Script para crear una reserva COMPLETADA para poder probar el sistema de reviews
-- Usuario: guest1@balconazo.com (ID: 33333333-3333-3333-3333-333333333333)
-- Espacio: e3ab2d08-db34-48d7-bdeb-bf37bb4d3458 (Terraza con Vista)

-- Conectar a la base de datos booking_db
\c booking_db

-- Eliminar reservas de prueba anteriores si existen
DELETE FROM bookings 
WHERE guest_id = '33333333-3333-3333-3333-333333333333' 
  AND space_id = 'e3ab2d08-db34-48d7-bdeb-bf37bb4d3458';

-- Insertar una reserva COMPLETADA
INSERT INTO bookings (
  id,
  space_id,
  guest_id,
  host_id,
  start_ts,
  end_ts,
  num_guests,
  total_price_cents,
  status,
  payment_intent_id,
  created_at,
  updated_at
) VALUES (
  '99999999-aaaa-bbbb-cccc-111111111111',
  'e3ab2d08-db34-48d7-bdeb-bf37bb4d3458', -- Espacio: Terraza con Vista
  '33333333-3333-3333-3333-333333333333', -- Guest: guest1@balconazo.com
  '11111111-1111-1111-1111-111111111111', -- Host: host1@balconazo.com
  '2025-11-15 10:00:00+00',
  '2025-11-15 18:00:00+00',
  4,
  15000, -- 150.00 EUR
  'completed',
  'pi_test_completed_booking',
  '2025-11-14 12:00:00+00',
  '2025-11-15 19:00:00+00'
);

-- Verificar la reserva
SELECT 
  id,
  space_id,
  guest_id,
  status,
  start_ts,
  end_ts
FROM bookings 
WHERE id = '99999999-aaaa-bbbb-cccc-111111111111';

-- Verificar que NO exista una review para esta reserva todavía
SELECT COUNT(*) as existing_reviews 
FROM reviews 
WHERE booking_id = '99999999-aaaa-bbbb-cccc-111111111111';

ECHO 'Reserva completada creada exitosamente!';
ECHO 'Usuario: guest1@balconazo.com (password: password123)';
ECHO 'Espacio: Terraza con Vista';
ECHO 'Booking ID: 99999999-aaaa-bbbb-cccc-111111111111';
ECHO '';
ECHO 'Ahora puedes:';
ECHO '1. Login en http://localhost:4200/login con guest1@balconazo.com';
ECHO '2. Ir al espacio e3ab2d08-db34-48d7-bdeb-bf37bb4d3458';
ECHO '3. Verás el botón "Escribir una reseña" porque tienes una reserva completada';
