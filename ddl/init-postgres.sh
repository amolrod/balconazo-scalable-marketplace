#!/bin/bash
set -e

# Configurar pg_hba.conf para permitir conexiones md5
cat > ${PGDATA}/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    all             all             0.0.0.0/0               md5
EOF

# Asegurar que el usuario postgres tiene la contraseña correcta
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER USER postgres WITH PASSWORD 'postgres';
    CREATE SCHEMA IF NOT EXISTS catalog;
    GRANT ALL ON SCHEMA catalog TO postgres;
EOSQL

echo "PostgreSQL configurado correctamente con contraseña"

