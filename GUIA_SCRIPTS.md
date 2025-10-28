# 🚀 GUÍA DE SCRIPTS - PROYECTO BALCONAZO

## 📋 SCRIPTS DISPONIBLES

### 1. **start-infrastructure.sh** ✅
Inicia TODA la infraestructura Docker (PostgreSQL, Kafka, Zookeeper, Redis)

```bash
./start-infrastructure.sh
```

**Qué hace:**
- ✅ Inicia PostgreSQL Catalog (puerto 5433)
- ✅ Inicia PostgreSQL Booking (puerto 5434)
- ✅ Inicia Zookeeper (puerto 2181)
- ✅ Inicia Kafka (puerto 9092)
- ✅ Inicia Redis (puerto 6379)
- ✅ Crea schemas en las bases de datos

---

### 2. **start-catalog.sh** ✅
Inicia el Catalog Microservice

```bash
./start-catalog.sh
```

**Qué hace:**
- ✅ Verifica que PostgreSQL Catalog esté corriendo
- ✅ Verifica que Kafka esté corriendo
- ✅ Libera el puerto 8085
- ✅ Inicia el servicio en puerto 8085

---

### 3. **start-booking.sh** ✅
Inicia el Booking Microservice

```bash
./start-booking.sh
```

**Qué hace:**
- ✅ Verifica que PostgreSQL Booking esté corriendo
- ✅ Verifica que Kafka esté corriendo
- ✅ Libera el puerto 8082
- ✅ Inicia el servicio en puerto 8082

---

### 4. **restart-booking.sh** ✅
Reinicia el Booking Microservice (detiene y vuelve a iniciar)

```bash
./restart-booking.sh
```

**Qué hace:**
- ✅ Detiene el proceso en puerto 8082
- ✅ Inicia el servicio nuevamente

---

## 🎯 FLUJO COMPLETO DE ARRANQUE

### Primera vez (desde cero):

```bash
cd /Users/angel/Desktop/BalconazoApp

# Paso 1: Levantar infraestructura
./start-infrastructure.sh

# Esperar 20 segundos a que todo esté listo
sleep 20

# Paso 2: Iniciar Catalog Service (en otra terminal)
./start-catalog.sh

# Paso 3: Iniciar Booking Service (en otra terminal)
./start-booking.sh
```

### Si ya tienes infraestructura corriendo:

```bash
cd /Users/angel/Desktop/BalconazoApp

# Solo iniciar los servicios
./start-catalog.sh   # Terminal 1
./start-booking.sh   # Terminal 2
```

---

## ✅ VERIFICAR QUE TODO FUNCIONA

```bash
# 1. Ver contenedores Docker
docker ps --filter "name=balconazo"

# 2. Health check Catalog Service
curl http://localhost:8085/actuator/health | python3 -m json.tool

# 3. Health check Booking Service
curl http://localhost:8082/actuator/health | python3 -m json.tool

# 4. Listar tópicos Kafka
docker exec balconazo-kafka kafka-topics --list --bootstrap-server localhost:9092
```

**Deberías ver:**
- ✅ 5 contenedores Docker corriendo
- ✅ Catalog Service UP en puerto 8085
- ✅ Booking Service UP en puerto 8082
- ✅ Componente **kafka** en ambos health checks

---

## 🔄 REINICIAR BOOKING SERVICE (con Kafka Health Check)

Si acabas de añadir el KafkaHealthIndicator:

```bash
# Opción 1: Usar el script
./restart-booking.sh

# Opción 2: Manual
lsof -ti:8082 | xargs kill -9
cd booking_microservice
mvn spring-boot:run
```

**Después de reiniciar, verifica:**

```bash
curl http://localhost:8082/actuator/health | python3 -m json.tool
```

Ahora deberías ver:

```json
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "kafka": {
      "status": "UP",
      "details": {
        "clusterId": "...",
        "nodeCount": 1,
        "bootstrapServers": "localhost:9092"
      }
    },
    "redis": { "status": "UP" },
    "ping": { "status": "UP" }
  }
}
```

---

## 🐛 TROUBLESHOOTING

### Script no tiene permisos

```bash
chmod +x *.sh
```

### Puerto ya en uso

```bash
# Catalog (8085)
lsof -ti:8085 | xargs kill -9

# Booking (8082)
lsof -ti:8082 | xargs kill -9
```

### Contenedor no inicia

```bash
# Ver logs
docker logs balconazo-kafka
docker logs balconazo-pg-booking

# Reiniciar contenedor
docker restart balconazo-kafka
sleep 15
```

### Kafka no responde

```bash
# Verificar que esté corriendo
docker ps | grep kafka

# Reiniciar
docker restart balconazo-kafka
sleep 15

# Probar conexión
docker exec balconazo-kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

---

## 📊 RESUMEN DE PUERTOS

| Servicio | Puerto | Contenedor |
|----------|--------|------------|
| **Catalog Service** | 8085 | (Spring Boot) |
| **Booking Service** | 8082 | (Spring Boot) |
| PostgreSQL Catalog | 5433 | balconazo-pg-catalog |
| PostgreSQL Booking | 5434 | balconazo-pg-booking |
| Kafka | 9092 | balconazo-kafka |
| Zookeeper | 2181 | balconazo-zookeeper |
| Redis | 6379 | balconazo-redis |

---

## 🎯 SIGUIENTE PASO

**Para reiniciar el Booking Service con el Kafka Health Check:**

```bash
cd /Users/angel/Desktop/BalconazoApp
./restart-booking.sh
```

Espera 30-40 segundos y luego verifica:

```bash
curl http://localhost:8082/actuator/health | python3 -m json.tool
```

✅ **Ahora verás el componente `kafka` con todos sus detalles**

