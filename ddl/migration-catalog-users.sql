-- Migración de la tabla users en catalog_db para modelo de roles dinámicos
-- Este script actualiza la estructura de catalog.users para alinearse con el nuevo modelo

\c catalog_db;

-- Agregar nuevas columnas
ALTER TABLE catalog.users 
ADD COLUMN IF NOT EXISTS name VARCHAR(100),
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS profile_image_url VARCHAR(500),
ADD COLUMN IF NOT EXISTS is_host BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_guest BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT TRUE;

-- Migrar datos existentes: asignar is_host basado en role
UPDATE catalog.users 
SET is_host = (role = 'HOST'),
    is_guest = (role = 'GUEST' OR role = 'ADMIN'),
    active = (status = 'active' OR status = 'ACTIVE')
WHERE role IS NOT NULL;

-- Establecer NOT NULL después de migrar datos
ALTER TABLE catalog.users
ALTER COLUMN is_host SET NOT NULL,
ALTER COLUMN is_guest SET NOT NULL,
ALTER COLUMN active SET NOT NULL;

-- Eliminar columnas antiguas
ALTER TABLE catalog.users 
DROP COLUMN IF EXISTS role,
DROP COLUMN IF EXISTS password_hash,
DROP COLUMN IF EXISTS status;

SELECT 'Migración de catalog.users completada ✅' AS status;
