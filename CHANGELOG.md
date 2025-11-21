# CHANGELOG

Todos los cambios notables de este proyecto serán documentados aquí.

## [Unreleased] - 2025-11-21

### Security - Reviews System
- **[CRÍTICO]** Implementado sistema de seguridad para reviews
  - **Problema**: Cualquier usuario podía crear reseñas falsas para reservas de otros
  - **Solución**: Validación de ownership - solo el guest de la reserva puede reseñarla
  - **Implementado**:
    - Extracción de userId del JWT en ReviewController
    - Validación de ownership en ReviewServiceImpl
    - Excepciones custom: UnauthorizedReviewException, ReviewNotAllowedException, DuplicateReviewException
    - Handlers específicos en GlobalExceptionHandler (403, 400, 409)
  - **Rutas actualizadas**: `/api/booking/reviews` → `/api/bookings/reviews`
  - **Protección JWT**: Ahora bajo `/api/bookings/**` (protegido por SecurityFilter)
  - Ver detalles en: `REVIEWS_SEGURIDAD_IMPLEMENTADO.md`

### Fixed
- **[CRÍTICO]** Duplicación de path `/bookings` en BookingsService del frontend
  - Problema: Todos los métodos generaban rutas con `/bookings/bookings/...`
  - Ejemplo: `getMyBookings()` llamaba a `/api/bookings/bookings/my` en lugar de `/api/bookings/my`
  - Causaba errores 500 en página "Mis Reservas"
  - Solución: Eliminado prefijo `/bookings` en 9 métodos del servicio
  - Commit: `547ef66`
  - Ver detalles en: `SOLUCION_PATH_DUPLICADO_BOOKINGS.md`

### Changed
- Actualizada documentación de endpoints de bookings
  - `README.md`: Endpoint `/api/bookings/my-bookings` → `/api/bookings/my`
  - `docs/INDEX.md`: Tabla de endpoints actualizada
  - `docs/FRONTEND_API_GUIDE_PART_3_BOOKINGS.md`: Ejemplos corregidos
  - `docs/BACKEND_ARCHITECTURE.md`: Referencia a endpoints actualizada

### Technical Details
- **Archivos modificados**:
  - `balconazo-frontend/src/app/core/services/bookings.service.ts` (9 métodos corregidos)
  - Documentación: README, INDEX, FRONTEND_API_GUIDE_PART_3, BACKEND_ARCHITECTURE
  - Nuevo documento: `SOLUCION_PATH_DUPLICADO_BOOKINGS.md`

## [0.1.0] - 2025-11-21

### Added
- Sistema de autenticación con JWT (Auth Service)
- Microservicio de catálogo de espacios (Catalog Service)
- Microservicio de reservas (Booking Service)
- Microservicio de búsqueda (Search Service)
- API Gateway con Spring Cloud Gateway
- Eureka Server para service discovery
- Frontend Angular 20.3.3
- Docker Compose para infraestructura
- Bases de datos PostgreSQL (Catalog, Booking, Search) y MySQL (Auth)

### Security
- JWT con algoritmo HS512
- BCrypt para contraseñas
- CORS configurado en Gateway
- Endpoints públicos y protegidos separados

### Infrastructure
- 6 microservicios en Spring Boot 3.5.7
- Service Discovery con Eureka
- API Gateway en puerto 8080
- Frontend en puerto 4200
- Bases de datos PostgreSQL (5432-5435) y MySQL (3307)
