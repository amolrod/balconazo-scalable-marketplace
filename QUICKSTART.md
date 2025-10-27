# 🚀 Guía de Inicio Rápido - Catalog Service

## ⚡ Inicio en 3 Pasos (5 minutos)

### Paso 1️⃣: Levantar PostgreSQL

```bash
cd /Users/angel/Desktop/BalconazoApp
docker-compose up -d postgres-catalog
```

**Verificar:**
```bash
docker ps | grep postgres
```

Deberías ver:
```
postgres-catalog   Up   0.0.0.0:5433->5432/tcp
```

---

### Paso 2️⃣: Ejecutar el Servicio

```bash
cd catalog_microservice
mvn spring-boot:run
```

**Esperarás ver:**
```
Started CatalogMicroserviceApplication in 4.2 seconds
Tomcat started on port 8081
```

---

### Paso 3️⃣: Probar

```bash
curl http://localhost:8081/actuator/health
```

**Respuesta esperada:**
```json
{"status":"UP"}
```

---

## 🧪 Pruebas Rápidas

### 1. Crear un Usuario Host

```bash
curl -X POST http://localhost:8081/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "maria@balconazo.com",
    "password": "securepass123",
    "role": "host"
  }'
```

**Respuesta esperada:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "maria@balconazo.com",
  "role": "host",
  "trustScore": 0,
  "status": "active",
  "createdAt": "2025-10-27T12:30:00",
  "updatedAt": "2025-10-27T12:30:00"
}
```

**Guarda el `id` del usuario para el siguiente paso.**

---

### 2. Crear un Espacio

```bash
# Reemplaza USER_ID con el id del paso anterior
USER_ID="550e8400-e29b-41d4-a716-446655440000"

curl -X POST http://localhost:8081/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerId\": \"$USER_ID\",
    \"title\": \"Balcón con vistas al mar\",
    \"description\": \"Hermoso balcón de 25m² con vistas panorámicas\",
    \"capacity\": 20,
    \"areaSqm\": 25.5,
    \"address\": \"Paseo Marítimo 15, Valencia\",
    \"lat\": 39.4699,
    \"lon\": -0.3763,
    \"basePriceCents\": 12000
  }"
```

**Respuesta esperada:**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "ownerId": "550e8400-e29b-41d4-a716-446655440000",
  "ownerEmail": "maria@balconazo.com",
  "title": "Balcón con vistas al mar",
  "description": "Hermoso balcón de 25m² con vistas panorámicas",
  "capacity": 20,
  "areaSqm": 25.5,
  "address": "Paseo Marítimo 15, Valencia",
  "lat": 39.4699,
  "lon": -0.3763,
  "basePriceCents": 12000,
  "status": "draft",
  "createdAt": "2025-10-27T12:35:00",
  "updatedAt": "2025-10-27T12:35:00"
}
```

**Guarda el `id` del espacio.**

---

### 3. Activar el Espacio (Publicarlo)

```bash
SPACE_ID="660e8400-e29b-41d4-a716-446655440001"

curl -X POST http://localhost:8081/api/catalog/spaces/$SPACE_ID/activate
```

---

### 4. Añadir Disponibilidad

```bash
curl -X POST http://localhost:8081/api/catalog/availability \
  -H "Content-Type: application/json" \
  -d "{
    \"spaceId\": \"$SPACE_ID\",
    \"startTs\": \"2025-12-31T18:00:00\",
    \"endTs\": \"2026-01-01T06:00:00\",
    \"maxGuests\": 20
  }"
```

---

### 5. Listar Espacios Activos

```bash
curl http://localhost:8081/api/catalog/spaces
```

---

## 📋 Comandos Útiles

### Ver Logs

```bash
# En la terminal donde ejecutaste mvn spring-boot:run
# Los logs aparecen automáticamente
```

### Detener el Servicio

```bash
# Presiona Ctrl+C en la terminal del servicio
```

### Detener PostgreSQL

```bash
docker-compose down postgres-catalog
```

### Ver Base de Datos

```bash
docker exec -it postgres-catalog psql -U catalog_user -d catalog_db

# Dentro de psql:
\dt catalog.*           # Listar tablas
SELECT * FROM catalog.users;
SELECT * FROM catalog.spaces;
\q                      # Salir
```

---

## 🐛 Solución de Problemas

### PostgreSQL no inicia

```bash
# Ver logs
docker logs postgres-catalog

# Reiniciar
docker-compose restart postgres-catalog
```

### Puerto 8081 ya está en uso

```bash
# Cambiar puerto en application.yml
# O detener el proceso que usa el puerto:
lsof -ti:8081 | xargs kill -9
```

### Error de conexión a base de datos

```bash
# Verificar que PostgreSQL está corriendo
docker ps | grep postgres

# Verificar configuración en application.yml
# url: jdbc:postgresql://localhost:5433/catalog_db
```

---

## 📚 Próximos Pasos

1. ✅ Servicio funcionando
2. ➡️ Prueba todos los endpoints con Postman
3. ➡️ Implementa el microservicio de booking
4. ➡️ Implementa el microservicio de search
5. ➡️ Conecta con Kafka para eventos

---

## 🎯 Endpoints Disponibles

| Recurso | Endpoint Base |
|---------|---------------|
| Users | `/api/catalog/users` |
| Spaces | `/api/catalog/spaces` |
| Availability | `/api/catalog/availability` |
| Health | `/actuator/health` |

Ver documentación completa en `README.md`

---

**¡Listo! 🎉 El servicio está corriendo y funcional.**

