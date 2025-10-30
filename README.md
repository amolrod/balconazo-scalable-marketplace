# 🏢 BalconazoApp - Plataforma de Alquiler de Espacios

**Estado del Proyecto:** ✅ **Backend Completado y Funcional (100%)**  
**Versión:** 1.0.0  
**Fecha:** Octubre 2025

Sistema de microservicios empresarial para reserva y alquiler de espacios compartidos (terrazas, balcones, patios, azoteas) con búsqueda geoespacial, pagos y reseñas.

---

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Arquitectura del Sistema](#arquitectura-del-sistema)
- [Tecnologías Utilizadas](#tecnologías-utilizadas)
- [Requisitos Previos](#requisitos-previos)
- [Inicio Rápido](#inicio-rápido)
- [Scripts Disponibles](#scripts-disponibles)
- [Endpoints Principales](#endpoints-principales)
- [Estado del Proyecto](#estado-del-proyecto)
- [Documentación Adicional](#documentación-adicional)

---

## 🎯 Descripción General

**BalconazoApp** es una plataforma que conecta propietarios de espacios únicos (hosts) con personas que buscan alquilar estos espacios por horas (guests). Similar a Airbnb pero enfocado en espacios al aire libre y eventos.

### Características Principales

✅ **Autenticación y Autorización** con JWT (HS512)  
✅ **Búsqueda Geoespacial** con PostGIS (radio, filtros, ordenamiento)  
✅ **Gestión de Reservas** con estados y validaciones de negocio  
✅ **Sistema de Reseñas** para calificar espacios  
✅ **Eventos Asíncronos** vía Kafka para propagación de datos  
✅ **Caché Distribuida** con Redis para optimización  
✅ **API Gateway** con rate limiting y circuit breaker  
✅ **Service Discovery** con Eureka para alta disponibilidad  

---

## 🏗️ Arquitectura del Sistema

### Microservicios (Spring Boot 3.5.7)

| Servicio | Puerto | Base de Datos | Descripción |
|----------|--------|---------------|-------------|
| **API Gateway** | 8080 | - | Puerta de entrada única, enrutamiento, seguridad |
| **Eureka Server** | 8761 | - | Registro y descubrimiento de servicios |
| **Auth Service** | 8084 | MySQL 3307 | Autenticación JWT, gestión de usuarios |
| **Catalog Service** | 8085 | PostgreSQL 5433 | CRUD de espacios, disponibilidad |
| **Booking Service** | 8082 | PostgreSQL 5434 | Reservas, reseñas, pagos |
| **Search Service** | 8083 | PostgreSQL 5435 | Búsquedas geoespaciales con PostGIS |

### Infraestructura (Docker)

| Componente | Puerto | Imagen | Uso |
|------------|--------|--------|-----|
| **PostgreSQL (Catalog)** | 5433 | postgres:16-alpine | BD de espacios |
| **PostgreSQL (Booking)** | 5434 | postgres:16-alpine | BD de reservas |
| **PostgreSQL (Search)** | 5435 | postgis/postgis:16-3.4 | BD con extensión PostGIS |
| **MySQL (Auth)** | 3307 | mysql:8.0 | BD de usuarios |
| **Redis** | 6379 | redis:7-alpine | Caché distribuida |
| **Kafka** | 9092 | cp-kafka:7.5.0 | Message broker |
| **Zookeeper** | 2181 | cp-zookeeper:7.5.0 | Coordinación Kafka |

### Diagrama de Flujo

```
Cliente HTTP → API Gateway (8080) → Eureka Discovery
                    ↓
    ┌───────────────┼───────────────┐
    ↓               ↓               ↓
Auth Service   Catalog Service   Booking Service   Search Service
(JWT Auth)     (Spaces CRUD)     (Bookings)        (Geo Search)
    ↓               ↓               ↓                    ↓
  MySQL         PostgreSQL       PostgreSQL        PostgreSQL+PostGIS
                    ↓               ↓
                  Redis (Cache)   Kafka (Events)
```

---

## 🛠️ Tecnologías Utilizadas

### Backend (Java 21)
- **Spring Boot** 3.5.7 (Framework principal)
- **Spring Cloud** 2024.0.0 (Microservicios)
  - Spring Cloud Gateway (API Gateway)
  - Spring Cloud Netflix Eureka (Service Discovery)
  - Spring Cloud Circuit Breaker (Resilience4j)
- **Spring Security** 6.2.x (JWT, OAuth2 Resource Server)
- **Spring Data JPA** + Hibernate 6.6.x (ORM)
- **MapStruct** 1.6.x (Mapeo DTO ↔ Entity)
- **Lombok** (Reducción de boilerplate)

### Bases de Datos
- **PostgreSQL** 16 (Catalog, Booking, Search)
- **PostGIS** 3.4 (Extensión geoespacial)
- **MySQL** 8.0 (Auth)
- **Redis** 7 (Caché)

### Mensajería y Eventos
- **Apache Kafka** 3.9.x (Event streaming)
- **Outbox Pattern** (Consistencia eventual)

### Build y DevOps
- **Maven** 3.9+ (Gestión de dependencias)
- **Docker** + Docker Compose (Contenedores)
- **Spring Boot Actuator** (Métricas y health checks)

---

## 📦 Requisitos Previos

### Instalación Local

1. **Java Development Kit (JDK) 21**
   ```bash
   # macOS con Homebrew
   brew install openjdk@21
   
   # Verificar instalación
   java -version  # Debe mostrar versión 21.x
   ```

2. **Apache Maven 3.9+**
   ```bash
   brew install maven
   mvn -version  # Debe mostrar 3.9.x o superior
   ```

3. **Docker Desktop para Mac**
   ```bash
   # Descargar desde: https://www.docker.com/products/docker-desktop
   # Verificar instalación
   docker --version
   docker-compose --version
   ```

4. **Herramientas Opcionales**
   ```bash
   # Para pruebas de API
   brew install curl jq
   
   # Cliente PostgreSQL (opcional)
   brew install postgresql@16
   ```

### Requisitos de Sistema

- **macOS** 11+ (Big Sur o superior)
- **Arquitectura:** ARM64 (Apple Silicon) o AMD64
- **RAM:** Mínimo 8GB (recomendado 16GB)
- **Disco:** 5GB libres

---

## 🚀 Inicio Rápido

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd BalconazoApp
```

### 2. Iniciar Infraestructura (Docker)

```bash
# Inicia PostgreSQL, MySQL, Redis, Kafka, Zookeeper
./start-infrastructure.sh

# Verificar que los contenedores estén corriendo
docker ps
```

**Salida esperada:** 7 contenedores en estado "Up"

### 3. Compilar Todos los Servicios

```bash
./recompile-all.sh
```

Este script compila:
- Eureka Server
- API Gateway
- Auth Service
- Catalog Service
- Booking Service
- Search Service

⏱️ **Tiempo estimado:** 2-3 minutos

### 4. Iniciar Todos los Microservicios

```bash
./start-all-services.sh
```

Este script inicia los servicios en el orden correcto:
1. Eureka Server (8761)
2. API Gateway (8080)
3. Auth Service (8084)
4. Catalog, Booking, Search Services

⏱️ **Tiempo de arranque:** ~45 segundos

### 5. Verificar Estado del Sistema

```bash
./comprobacionmicroservicios.sh
```

**Salida esperada:**
```
✅ API Gateway UP (200)
✅ Eureka Server UP (200)
✅ Auth Service UP (200)
✅ Catalog Service UP (200)
✅ Booking Service UP (200)
✅ Search Service UP (200)
```

### 6. Insertar Datos de Prueba

```bash
# Datos para Auth Service
./insert-test-data.sh

# Datos para Search Service
./insert-search-test-data.sh

# Datos para Bookings (estados de prueba)
./reset-bookings-test-data.sh
```

### 7. Probar el Sistema

```bash
# Obtener token JWT
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  | jq -r '.accessToken')

echo "Token obtenido: ${TOKEN:0:50}..."

# Buscar espacios cercanos
curl -s "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5" | jq

# Obtener perfil del usuario
curl -s http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN" | jq
```

---

## 📜 Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `start-infrastructure.sh` | Inicia contenedores Docker (BD, Redis, Kafka) |
| `start-all-services.sh` | Inicia todos los microservicios Java |
| `stop-all.sh` | Detiene todos los servicios y contenedores |
| `recompile-all.sh` | Recompila todos los módulos Maven |
| `comprobacionmicroservicios.sh` | Verifica health de todos los servicios |
| `insert-test-data.sh` | Inserta datos de prueba en Catalog y Auth |
| `insert-search-test-data.sh` | Inserta espacios en Search Service |
| `reset-bookings-test-data.sh` | Resetea bookings con estados limpios |
| `test-e2e-completo.sh` | Ejecuta suite completa de tests E2E |

### Uso de Scripts

```bash
# Detener todo y reiniciar
./stop-all.sh
./start-infrastructure.sh
./start-all-services.sh

# Ver logs de un servicio específico
tail -f /tmp/auth-service.log
tail -f /tmp/booking-service.log

# Recompilar solo un servicio
cd catalog_microservice
mvn clean package -DskipTests
```

---

## 🌐 Endpoints Principales

### Autenticación

```bash
# Registrar usuario
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePass123",
  "role": "HOST"
}

# Login
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePass123"
}

# Respuesta
{
  "accessToken": "eyJhbGciOiJIUzUxMiJ9...",
  "refreshToken": "eyJhbGciOiJIUzUxMiJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "userId": "uuid",
  "email": "user@example.com",
  "role": "HOST"
}
```

### Búsqueda de Espacios

```bash
# Búsqueda geoespacial
GET http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=5&minCapacity=4

# Obtener espacio por ID
GET http://localhost:8080/api/search/spaces/{spaceId}
```

### Gestión de Reservas

```bash
# Crear reserva
POST http://localhost:8080/api/booking/bookings
Authorization: Bearer {token}

{
  "spaceId": "uuid",
  "guestId": "uuid",
  "startTs": "2025-11-01T10:00:00",
  "endTs": "2025-11-01T14:00:00",
  "numGuests": 4
}

# Confirmar reserva
POST http://localhost:8080/api/booking/bookings/{bookingId}/confirm?paymentIntentId=pi_xxx

# Completar reserva
POST http://localhost:8080/api/booking/bookings/{bookingId}/complete
```

**Ver documentación completa de endpoints:** `POSTMAN_ENDPOINTS.md`

---

## ✅ Estado del Proyecto

### Backend: 100% Completado ✅

- [x] Arquitectura de microservicios implementada
- [x] Autenticación JWT funcional
- [x] CRUD completo de espacios
- [x] Sistema de reservas con estados (pending → confirmed → completed)
- [x] Búsqueda geoespacial con PostGIS
- [x] Sistema de reseñas
- [x] Eventos asíncronos con Kafka
- [x] Caché con Redis
- [x] API Gateway con rate limiting
- [x] Service Discovery con Eureka
- [x] Exception handling centralizado
- [x] Validaciones de negocio
- [x] Tests E2E automatizados
- [x] Scripts de deployment
- [x] Datos de prueba

### Pendiente (Frontend)

- [ ] Interfaz de usuario web
- [ ] Aplicación móvil
- [ ] Panel de administración

**Ver roadmap completo:** `NEXT-STEPS.md`

---

## 📚 Documentación Adicional

| Documento | Descripción |
|-----------|-------------|
| **[DOCUMENTATION.md](DOCUMENTATION.md)** | Arquitectura detallada, flujos de negocio |
| **[DATABASE.md](DATABASE.md)** | Esquemas de BD, relaciones, queries |
| **[FRONTEND-START.md](FRONTEND-START.md)** | Guía para desarrolladores frontend |
| **[NEXT-STEPS.md](NEXT-STEPS.md)** | Roadmap y tareas futuras |
| **[POSTMAN_ENDPOINTS.md](POSTMAN_ENDPOINTS.md)** | Lista completa de endpoints con ejemplos |
| **[JWT_IMPLEMENTADO.md](JWT_IMPLEMENTADO.md)** | Detalles de autenticación JWT |

---

## 🧪 Testing

### Tests Manuales con Postman

1. Importar colección: `POSTMAN_ENDPOINTS.md`
2. Configurar variable `baseUrl`: `http://localhost:8080`
3. Ejecutar flujo completo: Login → Crear Espacio → Buscar → Reservar → Review

### Tests Automatizados E2E

```bash
./test-e2e-completo.sh
```

**Suite incluye:**
- Health checks de todos los servicios
- Registro en Eureka
- Flujo de autenticación
- CRUD de espacios (Catalog)
- Búsqueda geoespacial (Search)
- Flujo completo de reservas (Booking)
- Sistema de reseñas
- Validación de seguridad (JWT)
- Verificación de eventos Kafka
- Métricas de Actuator

---

## 🐛 Troubleshooting

### Los servicios no inician

```bash
# Verificar que Docker esté corriendo
docker ps

# Verificar puertos libres
lsof -i:8080  # API Gateway
lsof -i:8761  # Eureka

# Ver logs de errores
tail -50 /tmp/api-gateway.log
```

### Error de conexión a BD

```bash
# Verificar contenedores de BD
docker ps | grep postgres
docker ps | grep mysql

# Reiniciar contenedores
docker-compose restart pg-catalog pg-booking pg-search mysql-auth
```

### Error "Service Unavailable"

```bash
# Verificar Eureka
curl http://localhost:8761/eureka/apps | grep "UP"

# Reiniciar servicios en orden
./stop-all.sh
./start-all-services.sh
```

---

## 👥 Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Add: nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

---

## 📄 Licencia

Este proyecto es privado y confidencial.

---

## 📧 Contacto

Para preguntas o soporte, contactar al equipo de desarrollo.

---

**Última actualización:** Octubre 2025  
**Versión del Backend:** 1.0.0 ✅ Completado

