-- ===========================================
-- PARTE 1: AUTH SERVICE (MySQL)
-- ===========================================
-- Ejecutar en la base de datos auth_db (MySQL)
-- Usuario: test@test.com / Password: password123

INSERT INTO users (id, email, password_hash, full_name, created_at)
VALUES (
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',
    'test@test.com',
    '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq',  -- password123
    'Usuario de Prueba',
    NOW()
) ON DUPLICATE KEY UPDATE email = email;

-- 2. Reservas completadas en diferentes espacios (Booking Service)
-- Estas reservas permitirán al usuario dejar reseñas

-- Reserva 1: En "Terraza con vistas al mar" (COMPLETED)
INSERT INTO bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, created_at, updated_at
)
VALUES (
    'b1111111-1111-1111-1111-111111111111',
    'e3ab2d08-db34-48d7-9f62-1c8e5a7b9d3f',  -- Terraza con vistas al mar
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',  -- test@test.com
    NOW() - INTERVAL '20 days',  -- Hace 20 días
    NOW() - INTERVAL '18 days',  -- Hace 18 días
    4,
    12000,  -- 120€
    'COMPLETED',
    'succeeded',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '18 days'
) ON CONFLICT (id) DO NOTHING;

-- Reserva 2: En "Balcón urbano moderno" (COMPLETED)
INSERT INTO bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, created_at, updated_at
)
VALUES (
    'b2222222-2222-2222-2222-222222222222',
    'f4bc3e19-ec45-59e8-af73-2d9f6b8c0e4a',  -- Balcón urbano moderno
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',  -- test@test.com
    NOW() - INTERVAL '15 days',
    NOW() - INTERVAL '13 days',
    2,
    8000,  -- 80€
    'COMPLETED',
    'succeeded',
    NOW() - INTERVAL '16 days',
    NOW() - INTERVAL '13 days'
) ON CONFLICT (id) DO NOTHING;

-- Reserva 3: En "Azotea con jardín" (COMPLETED)
INSERT INTO bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, created_at, updated_at
)
VALUES (
    'b3333333-3333-3333-3333-333333333333',
    'a7d94f2b-3c81-4a6e-8b5f-9e2d1c4a6b8d',  -- Azotea con jardín
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',  -- test@test.com
    NOW() - INTERVAL '10 days',
    NOW() - INTERVAL '8 days',
    6,
    18000,  -- 180€
    'COMPLETED',
    'succeeded',
    NOW() - INTERVAL '11 days',
    NOW() - INTERVAL '8 days'
) ON CONFLICT (id) DO NOTHING;

-- Reserva 4: En "Terraza minimalista" (CONFIRMED - futura, no puede reseñar)
INSERT INTO bookings (
    id, space_id, guest_id, start_ts, end_ts, num_guests,
    total_price_cents, status, payment_status, created_at, updated_at
)
VALUES (
    'b4444444-4444-4444-4444-444444444444',
    'b8e05g3c-4d92-5b7g-9c6h-0f3e2d5b7c9e',  -- Terraza minimalista
    'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890',  -- test@test.com
    NOW() + INTERVAL '5 days',
    NOW() + INTERVAL '7 days',
    3,
    10000,  -- 100€
    'CONFIRMED',
    'succeeded',
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Mostrar resumen de lo creado
SELECT 
    '✅ Usuario creado' as resultado,
    email,
    full_name
FROM users 
WHERE id = 'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890';

SELECT 
    '✅ Reservas creadas' as resultado,
    COUNT(*) as total_reservas,
    SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) as completadas,
    SUM(CASE WHEN status = 'CONFIRMED' THEN 1 ELSE 0 END) as confirmadas
FROM bookings 
WHERE guest_id = 'a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890';
