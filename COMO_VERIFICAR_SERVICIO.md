# ✅ CÓMO VERIFICAR QUE CATALOG-SERVICE FUNCIONA

**Guía completa de verificación y pruebas**

---

## 🚀 MÉTODO 1: Health Check (Lo Más Rápido)

### Desde Terminal (sin navegador)

```bash
# Health check básico
curl http://localhost:8085/actuator/health

# Debería responder:
# {"status":"UP","components":{"db":{"status":"UP"},...}}
```

✅ Si ves `"status":"UP"` → **El servicio está funcionando**

### Desde Navegador

Abre en tu navegador: **http://localhost:8085/actuator/health**

Verás algo como:
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

---

## 🧪 MÉTODO 2: Probar los Endpoints (Recomendado)

### 2.1 Crear un Usuario

```bash
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@balconazo.com",
    "password": "password123",
    "role": "host"
  }'
```

**Respuesta esperada:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "test@balconazo.com",
  "role": "host",
  "status": "ACTIVE",
  "trustScore": 0,
  "createdAt": "2025-10-27T17:00:00Z"
}
```

✅ **Si recibes un JSON con el usuario creado** → Funciona perfectamente

❌ Si sale error → Revisar logs de Spring Boot

### 2.2 Listar Usuarios

```bash
curl http://localhost:8085/api/catalog/users
```

**Respuesta esperada:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@balconazo.com",
    "role": "host",
    "status": "ACTIVE",
    "trustScore": 0,
    "createdAt": "2025-10-27T17:00:00Z"
  }
]
```

### 2.3 Crear un Espacio

Primero copia el `id` del usuario que creaste arriba, luego:

```bash
curl -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "PEGA-AQUI-EL-ID-DEL-USUARIO",
    "title": "Terraza con vistas",
    "description": "Bonita terraza de 30m²",
    "address": "Calle Mayor 1, Madrid",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 15,
    "areaSqm": 30.0,
    "basePriceCents": 10000,
    "amenities": ["wifi", "barbecue"],
    "rules": {"no_smoking": true}
  }'
```

**Respuesta esperada:**
```json
{
  "id": "660f9500-f39c-52e5-b827-557766551111",
  "ownerId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Terraza con vistas",
  "description": "Bonita terraza de 30m²",
  "address": "Calle Mayor 1, Madrid",
  "lat": 40.4168,
  "lon": -3.7038,
  "capacity": 15,
  "areaSqm": 30.0,
  "basePriceCents": 10000,
  "amenities": ["wifi", "barbecue"],
  "status": "ACTIVE",
  "createdAt": "2025-10-27T17:05:00Z"
}
```

### 2.4 Listar Espacios

```bash
curl http://localhost:8085/api/catalog/spaces
```

---

## 🌐 MÉTODO 3: Usando el Navegador (Visual)

### Ver Health Check
Abre: **http://localhost:8085/actuator/health**

### Ver Info del Servicio
Abre: **http://localhost:8085/actuator/info**

### Ver Métricas
Abre: **http://localhost:8085/actuator/metrics**

### Usar Swagger UI (si está configurado)
Abre: **http://localhost:8085/swagger-ui.html**

---

## 🔬 MÉTODO 4: Verificar en PostgreSQL

```bash
# Conectarse a PostgreSQL
docker exec -it balconazo-pg-catalog psql -U postgres -d catalog_db

# Dentro de psql:
\dt catalog.*                    # Ver tablas
SELECT * FROM catalog.users;     # Ver usuarios creados
SELECT * FROM catalog.spaces;    # Ver espacios creados
\q                               # Salir
```

---

## 📊 MÉTODO 5: Ver Logs de Spring Boot

### Ver logs en tiempo real

```bash
# Si arrancaste con mvn spring-boot:run
# Los logs aparecen directamente en esa terminal
```

**Busca líneas como:**
```
✅ Started CatalogMicroserviceApplication in 3.XXX seconds
✅ Tomcat started on port 8085
✅ HikariPool-1 - Start completed
```

### Si hay errores, verás:
```
❌ Error creating bean...
❌ Failed to initialize JPA EntityManagerFactory...
❌ Unable to connect to...
```

---

## 🎯 MÉTODO 6: Verificación Completa (Script Todo-en-Uno)

Guarda este script como `test-catalog-service.sh`:

```bash
#!/bin/bash

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     🧪 VERIFICACIÓN COMPLETA DE CATALOG-SERVICE         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# 1. Health Check
echo "1️⃣  Health Check..."
HEALTH=$(curl -s http://localhost:8085/actuator/health | grep -c "UP")
if [ $HEALTH -gt 0 ]; then
    echo "   ✅ Servicio UP"
else
    echo "   ❌ Servicio DOWN"
    exit 1
fi
echo ""

# 2. Crear usuario de prueba
echo "2️⃣  Creando usuario de prueba..."
USER_RESPONSE=$(curl -s -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test-'$(date +%s)'@balconazo.com",
    "password": "password123",
    "role": "host"
  }')

USER_ID=$(echo $USER_RESPONSE | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$USER_ID" ]; then
    echo "   ✅ Usuario creado: $USER_ID"
else
    echo "   ❌ Error al crear usuario"
    echo "   Respuesta: $USER_RESPONSE"
    exit 1
fi
echo ""

# 3. Crear espacio
echo "3️⃣  Creando espacio de prueba..."
SPACE_RESPONSE=$(curl -s -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d '{
    "ownerId": "'$USER_ID'",
    "title": "Espacio Test",
    "description": "Espacio de prueba automática",
    "address": "Calle Test 123",
    "lat": 40.4168,
    "lon": -3.7038,
    "capacity": 10,
    "areaSqm": 20.0,
    "basePriceCents": 5000,
    "amenities": ["wifi"],
    "rules": {"no_smoking": true}
  }')

SPACE_ID=$(echo $SPACE_RESPONSE | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$SPACE_ID" ]; then
    echo "   ✅ Espacio creado: $SPACE_ID"
else
    echo "   ❌ Error al crear espacio"
    echo "   Respuesta: $SPACE_RESPONSE"
    exit 1
fi
echo ""

# 4. Listar espacios
echo "4️⃣  Listando espacios..."
SPACES_COUNT=$(curl -s http://localhost:8085/api/catalog/spaces | grep -c "id")
echo "   ✅ Total espacios encontrados: $SPACES_COUNT"
echo ""

# 5. Verificar PostgreSQL
echo "5️⃣  Verificando PostgreSQL..."
DB_COUNT=$(docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
  -t -c "SELECT COUNT(*) FROM catalog.spaces;" 2>/dev/null | tr -d ' ')
echo "   ✅ Espacios en DB: $DB_COUNT"
echo ""

echo "╔══════════════════════════════════════════════════════════╗"
echo "║              ✅ TODAS LAS PRUEBAS PASARON               ║"
echo "╚══════════════════════════════════════════════════════════╝"
```

**Ejecutar:**
```bash
chmod +x test-catalog-service.sh
./test-catalog-service.sh
```

---

## 🛠️ HERRAMIENTAS ÚTILES

### Postman (GUI para APIs)
1. Descarga Postman: https://www.postman.com/downloads/
2. Importa la colección de endpoints (puedo crear una)
3. Prueba todos los endpoints visualmente

### Insomnia (Alternativa a Postman)
Similar a Postman pero más ligero

### HTTPie (Terminal amigable)
```bash
# Instalar
brew install httpie

# Usar (más bonito que curl)
http POST localhost:8085/api/catalog/users email=test@test.com password=pass123 role=host
```

---

## 📋 CHECKLIST DE VERIFICACIÓN

- [ ] ✅ Health check responde con status UP
- [ ] ✅ Puedo crear un usuario
- [ ] ✅ Puedo listar usuarios
- [ ] ✅ Puedo crear un espacio
- [ ] ✅ Puedo listar espacios
- [ ] ✅ Los datos se guardan en PostgreSQL
- [ ] ✅ No hay errores en los logs de Spring Boot
- [ ] ✅ No hay errores en logs de PostgreSQL

**Si todos tienen ✅ → El servicio funciona PERFECTAMENTE** 🎉

---

## ❌ TROUBLESHOOTING

### "Connection refused" en curl
```bash
# Verificar que el servicio está corriendo
curl http://localhost:8085/actuator/health

# Si falla:
# 1. Ver si Spring Boot está corriendo
ps aux | grep spring-boot

# 2. Ver logs del servicio
# (en la terminal donde ejecutaste mvn spring-boot:run)
```

### "404 Not Found"
```bash
# Verifica la URL exacta
curl -v http://localhost:8085/actuator/health

# Asegúrate del puerto correcto (8085)
```

### Usuario no se crea
```bash
# Ver logs de Spring Boot
# Buscar líneas con ERROR o WARN

# Verificar PostgreSQL
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c "SELECT * FROM catalog.users;"
```

---

## 🎥 DEMO VISUAL PASO A PASO

### Opción 1: Terminal + curl (Rápido)
```bash
# 1. Health check
curl http://localhost:8085/actuator/health

# 2. Crear usuario
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@test.com","password":"pass","role":"host"}'

# 3. Listar usuarios
curl http://localhost:8085/api/catalog/users
```

### Opción 2: Navegador (Visual)
1. Abre **http://localhost:8085/actuator/health**
2. Deberías ver JSON con `"status":"UP"`
3. Instala una extensión de JSON viewer para Chrome/Firefox para verlo bonito

### Opción 3: Postman/Insomnia (Profesional)
1. Crea una colección
2. Agrega requests para cada endpoint
3. Prueba todo con clicks

---

## 📊 RESUMEN

### ¿Funciona el servicio?
```bash
curl http://localhost:8085/actuator/health
```
**Si responde con `"status":"UP"` → SÍ funciona** ✅

### ¿Funciona la base de datos?
```bash
curl -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"pass","role":"host"}'
```
**Si responde con un JSON del usuario → SÍ funciona** ✅

### ¿Puedo verlo visualmente?
**Sí**, abre en navegador: **http://localhost:8085/actuator/health**

---

**Última actualización:** 27 de octubre de 2025  
**Para más ayuda:** Ver `TESTING.md` o `QUICKSTART.md`

