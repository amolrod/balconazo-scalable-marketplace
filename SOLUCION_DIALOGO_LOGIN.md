# 🔓 SOLUCIÓN: Diálogo de Autenticación HTTP Basic

**Problema:** Al acceder a `http://localhost:8080/` aparece un diálogo de "Iniciar sesión" pidiendo usuario y contraseña.

**Causa:** Spring Security por defecto estaba requiriendo autenticación para TODAS las rutas, incluyendo la raíz `/`.

---

## ✅ CORRECCIONES APLICADAS

### 1. SecurityConfig.java - Permitir acceso a raíz

**Cambio realizado:**
```java
.authorizeExchange(exchanges -> exchanges
    // Rutas públicas (sin autenticación)
    .pathMatchers("/").permitAll()           // ✅ NUEVO - Permitir raíz
    .pathMatchers("/api/auth/**").permitAll()
    .pathMatchers("/api/search/**").permitAll()
    .pathMatchers("/actuator/**").permitAll()
    .pathMatchers("/fallback/**").permitAll()
    
    // Rutas protegidas (requieren JWT)
    .pathMatchers("/api/catalog/**").authenticated()
    .pathMatchers("/api/booking/**").authenticated()
    
    // Cualquier otra ruta API requiere autenticación
    .pathMatchers("/api/**").authenticated()
    
    // Otras rutas son públicas
    .anyExchange().permitAll()              // ✅ CAMBIADO de .authenticated()
)
```

### 2. WelcomeController.java - Endpoint de Bienvenida

**Nuevo archivo creado:**
```java
@RestController
public class WelcomeController {
    
    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> welcome() {
        return ResponseEntity.ok(Map.of(
            "service", "Balconazo API Gateway",
            "version", "1.0.0",
            "status", "UP",
            "endpoints", Map.of(
                "health", "/actuator/health",
                "auth", "POST /api/auth/login",
                "catalog", "GET /api/catalog/spaces (requiere JWT)",
                "search", "GET /api/search/spaces?lat=40&lon=-3&radius=10"
            )
        ));
    }
}
```

---

## 🚀 CÓMO REINICIAR EL API GATEWAY

### Opción 1: Con script (recomendado)
```bash
# Detener gateway actual
lsof -ti:8080 | xargs kill -9 2>/dev/null

# Iniciar con script
cd /Users/angel/Desktop/BalconazoApp
./start-gateway.sh
```

### Opción 2: Manual
```bash
# Detener gateway actual
lsof -ti:8080 | xargs kill -9 2>/dev/null

# Compilar (si no está compilado)
cd api-gateway
mvn clean package -DskipTests

# Iniciar
java -jar target/api-gateway-1.0.0.jar
```

### Opción 3: Con Maven (para desarrollo)
```bash
cd /Users/angel/Desktop/BalconazoApp/api-gateway
mvn spring-boot:run
```

---

## 🧪 VERIFICAR QUE FUNCIONA

### 1. Esperar 20-30 segundos después de iniciar

### 2. Verificar health check
```bash
curl http://localhost:8080/actuator/health
```

**Respuesta esperada:**
```json
{
  "status": "UP",
  "components": {
    "eureka": {"status": "UP"},
    "redis": {"status": "UP"}
  }
}
```

### 3. Acceder a la raíz (ya NO pedirá usuario/contraseña)
```bash
curl http://localhost:8080/
```

**Respuesta esperada:**
```json
{
  "service": "Balconazo API Gateway",
  "version": "1.0.0",
  "status": "UP",
  "endpoints": { ... }
}
```

### 4. Abrir en navegador
```
http://localhost:8080/
```

**Ahora debería mostrar JSON en lugar del diálogo de login.**

---

## 🎯 RUTAS DISPONIBLES

### ✅ Públicas (sin autenticación)
| Ruta | Método | Descripción |
|------|--------|-------------|
| `/` | GET | Página de bienvenida |
| `/actuator/health` | GET | Health check |
| `/api/auth/register` | POST | Registrar usuario |
| `/api/auth/login` | POST | Iniciar sesión |
| `/api/search/spaces` | GET | Buscar espacios |

### 🔒 Protegidas (requieren JWT)
| Ruta | Método | Descripción |
|------|--------|-------------|
| `/api/catalog/spaces` | GET | Listar espacios |
| `/api/catalog/users` | GET | Listar usuarios |
| `/api/booking/bookings` | GET | Listar reservas |
| `/api/booking/reviews` | GET | Listar reviews |

---

## 📝 EJEMPLO DE USO

### 1. Acceder a la raíz (público)
```bash
curl http://localhost:8080/
```

### 2. Buscar espacios (público)
```bash
curl "http://localhost:8080/api/search/spaces?lat=40.4168&lon=-3.7038&radius=10"
```

### 3. Registrar usuario
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "angel@balconazo.com",
    "password": "miPassword123",
    "role": "HOST"
  }'
```

### 4. Login y obtener JWT
```bash
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "angel@balconazo.com",
    "password": "miPassword123"
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

### 5. Usar JWT en rutas protegidas
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/catalog/spaces
```

---

## 🔍 TROUBLESHOOTING

### Si sigue apareciendo el diálogo de login:

1. **Verificar que el gateway se reinició correctamente:**
   ```bash
   lsof -i:8080
   # Debe mostrar el proceso de java con api-gateway
   ```

2. **Verificar logs:**
   ```bash
   tail -f logs/api-gateway.log
   # o
   tail -f /tmp/api-gateway.log
   ```

3. **Limpiar caché del navegador:**
   - Chrome/Firefox: Ctrl+Shift+Del → Borrar caché
   - O usar modo incógnito

4. **Verificar que el JAR esté actualizado:**
   ```bash
   ls -lh api-gateway/target/api-gateway-1.0.0.jar
   # Debe tener fecha/hora reciente (después de la compilación)
   ```

---

## ✅ SOLUCIÓN APLICADA

✅ SecurityConfig modificado para permitir acceso público a `/`  
✅ WelcomeController creado con endpoint de bienvenida  
✅ Compilación exitosa (BUILD SUCCESS)  
✅ Listo para reiniciar el gateway  

**Después de reiniciar, ya NO aparecerá el diálogo de autenticación HTTP Basic.**

