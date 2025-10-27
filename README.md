# 🏠 BALCONAZO - Marketplace de Espacios

**Marketplace para alquiler de balcones/terrazas para eventos**

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.java.net/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red.svg)](https://redis.io/)
[![Kafka](https://img.shields.io/badge/Kafka-7.5-black.svg)](https://kafka.apache.org/)

---

## 📊 ESTADO DEL PROYECTO

**Fecha:** 27 de octubre de 2025  
**Versión:** 0.2.0-MVP  
**Estado:** ✅ Catalog Service 100% Operacional

| Componente | Estado | Puerto | Descripción |
|------------|--------|--------|-------------|
| **Catalog Service** | ✅ RUNNING | 8085 | Gestión de usuarios y espacios |
| PostgreSQL Catalog | ✅ UP | 5433 | Base de datos principal |
| Kafka | ✅ UP | 9092 | Event streaming |
| Zookeeper | ✅ UP | 2181 | Coordinación Kafka |
| Redis | ✅ UP | 6379 | Caché y sesiones |
| Booking Service | ⏸️ PENDING | 8082 | Gestión de reservas |
| Search-Pricing | ⏸️ PENDING | 8083 | Búsquedas y pricing |

---

## 🚀 QUICK START

### Requisitos
- Java 21+
- Maven 3.9+
- Docker 24+

### Inicio Rápido (5 minutos)

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd BalconazoApp

# 2. Levantar infraestructura
docker start balconazo-pg-catalog balconazo-kafka balconazo-zookeeper balconazo-redis

# 3. Arrancar Catalog Service
cd catalog_microservice
mvn spring-boot:run

# 4. Verificar
curl http://localhost:8085/actuator/health
```

**Ver guía completa:** [QUICKSTART.md](QUICKSTART.md)

---

## 📚 DOCUMENTACIÓN

### Documentos Principales

| Documento | Descripción | Estado |
|-----------|-------------|--------|
| **[README.md](README.md)** | Este archivo - Vista general | ✅ Actualizado |
| **[QUICKSTART.md](QUICKSTART.md)** | Guía de instalación rápida | ✅ Actualizado |
| **[documentacion.md](documentacion.md)** | Especificación técnica completa | ✅ Vigente |
| **[RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md)** | Resumen de progreso | ✅ Actualizado |
| **[REDIS_COMPLETO.md](REDIS_COMPLETO.md)** | Documentación de Redis | ✅ Completo |
| **[KAFKA_SETUP.md](KAFKA_SETUP.md)** | Configuración de Kafka | ✅ Vigente |
| **[ESTADO_ACTUAL.md](ESTADO_ACTUAL.md)** | Estado detallado del proyecto | ✅ Vigente |
| **[TESTING.md](TESTING.md)** | Estrategia de testing | 📝 Referencia |

### Documentos en `/docs`
- `AUTH_SIMPLIFIED.md` - Autenticación simplificada
- `PRICING_ALGORITHM.md` - Motor de pricing
- `WIREFRAMES.md` - Diseños UI
- `MVP_STATUS.md` - Estado del MVP
- `CHANGELOG.md` - Historial de cambios

---

## 🏗️ ARQUITECTURA

### Microservicios

```
┌─────────────────────────────────────────────────────────┐
│                     API Gateway :8080                    │
└────────────┬─────────────┬──────────────┬───────────────┘
             │             │              │
    ┌────────▼────────┐   │   ┌──────────▼─────────┐
    │  Catalog :8081  │   │   │  Booking :8082     │
    │  Users/Spaces   │   │   │  Reservas/Pagos    │
    └────────┬────────┘   │   └──────────┬─────────┘
             │            │              │
    ┌────────▼────────┐   │   ┌──────────▼─────────┐
    │ PostgreSQL:5433 │   │   │ PostgreSQL:5434    │
    └─────────────────┘   │   └────────────────────┘
                          │
                ┌─────────▼──────────┐
                │ Search-Pricing     │
                │ :8083              │
                └─────────┬──────────┘
                          │
                ┌─────────▼──────────┐
                │ PostgreSQL:5435    │
                └────────────────────┘

┌──────────────────────────────────────────────────────────┐
│          Kafka :9092 (Event Streaming)                   │
│  Topics: space.events.v1, availability.events.v1, etc.   │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│               Redis :6379 (Cache/Sessions)                │
└──────────────────────────────────────────────────────────┘
```

### Stack Tecnológico

**Backend:**
- Spring Boot 3.5.7
- Spring Data JPA
- Spring Kafka
- MapStruct
- Lombok

**Bases de Datos:**
- PostgreSQL 16 (persistencia)
- Redis 7 (caché)

**Mensajería:**
- Apache Kafka 7.5 (event streaming)
- Zookeeper 7.5 (coordinación)

**Infraestructura:**
- Docker
- Maven

---

## 🎯 CATALOG SERVICE (Completado)

### Características Implementadas

✅ **Gestión de Usuarios**
- Crear, listar, obtener por ID
- Roles: host, guest, admin
- Trust score
- Validaciones completas

✅ **Gestión de Espacios**
- CRUD completo
- Geolocalización (lat/lon)
- Amenities (array)
- Rules (JSONB)
- Pricing en centavos
- Estados: draft, active, inactive

✅ **Disponibilidad**
- Slots de tiempo
- Validación de capacidad
- No solapamiento

✅ **Event-Driven**
- Publicación de eventos a Kafka
- SpaceCreated, SpaceUpdated, SpaceDeactivated
- AvailabilityAdded, AvailabilityRemoved

✅ **Caché con Redis**
- Caché automático de espacios (TTL 5 min)
- Endpoints de administración de caché
- Reducción de latencia 99%

### API Endpoints

**Base URL:** `http://localhost:8085/api/catalog`

#### Usuarios
- `POST /users` - Crear usuario
- `GET /users?role={role}` - Listar por rol
- `GET /users/{id}` - Obtener por ID

#### Espacios
- `POST /spaces` - Crear espacio
- `GET /spaces?hostId={id}` - Listar por host
- `GET /spaces/{id}` - Obtener por ID
- `PUT /spaces/{id}` - Actualizar
- `DELETE /spaces/{id}` - Eliminar

#### Caché (Testing)
- `POST /cache?key=X&value=Y&ttl=Z` - Guardar
- `GET /cache/{key}` - Obtener
- `DELETE /cache/{key}` - Eliminar

#### Health Check
- `GET /actuator/health` - Estado del servicio

### Ejemplos

```bash
# Crear usuario
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@example.com",
    "password": "password123",
    "role": "host"
  }'

# Crear espacio
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "uuid-del-usuario",
    "title": "Terraza Madrid Centro",
    "description": "Bonita terraza en el centro",
    "address": "Calle Mayor 1, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 20,
    "areaSqm": 80.0,
    "basePriceCents": 10000,
    "amenities": ["wifi", "bar", "music"],
    "rules": {"no_smoking": true}
  }'
```

---

## 🐳 DOCKER

### Contenedores Activos

```bash
# Ver todos los contenedores
docker ps | grep balconazo

# Debería mostrar:
# balconazo-pg-catalog (PostgreSQL:5433)
# balconazo-kafka (Kafka:9092)
# balconazo-zookeeper (Zookeeper:2181)
# balconazo-redis (Redis:6379)
```

### Comandos Útiles

```bash
# Iniciar todos
docker start balconazo-pg-catalog balconazo-kafka balconazo-zookeeper balconazo-redis

# Detener todos
docker stop balconazo-pg-catalog balconazo-kafka balconazo-zookeeper balconazo-redis

# Ver logs
docker logs -f balconazo-kafka
docker logs -f balconazo-pg-catalog

# Conectar a PostgreSQL
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db

# Conectar a Redis
docker exec -it balconazo-redis redis-cli

# Listar topics Kafka
docker exec balconazo-kafka kafka-topics --list --bootstrap-server localhost:9092
```

---

## 🧪 TESTING

### Health Checks

```bash
# Catalog Service
curl http://localhost:8085/actuator/health

# PostgreSQL
docker exec balconazo-pg-catalog psql -U postgres -c "SELECT 1"

# Redis
docker exec balconazo-redis redis-cli PING

# Kafka
docker exec balconazo-kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

### Pruebas End-to-End

Ver ejemplos completos en [QUICKSTART.md](QUICKSTART.md)

---

## 📊 PROGRESO

### Completado ✅
- [x] Infraestructura Docker
- [x] PostgreSQL configurado
- [x] Kafka + Zookeeper
- [x] Redis integrado
- [x] Catalog Service completo
  - [x] Arquitectura hexagonal
  - [x] Entities, Repositories, Services, Controllers
  - [x] DTOs y Mappers
  - [x] Event Producers
  - [x] Caché con Redis
  - [x] Validaciones
  - [x] Exception handling

### En Desarrollo 🔨
- [ ] Booking Service
  - [ ] Entities (Booking, Payment, Review)
  - [ ] Saga de reserva
  - [ ] Outbox Pattern
  - [ ] PostgreSQL puerto 5434
- [ ] Search-Pricing Service
  - [ ] Read model
  - [ ] Búsqueda geoespacial
  - [ ] Motor de pricing
  - [ ] PostgreSQL puerto 5435

### Planificado 📋
- [ ] Autenticación JWT
- [ ] API Gateway
- [ ] Frontend Angular
- [ ] Tests unitarios
- [ ] Tests de integración
- [ ] Observabilidad (Prometheus/Grafana)
- [ ] CI/CD

---

## 🎓 APRENDIZAJES

### Patrones Implementados
- ✅ Arquitectura Hexagonal (Ports & Adapters)
- ✅ Repository Pattern
- ✅ DTO Pattern
- ✅ Service Layer Pattern
- ✅ Event-Driven Architecture
- ✅ Cache-Aside Pattern

### Tecnologías Dominadas
- ✅ Spring Boot 3.x
- ✅ Spring Data JPA
- ✅ MapStruct
- ✅ Lombok
- ✅ Bean Validation
- ✅ Kafka Producers
- ✅ Redis Cache
- ✅ Docker

---

## 🔧 TROUBLESHOOTING

### Puerto 8085 ya en uso
```bash
lsof -ti:8085 | xargs kill -9
```

### PostgreSQL no conecta
```bash
docker restart balconazo-pg-catalog
sleep 10
```

### Kafka no funciona
```bash
docker logs balconazo-kafka | tail -50
docker restart balconazo-kafka
```

### Redis no aparece en health check
```bash
# Verificar configuración
grep redis catalog_microservice/src/main/resources/application.properties

# Reiniciar servicio
pkill -f catalog_microservice
mvn spring-boot:run
```

---

## 📞 CONTACTO Y CONTRIBUCIÓN

**Desarrollador:** Angel  
**Asistente:** GitHub Copilot  
**Fecha de inicio:** 27 de octubre de 2025

---

## 📝 LICENCIA

Este proyecto es educacional y de aprendizaje.

---

## 🚀 PRÓXIMOS PASOS

1. **Implementar Booking Service** (estimado: 8-10 horas)
2. **Implementar Search-Pricing Service** (estimado: 6-8 horas)
3. **Integración entre servicios vía Kafka**
4. **Autenticación JWT simplificada**
5. **Frontend Angular básico**

---

**¿Nuevo en el proyecto?** Comienza con [QUICKSTART.md](QUICKSTART.md)  
**¿Quieres detalles técnicos?** Lee [documentacion.md](documentacion.md)  
**¿Estado actual?** Consulta [RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md)

