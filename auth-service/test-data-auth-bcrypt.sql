-- Insertar datos de prueba en Auth DB con contraseñas BCrypt
-- Password para todos: "password123"
-- Hash BCrypt: $2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq

USE auth_db;

-- Eliminar usuarios existentes
DELETE FROM users;

-- Insertar usuarios con contraseñas BCrypt
INSERT INTO users (id, email, password_hash, role, active, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq', 'HOST', true, NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'host2@balconazo.com', '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq', 'HOST', true, NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'guest1@balconazo.com', '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq', 'GUEST', true, NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', 'guest2@balconazo.com', '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq', 'GUEST', true, NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', 'admin@balconazo.com', '$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq', 'HOST', true, NOW(), NOW());

-- Verificar inserción
SELECT
    email,
    role,
    active,
    LEFT(password_hash, 40) as hash_preview,
    CASE
        WHEN password_hash LIKE '$2a$%' THEN '✅ BCrypt'
        ELSE '❌ Plain'
    END as status
FROM users
ORDER BY role, email;

