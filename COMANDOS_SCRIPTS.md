# 📋 Comandos para Scripts de BalconazoApp

## 🚀 Scripts de Inicio

### Iniciar TODA la infraestructura y servicios
```bash
./start-all-with-eureka.sh
```
Inicia: Postgres, Redis, Kafka, Zookeeper, Eureka, Gateway, Auth, Catalog, Booking, Search y Frontend

### Iniciar solo infraestructura (sin servicios)
```bash
./start-infrastructure.sh
```
Inicia: Postgres (catalog + booking), Redis, Kafka, Zookeeper

### Iniciar todos los servicios (asume infraestructura ya corriendo)
```bash
./start-all-services.sh
```
Inicia: Eureka, Gateway, Auth, Catalog, Booking, Search

### Iniciar solo frontend
```bash
./start-frontend.sh
```
Inicia Angular frontend en `http://localhost:4200`

## 🛑 Scripts de Detención

### Detener TODOS los servicios
```bash
./stop-all.sh
```
Detiene todos los servicios Java y el frontend Angular

## 🔧 Scripts de Compilación

### Recompilar todos los microservicios
```bash
./recompile-all.sh
```
Compila: Eureka, Gateway, Auth, Catalog, Booking, Search (Maven con -DskipTests)

## 🔄 Scripts de Reinicio

### Reiniciar Catalog con imágenes
```bash
./restart-catalog-with-images.sh
```
Reconstruye y reinicia el servicio de catálogo

## 🧪 Scripts de Testing

### Test E2E completo
```bash
./test-e2e-completo.sh
```
Ejecuta pruebas end-to-end del sistema completo

### Verificar sistema
```bash
./verify-system.sh
```
Verifica que todos los servicios estén funcionando correctamente

## 📊 Scripts de Base de Datos

### Insertar datos de prueba completos
```bash
./insert-test-data.sh
```
Inserta datos en: Auth, Catalog, Booking, Search

### Insertar datos de prueba para búsqueda
```bash
./insert-search-test-data.sh
```
Inserta datos de prueba específicos para el servicio de búsqueda

### Resetear datos de prueba de bookings
```bash
./reset-bookings-test-data.sh
```
Resetea los datos de prueba del servicio de reservas

### Gestionar Postgres Search
```bash
./manage-pg-search.sh [start|stop|restart|logs]
```
Gestiona el contenedor de Postgres para Search Service

## 🔍 Verificación de Servicios

### Comprobar microservicios
```bash
./comprobacionmicroservicios.sh
```
Verifica el estado de todos los microservicios

## 📝 Orden Recomendado para Iniciar

### Primera vez o inicio completo:
```bash
# 1. Iniciar infraestructura
./start-infrastructure.sh

# 2. Esperar ~10 segundos

# 3. Iniciar servicios
./start-all-services.sh

# 4. Esperar ~30 segundos

# 5. Iniciar frontend
./start-frontend.sh

# 6. Verificar que todo funciona
./verify-system.sh
```

### Inicio rápido (todo de una vez):
```bash
./start-all-with-eureka.sh
```

### Detener todo:
```bash
./stop-all.sh
```

## 🌐 URLs de Acceso

Después de iniciar los servicios:

- **Frontend**: http://localhost:4200
- **API Gateway**: http://localhost:8080
- **Eureka Dashboard**: http://localhost:8761
- **Auth Service**: http://localhost:8084
- **Catalog Service**: http://localhost:8085
- **Booking Service**: http://localhost:8082
- **Search Service**: http://localhost:8083

## 🔐 Usuarios de Prueba

### Usuario Guest/Test
- Email: `test@test.com`
- Password: `password123`
- Rol: GUEST (con 6 reservas completadas sin reseñas)

### Usuario Host
- Email: `host@host.com`
- Password: `password123`
- Rol: HOST

## 🗄️ Conexiones Base de Datos

### Postgres Catalog
- Host: `localhost:5433`
- Database: `catalog_db`
- User: `postgres`
- Password: `postgres`

### Postgres Booking
- Host: `localhost:5434`
- Database: `booking_db`
- User: `postgres`
- Password: `postgres`

### Postgres Search
- Host: `localhost:5435`
- Database: `search_db`
- User: `postgres`
- Password: `postgres`

### MySQL Auth
- Host: `localhost:3307`
- Database: `auth_db`
- User: `root`
- Password: `root`

### Redis
- Host: `localhost:6379`

### Kafka
- Bootstrap: `localhost:9092`

## 🐛 Troubleshooting

### Si un servicio no inicia:
```bash
# Ver logs del servicio
tail -f /tmp/[servicio].log

# Ejemplo:
tail -f /tmp/catalog.log
tail -f /tmp/booking.log
```

### Si necesitas recompilar un servicio específico:
```bash
cd [servicio]_microservice
mvn clean package -DskipTests
```

### Si el puerto está ocupado:
```bash
# Ver qué proceso usa el puerto
lsof -i :[puerto]

# Ejemplo para puerto 8085:
lsof -i :8085

# Matar el proceso
kill -9 [PID]
```

### Limpiar todo y empezar de cero:
```bash
./stop-all.sh
docker-compose down -v
./start-all-with-eureka.sh
```
