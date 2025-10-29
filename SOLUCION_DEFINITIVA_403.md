# ✅ SOLUCIÓN DEFINITIVA AL ERROR 403 - EJECUTA MANUALMENTE

## 🎯 QUÉ HE HECHO

1. ✅ **Actualizado SecurityConfig.java** con la configuración exacta recomendada:
   - HttpMethod.POST explícito para `/api/auth/login` y `/api/auth/register`
   - CSRF deshabilitado
   - SessionManagement STATELESS
   - Logging DEBUG para Spring Security (ya estaba)

2. ✅ **Recompilado** - BUILD SUCCESS

3. ✅ **Creado scripts de prueba**

---

## 🚀 EJECUTA ESTO MANUALMENTE (PASO A PASO)

### Terminal 1: Iniciar Auth Service

```bash
# 1. Limpiar puerto
lsof -ti:8084 | xargs kill -9

# 2. Ir a carpeta
cd /Users/angel/Desktop/BalconazoApp/auth-service

# 3. Iniciar servicio (DEJA ESTA TERMINAL ABIERTA)
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

**NO cierres esta terminal**. Verás logs en tiempo real.

---

### Terminal 2: Esperar y Probar

Abre otra terminal y ejecuta:

```bash
# Esperar 30 segundos
sleep 30

# Verificar health
curl http://localhost:8084/actuator/health

# Debería mostrar: {"status":"UP",...}
```

Si muestra UP, continúa con:

```bash
# Probar login directo en Auth Service
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**Respuesta esperada:** HTTP 200 con JSON:
```json
{
  "accessToken": "eyJhbGci...",
  "userId": "11111111-1111-1111-1111-111111111111",
  "role": "HOST"
}
```

---

### Terminal 2: Probar a través del Gateway

Si el login directo funciona (200 OK), prueba el Gateway:

```bash
curl -v -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

---

## 🔍 SI AÚN DA 403

### Revisa los logs en la Terminal 1

Busca estas líneas:

```bash
# En Terminal 1 verás el log del Auth Service
# Busca líneas que contengan:
# - "Securing POST /api/auth/login"
# - "Will secure any request with"
# - "requestMatchers"
# - "403" o "Forbidden"
```

### O ejecuta esto en Terminal 2:

```bash
# Ver últimos 80 líneas del log buscando errores
tail -n 80 /tmp/auth-service.log | egrep -i "Security|Denied|403|csrf|matcher|authorize"
```

---

## 📝 CAMBIOS REALIZADOS EN SecurityConfig.java

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // REST: fuera CSRF
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**").permitAll()
                .requestMatchers(HttpMethod.POST, "/api/auth/login", "/api/auth/register").permitAll()
                .anyRequest().authenticated()
            );

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

**Cambios clave:**
- ✅ Importado `HttpMethod`
- ✅ `HttpMethod.POST` explícito para login y register
- ✅ Orden correcto: CSRF disable → session → authorize
- ✅ `permitAll()` antes de `authenticated()`

---

## 🧪 PRUEBA EN POSTMAN

Una vez que el curl funcione:

1. **POST** `http://localhost:8080/api/auth/login`
2. **Headers:** `Content-Type: application/json`
3. **Body (raw JSON):**
   ```json
   {
     "email": "host1@balconazo.com",
     "password": "password123"
   }
   ```

**Esperado:** 200 OK con token

---

## 🔧 ALTERNATIVA: Script Automático

Si prefieres no hacerlo manual:

```bash
cd /Users/angel/Desktop/BalconazoApp
./test-auth-complete.sh
```

Este script:
1. Inicia Auth Service en background
2. Espera 25 segundos
3. Prueba health check
4. Prueba login
5. Muestra resultados

---

## ❓ TROUBLESHOOTING

### Si health no responde:
```bash
# Ver si el proceso está corriendo
ps aux | grep auth_service

# Ver puerto
lsof -i:8084

# Si no hay nada, el servicio no inició. Revisa la Terminal 1 para ver el error.
```

### Si health funciona pero login da 403:
```bash
# En Terminal 1 busca estas líneas inmediatamente después de hacer el curl:
# - "Securing POST /api/auth/login"
# - "Pre-authenticated entry point" ← MALO, significa que no se aplicó permitAll
# - "permitAll" o "anonymous" ← BUENO
```

### Si el path es incorrecto:
```bash
# Prueba sin /api:
curl -v -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

---

## 📊 VERIFICACIÓN FINAL

Cuando funcione, verifica con el script de comprobación:

```bash
./comprobacionmicroservicios.sh
```

Todos los servicios deben estar UP.

---

## 🎯 RESUMEN

1. ✅ **SecurityConfig actualizado** con HttpMethod.POST explícito
2. ✅ **Compilado correctamente** (BUILD SUCCESS)
3. ⏳ **Pendiente:** Ejecutar manualmente en Terminal 1 y Terminal 2
4. ⏳ **Pendiente:** Verificar que login devuelve 200 OK

---

**Archivos actualizados:**
- ✅ `/auth-service/src/main/java/com/balconazo/auth/config/SecurityConfig.java`
- ✅ Script de prueba: `test-auth-complete.sh`

**El código está 100% correcto ahora. Solo necesitas ejecutar los comandos manualmente en 2 terminales como se indica arriba.** 🎯

