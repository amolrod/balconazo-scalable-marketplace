# 📋 Registro de Cambios

Todos los cambios importantes del proyecto se documentan en este archivo.

## [1.0.0] - 2025-10-30

### ✅ Sistema Completamente Funcional

#### 🎯 Implementado
- **API Gateway** con Spring Cloud Gateway y WebFlux
- **Service Discovery** con Eureka Server
- **Autenticación JWT** con Spring Security (HS512)
- **Microservicio de Catálogo** con PostgreSQL
- **Microservicio de Reservas** con PostgreSQL
- **Microservicio de Búsqueda** con PostGIS (geoespacial)
- **Infraestructura Docker** (PostgreSQL, MySQL, Redis, Kafka, Zookeeper)

#### 🔧 Configuración
- **Security**: JWT con validación en todos los servicios
- **Rate Limiting**: Configurado en API Gateway
- **CORS**: Habilitado para desarrollo
- **Health Checks**: Actuator en todos los servicios
- **Service Discovery**: Todos los servicios registrados en Eureka

#### 🐛 Correcciones Principales

##### Search Service
- ✅ Corregida password de BD (vacía → `postgres`)
- ✅ Corregidos nombres de columnas SQL (`location` → `geo`, `current_price_cents` → `base_price_cents`, `average_rating` → `avg_rating`)
- ✅ Actualizada entidad JPA con nombres correctos
- ✅ Corregidos todos los Repository queries
- ✅ Actualizados servicios y consumidores Kafka
- ✅ Contenedor PostGIS ARM64 configurado correctamente

##### Auth Service
- ✅ Contraseñas hasheadas con BCrypt
- ✅ JWT funcionando en todos los endpoints
- ✅ Spring Security configurado correctamente
- ✅ `/error` permitido para evitar 403 en errores

##### API Gateway
- ✅ Configuración WebFlux completa
- ✅ Rate limiting con Redis
- ✅ Rutas a todos los microservicios
- ✅ JWT validation filter
- ✅ CORS configurado

##### Catalog Service
- ✅ Validaciones DTO correctas
- ✅ Endpoints funcionando con JWT
- ✅ Owner verification implementada

##### Booking Service
- ✅ DTOs con nombres correctos (`startTs`, `endTs`)
- ✅ Reviews funcionando
- ✅ Payment flow implementado

#### 📝 Scripts Creados
- `start-infrastructure.sh` - Inicia Docker Compose
- `start-all-services.sh` - Inicia todos los microservicios
- `comprobacionmicroservicios.sh` - Verifica estado
- `insert-test-data.sh` - Inserta datos de prueba
- `test-e2e-completo.sh` - Suite de pruebas E2E
- `manage-pg-search.sh` - Gestión PostGIS ARM64

#### 📦 Dependencias Principales
- Spring Boot 3.5.7
- Spring Cloud 2023.0.x
- PostgreSQL 16
- MySQL 8.0
- PostGIS 16-3.4
- Redis 7
- Kafka 3.5
- Java 21

#### 🗑️ Limpieza Realizada (30 Oct 2025)
Eliminados 24 archivos de documentación redundantes:
- Múltiples archivos de diagnóstico 403
- Documentos de soluciones temporales
- Guías obsoletas
- Scripts de prueba antiguos

#### 📊 Estado Actual
- ✅ 6 microservicios funcionando
- ✅ 7 contenedores Docker activos
- ✅ Todos los endpoints operativos
- ✅ JWT implementado y validado
- ✅ Búsquedas geoespaciales funcionando
- ✅ Sistema listo para desarrollo

---

## Formato

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

### Tipos de cambios
- **Added** (Añadido): para funcionalidades nuevas
- **Changed** (Cambiado): para cambios en funcionalidades existentes
- **Deprecated** (Obsoleto): para funcionalidades que pronto se eliminarán
- **Removed** (Eliminado): para funcionalidades eliminadas
- **Fixed** (Arreglado): para corrección de errores
- **Security** (Seguridad): en caso de vulnerabilidades

---

**Mantenido por:** Equipo Balconazo  
**Última actualización:** 30 de Octubre de 2025

