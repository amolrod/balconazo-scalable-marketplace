# 🏠 BALCONAZO - Marketplace de Espacios

**Marketplace para alquiler de balcones/terrazas para eventos**

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.java.net/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)
[![Kafka](https://img.shields.io/badge/Kafka-7.5-black.svg)](https://kafka.apache.org/)
[![Redis](https://img.shields.io/badge/Redis-8-red.svg)](https://redis.io/)

---

## 📊 ESTADO DEL PROYECTO

**Fecha:** 29 de Octubre de 2025  
**Versión:** 0.9.0-MVP  
**Progreso:** 95% completado

| Componente | Estado | Puerto | Descripción |
|------------|--------|--------|-------------|
| **API Gateway** | ✅ RUNNING | 8080 | Punto de entrada único + JWT + Rate limiting |
| **Auth Service** | ✅ RUNNING | 8084 | Autenticación JWT + Refresh tokens |
| **Catalog Service** | ✅ RUNNING | 8085 | Gestión de usuarios y espacios |
| **Booking Service** | ✅ RUNNING | 8082 | Gestión de reservas y reviews |
| **Search Service** | ✅ RUNNING | 8083 | Búsqueda geoespacial + PostGIS |
| **Eureka Server** | ✅ RUNNING | 8761 | Service Discovery |
| PostgreSQL Catalog | ✅ UP | 5433 | BD catalog_db |
| PostgreSQL Booking | ✅ UP | 5434 | BD booking_db |
| PostgreSQL Search | ✅ UP | 5435 | BD search_db (PostGIS) |
| MySQL Auth | ✅ UP | 3307 | BD auth_db |
| Kafka | ✅ UP | 9092 | Event streaming |
| Zookeeper | ✅ UP | 2181 | Coordinación Kafka |
| Redis | ✅ UP | 6379 | Cache, locks y rate limiting |

---

## 🎯 CARACTERÍSTICAS PRINCIPALES

### ✅ Implementado
- **API Gateway** (punto de entrada único con Spring Cloud Gateway)
- **Autenticación JWT** (Auth Service con MySQL)
- **Service Discovery** (Eureka Server)
- **Gestión de usuarios** (hosts y guests)
- **Gestión de espacios** (CRUD completo)
- **Sistema de reservas** (crear, confirmar, cancelar)
- **Sistema de reviews** (rating y comentarios)
- **Búsqueda geoespacial** (PostGIS con radio en km)
- **Eventos Kafka** (comunicación entre servicios)
- **Patrón Outbox** (consistencia transaccional)
- **Rate Limiting** (Redis con token bucket)
- **Circuit Breaker** (Resilience4j)
- **Correlation ID** (trazabilidad de requests)
- **Health checks** (monitoreo completo)
- **Pruebas E2E** (flujo completo funcionando)

### ⏭️ Planificado
- Pricing dinámico con Kafka Streams
- Frontend Angular 20
- Despliegue en AWS (ECS/MSK/RDS)
- Observabilidad (Prometheus/Grafana/Jaeger)

---

## 🏗️ ARQUITECTURA

```
┌─────────────────────────────────────────────────┐
│              FRONTEND (Planificado)             │
│           Angular 20 + Tailwind CSS             │
└──────────────────┬──────────────────────────────┘
                   │ HTTP/JWT
                   ▼
┌─────────────────────────────────────────────────┐
│          🌐 API GATEWAY :8080 ✅                │
│     Spring Cloud Gateway (Reactive)              │
│  • JWT Validation (stateless)                   │
│  • Rate Limiting (Redis)                        │
│  • Circuit Breaker (Resilience4j)               │
│  • CORS + Correlation ID                        │
└──────────────────┬──────────────────────────────┘
                   │ Service Discovery
                   ▼
┌─────────────────────────────────────────────────┐
│         🎯 EUREKA SERVER :8761 ✅               │
│           Service Registry                       │
└──────────────────┬──────────────────────────────┘
                   │
     ┌─────────────┼─────────────┬──────────┐
     ▼             ▼             ▼          ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  AUTH    │  │ CATALOG  │  │ BOOKING  │  │ SEARCH   │
│ SERVICE  │  │ SERVICE  │  │ SERVICE  │  │ SERVICE  │
│  :8084   │  │  :8085   │  │  :8082   │  │  :8083   │
│    ✅    │  │    ✅    │  │    ✅    │  │    ✅    │
└────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │             │
     ▼             ▼             ▼             ▼
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  MySQL   │  │PostgreSQL│  │PostgreSQL│  │PostgreSQL│
│ auth_db  │  │catalog_db│  │booking_db│  │search_db │
│  :3307   │  │  :5433   │  │  :5434   │  │  :5435   │
│   ✅     │  │    ✅    │  │    ✅    │  │ +PostGIS │
└──────────┘  └──────────┘  └──────────┘  └─────✅────┘
     
              ▲             ▲             ▲
              └─────────────┼─────────────┘
                            │
              ┌─────────────▼─────────────┐
              │    Apache Kafka :9092     │
              │  + Zookeeper :2181        │
              │          ✅               │
              └───────────────────────────┘
              
              ┌───────────────────────────┐
              │      Redis :6379          │
              │  (Cache + Rate Limit)     │
              │          ✅               │
              └───────────────────────────┘
```

### Eventos Kafka

| Tópico | Eventos | Productor | Consumidor |
|--------|---------|-----------|------------|
| `space-events-v1` | SpaceCreated, Updated, Deactivated | Catalog | Search (pendiente) |
| `availability-events-v1` | AvailabilityAdded, Removed | Catalog | Search (pendiente) |
| `booking.events.v1` | BookingCreated, Confirmed, Cancelled | Booking | Search (pendiente) |
| `review.events.v1` | ReviewCreated | Booking | Search (pendiente) |

---

## 🚀 QUICK START

### Requisitos previos
- Java 21+
- Maven 3.9+
- Docker 24+
- Redis (puerto 6379)

### Opción 1: Inicio automático completo (recomendado)

```bash
cd /Users/angel/Desktop/BalconazoApp
./start-all-complete.sh
```

Este script inicia **todo el sistema** automáticamente:
1. ✅ Infraestructura (Kafka, Redis, PostgreSQL, MySQL)
2. ✅ Eureka Server
3. ✅ Auth Service
4. ✅ Catalog Service
5. ✅ Booking Service
6. ✅ Search Service
7. ✅ API Gateway

**Tiempo estimado:** 2-3 minutos

### Opción 2: Inicio individual del API Gateway

```bash
./start-gateway.sh
```

### Verificar que todo está corriendo

```bash
# Health check del API Gateway
curl http://localhost:8080/actuator/health

# Ver servicios registrados en Eureka
open http://localhost:8761

# Todas las rutas configuradas
curl http://localhost:8080/actuator/gateway/routes | jq
```
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/BalconazoApp
cd BalconazoApp

# 2. Levantar toda la infraestructura
./start-infrastructure.sh

# 3. En terminal separada: Iniciar Catalog Service
./start-catalog.sh

# 4. En otra terminal: Iniciar Booking Service
./start-booking.sh

# 5. Hacer prueba E2E completa
./test-e2e.sh
```

### Opción 2: Inicio manual

```bash
# 1. Levantar infraestructura Docker
docker start balconazo-pg-catalog balconazo-pg-booking \
             balconazo-kafka balconazo-zookeeper balconazo-redis

# 2. Iniciar Catalog Service
cd catalog_microservice
mvn spring-boot:run &

# 3. Iniciar Booking Service
cd ../booking_microservice
mvn spring-boot:run &
```

### Verificar que todo funciona

```bash
# Health checks
curl http://localhost:8085/actuator/health | python3 -m json.tool
curl http://localhost:8082/actuator/health | python3 -m json.tool

# Ver tópicos Kafka
docker exec balconazo-kafka kafka-topics --list --bootstrap-server localhost:9092

# Ver contenedores activos
docker ps --filter "name=balconazo"
```

---

## 📡 ENDPOINTS API

### Catalog Service (puerto 8085)

#### Usuarios
```http
POST   /api/catalog/users
GET    /api/catalog/users?role={guest|host}
GET    /api/catalog/users/{id}
```

**Ejemplo - Crear usuario:**
```bash
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@example.com",
    "password": "password123",
    "role": "host"
  }'
```

#### Espacios
```http
POST   /api/catalog/spaces
GET    /api/catalog/spaces?hostId={id}
GET    /api/catalog/spaces/{id}
PUT    /api/catalog/spaces/{id}
DELETE /api/catalog/spaces/{id}
```

**Ejemplo - Crear espacio:**
```bash
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "uuid-del-host",
    "title": "Terraza con vista",
    "description": "Hermosa terraza céntrica",
    "address": "Calle Mayor 1, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 6,
    "areaSqm": 50.0,
    "basePriceCents": 8000,
    "amenities": ["wifi", "parking"],
    "rules": {"no_smoking": true}
  }'
```

#### Disponibilidad
```http
POST   /api/catalog/availability
GET    /api/catalog/availability/space/{spaceId}
DELETE /api/catalog/availability/{id}
```

### Booking Service (puerto 8082)

#### Reservas
```http
POST   /api/booking/bookings
POST   /api/booking/bookings/{id}/confirm?paymentIntentId={id}
POST   /api/booking/bookings/{id}/cancel?reason={reason}
GET    /api/booking/bookings/{id}
GET    /api/booking/bookings?guestId={id}
GET    /api/booking/bookings/space/{spaceId}
```

**Ejemplo - Crear reserva:**
```bash
curl -X POST http://localhost:8082/api/booking/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "uuid-del-espacio",
    "guestId": "uuid-del-guest",
    "startTs": "2025-12-31T18:00:00",
    "endTs": "2025-12-31T23:00:00",
    "numGuests": 4
  }'
```

**Ejemplo - Confirmar reserva:**
```bash
curl -X POST "http://localhost:8082/api/booking/bookings/{booking-id}/confirm?paymentIntentId=pi_test_123"
```

#### Reviews
```http
POST   /api/booking/reviews
GET    /api/booking/reviews/{id}
GET    /api/booking/reviews/space/{spaceId}
GET    /api/booking/reviews/space/{spaceId}/rating
```

**Ejemplo - Crear review:**
```bash
curl -X POST http://localhost:8082/api/booking/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "uuid-de-la-reserva",
    "rating": 5,
    "comment": "¡Excelente experiencia!"
  }'
```

---

## 🧪 PRUEBAS

### Prueba End-to-End completa

```bash
./test-e2e.sh
```

Este script:
1. Crea un usuario HOST
2. Crea un usuario GUEST
3. Crea un espacio
4. Crea una reserva
5. Verifica el evento en Kafka

### Verificar eventos en Kafka

```bash
# Ver eventos de bookings
docker exec balconazo-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic booking.events.v1 \
  --from-beginning \
  --max-messages 5

# Ver eventos de espacios
docker exec balconazo-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic space-events-v1 \
  --from-beginning \
  --max-messages 5
```

### Consultas SQL útiles

```bash
# Ver usuarios
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
  -c "SELECT id, email, role FROM catalog.users LIMIT 5;"

# Ver espacios
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
  -c "SELECT id, title, base_price_cents/100.0 as price_eur FROM catalog.spaces LIMIT 5;"

# Ver reservas
docker exec balconazo-pg-booking psql -U postgres -d booking_db \
  -c "SELECT id, status, payment_status FROM booking.bookings LIMIT 5;"

# Ver eventos del Outbox
docker exec balconazo-pg-booking psql -U postgres -d booking_db \
  -c "SELECT event_type, status, retry_count FROM booking.outbox_events ORDER BY created_at DESC LIMIT 10;"
```

---

## 🛠️ STACK TECNOLÓGICO

### Backend
- **Spring Boot 3.5.7** - Framework principal
- **Java 21** - Lenguaje de programación
- **Maven** - Gestión de dependencias
- **MapStruct** - Mapeo de DTOs
- **Lombok** - Reducción de boilerplate

### Bases de datos
- **PostgreSQL 16** - Base de datos principal
- **PostGIS** (pendiente) - Extensión geoespacial
- **Redis 8** - Cache y locks distribuidos

### Mensajería y Eventos
- **Apache Kafka 7.5** - Event streaming
- **KRaft mode** - Kafka sin Zookeeper legacy
- **Spring Kafka** - Integración con Spring

### Patrones implementados
- ✅ **Microservicios** (arquitectura distribuida)
- ✅ **Event-Driven Architecture** (comunicación asíncrona)
- ✅ **Outbox Pattern** (consistencia transaccional)
- ✅ **Repository Pattern** (acceso a datos)
- ✅ **Service Layer** (lógica de negocio)
- ✅ **DTO Pattern** (transferencia de datos)
- ⏭️ **CQRS** (read-model en Search Service)
- ⏭️ **Saga Pattern** (orquestación de reservas)

---

## 📁 ESTRUCTURA DEL PROYECTO

```
BalconazoApp/
├── catalog_microservice/        ✅ 100% funcional
│   ├── src/main/java/
│   │   ├── entity/             (User, Space, AvailabilitySlot)
│   │   ├── repository/         (Spring Data JPA)
│   │   ├── service/            (Lógica de negocio)
│   │   ├── controller/         (REST endpoints)
│   │   ├── dto/                (Request/Response)
│   │   ├── mapper/             (MapStruct)
│   │   ├── kafka/              (Producers y eventos)
│   │   └── config/             (Configuraciones)
│   └── pom.xml
│
├── booking_microservice/        ✅ 100% funcional
│   ├── src/main/java/
│   │   ├── entity/             (Booking, Review, OutboxEvent)
│   │   ├── repository/         (Spring Data JPA)
│   │   ├── service/            (Lógica de negocio + Outbox)
│   │   ├── controller/         (REST endpoints)
│   │   ├── dto/                (Request/Response)
│   │   ├── mapper/             (MapStruct)
│   │   ├── kafka/              (Outbox relay, eventos)
│   │   └── config/             (Configuraciones, scheduler)
│   └── pom.xml
│
├── search_microservice/         ⏭️ Siguiente paso
│   └── (por implementar)
│
├── ddl/                         ✅ Scripts SQL
│   ├── catalog.sql
│   ├── booking.sql
│   └── search.sql
│
├── docs/                        📚 Documentación
│   ├── ESTADO_ACTUAL.md        ✅ Estado del proyecto
│   ├── HOJA_DE_RUTA.md         ✅ Próximos pasos
│   ├── GUIA_SCRIPTS.md         ✅ Guía de scripts
│   └── BOOKING_SERVICE_COMPLETADO.md
│
├── start-infrastructure.sh      🚀 Scripts de inicio
├── start-catalog.sh
├── start-booking.sh
├── test-e2e.sh
│
├── pom.xml                      Maven parent
├── README.md                    Este archivo
└── documentacion.md             Especificación técnica
```

---

## 🐛 TROUBLESHOOTING

### Puerto ya en uso
```bash
# Ver qué proceso usa el puerto
lsof -i :8085  # Catalog
lsof -i :8082  # Booking

# Matar proceso
lsof -ti:8085 | xargs kill -9
```

### Kafka no responde
```bash
# Ver logs
docker logs balconazo-kafka --tail 50

# Reiniciar
docker restart balconazo-kafka
sleep 15

# Verificar conectividad
docker exec balconazo-kafka kafka-broker-api-versions \
  --bootstrap-server localhost:9092
```

### PostgreSQL connection refused
```bash
# Verificar que esté corriendo
docker ps | grep balconazo-pg

# Ver logs
docker logs balconazo-pg-catalog

# Reiniciar
docker restart balconazo-pg-catalog
```

### Build falló
```bash
# Limpiar y recompilar
cd catalog_microservice  # o booking_microservice
mvn clean install -DskipTests

# Ver errores específicos
mvn clean compile 2>&1 | grep ERROR
```

---

## 📚 DOCUMENTACIÓN ADICIONAL

- **[ESTADO_ACTUAL.md](ESTADO_ACTUAL.md)** - Estado detallado del proyecto
- **[HOJA_DE_RUTA.md](HOJA_DE_RUTA.md)** - Roadmap y próximos pasos
- **[GUIA_SCRIPTS.md](GUIA_SCRIPTS.md)** - Guía de uso de scripts
- **[BOOKING_SERVICE_COMPLETADO.md](BOOKING_SERVICE_COMPLETADO.md)** - Documentación técnica Booking
- **[documentacion.md](documentacion.md)** - Especificación técnica completa

---

## 👥 CONTRIBUIR

Este es un proyecto de aprendizaje. Si quieres contribuir:

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit de cambios (`git commit -am 'Add nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear Pull Request

---

## 📄 LICENCIA

Este proyecto está bajo licencia MIT - ver archivo [LICENSE](LICENSE) para detalles.

---

## 🎯 PRÓXIMOS PASOS

1. ⏭️ **Implementar Search & Pricing Microservice**
   - Búsqueda geoespacial con PostGIS
   - Motor de pricing dinámico
   - Consumers de eventos Kafka

2. ⏭️ **API Gateway**
   - Spring Cloud Gateway
   - Autenticación JWT
   - Rate limiting con Redis

3. ⏭️ **Frontend Angular**
   - Búsqueda con mapa interactivo
   - Gestión de reservas
   - Dashboard host/guest

4. ⏭️ **Despliegue en AWS**
   - ECS/EKS para microservicios
   - RDS PostgreSQL Multi-AZ
   - MSK para Kafka
   - ElastiCache Redis

Ver **[HOJA_DE_RUTA.md](HOJA_DE_RUTA.md)** para detalles completos.

---

**Desarrollado usando Spring Boot y Kafka**  
**Última actualización:** 28 de Octubre de 2025

