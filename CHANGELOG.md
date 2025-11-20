# 📋 Registro de Cambios

Todos los cambios importantes del proyecto se documentan en este archivo.

## [1.1.0] - 2025-11-20

### 📚 Consolidación de Documentación

#### ✅ Implementado
- **PROJECT_CONTEXT.md**: Documento maestro unificado con toda la información del proyecto (6500+ líneas)
  - Arquitectura completa de microservicios
  - Guías de inicio y configuración
  - Variables de entorno
  - Datos de prueba completos
  - Roadmap y próximos pasos
  - ADRs (Decisiones Arquitectónicas)
  - Convenciones de código
  - Troubleshooting
  - Documentación de frontend

#### 🧹 Documentación Histórica Consolidada
Los siguientes archivos fueron consolidados en `CHANGELOG.md` (v1.1.0) y `PROJECT_CONTEXT.md`:

**Implementaciones Completadas:**
- `JWT_IMPLEMENTADO.md` - Sistema JWT con HS512 (24h expiration)
- `FRONTEND_SETUP_COMPLETADO.md` - Angular 20 + TailwindCSS + Design System
- `IMAGENES_EN_DETALLE_COMPLETADO.md` - Sistema de upload y galería de imágenes
- `INSTAGRAM-LAYOUT-IMPLEMENTADO.md` - Layout tipo Instagram en Space Detail
- `MODELO-AIRBNB-IMPLEMENTADO.md` - Modelo de roles dinámicos (usuario = host + guest)
- `AUTH-SIN-SCROLL-FINAL.md` - Solución scroll en login/register
- `REGISTRO-ARREGLADO-FINAL.md` - Corrección flujo de registro
- `MIS-ESPACIOS-VISIBLE.md` - Dashboard de host funcionando
- `SISTEMA_IMAGENES_COMPLETADO.md` - Sistema completo de imágenes (backend + frontend)

**Problemas Resueltos:**
- `PROBLEMAS-FINALES-SOLUCIONADOS.md` - Correcciones finales sistema
- `RESUMEN_CORRECCIONES_FINALES.md` - Resumen de correcciones
- `PRUEBAS_COMPLETAS_SISTEMA.md` - Suite de pruebas E2E

**Pull Requests Frontend:**
- `RESUMEN-3-PRS-COMPLETADOS.md` - Resumen de 3 PRs
- `PR-1-DESIGN-SYSTEM.md` - Design System base
- `PR-1-ENTREGA.md` - Primera entrega frontend
- `PR-2-CORE-INFRASTRUCTURE.md` - Infraestructura core

**Roadmap y Postman:**
- `siguientesfuncionalidades.md` - Próximas funcionalidades (ahora en NEXT-STEPS.md)
- `POSTMAN_README.md` - Introducción a colección Postman (ahora en POSTMAN_ENDPOINTS.md)

#### 🗃️ Archivos Eliminados (20 Nov 2025)
Total: **17 archivos** de documentación histórica eliminados tras consolidación
- Sin pérdida de información (todo migrado a `PROJECT_CONTEXT.md` y `CHANGELOG.md`)

---

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

