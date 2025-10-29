# 🔍 VERIFICACIÓN FINAL DEL ERROR 403 - INSIGHT CRÍTICO

**Fecha:** 29 de Octubre de 2025

---

## 🎯 INSIGHT CLAVE

Tienes razón: **El 403 puede estar OCULTANDO un 404**.

Cuando haces `POST /api/auth/login` y:
1. El endpoint NO existe (path incorrecto)
2. O el controller no se registró (problema de escaneo)
3. Spring redirige a `/error`
4. Si `/error` NO está en `permitAll()` → **403 en lugar de 404**

**Resultado:** Ves "Securing POST /error" en logs y piensas que es problema de seguridad, cuando en realidad **el endpoint no existe**.

---

## ✅ CAMBIOS APLICADOS

He aplicado los cambios que sugeriste:

### 1. Añadido mappings al Actuator

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,mappings  # ← AÑADIDO mappings
```

### 2. Permitido /error en SecurityConfig

```java
@Bean
public SecurityFilterChain securityFilterChain(HttpSecurity http) {
    http
        .csrf(csrf -> csrf.disable())
        .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/actuator/**", "/error").permitAll()  // ← AÑADIDO /error
            .requestMatchers(HttpMethod.POST, "/api/auth/login", "/api/auth/register").permitAll()
            .anyRequest().authenticated()
        );
    return http.build();
}
```

### 3. Verificado escaneo de paquetes

```java
// AuthServiceApplication.java
package com.balconazo.auth;  // ✅ Raíz correcta

@SpringBootApplication  // ✅ Escanea com.balconazo.auth y subpaquetes
@EnableDiscoveryClient
public class AuthServiceApplication {
    // ...
}
```

```java
// AuthController.java
package com.balconazo.auth.controller;  // ✅ Dentro del escaneo

@RestController
@RequestMapping("/api/auth")  // ✅ Path correcto
public class AuthController {
    
    @PostMapping("/login")  // ✅ → /api/auth/login
    // ...
}
```

**Conclusión:** ✅ El escaneo es correcto, el controller DEBE registrarse.

---

## 🚀 EJECUTA ESTOS COMANDOS MANUALMENTE

### Terminal 1: Iniciar Auth Service

```bash
# 1. Limpiar puerto
lsof -ti:8084 | xargs kill -9

# 2. Ir a carpeta
cd /Users/angel/Desktop/BalconazoApp/auth-service

# 3. Iniciar servicio (DEJAR TERMINAL ABIERTA)
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

### Terminal 2: Verificar mappings (después de 30 segundos)

```bash
# Verificar que está UP
curl http://localhost:8084/actuator/health

# CRÍTICO: Ver qué endpoints están registrados
curl -s http://localhost:8084/actuator/mappings | grep -i "auth/login" -B 2 -A 2
```

**Buscar en la salida:**

Si aparece:
```json
{
  "handler": "...",
  "predicate": "{POST [/api/auth/login]}",
  ...
}
```
→ ✅ **El endpoint SÍ está registrado en `/api/auth/login`**

Si aparece:
```json
{
  "handler": "...",
  "predicate": "{POST [/auth/login]}",  // ← Sin /api
  ...
}
```
→ ⚠️ **El endpoint está en `/auth/login` (sin /api)**

Si NO aparece nada:
→ ❌ **El controller NO se está registrando**

---

### Terminal 2: Probar AMBOS paths

```bash
# Test 1: Con /api
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'

# Test 2: Sin /api
curl -v -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**Interpretar resultados:**

| Test 1 (/api/auth/login) | Test 2 (/auth/login) | Diagnóstico |
|--------------------------|----------------------|-------------|
| 200 OK | 404 Not Found | ✅ **TODO CORRECTO** - Path es `/api/auth/login` |
| 404 Not Found | 200 OK | ⚠️ **PATH INCORRECTO** - Controller usa `/auth` no `/api/auth` |
| 403 Forbidden | 403 Forbidden | ❌ **SecurityConfig no aplicado o JAR viejo** |
| 404 Not Found | 404 Not Found | ❌ **Controller NO registrado** |

---

## 🔍 TROUBLESHOOTING SEGÚN RESULTADO

### Caso A: Ambos dan 404

**Problema:** Controller no se está registrando.

**Verificar:**
```bash
# Ver si el controller está en el JAR
jar -tf target/auth_service-0.0.1-SNAPSHOT.jar | grep AuthController
```

Debe mostrar:
```
BOOT-INF/classes/com/balconazo/auth/controller/AuthController.class
```

**Solución:**
1. Verificar que `AuthController.java` existe y tiene `@RestController`
2. Recompilar: `mvn clean package -DskipTests`
3. Reiniciar

---

### Caso B: /auth/login da 200, pero /api/auth/login da 404

**Problema:** El controller usa `@RequestMapping("/auth")` no `@RequestMapping("/api/auth")`.

**Solución:**
1. Editar `AuthController.java`: cambiar `@RequestMapping("/auth")` a `@RequestMapping("/api/auth")`
2. Recompilar
3. Ajustar Gateway routes si es necesario

---

### Caso C: Ambos dan 403

**Problema:** SecurityConfig no se aplicó o estás corriendo JAR viejo.

**Solución:**
1. Verificar fecha del JAR: `ls -lh target/auth_service-0.0.1-SNAPSHOT.jar`
2. Si es antiguo: `mvn clean package -DskipTests`
3. Matar proceso: `lsof -ti:8084 | xargs kill -9`
4. Reiniciar con JAR NUEVO

**Ver logs en Terminal 1:**
Buscar estas líneas inmediatamente después de hacer curl:

Si ves:
```
Securing POST /error
Pre-authenticated entry point called. Rejecting access
```
→ El endpoint NO existe, cayó en error handler

Si ves:
```
POST /api/auth/login - Email: host1@balconazo.com
```
→ El endpoint SÍ llegó al controller

---

## 📊 DIAGNÓSTICO RÁPIDO (2 MINUTOS)

```bash
# 1. ¿Está corriendo?
lsof -i:8084

# 2. ¿Qué endpoints tiene?
curl -s http://localhost:8084/actuator/mappings | grep -i "login"

# 3. ¿Responde health?
curl http://localhost:8084/actuator/health

# 4. Probar con /api
curl -I -X POST http://localhost:8084/api/auth/login

# 5. Probar sin /api
curl -I -X POST http://localhost:8084/auth/login

# 6. Ver logs
tail -f /tmp/auth-service.log  # En Terminal 1
```

---

## ✅ ARCHIVOS MODIFICADOS

1. **`application.yml`** - Añadido `mappings` al actuator
2. **`SecurityConfig.java`** - Añadido `/error` a `permitAll()`

**Estado:** ✅ **Compilado con BUILD SUCCESS**

---

## 🎯 PRÓXIMOS PASOS

1. **Ejecutar** comandos de Terminal 1 (iniciar Auth Service)
2. **Esperar** 30 segundos
3. **Ejecutar** comandos de Terminal 2 (verificar mappings)
4. **Analizar** resultado según la tabla
5. **Aplicar** solución correspondiente

---

## 💡 POR QUÉ ESTE CAMBIO ES CRÍTICO

**ANTES:**
```
POST /api/auth/login (no existe)
  ↓
Spring → /error (handler de errores)
  ↓
SecurityConfig → /error NO está en permitAll()
  ↓
403 Forbidden ← ENGAÑOSO
```

**AHORA:**
```
POST /api/auth/login (no existe)
  ↓
Spring → /error
  ↓
SecurityConfig → /error SÍ está en permitAll()
  ↓
404 Not Found ← VERDAD
```

---

## 🎉 CONCLUSIÓN

Con estos cambios:
- ✅ Si el endpoint NO existe → verás **404** (no 403)
- ✅ Puedes verificar EXACTAMENTE qué paths están registrados
- ✅ Sabrás si el problema es SecurityConfig o path incorrecto

**Ahora ejecuta los comandos de Terminal 1 y Terminal 2 para diagnosticar el problema real.** 🎯

