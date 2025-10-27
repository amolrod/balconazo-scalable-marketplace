# 🎉 Balconazo - Catalog Microservice

**Marketplace de alquiler de espacios tipo balcones/terrazas**

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.org/)
[![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![License](https://img.shields.io/badge/license-MIT-blue.svg)]()

---

## 📋 Descripción

Microservicio de catálogo para la plataforma Balconazo. Gestiona:
- 👥 **Usuarios** (hosts, guests, admins)
- 🏠 **Espacios** (balcones, terrazas)
- 📅 **Disponibilidad** de espacios

---

## 🏗️ Arquitectura

### Stack Tecnológico

- **Framework:** Spring Boot 3.3.5
- **Lenguaje:** Java 21
- **Base de Datos:** PostgreSQL 16
- **Caché:** Redis
- **Mensajería:** Apache Kafka
- **Validación:** Bean Validation
- **Mapeo:** MapStruct
- **Seguridad:** BCrypt (Spring Security)
- **Build:** Maven 3.9+

### Capas de la Aplicación

```
catalog-service/
├── 📦 Domain Layer
│   ├── Entities (JPA)
│   ├── Constants
│   └── Exceptions
├── 🔧 Application Layer
│   ├── Services (Business Logic)
│   ├── DTOs
│   └── Mappers (MapStruct)
├── 🗄️ Infrastructure Layer
│   ├── Repositories (Spring Data JPA)
│   └── Config (JPA, Security, Exception Handling)
└── 🌐 Presentation Layer
    └── Controllers (REST API)
```

---

## 🚀 Inicio Rápido

### Prerrequisitos

- Java 21+
- Maven 3.9+
- Docker & Docker Compose
- PostgreSQL 16 (via Docker)

### 1. Clonar el Proyecto

```bash
git clone https://github.com/tuusuario/BalconazoApp.git
cd BalconazoApp
```

### 2. Levantar Infraestructura

```bash
# Levantar PostgreSQL, Kafka y Redis
docker-compose up -d
```

### 3. Compilar el Proyecto

```bash
cd catalog_microservice
mvn clean install
```

**Resultado esperado:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: 3.411 s
```

### 4. Ejecutar el Servicio

```bash
mvn spring-boot:run
```

El servicio estará disponible en: **http://localhost:8081**

### 5. Verificar que Funciona

```bash
# Health check
curl http://localhost:8081/actuator/health

# Respuesta esperada:
# {"status":"UP"}
```

---

## 📡 API REST

### Endpoints Principales

#### 👥 Users API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/catalog/users` | Crear usuario |
| GET | `/api/catalog/users/{id}` | Obtener usuario por ID |
| GET | `/api/catalog/users/email/{email}` | Buscar por email |
| GET | `/api/catalog/users?role=host` | Listar por rol |
| PATCH | `/api/catalog/users/{id}/trust-score` | Actualizar confianza |
| POST | `/api/catalog/users/{id}/suspend` | Suspender usuario |
| POST | `/api/catalog/users/{id}/activate` | Activar usuario |

#### 🏠 Spaces API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/catalog/spaces` | Crear espacio |
| GET | `/api/catalog/spaces/{id}` | Obtener espacio |
| GET | `/api/catalog/spaces/owner/{ownerId}` | Listar por propietario |
| GET | `/api/catalog/spaces` | Listar espacios activos |
| PUT | `/api/catalog/spaces/{id}` | Actualizar espacio |
| POST | `/api/catalog/spaces/{id}/activate` | Publicar espacio |
| POST | `/api/catalog/spaces/{id}/snooze` | Pausar espacio |
| DELETE | `/api/catalog/spaces/{id}` | Eliminar (soft delete) |

#### 📅 Availability API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/catalog/availability` | Añadir disponibilidad |
| GET | `/api/catalog/availability/space/{spaceId}` | Listar slots de un espacio |
| GET | `/api/catalog/availability/space/{spaceId}/future` | Slots futuros |
| GET | `/api/catalog/availability/space/{spaceId}/range` | Por rango de fechas |
| DELETE | `/api/catalog/availability/{slotId}` | Eliminar slot |

---

## 🧪 Ejemplos de Uso

### Crear Usuario

```bash
curl -X POST http://localhost:8081/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host@example.com",
    "password": "password123",
    "role": "host"
  }'
```

### Crear Espacio

```bash
curl -X POST http://localhost:8081/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "uuid-del-usuario",
    "title": "Balcón con vistas al mar",
    "description": "Hermoso balcón de 20m²",
    "capacity": 15,
    "areaSqm": 20.5,
    "address": "Calle Principal 123, Barcelona",
    "lat": 41.3851,
    "lon": 2.1734,
    "basePriceCents": 8000
  }'
```

### Añadir Disponibilidad

```bash
curl -X POST http://localhost:8081/api/catalog/availability \
  -H "Content-Type: application/json" \
  -d '{
    "spaceId": "uuid-del-espacio",
    "startTs": "2025-12-31T18:00:00",
    "endTs": "2026-01-01T06:00:00",
    "maxGuests": 15
  }'
```

---

## 🗂️ Estructura del Proyecto

```
catalog_microservice/
├── src/main/java/com/balconazo/catalog_microservice/
│   ├── CatalogMicroserviceApplication.java    # Main
│   ├── constants/
│   │   └── CatalogConstants.java               # Constantes
│   ├── exception/
│   │   ├── CatalogException.java               # Base exception
│   │   ├── ResourceNotFoundException.java
│   │   ├── DuplicateResourceException.java
│   │   └── BusinessValidationException.java
│   ├── entity/
│   │   ├── UserEntity.java                     # Usuarios
│   │   ├── SpaceEntity.java                    # Espacios
│   │   ├── AvailabilitySlotEntity.java         # Disponibilidad
│   │   └── ProcessedEventEntity.java           # Idempotencia
│   ├── repository/
│   │   ├── UserRepository.java
│   │   ├── SpaceRepository.java
│   │   ├── AvailabilitySlotRepository.java
│   │   └── ProcessedEventRepository.java
│   ├── dto/
│   │   ├── CreateUserDTO.java
│   │   ├── UserDTO.java
│   │   ├── CreateSpaceDTO.java
│   │   ├── SpaceDTO.java
│   │   ├── CreateAvailabilityDTO.java
│   │   └── AvailabilitySlotDTO.java
│   ├── mapper/
│   │   ├── UserMapper.java                     # MapStruct
│   │   ├── SpaceMapper.java
│   │   └── AvailabilityMapper.java
│   ├── service/
│   │   ├── UserService.java
│   │   ├── SpaceService.java
│   │   ├── AvailabilityService.java
│   │   └── impl/
│   │       ├── UserServiceImpl.java
│   │       ├── SpaceServiceImpl.java
│   │       └── AvailabilityServiceImpl.java
│   ├── controller/
│   │   ├── UserController.java                 # REST API
│   │   ├── SpaceController.java
│   │   └── AvailabilityController.java
│   └── config/
│       ├── JpaConfig.java
│       ├── SecurityConfig.java
│       └── GlobalExceptionHandler.java
├── src/main/resources/
│   └── application.yml                          # Configuración
├── pom.xml                                      # Maven
└── README.md
```

**Total:** 35 archivos Java

---

## ⚙️ Configuración

### application.yml

```yaml
server:
  port: 8081

spring:
  application:
    name: catalog-service
  datasource:
    url: jdbc:postgresql://localhost:5433/catalog_db
    username: catalog_user
    password: catalog_pass
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
```

### Variables de Entorno

```bash
# Base de datos
DB_HOST=localhost
DB_PORT=5433
DB_NAME=catalog_db
DB_USER=catalog_user
DB_PASSWORD=catalog_pass

# Servidor
SERVER_PORT=8081
```

---

## 🧪 Testing

```bash
# Ejecutar tests
mvn test

# Ejecutar con cobertura
mvn clean test jacoco:report
```

---

## 🐳 Docker

### Levantar Infraestructura

```bash
docker-compose up -d
```

Servicios levantados:
- **PostgreSQL** (catalog_db) - Puerto 5433
- **Kafka + ZooKeeper** - Puerto 29092
- **Redis** - Puerto 6379

---

## 📊 Estado del Proyecto

✅ **BUILD SUCCESS** - Proyecto completamente funcional

| Componente | Archivos | Estado |
|-----------|----------|--------|
| Main | 1 | ✅ |
| Constants | 1 | ✅ |
| Exceptions | 4 | ✅ |
| Entities | 4 | ✅ |
| Repositories | 4 | ✅ |
| DTOs | 6 | ✅ |
| Mappers | 3 | ✅ |
| Services | 6 | ✅ |
| Controllers | 3 | ✅ |
| Config | 3 | ✅ |
| **TOTAL** | **35** | **100%** |

---

## 🎯 Roadmap

- [x] CRUD de Usuarios
- [x] CRUD de Espacios
- [x] Gestión de Disponibilidad
- [ ] Integración con Kafka (eventos)
- [ ] Cache con Redis
- [ ] Documentación Swagger/OpenAPI
- [ ] Tests de integración
- [ ] Métricas con Prometheus

---

## 🤝 Contribuir

1. Fork el proyecto
2. Crea tu rama (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📝 Licencia

Este proyecto está bajo la Licencia MIT.

---

## 👥 Autores

- **Angel** - *Desarrollo inicial*

---

## 🙏 Agradecimientos

- Spring Boot Team
- MapStruct
- Lombok

---

**🚀 ¡El servicio está listo para usar!**

Para más información, consulta la documentación en `/docs`

