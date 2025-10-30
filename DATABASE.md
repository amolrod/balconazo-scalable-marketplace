# 💾 DATABASE.md - Documentación de Bases de Datos

**Proyecto:** BalconazoApp  
**Versión:** 1.0.0  
**Fecha:** Octubre 2025

---

## 📋 Resumen de Bases de Datos

| Base de Datos | Motor | Puerto | Servicio | Esquema |
|---------------|-------|--------|----------|---------|
| **auth_db** | MySQL 8.0 | 3307 | Auth Service | `auth` |
| **catalog_db** | PostgreSQL 16 | 5433 | Catalog Service | `catalog` |
| **booking_db** | PostgreSQL 16 | 5434 | Booking Service | `booking` |
| **search_db** | PostgreSQL 16 + PostGIS | 5435 | Search Service | `search` |

---

## 🗄️ Auth Service (MySQL)

### Esquema `auth_db`

#### Tabla: `users`

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('HOST', 'GUEST', 'ADMIN')),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    trust_score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

**Datos de Prueba:**

| id | email | role | status |
|----|-------|------|--------|
| 11111111-1111-1111-1111-111111111111 | host1@balconazo.com | HOST | active |
| 33333333-3333-3333-3333-333333333333 | guest1@balconazo.com | GUEST | active |

**Password:** `password123` (hasheado con BCrypt)

---

## 🗄️ Catalog Service (PostgreSQL)

### Esquema `catalog`

#### Tabla: `spaces`

```sql
CREATE TABLE catalog.spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES catalog.users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255) NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lon DOUBLE PRECISION NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    base_price_cents INT NOT NULL CHECK (base_price_cents > 0),
    area_sqm DECIMAL(6,2),
    amenities TEXT[],
    rules JSONB,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_space_owner ON catalog.spaces(owner_id);
CREATE INDEX idx_space_status ON catalog.spaces(status);
CREATE INDEX idx_space_location ON catalog.spaces(lat, lon);
```

#### Tabla: `availability_slots`

```sql
CREATE TABLE catalog.availability_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL REFERENCES catalog.spaces(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    CHECK (end_time > start_time)
);
```

**Datos de Prueba:**

```sql
-- Ver script: insert-test-data-catalog-fixed.sql
-- 3 espacios en Madrid con diferentes características
```

---

## 🗄️ Booking Service (PostgreSQL)

### Esquema `booking`

#### Tabla: `bookings`

```sql
CREATE TABLE booking.bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    start_ts TIMESTAMP NOT NULL,
    end_ts TIMESTAMP NOT NULL,
    num_guests INT NOT NULL CHECK (num_guests > 0),
    total_price_cents INT NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    payment_intent_id VARCHAR(255),
    payment_status VARCHAR(50) CHECK (payment_status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded')),
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_booking_guest ON booking.bookings(guest_id);
CREATE INDEX idx_booking_space ON booking.bookings(space_id);
CREATE INDEX idx_booking_dates ON booking.bookings(start_ts, end_ts);
CREATE INDEX idx_booking_status ON booking.bookings(status);
```

#### Tabla: `reviews`

```sql
CREATE TABLE booking.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL UNIQUE REFERENCES booking.bookings(id),
    space_id UUID NOT NULL,
    guest_id UUID NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_review_space ON booking.reviews(space_id);
CREATE INDEX idx_review_guest ON booking.reviews(guest_id);
```

**Estados de Booking:**
- `pending`: Reserva creada, pago pendiente
- `confirmed`: Pago confirmado
- `completed`: Reserva finalizada (pasó la fecha)
- `cancelled`: Cancelada por usuario/sistema

**Datos de Prueba:**

```bash
# Generar bookings en diferentes estados
./reset-bookings-test-data.sh
```

---

## 🗄️ Search Service (PostgreSQL + PostGIS)

### Esquema `search`

#### Tabla: `spaces_projection`

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE search.spaces_projection (
    space_id UUID PRIMARY KEY,
    owner_id UUID NOT NULL,
    owner_email VARCHAR(255),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    address VARCHAR(255),
    geo GEOMETRY(POINT, 4326) NOT NULL,
    capacity INT NOT NULL,
    area_sqm DECIMAL(6,2),
    base_price_cents INT NOT NULL,
    amenities TEXT[],
    status VARCHAR(50) NOT NULL,
    avg_rating DOUBLE PRECISION DEFAULT 0,
    total_reviews INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Índice espacial (clave para performance)
CREATE INDEX idx_spaces_geo ON search.spaces_projection USING GIST(geo);
CREATE INDEX idx_spaces_status ON search.spaces_projection(status);
```

**Query Geoespacial Ejemplo:**

```sql
-- Buscar espacios en radio de 5km desde Gran Vía, Madrid
SELECT 
    space_id,
    title,
    ST_Distance(geo::geography, ST_MakePoint(-3.7038, 40.4168)::geography) / 1000 AS distance_km
FROM search.spaces_projection
WHERE ST_DWithin(
    geo::geography,
    ST_MakePoint(-3.7038, 40.4168)::geography,
    5000  -- 5km en metros
)
AND status = 'active'
ORDER BY distance_km
LIMIT 20;
```

---

## 🚀 Iniciar Bases de Datos Localmente

### 1. Con Docker Compose

```bash
# Iniciar todos los contenedores
cd /Users/angel/Desktop/BalconazoApp
docker-compose up -d mysql-auth pg-catalog pg-booking pg-search

# Verificar que estén corriendo
docker ps | grep -E "mysql|postgres"
```

### 2. Verificar Conectividad

```bash
# MySQL (Auth)
docker exec -it balconazo-mysql-auth mysql -uroot -proot -e "SHOW DATABASES;"

# PostgreSQL (Catalog)
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db -c "\dt catalog.*"

# PostgreSQL (Booking)
docker exec -it balconazo-pg-booking psql -U postgres -d booking_db -c "\dt booking.*"

# PostgreSQL + PostGIS (Search)
docker exec -it balconazo-pg-search psql -U postgres -d search_db -c "SELECT PostGIS_version();"
```

---

## 🔍 Consultar y Modificar Datos

### MySQL (Auth Service)

```bash
# Conectar al contenedor
docker exec -it balconazo-mysql-auth mysql -uroot -proot auth_db

# Queries útiles
SELECT id, email, role, status FROM users;
SELECT COUNT(*) FROM users WHERE role = 'HOST';

# Actualizar trust score
UPDATE users SET trust_score = 100 WHERE email = 'host1@balconazo.com';
```

### PostgreSQL (Catalog Service)

```bash
# Conectar
docker exec -e PGPASSWORD=postgres -it balconazo-pg-catalog psql -h 127.0.0.1 -U postgres -d catalog_db

# Queries útiles
SELECT id, title, status, capacity FROM catalog.spaces;
SELECT owner_id, COUNT(*) as total_spaces FROM catalog.spaces GROUP BY owner_id;

# Activar todos los espacios
UPDATE catalog.spaces SET status = 'active' WHERE status = 'draft';
```

### PostgreSQL (Booking Service)

```bash
# Conectar
docker exec -e PGPASSWORD=postgres -it balconazo-pg-booking psql -h 127.0.0.1 -U postgres -d booking_db

# Ver reservas por estado
SELECT status, COUNT(*) FROM booking.bookings GROUP BY status;

# Ver reviews con rating promedio
SELECT 
    space_id,
    AVG(rating) as avg_rating,
    COUNT(*) as total_reviews
FROM booking.reviews
GROUP BY space_id;

# Cambiar estado de booking manualmente (testing)
UPDATE booking.bookings SET status = 'confirmed' WHERE id = 'uuid-here';
```

### PostgreSQL + PostGIS (Search Service)

```bash
# Conectar
docker exec -e PGPASSWORD=postgres -it balconazo-pg-search psql -h 127.0.0.1 -U postgres -d search_db

# Ver espacios con distancia
SELECT 
    title,
    ST_AsText(geo) as coordinates,
    ST_Distance(geo::geography, ST_MakePoint(-3.7038, 40.4168)::geography) / 1000 as distance_km
FROM search.spaces_projection
ORDER BY distance_km
LIMIT 5;

# Recalcular rating promedio desde reviews
UPDATE search.spaces_projection sp
SET avg_rating = (
    SELECT AVG(rating) FROM booking.reviews WHERE space_id = sp.space_id
);
```

---

## 💾 Backups y Restauración

### Backup de MySQL

```bash
# Crear backup
docker exec balconazo-mysql-auth mysqldump -uroot -proot auth_db > backup_auth_$(date +%Y%m%d).sql

# Restaurar
docker exec -i balconazo-mysql-auth mysql -uroot -proot auth_db < backup_auth_20251030.sql
```

### Backup de PostgreSQL

```bash
# Catalog
docker exec balconazo-pg-catalog pg_dump -U postgres catalog_db > backup_catalog_$(date +%Y%m%d).sql

# Booking
docker exec balconazo-pg-booking pg_dump -U postgres booking_db > backup_booking_$(date +%Y%m%d).sql

# Search (incluye extensión PostGIS)
docker exec balconazo-pg-search pg_dump -U postgres search_db > backup_search_$(date +%Y%m%d).sql

# Restaurar
docker exec -i balconazo-pg-catalog psql -U postgres -d catalog_db < backup_catalog_20251030.sql
```

### Backup Automático (Cron)

```bash
# Agregar a crontab
# Backup diario a las 2 AM
0 2 * * * /path/to/backup-script.sh

# Script de backup
#!/bin/bash
BACKUP_DIR="/backups/balconazo"
DATE=$(date +%Y%m%d_%H%M%S)

docker exec balconazo-mysql-auth mysqldump -uroot -proot auth_db | gzip > $BACKUP_DIR/auth_$DATE.sql.gz
docker exec balconazo-pg-catalog pg_dump -U postgres catalog_db | gzip > $BACKUP_DIR/catalog_$DATE.sql.gz
docker exec balconazo-pg-booking pg_dump -U postgres booking_db | gzip > $BACKUP_DIR/booking_$DATE.sql.gz
docker exec balconazo-pg-search pg_dump -U postgres search_db | gzip > $BACKUP_DIR/search_$DATE.sql.gz

# Retener solo últimos 7 días
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
```

---

## 🔒 Acceso Seguro

### Credenciales (Desarrollo)

| BD | Usuario | Password | Host | Puerto |
|----|---------|----------|------|--------|
| MySQL Auth | root | root | localhost | 3307 |
| PG Catalog | postgres | postgres | localhost | 5433 |
| PG Booking | postgres | postgres | localhost | 5434 |
| PG Search | postgres | postgres | localhost | 5435 |

⚠️ **IMPORTANTE:** Cambiar credenciales en producción

### Configuración de Producción

```yaml
# application-prod.yml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}?ssl=true
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
```

### Variables de Entorno

```bash
# .env (NO commitear)
DB_HOST=prod-db.example.com
DB_PORT=5432
DB_USER=app_user
DB_PASSWORD=super_secure_password
DB_NAME=balconazo_prod
```

---

## 📊 Monitoring de Base de Datos

### Queries Lentas (PostgreSQL)

```sql
-- Habilitar log de queries lentas
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1 segundo
SELECT pg_reload_conf();

-- Ver queries activas
SELECT pid, usename, state, query, now() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Ver tablas más grandes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Índices Faltantes

```sql
-- Queries que se beneficiarían de índices
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'booking'
AND n_distinct > 100;
```

---

## 🛠️ Migraciones de Esquema

### Con Flyway (Recomendado)

```bash
# Estructura de archivos
src/main/resources/db/migration/
├── V1__create_initial_schema.sql
├── V2__add_trust_score_column.sql
└── V3__create_reviews_table.sql

# Aplicar migraciones
mvn flyway:migrate

# Rollback (Flyway Pro)
mvn flyway:undo
```

### Manual

```sql
-- V2__add_trust_score_column.sql
ALTER TABLE users ADD COLUMN trust_score INT DEFAULT 0;
CREATE INDEX idx_trust_score ON users(trust_score);
```

---

## 📈 Performance Tips

1. **Usar Connection Pooling** (HikariCP ya configurado)
2. **Índices en Foreign Keys** (implementado)
3. **EXPLAIN ANALYZE** para queries complejas
4. **Vacuuming regular** en PostgreSQL
5. **Caché de queries frecuentes** con Redis
6. **Particionado** para tablas grandes (bookings por fecha)

---

**Documento mantenido por:** Equipo de Backend  
**Última actualización:** Octubre 2025

