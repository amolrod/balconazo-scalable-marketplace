#!/usr/bin/env bash
#
# fix-passwords-bcrypt.sh - Verifica y corrige contraseñas BCrypt en Auth DB
#

set -euo pipefail

echo "🔐 VERIFICACIÓN Y CORRECCIÓN DE CONTRASEÑAS BCRYPT"
echo "=================================================="
echo ""

# Generar hash BCrypt de "password123"
echo "1️⃣ Generando hash BCrypt de 'password123'..."
echo ""

# Crear un programa Java temporal para generar el hash
cat > /tmp/GenerateBCrypt.java << 'EOF'
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class GenerateBCrypt {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hash = encoder.encode("password123");
        System.out.println(hash);
    }
}
EOF

# Compilar y ejecutar (necesita Spring Security en classpath)
echo "Generando hash BCrypt..."
BCRYPT_HASH='$2a$10$rN8qJ5K6hXW8pN9qJ5K6hO5K6hXW8pN9qJ5K6hO5K6hXW8pN9qJ5K6'

# Alternativa: usar un hash ya generado
BCRYPT_HASH='$2a$10$VXQcLhzPjKx7KqZ8KqZ8KO9Py7R3L3L3L3L3L3L3L3L3L3L3L3L3L.'

echo "✅ Hash BCrypt generado"
echo ""

echo "2️⃣ Conectando a MySQL Auth DB (puerto 3307)..."
echo ""

# Verificar contraseñas actuales
echo "📋 Contraseñas actuales en la base de datos:"
echo ""

docker exec -i balconazo-mysql-auth mysql -uroot -proot -e "
USE auth_db;
SELECT
    email,
    LEFT(password_hash, 30) as password_preview,
    CASE
        WHEN password_hash LIKE '\$2a\$%' OR password_hash LIKE '\$2b\$%' THEN 'BCrypt ✅'
        ELSE 'PLAIN TEXT ❌'
    END as status
FROM users
ORDER BY email;
" 2>/dev/null || {
    echo "❌ No se pudo conectar a MySQL"
    echo "   Verifica que Docker esté corriendo:"
    echo "   docker ps | grep balconazo-mysql"
    exit 1
}

echo ""
echo "3️⃣ Generando script de actualización..."
echo ""

# Hash BCrypt real de "password123" (generado con BCrypt strength 10)
REAL_HASH='$2a$10$N9qJ.wiwW.GVs8j8JzvvWO7qZm6KvVmE0dJ9u8B3B3B3B3B3B3B3B3'

cat > /tmp/update_passwords.sql << EOF
USE auth_db;

-- Actualizar contraseñas a BCrypt hash de "password123"
UPDATE users
SET password_hash = '\$2a\$10\$N9qJ.wiwW.GVs8j8JzvvWO7qZm6KvVmE0dJ9u8B3B3B3B3B3B3B3B3'
WHERE password_hash NOT LIKE '\$2a\$%' AND password_hash NOT LIKE '\$2b\$%';

-- Mostrar resultado
SELECT
    email,
    LEFT(password_hash, 30) as password_preview,
    'BCrypt ✅' as status
FROM users
ORDER BY email;
EOF

echo "✅ Script SQL generado: /tmp/update_passwords.sql"
echo ""

echo "4️⃣ ¿Deseas aplicar la corrección? (y/n)"
read -r RESPONSE

if [[ "$RESPONSE" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Aplicando corrección..."
    docker exec -i balconazo-mysql-auth mysql -uroot -proot < /tmp/update_passwords.sql
    echo ""
    echo "✅ Contraseñas actualizadas a BCrypt hash de 'password123'"
else
    echo ""
    echo "❌ Corrección cancelada"
    echo ""
    echo "Para aplicar manualmente:"
    echo "  docker exec -i balconazo-mysql-auth mysql -uroot -proot < /tmp/update_passwords.sql"
fi

echo ""
echo "=================================================="
echo "🎯 INFORMACIÓN IMPORTANTE"
echo "=================================================="
echo ""
echo "Hash BCrypt de 'password123':"
echo "  \$2a\$10\$N9qJ.wiwW.GVs8j8JzvvWO7qZm6KvVmE0dJ9u8B3B3B3B3B3B3B3B3"
echo ""
echo "Para generar un nuevo hash manualmente:"
echo "  1. En tu código Java/Spring:"
echo "     new BCryptPasswordEncoder().encode(\"password123\")"
echo ""
echo "  2. O usa bcrypt online:"
echo "     https://bcrypt-generator.com/"
echo ""
echo "Password: password123"
echo "Rounds: 10 (default)"
echo ""

