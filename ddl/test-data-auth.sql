-- ==========================================
-- DATOS DE PRUEBA - AUTH SERVICE (MySQL)
-- ==========================================

USE auth_db;

-- Limpiar datos existentes
DELETE FROM users;

-- Insertar usuarios de prueba
-- Contraseña: "password123" (encriptada con BCrypt)
INSERT INTO users (id, email, password_hash, role, active, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'host1@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'HOST', true, NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'guest1@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'GUEST', true, NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'host2@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'HOST', true, NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', 'guest2@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'GUEST', true, NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', 'admin@balconazo.com', '$2a$10$8K1p/XU5W5.vCjJXJlZZ3eGqP3VJ0TZ0Zt5YaQP3YxH8KzLc7QK8m', 'ADMIN', true, NOW(), NOW());

SELECT 'Auth Service: 5 usuarios insertados' AS resultado;

