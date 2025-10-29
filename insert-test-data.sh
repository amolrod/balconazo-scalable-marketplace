#!/usr/bin/env bash
#
# insert-test-data.sh - Insertar datos de prueba en todas las bases de datos
#

set -euo pipefail

echo "🔄 Insertando datos de prueba..."
echo ""

# Auth Service (MySQL)
echo "1️⃣ Auth Service (MySQL)..."
docker exec -i mysql-auth mysql -uroot < ddl/test-data-auth.sql
echo "✅ Auth Service OK"
echo ""

# Catalog Service (PostgreSQL)
echo "2️⃣ Catalog Service (PostgreSQL)..."
docker exec -i postgres-catalog psql -U postgres < ddl/test-data-catalog.sql
echo "✅ Catalog Service OK"
echo ""

# Booking Service (PostgreSQL)
echo "3️⃣ Booking Service (PostgreSQL)..."
docker exec -i postgres-booking psql -U postgres < ddl/test-data-booking.sql
echo "✅ Booking Service OK"
echo ""

# Search Service (PostgreSQL)
echo "4️⃣ Search Service (PostgreSQL)..."
docker exec -i postgres-search psql -U postgres < ddl/test-data-search.sql
echo "✅ Search Service OK"
echo ""

echo "🎉 Datos de prueba insertados correctamente"
echo ""
echo "📊 RESUMEN:"
echo "  • Auth: 5 usuarios"
echo "  • Catalog: 5 usuarios, 4 espacios, 5 slots disponibilidad"
echo "  • Booking: 3 reservas con eventos"
echo "  • Search: 3 espacios indexados"
echo ""
echo "🔑 CREDENCIALES DE PRUEBA:"
echo "  Email: host1@balconazo.com"
echo "  Password: password123"
echo ""

