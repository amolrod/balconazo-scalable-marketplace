# ❌ PROBLEMA PERSISTENTE - Password Authentication

El error **"password authentication failed for user postgres"** persiste incluso después de recrear el contenedor y volumen.

## 🔍 Solución Final - Manual Step

Ejecuta en tu terminal AHORA:

```bash
# 1. Detener servicio Spring Boot (Ctrl+C en la terminal del servicio)

# 2. Eliminar completamente PostgreSQL
docker stop balconazo-pg-catalog 2>/dev/null
docker rm -f balconazo-pg-catalog 2>/dev/null
docker volume rm pg-catalog-data 2>/dev/null

# 3. Levantar PostgreSQL SIN autenticación temporalmente
docker run -d --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  postgres:16-alpine

# 4. Esperar 10 segundos
sleep 10

# 5. Cambiar la contraseña dentro del contenedor
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db -c "ALTER USER postgres WITH PASSWORD 'postgres';"

# 6. Crear schema
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "CREATE SCHEMA IF NOT EXISTS catalog;"

# 7. Reiniciar el contenedor con autenticación normal
docker restart balconazo-pg-catalog

# 8. Esperar 8 segundos
sleep 8

# 9. Ejecutar servicio
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

## 📝 O usa esta alternativa MÁS SIMPLE:

```bash
# Eliminar todo
docker stop balconazo-pg-catalog 2>/dev/null
docker rm -f balconazo-pg-catalog 2>/dev/null  
docker volume rm -f pg-catalog-data 2>/dev/null

# Levantar con variable TRUST
docker run -d --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -v pg-catalog-data:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 12

# Verificar
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "SELECT version();"

# Crear schema
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "CREATE SCHEMA IF NOT EXISTS catalog;"

# Ejecutar servicio
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

**Ejecuta UNO de estos dos bloques de comandos y pégame la salida.**

