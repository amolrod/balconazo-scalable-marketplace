# 🏢 BalconazoApp - Sistema de Reservas de Espacios

Sistema de microservicios para alquiler de espacios (terrazas, balcones, etc.) desarrollado con Spring Boot, Spring Cloud y PostgreSQL.

## 📋 Arquitectura

### Microservicios
- **API Gateway** (Puerto 8080): Puerta de entrada única al sistema
- **Eureka Server** (Puerto 8761): Registro y descubrimiento de servicios
- **Auth Service** (Puerto 8084): Autenticación y autorización con JWT
- **Catalog Service** (Puerto 8085): Gestión de espacios
- **Booking Service** (Puerto 8082): Gestión de reservas y reseñas
- **Search Service** (Puerto 8083): Búsquedas geoespaciales con PostGIS

### Infraestructura
- **PostgreSQL** (Puertos 5433, 5434, 5435): Bases de datos por microservicio
- **MySQL** (Puerto 3307): Base de datos para Auth Service
- **Redis** (Puerto 6379): Caché distribuida
- **Kafka** (Puerto 9092): Mensajería asíncrona
- **Zookeeper** (Puerto 2181): Coordinación de Kafka

## 🚀 Inicio Rápido

### Prerequisitos
- Java 21
- Maven 3.9+
- Docker y Docker Compose
- macOS con arquitectura ARM64 (Apple Silicon)

### 1. Iniciar Infraestructura (Docker)
```bash
./start-infrastructure.sh
```

Esto inicia: PostgreSQL, MySQL, Redis, Kafka y Zookeeper.

### 2. Iniciar Todos los Microservicios
```bash
./start-all-services.sh
```

### 3. Verificar Estado del Sistema
```bash
./comprobacionmicroservicios.sh
```

Todos los servicios deben mostrar **200 OK**.

### 4. Insertar Datos de Prueba
```bash
./insert-test-data.sh
```

## 📝 Documentación

- **[COMO_INICIAR_SERVICIOS.md](./COMO_INICIAR_SERVICIOS.md)**: Guía detallada de inicio
- **[DATOS_PRUEBA_IDS.md](./DATOS_PRUEBA_IDS.md)**: IDs de usuarios y espacios de prueba
- **[JWT_IMPLEMENTADO.md](./JWT_IMPLEMENTADO.md)**: Configuración de seguridad JWT
- **[POSTMAN_ENDPOINTS.md](./POSTMAN_ENDPOINTS.md)**: Lista completa de endpoints
- **[PRUEBAS_COMPLETAS_SISTEMA.md](./PRUEBAS_COMPLETAS_SISTEMA.md)**: Suite de pruebas E2E

## 🔑 Credenciales de Prueba

### Usuario HOST
```
Email: host1@balconazo.com
Password: password123
Role: HOST
```

### Usuario GUEST
```
Email: guest1@balconazo.com
Password: password123
Role: GUEST
```

## 🧪 Pruebas con Postman

1. Importar colección: `BalconazoApp.postman_collection.json`
2. Importar entorno: `Balconazo_Local.postman_environment.json`
3. Ejecutar: `1. Auth > Login` para obtener el token
4. El token se guarda automáticamente en las variables de entorno

## 📊 Endpoints Principales

### Autenticación (Público)
```bash
POST /api/auth/register
POST /api/auth/login
```

### Catálogo (Requiere JWT)
```bash
GET    /api/catalog/spaces
POST   /api/catalog/spaces
GET    /api/catalog/spaces/{id}
PUT    /api/catalog/spaces/{id}
POST   /api/catalog/spaces/{id}/activate
POST   /api/catalog/spaces/{id}/deactivate
```

### Búsqueda Geoespacial (Público)
```bash
GET /api/search/spaces?lat={lat}&lon={lon}&radius={km}
```

### Reservas (Requiere JWT)
```bash
POST   /api/booking/bookings
GET    /api/booking/bookings/guest/{guestId}
POST   /api/booking/bookings/{id}/confirm
POST   /api/booking/bookings/{id}/cancel
POST   /api/booking/bookings/{id}/complete
```

### Reseñas (Requiere JWT)
```bash
POST   /api/booking/reviews
GET    /api/booking/reviews/space/{spaceId}
```

## 🛠️ Scripts Útiles

| Script | Descripción |
|--------|-------------|
| `start-infrastructure.sh` | Inicia contenedores Docker |
| `start-all-services.sh` | Inicia todos los microservicios |
| `start-all-with-eureka.sh` | Inicia servicios + Eureka |
| `comprobacionmicroservicios.sh` | Verifica estado de servicios |
| `stop-all.sh` | Detiene todos los servicios |
| `recompile-all.sh` | Recompila todos los módulos |
| `insert-test-data.sh` | Inserta datos de prueba |
| `test-e2e-completo.sh` | Suite completa de pruebas E2E |
| `verify-system.sh` | Verificación completa del sistema |
| `manage-pg-search.sh` | Gestión del contenedor PostGIS |

## 🏗️ Estructura del Proyecto

```
BalconazoApp/
├── api-gateway/           # Gateway (Spring Cloud Gateway)
├── eureka-server/         # Service Discovery
├── auth-service/          # Autenticación JWT
├── catalog_microservice/  # Catálogo de espacios
├── booking_microservice/  # Reservas y reseñas
├── search_microservice/   # Búsqueda geoespacial
├── ddl/                   # Schemas SQL
├── docs/                  # Documentación adicional
└── docker-compose.yml     # Infraestructura Docker
```

## 🔧 Tecnologías

- **Backend**: Spring Boot 3.x, Spring Cloud 2023.x
- **Bases de Datos**: PostgreSQL 16, MySQL 8.0, PostGIS
- **Mensajería**: Apache Kafka 3.5
- **Caché**: Redis 7
- **Service Discovery**: Netflix Eureka
- **API Gateway**: Spring Cloud Gateway
- **Seguridad**: Spring Security, JWT (HS512)
- **Build**: Maven
- **Containerización**: Docker

## 📈 Monitoreo

- **Eureka Dashboard**: http://localhost:8761
- **Gateway Actuator**: http://localhost:8080/actuator
- **Service Health**: http://localhost:{port}/actuator/health

## 🐛 Troubleshooting

### Search Service no inicia
```bash
# Recrear contenedor PostGIS
./manage-pg-search.sh
```

### Puertos ocupados
```bash
# Detener todos los servicios
./stop-all.sh

# Limpiar puertos manualmente
lsof -ti:8080,8082,8083,8084,8085,8761 | xargs kill -9
```

### Recompilar todo
```bash
./recompile-all.sh
```

## 📄 Licencia

Este proyecto es un sistema de demostración para fines educativos.

---

**Última actualización:** 30 de Octubre de 2025  
**Versión:** 1.0.0  
**Estado:** ✅ Producción

