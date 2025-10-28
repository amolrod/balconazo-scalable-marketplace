# 🚀 GUÍA RÁPIDA DE INICIO - SISTEMA BALCONAZO

**Fecha:** 28 de octubre de 2025

---

## ✅ SCRIPTS DISPONIBLES

Todos los scripts están en `/Users/angel/Desktop/BalconazoApp/`

| Script | Descripción |
|--------|-------------|
| `check-system.sh` | Verifica qué servicios están corriendo |
| `start-eureka.sh` | Inicia solo Eureka Server |
| `start-mysql-auth.sh` | Inicia MySQL para Auth Service |
| `recompile-all.sh` | Recompila Catalog, Booking y Search |
| `start-all-with-eureka.sh` | **INICIA TODO EL SISTEMA** |

---

## 🎯 OPCIÓN 1: INICIO COMPLETO AUTOMÁTICO

```bash
cd /Users/angel/Desktop/BalconazoApp

# 1. Verificar estado actual
./check-system.sh

# 2. Iniciar todo el sistema (Eureka + Auth + 3 microservicios)
./start-all-with-eureka.sh

# Esperar 2-3 minutos y verificar
./check-system.sh
```

---

## 🎯 OPCIÓN 2: INICIO PASO A PASO (Recomendado para primera vez)

### PASO 1: Compilar Auth Service (solo primera vez)

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean install -DskipTests
```

**Espera:** ~2 minutos  
**Resultado esperado:** `BUILD SUCCESS`

---

### PASO 2: Iniciar Eureka Server

```bash
cd /Users/angel/Desktop/BalconazoApp
./start-eureka.sh
```

**Espera:** 25 segundos  
**Verificar:** 
- http://localhost:8761 (Dashboard de Eureka)
- Deberías ver "Instances currently registered with Eureka: 0"

---

### PASO 3: Iniciar MySQL para Auth Service

```bash
./start-mysql-auth.sh
```

**Espera:** 30 segundos  
**Resultado esperado:** 
```
✅ MySQL corriendo en puerto 3307
✅ Base de datos auth_db lista
```

---

### PASO 4: Iniciar Auth Service

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn spring-boot:run > /tmp/auth-service.log 2>&1 &
echo $! > /tmp/auth-pid.txt
```

**Espera:** 30-40 segundos  
**Verificar:**
```bash
tail -f /tmp/auth-service.log
# Ctrl+C para salir

# Cuando veas "Started AuthServiceApplication..."
curl http://localhost:8084/actuator/health
```

**Resultado esperado:**
```json
{"status":"UP"}
```

---

### PASO 5: Iniciar Catalog Service

```bash
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run > /tmp/catalog-service.log 2>&1 &
echo $! > /tmp/catalog-pid.txt
```

**Espera:** 25-30 segundos  
**Verificar:**
```bash
curl http://localhost:8085/actuator/health
```

---

### PASO 6: Iniciar Booking Service

```bash
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
mvn spring-boot:run > /tmp/booking-service.log 2>&1 &
echo $! > /tmp/booking-pid.txt
```

**Espera:** 25-30 segundos  
**Verificar:**
```bash
curl http://localhost:8082/actuator/health
```

---

### PASO 7: Iniciar Search Service

```bash
cd /Users/angel/Desktop/BalconazoApp/search_microservice
mvn spring-boot:run > /tmp/search-service.log 2>&1 &
echo $! > /tmp/search-pid.txt
```

**Espera:** 25-30 segundos  
**Verificar:**
```bash
curl http://localhost:8083/actuator/health
```

---

### PASO 8: Verificar que todo está registrado en Eureka

```bash
# Abrir dashboard de Eureka
open http://localhost:8761
```

**Deberías ver 4 servicios:**
- AUTH-SERVICE
- CATALOG-SERVICE
- BOOKING-SERVICE
- SEARCH-SERVICE

---

## 🧪 PRUEBAS DEL SISTEMA

### 1. Registrar un usuario en Auth Service

```bash
curl -X POST http://localhost:8084/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "password123",
    "role": "HOST"
  }' | python3 -m json.tool
```

**Resultado esperado:**
```json
{
  "id": "uuid-generado",
  "email": "test@balconazo.com",
  "role": "HOST",
  "active": true,
  "createdAt": "2025-10-28T..."
}
```

---

### 2. Login y obtener JWT

```bash
curl -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "password123"
  }' | python3 -m json.tool
```

**Resultado esperado:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "userId": "uuid",
  "email": "test@balconazo.com",
  "role": "HOST"
}
```

---

### 3. Guardar el JWT en una variable

```bash
JWT=$(curl -s -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "password123"
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")

echo $JWT
```

---

### 4. Crear un espacio en Catalog (requiere userId)

```bash
# Primero, obtener el userId del login
USER_ID=$(curl -s -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "password123"
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['userId'])")

# Crear espacio
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d "{
    \"ownerId\": \"$USER_ID\",
    \"title\": \"Terraza con vistas\",
    \"description\": \"Hermosa terraza en el centro\",
    \"address\": \"Calle Mayor 1, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 10,
    \"areaSqm\": 50.0,
    \"basePriceCents\": 10000,
    \"amenities\": [\"wifi\", \"music_system\"],
    \"rules\": {\"no_smoking\": true}
  }" | python3 -m json.tool
```

---

## 🛑 DETENER TODO EL SISTEMA

### Opción 1: Matar por PIDs guardados

```bash
kill $(cat /tmp/eureka-pid.txt /tmp/auth-pid.txt /tmp/catalog-pid.txt /tmp/booking-pid.txt /tmp/search-pid.txt 2>/dev/null)
```

### Opción 2: Matar por puerto

```bash
lsof -ti:8761 | xargs kill -9  # Eureka
lsof -ti:8084 | xargs kill -9  # Auth
lsof -ti:8085 | xargs kill -9  # Catalog
lsof -ti:8082 | xargs kill -9  # Booking
lsof -ti:8083 | xargs kill -9  # Search
```

### Opción 3: Script de detención

```bash
#!/bin/bash
# stop-all.sh
lsof -ti:8761,8084,8085,8082,8083 | xargs kill -9 2>/dev/null
echo "✅ Todos los microservicios detenidos"
```

---

## 📊 VERIFICAR ESTADO DEL SISTEMA

```bash
./check-system.sh
```

---

## 📝 VER LOGS EN TIEMPO REAL

```bash
# Eureka
tail -f /tmp/eureka-server.log

# Auth Service
tail -f /tmp/auth-service.log

# Catalog Service
tail -f /tmp/catalog-service.log

# Booking Service
tail -f /tmp/booking-service.log

# Search Service
tail -f /tmp/search-service.log
```

---

## ⚠️ SOLUCIÓN DE PROBLEMAS COMUNES

### Error: "Port already in use"
```bash
# Liberar puerto específico
lsof -ti:8084 | xargs kill -9

# O ver qué está usando el puerto
lsof -i:8084
```

### Error: "MySQL connection refused"
```bash
# Verificar que MySQL esté corriendo
docker ps | grep mysql-auth

# Si no está, iniciar
./start-mysql-auth.sh
```

### Error: "Unable to connect to Eureka"
```bash
# Verificar que Eureka esté corriendo
curl http://localhost:8761/actuator/health

# Si no responde, iniciar
./start-eureka.sh
```

### Auth Service no compila
```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service

# Ver errores específicos
mvn clean compile

# Si hay errores de dependencias
mvn dependency:purge-local-repository
mvn clean install -DskipTests
```

---

## 🎯 ORDEN RECOMENDADO DE INICIO

1. ✅ Infraestructura Docker (PostgreSQL, Kafka, Redis) - **debe estar corriendo**
2. ✅ Eureka Server (puerto 8761)
3. ✅ MySQL Auth (puerto 3307)
4. ✅ Auth Service (puerto 8084)
5. ✅ Catalog Service (puerto 8085)
6. ✅ Booking Service (puerto 8082)
7. ✅ Search Service (puerto 8083)

**Tiempo total de inicio:** ~3-4 minutos

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [ ] Todos los contenedores Docker corriendo
- [ ] Eureka Dashboard accesible (http://localhost:8761)
- [ ] 4 servicios registrados en Eureka
- [ ] Auth Service responde a `/actuator/health`
- [ ] Puedo registrar un usuario
- [ ] Puedo hacer login y obtener JWT
- [ ] Catalog Service responde
- [ ] Booking Service responde
- [ ] Search Service responde

---

**Si todo está ✅, el sistema está listo para usar!**

**Próximo paso:** Crear API Gateway (puerto 8080) para unificar el acceso a todos los servicios.

