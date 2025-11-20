# 🏢 BalconazoApp - Marketplace de Alquiler de Espacios

[![Tests](https://img.shields.io/badge/tests-45%2F45%20passing-success)](./scripts/test-roles-usuarios-completo.sh)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](./docs/BACKEND_ARCHITECTURE.md)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.5.7-brightgreen)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-17+-orange)](https://openjdk.org/)

> Plataforma de microservicios tipo Airbnb para alquiler de espacios (terrazas, jardines, salones) con autenticación JWT, sistema de roles dinámico y gestión completa de reservas.

---

## 📋 Tabla de Contenidos

- [Características Principales](#-características-principales)
- [Arquitectura](#-arquitectura)
- [Inicio Rápido](#-inicio-rápido)
- [Documentación](#-documentación)
- [Scripts Disponibles](#-scripts-disponibles)
- [Estado del Proyecto](#-estado-del-proyecto)
- [Tecnologías](#-tecnologías)
- [Contribuir](#-contribuir)

---

## ✨ Características Principales

### Para Usuarios
- 🔐 **Autenticación JWT** - Registro, login y gestión segura de sesiones
- 👥 **Roles Dinámicos** - Sistema Guest/Host con promoción automática
- 🏠 **Gestión de Espacios** - CRUD completo con validación de ownership
- 📸 **Múltiples Imágenes** - Galería de fotos con imagen primaria
- 📅 **Sistema de Reservas** - Crear, confirmar y cancelar reservas
- 🔍 **Búsqueda Avanzada** - Filtros por ubicación, precio y capacidad
- 💰 **Cálculo Automático** - Precios calculados por horas

### Para Desarrolladores
- 🏗️ **Microservicios** - Arquitectura escalable e independiente
- 🔒 **Seguridad** - JWT en todos los endpoints protegidos
- 🗄️ **Database per Service** - PostgreSQL aislado por servicio
- 🔄 **Service Discovery** - Eureka Server para registro automático
- 🚪 **API Gateway** - Punto de entrada único con enrutamiento
- ✅ **100% Tests** - Suite completa de 45 tests end-to-end pasando

---

## 🏗️ Arquitectura

### Visión General

```
┌─────────────┐
│   Cliente   │
│  (Frontend) │
└──────┬──────┘
       │
       │ HTTP/HTTPS
       ▼
┌─────────────────┐
│  API Gateway    │ ← Punto de entrada único (Port 8080)
│  Spring Cloud   │
└────────┬────────┘
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│  Auth  │ │Catalog │ │Booking │ │Search  │
│  8084  │ │  8085  │ │  8082  │ │  8083  │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘
    │          │          │          │
    ▼          ▼          ▼          ▼
┌────────────────────────────────────────┐
│         PostgreSQL Databases           │
│  auth_db  catalog_db  booking_db  search_db
│  :5433      :5432       :5434      :5435 │
└────────────────────────────────────────┘

        ┌──────────────┐
        │Eureka Server │ ← Service Discovery (:8761)
        └──────────────┘
```

### Microservicios

| Servicio | Puerto | Base de Datos | Responsabilidad |
|----------|--------|---------------|-----------------|
| **API Gateway** | 8080 | - | Enrutamiento, seguridad, balanceo |
| **Auth Service** | 8084 | PostgreSQL :5433 | Autenticación, usuarios, roles |
| **Catalog Service** | 8085 | PostgreSQL :5432 | Espacios, imágenes, ownership |
| **Booking Service** | 8082 | PostgreSQL :5434 | Reservas, confirmación, cancelación |
| **Search Service** | 8083 | PostgreSQL :5435 | Búsqueda con filtros |
| **Eureka Server** | 8761 | - | Service Discovery |

---

## 🚀 Inicio Rápido

### Prerrequisitos

- **Java 17+** ([OpenJDK](https://openjdk.org/))
- **Maven 3.9+** ([Apache Maven](https://maven.apache.org/))
- **Docker & Docker Compose** ([Docker Desktop](https://www.docker.com/products/docker-desktop/))
- **Git** ([Git SCM](https://git-scm.com/))

### Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/amolrod/balconazo-scalable-marketplace.git
cd balconazo-scalable-marketplace

# 2. Iniciar infraestructura (PostgreSQL containers)
./scripts/start-infrastructure.sh

# 3. Compilar todos los servicios
./scripts/recompile-all.sh

# 4. Iniciar todos los microservicios
./scripts/start-all-with-eureka.sh

# 5. Verificar que todo esté funcionando
./scripts/verify-system.sh
```

### Verificación

Una vez iniciados todos los servicios, verifica:

- **API Gateway**: http://localhost:8080
- **Eureka Dashboard**: http://localhost:8761
- **Health Check**: `curl http://localhost:8080/actuator/health`

### Ejecutar Tests

```bash
# Tests end-to-end completos (45 tests)
./scripts/test-roles-usuarios-completo.sh
```

**Resultado esperado:**
```
Tests ejecutados:     45
Tests exitosos:       45 ✅
Tests fallidos:       0 ❌
Tasa de éxito:        100,00%
```

---

## 📚 Documentación

La documentación completa está organizada en la carpeta [`docs/`](./docs/):

### 🎯 Para Desarrolladores Frontend

Guías completas para integrar con la API REST:

1. **[Autenticación y Roles](./docs/FRONTEND_API_GUIDE_PART_1_AUTH.md)**
   - Sistema de autenticación JWT
   - Registro, login y gestión de sesiones
   - Roles dinámicos (Guest/Host)
   - Context API y protected routes
   - Ejemplos React/TypeScript completos

2. **[Gestión de Espacios](./docs/FRONTEND_API_GUIDE_PART_2_SPACES.md)**
   - CRUD de espacios
   - Sistema de ownership
   - Gestión de múltiples imágenes
   - Validación de permisos
   - Componentes React de ejemplo

3. **[Sistema de Reservas](./docs/FRONTEND_API_GUIDE_PART_3_BOOKINGS.md)**
   - Crear, confirmar y cancelar reservas
   - Validación de conflictos de fechas
   - Listado de reservas (guest y host)
   - Integración con Stripe (conceptual)
   - Dashboards y casos de uso

4. **[Búsqueda de Espacios](./docs/FRONTEND_API_GUIDE_PART_4_SEARCH.md)**
   - Búsqueda sin autenticación (endpoint público)
   - Filtros: ubicación, precio, capacidad
   - Búsqueda con debounce
   - Landing page pública

### 🏗️ Para Desarrolladores Backend

- **[Arquitectura Completa](./docs/BACKEND_ARCHITECTURE.md)**
  - Visión general de microservicios
  - Tecnologías y stack técnico
  - Comunicación entre servicios
  - Esquemas de base de datos
  - Flujos de datos principales
  - ADRs (Architectural Decision Records)
  - Despliegue y operaciones

### 📖 Índice General

- **[INDEX.md](./docs/INDEX.md)** - Índice completo con enlaces rápidos y convenciones

### 📝 Decisiones de Arquitectura (ADRs)

- **[ADR: API Gateway sin Persistencia](./docs/ADR_API_GATEWAY_SIN_PERSISTENCIA.md)**
- **[ADR: Modelo de Roles Dinámicos](./docs/ADR_MODELO_ROLES_DINAMICOS.md)**
- **[Algoritmo de Precios](./docs/PRICING_ALGORITHM.md)**

---

## 🛠️ Scripts Disponibles

Todos los scripts están en la carpeta [`scripts/`](./scripts/):

| Script | Descripción |
|--------|-------------|
| `start-infrastructure.sh` | Inicia contenedores PostgreSQL (Docker Compose) |
| `start-all-with-eureka.sh` | Inicia Eureka + todos los microservicios |
| `start-all-services.sh` | Inicia solo microservicios (sin Eureka) |
| `stop-all.sh` | Detiene todos los servicios Java |
| `recompile-all.sh` | Recompila todos los microservicios (Maven) |
| `verify-system.sh` | Verifica salud de todos los servicios |
| `test-roles-usuarios-completo.sh` | Ejecuta suite completa de tests E2E |

### Uso Típico

```bash
# Desarrollo diario
./scripts/start-infrastructure.sh  # Una vez
./scripts/start-all-with-eureka.sh # Al iniciar sesión
./scripts/verify-system.sh         # Para verificar

# Al hacer cambios
./scripts/stop-all.sh
./scripts/recompile-all.sh
./scripts/start-all-with-eureka.sh

# Antes de commit
./scripts/test-roles-usuarios-completo.sh
```

---

## 📊 Estado del Proyecto

### ✅ Completado (100%)

- [x] **Arquitectura de Microservicios** - 5 servicios + API Gateway + Eureka
- [x] **Autenticación JWT** - Registro, login, validación de tokens
- [x] **Sistema de Roles Dinámico** - Promoción automática Guest → Host
- [x] **CRUD de Espacios** - Con validación de ownership y múltiples imágenes
- [x] **Sistema de Reservas** - Estados (pending → confirmed/cancelled)
- [x] **Búsqueda Avanzada** - Filtros combinados por ubicación, precio, capacidad
- [x] **API Gateway** - Enrutamiento y seguridad centralizada
- [x] **Service Discovery** - Eureka Server funcional
- [x] **Base de Datos** - PostgreSQL por servicio (Database per Service)
- [x] **Tests E2E** - 45/45 tests pasando (100%)
- [x] **Documentación** - Guías completas para frontend y backend

### 🔜 Roadmap Futuro

- [ ] **Reviews y Ratings** - Sistema de reseñas para espacios
- [ ] **Chat en Tiempo Real** - Mensajería entre guest y host (WebSockets)
- [ ] **Calendario Avanzado** - Bloqueo de fechas y disponibilidad
- [ ] **Integración Stripe** - Pagos completos con webhooks
- [ ] **Notificaciones** - Email/SMS para eventos importantes
- [ ] **Panel Admin** - Dashboard de administración
- [ ] **App Móvil** - React Native o Flutter
- [ ] **CI/CD** - GitHub Actions para deploy automático
- [ ] **Kubernetes** - Orquestación de contenedores
- [ ] **Monitoring** - Prometheus + Grafana

---

## 🔧 Tecnologías

### Backend

| Tecnología | Versión | Uso |
|------------|---------|-----|
| **Spring Boot** | 3.5.7 | Framework de aplicación |
| **Spring Cloud Gateway** | 4.2.0 | API Gateway |
| **Spring Cloud Netflix Eureka** | 4.2.0 | Service Discovery |
| **Spring Security** | 6.4.2 | Autenticación y autorización |
| **Spring Data JPA** | 3.5.7 | ORM y acceso a datos |
| **Java JWT** | 4.4.0 | Generación y validación de tokens |
| **PostgreSQL** | 16 | Base de datos relacional |
| **Docker** | - | Contenedores de BD |
| **Maven** | 3.9+ | Build tool |
| **Lombok** | 1.18.30 | Reducción de boilerplate |

### Arquitectura

- **Patrón**: Microservicios
- **Comunicación**: REST + Load Balancing
- **Persistencia**: Database per Service
- **Seguridad**: JWT (HS256)
- **Discovery**: Eureka Server

---

## 📡 Endpoints Principales

**Base URL**: `http://localhost:8080` (API Gateway)

### Autenticación (Público)

```http
POST   /api/auth/register    # Registrar usuario
POST   /api/auth/login       # Iniciar sesión
GET    /api/auth/me          # Obtener perfil (requiere token)
```

### Espacios (Requiere autenticación)

```http
GET    /api/spaces           # Listar todos los espacios
POST   /api/spaces           # Crear espacio (se convierte en HOST)
GET    /api/spaces/{id}      # Obtener espacio por ID
PUT    /api/spaces/{id}      # Actualizar espacio (solo owner)
DELETE /api/spaces/{id}      # Eliminar espacio (solo owner)
GET    /api/spaces/my-spaces # Mis espacios como HOST
```

### Reservas (Requiere autenticación)

```http
POST   /api/bookings                  # Crear reserva
GET    /api/bookings/my-bookings      # Mis reservas como GUEST
GET    /api/bookings/space/{spaceId}  # Reservas de mi espacio (HOST)
POST   /api/bookings/{id}/confirm     # Confirmar reserva (HOST)
POST   /api/bookings/{id}/cancel      # Cancelar reserva
```

### Búsqueda (Público)

```http
GET    /api/search?location={loc}&maxPrice={price}&minCapacity={cap}
```

**Ejemplo**:
```bash
curl "http://localhost:8080/api/search?location=Barcelona&maxPrice=50&minCapacity=10"
```

---

## 🧪 Testing

### Suite de Tests E2E

**Archivo**: [`scripts/test-roles-usuarios-completo.sh`](./scripts/test-roles-usuarios-completo.sh)

**Cobertura** (45 tests):

1. **Registro de Usuarios** (3 tests)
   - Registro exitoso
   - Validaciones de campos
   - Duplicados

2. **Autenticación** (7 tests)
   - Login correcto/incorrecto
   - Tokens JWT
   - Endpoints protegidos

3. **Gestión de Espacios** (15 tests)
   - CRUD completo
   - Validación de ownership
   - Promoción a HOST

4. **Búsqueda** (3 tests)
   - Búsqueda sin autenticación
   - Filtros combinados

5. **Reservas** (9 tests)
   - Crear reservas
   - Validación de conflictos
   - Confirmar/cancelar

6. **Listado de Reservas** (8 tests)
   - Vista guest
   - Vista host
   - Diferentes estados

**Ejecutar**:
```bash
./scripts/test-roles-usuarios-completo.sh
```

---

## 🤝 Contribuir

### Proceso de Desarrollo

1. Fork el repositorio
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit tus cambios: `git commit -m 'feat: agregar nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

### Convenciones de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `refactor:` - Refactorización de código
- `test:` - Agregar o modificar tests
- `chore:` - Tareas de mantenimiento

### Guía de Estilo

- **Java**: Seguir [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- **Commits**: Mensajes claros y descriptivos
- **Tests**: Agregar tests para nuevas funcionalidades
- **Documentación**: Actualizar docs al cambiar APIs

---

## 📄 Licencia

Este proyecto está bajo la licencia **MIT**.

---

## 👥 Autores

- **Angel Rodriguez** - [@amolrod](https://github.com/amolrod)

---

## 🔗 Enlaces Útiles

- [Documentación Completa](./docs/INDEX.md)
- [Arquitectura Backend](./docs/BACKEND_ARCHITECTURE.md)
- [Guías Frontend](./docs/FRONTEND_API_GUIDE_PART_1_AUTH.md)
- [Colección Postman](./Balconazo_API.postman_collection.json)
- [Spring Boot Docs](https://spring.io/projects/spring-boot)
- [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)

---

## 🙏 Agradecimientos

- Spring Boot Team por el excelente framework
- Spring Cloud Netflix por Eureka Server
- Comunidad Open Source

---

## 📞 Soporte

¿Problemas o preguntas?

1. Revisa la [documentación](./docs/INDEX.md)
2. Consulta los [issues existentes](https://github.com/amolrod/balconazo-scalable-marketplace/issues)
3. Crea un [nuevo issue](https://github.com/amolrod/balconazo-scalable-marketplace/issues/new)

---

<div align="center">

**⭐ Si te gusta el proyecto, dale una estrella! ⭐**

[Reportar Bug](https://github.com/amolrod/balconazo-scalable-marketplace/issues) · [Solicitar Feature](https://github.com/amolrod/balconazo-scalable-marketplace/issues) · [Documentación](./docs/INDEX.md)

Made with ❤️ by the BalconazoApp Team

</div>

