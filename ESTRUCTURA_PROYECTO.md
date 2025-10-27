# 📂 ESTRUCTURA DEL PROYECTO BALCONAZO

**Última actualización:** 27 de octubre de 2025, 16:40

---

## 📋 Archivos de Documentación

### Principal
- **README.md** - Introducción general del proyecto
- **QUICKSTART.md** - Guía de instalación rápida (10 min)
- **documentacion.md** - Documentación técnica completa y detallada

### Guías Específicas
- **TESTING.md** - Ejemplos de pruebas y uso de la API
- **KAFKA_SETUP.md** - Configuración detallada de Kafka (troubleshooting incluido)

### Estado y Resumen
- **RESUMEN_EJECUTIVO.md** - Estado actual, progreso y próximos pasos
- **ESTADO_ACTUAL.md** - Estado detallado de servicios e infraestructura

---

## 🗂️ Estructura de Directorios

```
BalconazoApp/
├── README.md                    # Introducción del proyecto
├── QUICKSTART.md               # Guía rápida
├── documentacion.md            # Documentación técnica
├── TESTING.md                  # Guía de pruebas
├── KAFKA_SETUP.md             # Setup de Kafka
├── RESUMEN_EJECUTIVO.md       # Resumen y roadmap
├── ESTADO_ACTUAL.md           # Estado de servicios
│
├── catalog_microservice/       # ✅ IMPLEMENTADO
│   ├── pom.xml
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/balconazo/catalog_microservice/
│   │   │   │   ├── CatalogMicroserviceApplication.java
│   │   │   │   ├── controller/
│   │   │   │   │   ├── UserController.java
│   │   │   │   │   ├── SpaceController.java
│   │   │   │   │   └── AvailabilityController.java
│   │   │   │   ├── service/
│   │   │   │   │   ├── UserService.java
│   │   │   │   │   ├── UserServiceImpl.java
│   │   │   │   │   ├── SpaceService.java
│   │   │   │   │   ├── SpaceServiceImpl.java
│   │   │   │   │   ├── AvailabilityService.java
│   │   │   │   │   └── AvailabilityServiceImpl.java
│   │   │   │   ├── repository/
│   │   │   │   │   ├── UserRepository.java
│   │   │   │   │   ├── SpaceRepository.java
│   │   │   │   │   ├── AvailabilitySlotRepository.java
│   │   │   │   │   └── ProcessedEventRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   ├── UserEntity.java
│   │   │   │   │   ├── SpaceEntity.java
│   │   │   │   │   ├── AvailabilitySlotEntity.java
│   │   │   │   │   └── ProcessedEventEntity.java
│   │   │   │   ├── dto/
│   │   │   │   │   ├── CreateUserDTO.java
│   │   │   │   │   ├── UserDTO.java
│   │   │   │   │   ├── CreateSpaceDTO.java
│   │   │   │   │   ├── SpaceDTO.java
│   │   │   │   │   ├── CreateAvailabilityDTO.java
│   │   │   │   │   └── AvailabilitySlotDTO.java
│   │   │   │   ├── mapper/
│   │   │   │   │   ├── UserMapper.java
│   │   │   │   │   └── SpaceMapper.java
│   │   │   │   ├── kafka/
│   │   │   │   │   ├── producer/
│   │   │   │   │   │   ├── SpaceEventProducer.java
│   │   │   │   │   │   └── AvailabilityEventProducer.java
│   │   │   │   │   └── event/
│   │   │   │   │       ├── SpaceCreatedEvent.java
│   │   │   │   │       ├── SpaceUpdatedEvent.java
│   │   │   │   │       ├── SpaceDeactivatedEvent.java
│   │   │   │   │       ├── AvailabilityAddedEvent.java
│   │   │   │   │       └── AvailabilityRemovedEvent.java
│   │   │   │   ├── config/
│   │   │   │   │   ├── KafkaConfig.java
│   │   │   │   │   ├── SwaggerConfig.java
│   │   │   │   │   └── GlobalExceptionHandler.java
│   │   │   │   ├── exception/
│   │   │   │   │   ├── ResourceNotFoundException.java
│   │   │   │   │   └── BusinessValidationException.java
│   │   │   │   └── constants/
│   │   │   │       └── CatalogConstants.java
│   │   │   └── resources/
│   │   │       ├── application.properties
│   │   │       └── application.yml
│   │   └── test/
│   │       └── java/com/balconazo/catalog_microservice/
│   │           └── CatalogMicroserviceApplicationTests.java
│   └── target/
│
├── booking_microservice/       # ⏳ PRÓXIMO
│   ├── pom.xml
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/balconazo/booking_microservice/
│   │   │   └── resources/
│   │   └── test/
│   └── target/
│
├── search_microservice/        # ⏸️ PENDIENTE
│   ├── pom.xml
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/balconazo/search_microservice/
│   │   │   └── resources/
│   │   └── test/
│   └── target/
│
├── ddl/                        # Scripts SQL
│   └── init-postgres.sh
│
└── pom.xml                     # POM padre (agregador)
```

---

## 🐳 Contenedores Docker

### En Ejecución
```
balconazo-pg-catalog     PostgreSQL 16      5433:5432   ✅ UP
balconazo-zookeeper      Zookeeper 7.5.0    2181:2181   ✅ UP
balconazo-kafka          Kafka 7.5.0        9092,29092  ✅ UP
```

### Pendientes
```
balconazo-pg-booking     PostgreSQL 16      5434:5432   ⏸️ TODO
balconazo-pg-search      PostGIS 16         5435:5432   ⏸️ TODO
balconazo-redis          Redis 7            6379:6379   ⏸️ TODO
api-gateway              Spring Cloud GW    8080:8080   ⏸️ TODO
```

---

## 📊 Bases de Datos

### catalog_db (Puerto 5433) ✅
```sql
Schema: catalog

Tablas:
- users                  (gestión de usuarios)
- spaces                 (espacios/propiedades)
- availability_slots     (disponibilidad temporal)
- processed_events       (idempotencia Kafka)
```

### booking_db (Puerto 5434) ⏸️
```sql
Schema: booking

Tablas planeadas:
- bookings               (reservas)
- payments               (transacciones)
- reviews                (reseñas)
- disputes               (disputas)
- outbox_events          (Outbox Pattern)
- processed_events       (idempotencia)
```

### search_db (Puerto 5435) ⏸️
```sql
Schema: search

Tablas planeadas:
- spaces_projection      (read-model con PostGIS)
- pricing_cache          (precios precalculados)
- search_analytics       (métricas de búsqueda)
```

---

## 📨 Tópicos Kafka

### Creados ✅
```
space-events-v1           (12 particiones)
availability-events-v1    (12 particiones)
booking-events-v1         (12 particiones)
```

### Pendientes ⏸️
```
payment-events-v1
review-events-v1
pricing-events-v1
notification-events-v1
```

---

## 🌐 Puertos en Uso

```
5433  - PostgreSQL catalog_db
5434  - PostgreSQL booking_db (pendiente)
5435  - PostgreSQL search_db (pendiente)
6379  - Redis (pendiente)
2181  - Zookeeper
9092  - Kafka (interno)
29092 - Kafka (externo)
8080  - API Gateway (pendiente)
8081  - catalog-service (actualmente en 8085)
8082  - booking-service (pendiente)
8083  - search-pricing-service (pendiente)
4200  - Frontend Angular (pendiente)
```

---

## 🔧 Tecnologías Implementadas

### Backend ✅
- Spring Boot 3.5.7
- Java 21
- Maven 3.9+
- Hibernate/JPA
- MapStruct
- Lombok

### Infraestructura ✅
- Docker
- PostgreSQL 16
- Apache Kafka 7.5.0 (KRaft mode)
- Zookeeper 7.5.0

### Pendientes ⏸️
- Redis 7
- Spring Cloud Gateway
- Angular 20
- Tailwind CSS
- PostGIS

---

## 📦 Dependencias Maven Principales

```xml
<!-- Spring Boot -->
spring-boot-starter-web
spring-boot-starter-data-jpa
spring-boot-starter-validation
spring-boot-starter-actuator

<!-- Kafka -->
spring-kafka

<!-- Database -->
postgresql

<!-- Utilities -->
lombok
mapstruct
```

---

## 🎯 Próxima Sesión de Trabajo

### Objetivo: Implementar booking-service

1. Crear estructura del proyecto booking_microservice
2. Configurar PostgreSQL booking_db (puerto 5434)
3. Implementar entidades:
   - BookingEntity
   - PaymentEntity
   - ReviewEntity
   - OutboxEventEntity
4. Implementar servicios con Saga Pattern
5. Configurar Kafka consumers y producers
6. Crear endpoints REST
7. Pruebas de integración con catalog-service

**Tiempo estimado:** 4-6 horas

---

**Mantenido por:** Angel Rodriguez  
**Última actualización:** 27 de octubre de 2025, 16:40

