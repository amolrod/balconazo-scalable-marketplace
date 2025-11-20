-- ==========================================
-- MIGRACIÓN: Modelo de Roles Estáticos → Roles Dinámicos
-- ==========================================
-- Fecha: 20 Noviembre 2025
-- Ref: ADR-002 (docs/ADR_MODELO_ROLES_DINAMICOS.md)
--
-- CAMBIOS:
-- 1. Eliminar columna role (enum ADMIN|GUEST|HOST)
-- 2. Agregar columna is_host BOOLEAN DEFAULT FALSE
-- 3. Agregar columna is_guest BOOLEAN DEFAULT TRUE
-- 4. Agregar columna name VARCHAR(100)
-- 5. Agregar columna phone VARCHAR(20) NULLABLE
-- 6. Agregar columna profile_image_url VARCHAR(500) NULLABLE
-- 7. Migrar datos existentes según rol antiguo
-- ==========================================

USE auth_db;

-- Paso 1: Agregar nuevas columnas
ALTER TABLE users 
  ADD COLUMN is_host BOOLEAN NOT NULL DEFAULT FALSE AFTER active,
  ADD COLUMN is_guest BOOLEAN NOT NULL DEFAULT TRUE AFTER is_host,
  ADD COLUMN name VARCHAR(100) AFTER email,
  ADD COLUMN phone VARCHAR(20) AFTER name,
  ADD COLUMN profile_image_url VARCHAR(500) AFTER phone;

-- Paso 2: Migrar datos existentes según rol antiguo
-- Usuarios con rol HOST → is_host=true, is_guest=true
UPDATE users SET is_host = TRUE, is_guest = TRUE WHERE role = 'HOST';

-- Usuarios con rol GUEST → is_host=false, is_guest=true
UPDATE users SET is_host = FALSE, is_guest = TRUE WHERE role = 'GUEST';

-- Usuarios con rol ADMIN → is_host=true, is_guest=true (acceso completo)
UPDATE users SET is_host = TRUE, is_guest = TRUE WHERE role = 'ADMIN';

-- Paso 3: Rellenar campo name con valor por defecto para usuarios existentes
UPDATE users SET name = CONCAT('User ', SUBSTRING(id, 1, 8)) WHERE name IS NULL;

-- Paso 4: Hacer name NOT NULL después de rellenarlo
ALTER TABLE users MODIFY COLUMN name VARCHAR(100) NOT NULL;

-- Paso 5: Eliminar columna role (ya no se usa)
ALTER TABLE users DROP COLUMN role;

-- Verificación
SELECT 
    id, 
    email, 
    name,
    is_host, 
    is_guest, 
    active,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- Resultado esperado:
-- - Todos los usuarios antiguos con HOST: is_host=1, is_guest=1
-- - Todos los usuarios antiguos con GUEST: is_host=0, is_guest=1
-- - Todos los usuarios antiguos con ADMIN: is_host=1, is_guest=1
-- - Todos tienen name rellenado
-- - Columna role ya no existe

SELECT 'Migración completada: Modelo de roles dinámicos activado ✅' AS resultado;
