# 🔧 SOLUCIÓN DEFINITIVA - Ejecuta ESTE bloque completo

El problema es incompatibilidad entre el método de autenticación de PostgreSQL y el driver JDBC.

## ✅ Ejecuta TODO este bloque (copy-paste completo):

```bash
# Detener Spring Boot (Ctrl+C si está corriendo)

# Limpiar completamente
docker stop balconazo-pg-catalog 2>/dev/null
docker rm -f balconazo-pg-catalog 2>/dev/null
docker volume rm -f pg-catalog-data 2>/dev/null

# Levantar PostgreSQL con PLAINTEXT md5 (compatible con JDBC)
docker run -d \
  --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:16-alpine

# Esperar arranque
sleep 15

# Configurar pg_hba.conf para md5
docker exec balconazo-pg-catalog sh -c "echo 'host all all all md5' > /var/lib/postgresql/data/pg_hba.conf"
docker exec balconazo-pg-catalog sh -c "echo 'local all all trust' >> /var/lib/postgresql/data/pg_hba.conf"

# Recargar configuración
docker exec balconazo-pg-catalog psql -U postgres -c "SELECT pg_reload_conf();"

# Crear schema
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "CREATE SCHEMA IF NOT EXISTS catalog;"

# Verificar conexión
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "SELECT 'PostgreSQL listo' as status;"

echo "✅ PostgreSQL configurado correctamente"
echo "🚀 Ahora ejecuta:"
echo "cd /Users/angel/Desktop/BalconazoApp/catalog_microservice && mvn spring-boot:run"
```

## 📋 Pega TODO el bloque en tu terminal y luego pégame la salida completa.

