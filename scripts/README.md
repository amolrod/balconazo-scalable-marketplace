# 📜 Scripts de BalconazoApp

Esta carpeta contiene todos los scripts operacionales para gestionar el ciclo de vida de la aplicación BalconazoApp.

---

## 📋 Índice de Scripts

| Script | Descripción | Uso |
|--------|-------------|-----|
| [`start-infrastructure.sh`](#start-infrastructuresh) | Inicia contenedores PostgreSQL | Inicio del sistema |
| [`start-all-with-eureka.sh`](#start-all-with-eurekash) | Inicia Eureka + todos los microservicios | Desarrollo completo |
| [`start-all-services.sh`](#start-all-servicessh) | Inicia solo microservicios | Desarrollo sin Eureka |
| [`stop-all.sh`](#stop-allsh) | Detiene todos los servicios | Finalizar trabajo |
| [`recompile-all.sh`](#recompile-allsh) | Recompila todos los servicios | Después de cambios |
| [`verify-system.sh`](#verify-systemsh) | Verifica salud del sistema | Testing/debugging |
| [`test-roles-usuarios-completo.sh`](#test-roles-usuarios-completosh) | Ejecuta tests E2E (45 tests) | Validación completa |

---

## 🚀 Flujo de Trabajo Típico

### Inicio de Día

```bash
# 1. Iniciar infraestructura (PostgreSQL)
./scripts/start-infrastructure.sh

# 2. Iniciar todos los microservicios con Eureka
./scripts/start-all-with-eureka.sh

# 3. Verificar que todo esté funcionando
./scripts/verify-system.sh
```

### Después de Hacer Cambios

```bash
# 1. Detener servicios
./scripts/stop-all.sh

# 2. Recompilar con cambios
./scripts/recompile-all.sh

# 3. Reiniciar servicios
./scripts/start-all-with-eureka.sh

# 4. Ejecutar tests
./scripts/test-roles-usuarios-completo.sh
```

### Finalizar Día

```bash
# Detener todos los servicios
./scripts/stop-all.sh

# Opcional: Detener también Docker (libera RAM)
docker-compose down
```

---

## 📄 Detalles de cada Script

### `start-infrastructure.sh`

**Propósito**: Inicia todos los contenedores Docker necesarios (bases de datos PostgreSQL).

**Qué hace**:
- Levanta 4 contenedores PostgreSQL (uno por cada microservicio)
- Crea las bases de datos: `auth_db`, `catalog_db`, `booking_db`, `search_db`
- Espera a que todas las BD estén listas
- Ejecuta scripts de inicialización (DDL)

**Uso**:
```bash
./scripts/start-infrastructure.sh
```

**Puertos utilizados**:
- PostgreSQL Auth: 5433
- PostgreSQL Catalog: 5432
- PostgreSQL Booking: 5434
- PostgreSQL Search: 5435

**Salida esperada**:
```
✅ Contenedores PostgreSQL iniciados
✅ Base de datos auth_db creada en puerto 5433
✅ Base de datos catalog_db creada en puerto 5432
✅ Base de datos booking_db creada en puerto 5434
✅ Base de datos search_db creada en puerto 5435
```

**Troubleshooting**:
```bash
# Verificar contenedores
docker ps

# Ver logs si hay error
docker logs pg-auth
docker logs pg-catalog
docker logs pg-booking
docker logs pg-search
```

---

### `start-all-with-eureka.sh`

**Propósito**: Inicia Eureka Server y todos los microservicios en el orden correcto.

**Qué hace**:
1. Inicia **Eureka Server** (8761) y espera 20 segundos
2. Inicia **API Gateway** (8080) y espera 15 segundos
3. Inicia **Auth Service** (8084)
4. Inicia **Catalog Service** (8085)
5. Inicia **Booking Service** (8082)
6. Inicia **Search Service** (8083)
7. Espera 30 segundos para registro completo en Eureka

**Uso**:
```bash
./scripts/start-all-with-eureka.sh
```

**Tiempo total**: ~1 minuto 45 segundos

**Logs**:
Los logs de cada servicio se escriben en `/tmp/`:
- `/tmp/eureka-server.log`
- `/tmp/api-gateway.log`
- `/tmp/auth-service.log`
- `/tmp/catalog-service.log`
- `/tmp/booking-service.log`
- `/tmp/search-service.log`

**Verificar logs en tiempo real**:
```bash
tail -f /tmp/auth-service.log
tail -f /tmp/catalog-service.log
```

**Salida esperada**:
```
🚀 Iniciando Eureka Server...
✅ Eureka Server iniciado en puerto 8761
🚀 Iniciando API Gateway...
✅ API Gateway iniciado en puerto 8080
🚀 Iniciando Auth Service...
✅ Auth Service iniciado en puerto 8084
...
✅ Todos los servicios iniciados correctamente
```

---

### `start-all-services.sh`

**Propósito**: Inicia solo los microservicios, sin Eureka Server (útil para desarrollo ligero).

**Cuándo usar**:
- Desarrollo donde no necesitas service discovery
- Pruebas locales de un servicio específico
- Menos carga de memoria

**Diferencia con `start-all-with-eureka.sh`**:
- **NO** inicia Eureka Server
- Tiempos de espera más cortos
- Servicios se conectan directamente por hostname

**Uso**:
```bash
./scripts/start-all-services.sh
```

**Nota**: Los servicios seguirán intentando conectarse a Eureka, pero funcionarán sin él gracias al API Gateway.

---

### `stop-all.sh`

**Propósito**: Detiene todos los procesos Java (microservicios) de manera limpia.

**Qué hace**:
- Busca todos los procesos Java ejecutándose
- Identifica servicios de BalconazoApp (eureka, gateway, auth, catalog, booking, search)
- Los detiene usando `kill` (SIGTERM)
- Muestra los servicios detenidos

**Uso**:
```bash
./scripts/stop-all.sh
```

**Salida esperada**:
```
🛑 Deteniendo todos los servicios Java...
  ✅ Detenido: eureka-server.jar (PID 12345)
  ✅ Detenido: api-gateway.jar (PID 12346)
  ✅ Detenido: auth-service.jar (PID 12347)
  ✅ Detenido: catalog-service.jar (PID 12348)
  ✅ Detenido: booking-service.jar (PID 12349)
  ✅ Detenido: search-service.jar (PID 12350)
✅ Todos los servicios detenidos
```

**Nota**: Este script **NO** detiene los contenedores Docker. Para eso usa:
```bash
docker-compose down
```

---

### `recompile-all.sh`

**Propósito**: Recompila todos los microservicios usando Maven (genera nuevos JARs).

**Qué hace**:
1. Limpia y compila el proyecto padre (`pom.xml` raíz)
2. Compila cada microservicio individualmente:
   - eureka-server
   - api-gateway
   - auth-service
   - catalog_microservice
   - booking_microservice
   - search_microservice

**Uso**:
```bash
./scripts/recompile-all.sh
```

**Opciones**:
```bash
# Recompilar sin ejecutar tests (más rápido)
./scripts/recompile-all.sh -DskipTests

# Recompilar solo un servicio
cd catalog_microservice
mvn clean package -DskipTests
```

**Tiempo estimado**: 2-3 minutos (depende de tu máquina)

**Salida esperada**:
```
🔨 Compilando proyecto padre...
✅ Proyecto padre compilado

🔨 Compilando Eureka Server...
[INFO] BUILD SUCCESS
✅ Eureka Server compilado

🔨 Compilando API Gateway...
[INFO] BUILD SUCCESS
✅ API Gateway compilado
...
✅ Todos los servicios compilados exitosamente
```

**Troubleshooting**:
```bash
# Si hay error en MapStruct (no debería)
mvn clean install -DskipTests -U

# Limpiar caché de Maven
rm -rf ~/.m2/repository
```

---

### `verify-system.sh`

**Propósito**: Verifica que todos los servicios estén corriendo y respondan correctamente.

**Qué hace**:
- Hace peticiones HTTP a los endpoints `/actuator/health` de cada servicio
- Muestra el estado de cada servicio (UP/DOWN)
- Retorna código de salida 0 si todo OK, 1 si algún servicio falló

**Uso**:
```bash
./scripts/verify-system.sh
```

**Salida esperada**:
```
🔍 Verificando estado de los servicios...

✅ API Gateway (8080): UP
✅ Eureka Server (8761): UP
✅ Auth Service (8084): UP
✅ Catalog Service (8085): UP
✅ Booking Service (8082): UP
✅ Search Service (8083): UP

✅ Todos los servicios están funcionando correctamente
```

**Salida si hay error**:
```
🔍 Verificando estado de los servicios...

✅ API Gateway (8080): UP
✅ Eureka Server (8761): UP
❌ Auth Service (8084): DOWN
✅ Catalog Service (8085): UP
✅ Booking Service (8082): UP
✅ Search Service (8083): UP

❌ Algunos servicios no están disponibles. Revisa los logs.
```

**Uso en CI/CD**:
```bash
# En GitHub Actions
./scripts/verify-system.sh
if [ $? -ne 0 ]; then
  echo "❌ Sistema no disponible"
  exit 1
fi
```

---

### `test-roles-usuarios-completo.sh`

**Propósito**: Ejecuta suite completa de tests end-to-end (45 tests) que valida todo el sistema.

**Cobertura de Tests**:

1. **Registro de Usuarios** (3 tests)
   - Registro exitoso
   - Validación de campos
   - Duplicados

2. **Autenticación** (7 tests)
   - Login correcto/incorrecto
   - Validación de tokens JWT
   - Endpoints protegidos

3. **Gestión de Espacios** (15 tests)
   - CRUD completo
   - Validación de ownership
   - Promoción automática a HOST
   - Múltiples imágenes

4. **Búsqueda** (3 tests)
   - Búsqueda sin autenticación (pública)
   - Filtros combinados (ubicación, precio, capacidad)

5. **Reservas** (9 tests)
   - Crear reservas
   - Validación de conflictos de fechas
   - Confirmar reservas (solo HOST)
   - Cancelar reservas

6. **Listado de Reservas** (8 tests)
   - Vista GUEST (mis reservas)
   - Vista HOST (reservas de mis espacios)
   - Diferentes estados (pending, confirmed, cancelled)

**Uso**:
```bash
./scripts/test-roles-usuarios-completo.sh
```

**Salida esperada**:
```
🧪 INICIANDO SUITE DE TESTS - SISTEMA COMPLETO
================================================

📋 Tests ejecutados:     45
✅ Tests exitosos:       45
❌ Tests fallidos:       0
📊 Tasa de éxito:        100,00%

✅ TODOS LOS TESTS PASARON CORRECTAMENTE
```

**Salida si hay errores**:
```
🧪 INICIANDO SUITE DE TESTS - SISTEMA COMPLETO
================================================

📋 Tests ejecutados:     45
✅ Tests exitosos:       43
❌ Tests fallidos:       2
📊 Tasa de éxito:        95,56%

❌ ALGUNOS TESTS FALLARON. Revisa los detalles arriba.

Tests fallidos:
- Test #24: Crear reserva con fechas en conflicto
- Test #31: Confirmar reserva sin ser HOST
```

**Prerequisitos**:
- Todos los servicios deben estar corriendo
- Bases de datos deben tener datos de prueba (ejecutar `insert-test-data.sh` si es necesario)

**Tiempo de ejecución**: ~2-3 minutos

---

## 🛠️ Comandos Útiles

### Ver logs en tiempo real

```bash
# Auth Service
tail -f /tmp/auth-service.log

# Catalog Service
tail -f /tmp/catalog-service.log

# Booking Service
tail -f /tmp/booking-service.log

# API Gateway
tail -f /tmp/api-gateway.log

# Todos a la vez (multiplex)
tail -f /tmp/*.log
```

### Verificar procesos Java corriendo

```bash
jps -l | grep -E "(eureka|gateway|auth|catalog|booking|search)"
```

### Verificar puertos en uso

```bash
lsof -i:8080  # API Gateway
lsof -i:8761  # Eureka
lsof -i:8084  # Auth
lsof -i:8085  # Catalog
lsof -i:8082  # Booking
lsof -i:8083  # Search
```

### Limpiar logs anteriores

```bash
rm -f /tmp/*.log
```

### Reinicio completo (limpio)

```bash
# 1. Detener todo
./scripts/stop-all.sh
docker-compose down

# 2. Limpiar logs
rm -f /tmp/*.log

# 3. Recompilar todo
./scripts/recompile-all.sh

# 4. Iniciar infraestructura
./scripts/start-infrastructure.sh

# 5. Iniciar servicios
./scripts/start-all-with-eureka.sh

# 6. Verificar
./scripts/verify-system.sh
```

---

## 🐛 Troubleshooting

### Problema: "Puerto ya en uso"

```bash
# Identificar qué proceso usa el puerto
lsof -i:8080

# Matar el proceso
kill -9 <PID>

# O usar el script stop-all
./scripts/stop-all.sh
```

### Problema: "Servicio no se registra en Eureka"

```bash
# 1. Verificar que Eureka esté corriendo
curl http://localhost:8761/eureka/apps

# 2. Ver logs del servicio
tail -100 /tmp/auth-service.log | grep -i eureka

# 3. Reiniciar el servicio problemático
# (detener con stop-all.sh y reiniciar solo ese servicio)
```

### Problema: "Base de datos no disponible"

```bash
# Verificar contenedores Docker
docker ps | grep postgres

# Ver logs de PostgreSQL
docker logs pg-auth
docker logs pg-catalog

# Reiniciar contenedores
docker-compose restart
```

### Problema: "Tests fallan"

```bash
# 1. Verificar que todos los servicios estén UP
./scripts/verify-system.sh

# 2. Ver logs de errores
tail -100 /tmp/auth-service.log
tail -100 /tmp/catalog-service.log

# 3. Reiniciar desde cero
./scripts/stop-all.sh
./scripts/start-infrastructure.sh
./scripts/start-all-with-eureka.sh
sleep 60  # Esperar que todo esté listo
./scripts/test-roles-usuarios-completo.sh
```

---

## 📚 Documentación Adicional

- [README Principal](../README.md) - Descripción general del proyecto
- [Documentación Backend](../docs/BACKEND_ARCHITECTURE.md) - Arquitectura completa
- [Guías Frontend](../docs/INDEX.md) - Integración con API REST
- [Docker Compose](../docker-compose.yml) - Configuración de contenedores

---

## 👥 Contribuir

Si encuentras algún problema con los scripts o quieres mejorarlos:

1. Abre un issue describiendo el problema
2. Propón mejoras en un Pull Request
3. Actualiza esta documentación si cambias algún script

---

**Última actualización**: Enero 2025  
**Mantenedor**: BalconazoApp Team
