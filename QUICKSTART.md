# QuickStart - Balconazo

**Objetivo:** Levantar el stack completo de Balconazo en tu máquina local en **menos de 30 minutos**.

**Stack:** 3 microservicios (Spring Boot 3.3 + Java 21), API Gateway, Kafka, 3 PostgreSQL, Redis, Angular 20.

**Nota:** Esta guía usa **autenticación simplificada** (JWT sin Keycloak). Ver [docs/AUTH_SIMPLIFIED.md](../docs/AUTH_SIMPLIFIED.md) para detalles.

---

## ⏱️ Tiempo Estimado: 25-30 minutos

| Paso | Duración | Descripción |
|------|----------|-------------|
| 1. Pre-requisitos | 2 min | Verificar versiones de herramientas |
| 2. Clonar repo | 1 min | Git clone |
| 3. Levantar infra | 3 min | Docker Compose (Kafka, Postgres, Redis, Keycloak) |
| 4. Crear tópicos Kafka | 2 min | Crear 7 tópicos |
| 5. Compilar backend | 5 min | Maven clean install |
| 6. Levantar servicios | 3 min | Docker Compose (Gateway + 3 microservicios) |
| 7. Health checks | 1 min | Verificar todos los servicios |
| 8. Seed data | 3 min | Crear usuario + espacio de prueba |
| 9. Levantar frontend | 3 min | npm install + npm start |
| 10. Flujo E2E | 5 min | Buscar → Ver detalle → Crear booking |

---

## 1️⃣ Pre-requisitos (2 min)

Verifica que tienes las versiones correctas instaladas:

```bash
# Java 21
java -version
# Debe mostrar: openjdk version "21.x.x" o superior

# Maven 3.9+
mvn -version
# Debe mostrar: Apache Maven 3.9.x o superior

# Docker 24+
docker --version
# Debe mostrar: Docker version 24.x.x o superior

# Docker Compose
docker-compose --version
# Debe mostrar: Docker Compose version 2.x.x o superior

# Node.js 20+
node --version
# Debe mostrar: v20.x.x o superior

# npm 10+
npm --version
# Debe mostrar: 10.x.x o superior
```

**Si falta alguna herramienta:**
- Java 21: https://adoptium.net/
- Maven: https://maven.apache.org/download.cgi
- Docker Desktop: https://www.docker.com/products/docker-desktop
- Node.js: https://nodejs.org/en/download/

---

## 2️⃣ Clonar el Repositorio (1 min)

```bash
git clone https://github.com/amolrod/balconazo-scalable-marketplace.git
cd balconazo-scalable-marketplace
```

Verifica la estructura:
```bash
ls -la
# Deberías ver: docker-compose.yml, backend/, frontend/, ddl/, README.md, etc.
```

---

Inicia Kafka, ZooKeeper, Redis y 3 bases de datos PostgreSQL:

Inicia Kafka, ZooKeeper, Redis, 3 bases de datos PostgreSQL y Keycloak:
docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search
```bash

**Nota:** NO levantamos Keycloak en MVP - autenticación JWT simplificada en Gateway.
docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search keycloak
```

**Espera 60 segundos** para que todos los servicios inicialicen correctamente:
```bash
sleep 60
```

Verifica que todos los contenedores están corriendo:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Output esperado:**
```
NAMES               STATUS              PORTS
zookeeper           Up 1 minute         0.0.0.0:2181->2181/tcp
kafka               Up 1 minute         0.0.0.0:29092->29092/tcp, 9092/tcp
pg-catalog          Up 1 minute         0.0.0.0:5433->5432/tcp

**Total: 6 contenedores** (sin Keycloak)
pg-booking          Up 1 minute         0.0.0.0:5434->5432/tcp
pg-search           Up 1 minute         0.0.0.0:5435->5432/tcp
keycloak            Up 1 minute         0.0.0.0:8081->8080/tcp
```

✅ **Checkpoint:** Todos los contenedores deben estar "Up" sin reinicios constantes.

---

## 4️⃣ Crear Tópicos Kafka (2 min)

Crea los 7 tópicos necesarios con 12 particiones cada uno:

```bash
# space.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic space.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

# availability.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic availability.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

# booking.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic booking.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

# payment.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic payment.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

# review.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic review.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=1209600000

# pricing.events.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic pricing.events.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=604800000

# analytics.search.v1
docker exec -it kafka kafka-topics.sh --create \
  --topic analytics.search.v1 \
  --bootstrap-server localhost:9092 \
  --partitions 12 \
  --replication-factor 1 \
  --config retention.ms=172800000
```

**Verifica que se crearon correctamente:**
```bash
docker exec -it kafka kafka-topics.sh --list --bootstrap-server localhost:9092
```

**Output esperado:**
```
analytics.search.v1
availability.events.v1
booking.events.v1
payment.events.v1
pricing.events.v1
review.events.v1
space.events.v1
```

✅ **Checkpoint:** Debes ver los 7 tópicos listados.

---

## 5️⃣ Compilar Microservicios Backend (5 min)

Compila todos los módulos Maven (parent POM + 3 microservicios):

```bash
cd backend

# Compilar sin ejecutar tests (para acelerar)
mvn clean install -DskipTests

cd ..
```

**Output esperado (al final):**
```
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] BalconazoApp - Parent ............................... SUCCESS [  0.5 s]
[INFO] catalog-service ..................................... SUCCESS [  45 s]
[INFO] booking-service ..................................... SUCCESS [  42 s]
[INFO] search-pricing-service .............................. SUCCESS [  48 s]
[INFO] api-gateway ......................................... SUCCESS [  35 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

✅ **Checkpoint:** "BUILD SUCCESS" sin errores de compilación.

---

## 6️⃣ Levantar Microservicios (3 min)

Inicia el API Gateway y los 3 microservicios:

```bash
docker-compose up -d api-gateway catalog-service booking-service search-pricing-service
```

**Espera 30 segundos** para que los servicios Spring Boot inicialicen:
```bash
sleep 30
```

Verifica que todos están corriendo:
```bash
docker ps | grep -E "(gateway|catalog|booking|search)"
```

**Output esperado:**
```
api-gateway              Up 30 seconds       0.0.0.0:8080->8080/tcp
catalog-service          Up 30 seconds       0.0.0.0:8081->8081/tcp
booking-service          Up 30 seconds       0.0.0.0:8082->8082/tcp
search-pricing-service   Up 30 seconds       0.0.0.0:8083->8083/tcp
```

✅ **Checkpoint:** 4 contenedores de servicios "Up" sin reinicios.

---

## 7️⃣ Health Checks (1 min)

Verifica que todos los servicios responden correctamente:

```bash
# API Gateway
curl -s http://localhost:8080/actuator/health | jq .
# Esperado: {"status":"UP"}

# Catalog Service
curl -s http://localhost:8081/actuator/health | jq .
# Esperado: {"status":"UP","components":{"db":{"status":"UP"},"kafka":{"status":"UP"}}}

# Booking Service
curl -s http://localhost:8082/actuator/health | jq .
# Esperado: {"status":"UP","components":{"db":{"status":"UP"},"kafka":{"status":"UP"}}}

# Search-Pricing Service
curl -s http://localhost:8083/actuator/health | jq .
# Esperado: {"status":"UP","components":{"db":{"status":"UP"},"kafka":{"status":"UP"}}}
```

**Si no tienes `jq` instalado**, omítelo y verifica manualmente que el JSON contiene `"status":"UP"`.

✅ **Checkpoint:** Todos los servicios devuelven `{"status":"UP"}`.

---

## 8️⃣ Seed Data Inicial (3 min)

Crea datos de prueba: 1 usuario host + 1 espacio + 1 slot de disponibilidad.

### a) Crear Usuario Host
```bash
curl -X POST http://localhost:8080/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@balconazo.com",
    "role": "host"
  }' | jq .
```

**Respuesta esperada:**
```json
{
  "id": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "email": "host@balconazo.com",
  "role": "host",
  "trustScore": 0,
  "status": "active",
  "createdAt": "2025-10-25T21:00:00.000Z"
}
```

**⚠️ Guarda el `id` del usuario** (lo necesitarás en el siguiente paso).

### b) Crear Espacio
Reemplaza `{USER_ID}` con el ID obtenido arriba:

```bash
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "{USER_ID}",
    "title": "Terraza con vistas al Retiro",
    "capacity": 15,
    "lat": 40.4168,
    "lon": -3.7038,
    "basePriceCents": 3500,
    "address": "Calle Alcalá 123, Madrid",
    "rules": {
      "noSmoking": true,
      "maxNoise": "moderate"
    }
  }' | jq .
```

**Respuesta esperada:**
```json
{
  "id": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
  "ownerId": "f3f2d5e0-1234-5678-90ab-cdef87654321",
  "title": "Terraza con vistas al Retiro",
  "capacity": 15,
  "lat": 40.4168,
  "lon": -3.7038,
  "basePriceCents": 3500,
  "status": "active",
  "createdAt": "2025-10-25T21:01:00.000Z"
}
```

**⚠️ Guarda el `id` del espacio** (lo necesitarás para disponibilidad).

### c) Crear Disponibilidad
Reemplaza `{SPACE_ID}` con el ID del espacio:

```bash
curl -X POST http://localhost:8080/api/catalog/availability \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "{SPACE_ID}",
    "startTs": "2025-12-31T22:00:00Z",
    "endTs": "2026-01-01T06:00:00Z",
    "maxGuests": 15
  }' | jq .
```

**Respuesta esperada:**
```json
{
  "id": "b2c3d4e5-f6g7-4890-ab12-3456789abcde",
  "spaceId": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "maxGuests": 15
}
```

### d) Verificar Eventos en Kafka
Opcionalmente, verifica que se publicaron eventos:

```bash
docker exec -it kafka kafka-console-consumer.sh \
  --topic space.events.v1 \
  --bootstrap-server localhost:9092 \
  --from-beginning \
  --max-messages 2 \
  --timeout-ms 5000
```

Deberías ver eventos `SpaceCreated` en formato JSON.

✅ **Checkpoint:** Tienes 1 usuario, 1 espacio y 1 slot de disponibilidad creados.

---

## 9️⃣ Levantar Frontend Angular (3 min)

```bash
cd frontend

# Instalar dependencias (solo la primera vez)
npm install

# Iniciar servidor de desarrollo
npm start
```

**Output esperado:**
```
** Angular Live Development Server is listening on localhost:4200 **
✔ Compiled successfully.
```

Abre tu navegador en: **http://localhost:4200**

✅ **Checkpoint:** Frontend cargado sin errores en consola del navegador.

---

## 🔟 Flujo de Prueba End-to-End (5 min)

### a) Buscar Espacios en Madrid

Desde el frontend (http://localhost:4200) o con curl:

```bash
curl -s "http://localhost:8080/api/search?lat=40.4168&lon=-3.7038&radius_m=5000&capacity=10" | jq .
```

**Respuesta esperada:**
```json
[
  {
    "spaceId": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
    "title": "Terraza con vistas al Retiro",
    "capacity": 15,
    "priceCents": 3500,
    "lat": 40.4168,
    "lon": -3.7038,
    "rating": null,
    "distanceMeters": 0
  }
]
```

✅ El espacio creado aparece en los resultados.

### b) Crear Usuario Guest (para booking)

```bash
curl -X POST http://localhost:8080/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "guest@balconazo.com",
    "role": "guest"
  }' | jq .
```

**⚠️ Guarda el `id` del guest.**

### c) Crear Booking (Hold)

Reemplaza `{SPACE_ID}` y `{GUEST_ID}`:

```bash
curl -X POST http://localhost:8080/api/bookings \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: 7c8e9d0a-unique-test-uuid-123" \
  -d '{
    "spaceId": "{SPACE_ID}",
    "guestId": "{GUEST_ID}",
    "startTs": "2025-12-31T22:00:00Z",
    "endTs": "2026-01-01T06:00:00Z"
  }' | jq .
```

**Respuesta esperada:**
```json
{
  "id": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "startTs": "2025-12-31T22:00:00Z",
  "endTs": "2026-01-01T06:00:00Z",
  "status": "held",
  "priceCents": 3500,
  "expiresAt": "2025-10-25T21:10:00.000Z",
  "createdAt": "2025-10-25T21:00:00.123Z"
}
```

✅ **Status es "held"** y tienes 10 minutos para confirmar.

### d) Confirmar Booking

Reemplaza `{BOOKING_ID}` con el ID del booking:

```bash
curl -X POST http://localhost:8080/api/bookings/{BOOKING_ID}/confirm \
  -H "Content-Type: application/json" | jq .
```

**Respuesta esperada:**
```json
{
  "id": "1a2b3c4d-5678-9012-3456-789012345678",
  "spaceId": "a1b2c3d4-e5f6-4789-90ab-cdef12345678",
  "guestId": "h8i9j0k1-2345-6789-0123-456789012345",
  "status": "confirmed",
  "priceCents": 3500,
  "paymentIntentId": "pi_mock_3AbcDefGhiJklMno",
  "confirmedAt": "2025-10-25T21:05:00.000Z"
}
```

✅ **Status cambia a "confirmed"** y `paymentIntentId` está presente.

### e) Verificar Eventos en Kafka

Consume eventos de `booking.events.v1`:

```bash
docker exec -it kafka kafka-console-consumer.sh \
  --topic booking.events.v1 \
  --bootstrap-server localhost:9092 \
  --from-beginning \
  --property print.key=true \
  --property print.timestamp=true \
  --max-messages 10 \
  --timeout-ms 5000
```

**Deberías ver (en orden):**
1. `BookingHeld`
2. `PaymentIntentCreated`
3. `PaymentAuthorized`
4. `BookingConfirmed`
5. `PaymentCaptured`

✅ **Flujo completo exitoso!** Has creado un espacio, lo buscaste, hiciste una reserva y la confirmaste.

---

## 🎉 ¡Éxito!

Has levantado el stack completo de Balconazo:
- ✅ 9 contenedores Docker (infra + servicios)
- ✅ 7 tópicos Kafka funcionando
- ✅ 3 bases de datos PostgreSQL con schemas
- ✅ API Gateway enrutando correctamente
- ✅ Frontend Angular comunicándose con backend
- ✅ Flujo end-to-end de booking completado

---

## 🧹 Limpieza (cuando termines)

Para detener todos los servicios:

```bash
# Detener servicios pero mantener volúmenes (datos persisten)
docker-compose down

# Detener y eliminar volúmenes (limpieza completa)
docker-compose down -v
```

Para reiniciar desde cero:
```bash
docker-compose down -v
# Luego vuelve al paso 3
```

---

## 🐛 Troubleshooting

### Problema: Kafka no inicia

**Síntoma:** `docker logs kafka` muestra errores de conexión a ZooKeeper.

**Solución:**
```bash
docker-compose restart zookeeper
sleep 10
docker-compose restart kafka
sleep 30
```

### Problema: Servicios no conectan a Kafka

**Síntoma:** Logs muestran `TimeoutException: Failed to update metadata`.

**Solución:**
Verifica que Kafka está escuchando en puerto 29092 para host:
```bash
docker exec -it kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

Si falla, revisa `KAFKA_CFG_ADVERTISED_LISTENERS` en `docker-compose.yml`.

### Problema: Health check devuelve DOWN

**Síntoma:** `curl http://localhost:8081/actuator/health` devuelve `{"status":"DOWN"}`.

**Solución:**
Revisa logs del servicio:
```bash
docker logs catalog-service --tail 50
```

Busca errores de conexión a Postgres o Kafka. Asegúrate de que los contenedores de infra están "Up".

### Problema: Frontend no carga

**Síntoma:** Navegador muestra pantalla en blanco.

**Solución:**
1. Verifica consola del navegador (F12) para errores de CORS.
2. Asegúrate de que API Gateway está corriendo:
   ```bash
   curl http://localhost:8080/actuator/health
   ```
3. Revisa que el frontend está configurado con `API_BASE=http://localhost:8080/api` en `environment.ts`.

### Problema: Booking devuelve 409 Conflict

**Síntoma:** `POST /bookings` devuelve `{"error":"Slot already booked"}`.

**Solución:**
El slot ya tiene un booking confirmado o held. Usa otro rango de fechas:
```json
{
  "startTs": "2026-01-15T22:00:00Z",
  "endTs": "2026-01-16T06:00:00Z"
}
```

O libera el lock Redis:
```bash
docker exec -it redis redis-cli
> DEL lock:booking:{space-id}:{start}-{end}
```

---

## 📚 Próximos Pasos

Ahora que tienes el sistema funcionando:

1. **Explora la arquitectura:** Lee [ARCHITECTURE.md](./ARCHITECTURE.md) para entender decisiones de diseño
2. **Revisa eventos Kafka:** Consulta [KAFKA_EVENTS.md](./KAFKA_EVENTS.md) para schemas completos
3. **Desarrolla features:** Añade endpoints, modifica el motor de pricing, integra notificaciones
4. **Tests:** Ejecuta `mvn test` en cada microservicio
5. **Monitoreo:** Accede a métricas en `http://localhost:8081/actuator/prometheus`
6. **Keycloak:** Configura realm y usuarios en `http://localhost:8081` (admin/admin)

---

**¿Problemas?**
- Revisa logs: `docker-compose logs -f [service-name]`
- Abre un issue: [GitHub Issues](https://github.com/amolrod/balconazo-scalable-marketplace/issues)
- Slack: [balconazo-dev.slack.com](https://balconazo-dev.slack.com)

**¡Happy coding! 🚀**


