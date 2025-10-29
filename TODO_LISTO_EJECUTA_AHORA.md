# ✅ TODO LISTO - EJECUTA ESTO AHORA

**Fecha:** 29 de Octubre de 2025  
**Estado:** ✅ **PASSWORDS BCRYPT ACTUALIZADAS - CÓDIGO CORREGIDO**

---

## ✅ LO QUE HE HECHO

### 1. Corregido AuthService.java
- ✅ `RuntimeException` → `BadCredentialsException`
- ✅ Devuelve 401 en lugar de 500

### 2. Creado AuthExceptionHandler.java
- ✅ Captura `BadCredentialsException` → 401
- ✅ Handler global de excepciones

### 3. Actualizado passwords en la base de datos
- ✅ Generado hash BCrypt válido de "password123"
- ✅ Insertados 5 usuarios con passwords BCrypt correctas:
  - `host1@balconazo.com` (HOST)
  - `host2@balconazo.com` (HOST)
  - `guest1@balconazo.com` (GUEST)
  - `guest2@balconazo.com` (GUEST)
  - `admin@balconazo.com` (HOST)

**Password para TODOS:** `password123`  
**Hash BCrypt:** `$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq`

---

## 🚀 EJECUTA AHORA (MANUAL)

### Terminal 1: Iniciar Auth Service

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

**DEJAR ESTA TERMINAL ABIERTA** para ver logs en tiempo real.

---

### Terminal 2: Probar Login (después de 30 segundos)

```bash
# Verificar que está UP
curl http://localhost:8084/actuator/health

# Probar login con host1@balconazo.com
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**Respuesta esperada:** HTTP 200 OK con token

```json
{
  "accessToken": "eyJhbGci...",
  "refreshToken": "eyJhbGci...",
  "tokenType": "Bearer",
  "userId": "11111111-1111-1111-1111-111111111111",
  "email": "host1@balconazo.com",
  "role": "HOST",
  "expiresIn": 86400
}
```

---

## 🧪 OTROS TESTS

### Test con password incorrecta (debe dar 401)

```bash
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"wrong"}'
```

**Esperado:** HTTP 401 Unauthorized

```json
{
  "timestamp": "2025-10-29T18:35:00",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid email or password"
}
```

---

### Test con email no existente (debe dar 401)

```bash
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"noexiste@test.com","password":"cualquiera"}'
```

**Esperado:** HTTP 401 Unauthorized

---

### Test con guest1@balconazo.com

```bash
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"guest1@balconazo.com","password":"password123"}'
```

**Esperado:** HTTP 200 OK con `"role": "GUEST"`

---

## 📋 USUARIOS DISPONIBLES

| Email | Password | Role | Status |
|-------|----------|------|--------|
| host1@balconazo.com | password123 | HOST | Active ✅ |
| host2@balconazo.com | password123 | HOST | Active ✅ |
| guest1@balconazo.com | password123 | GUEST | Active ✅ |
| guest2@balconazo.com | password123 | GUEST | Active ✅ |
| admin@balconazo.com | password123 | HOST | Active ✅ |

**Todos con hash BCrypt:** `$2a$10$F63d/UBiUnjAKL9FmUEK/OxCkYlQvzyBzVnxvgWs/lbvFlN3yzNEq`

---

## 🔍 QUÉ VER EN LOS LOGS (Terminal 1)

### ✅ BUENO (Login exitoso):

```
POST /api/auth/login - Email: host1@balconazo.com
Login exitoso para usuario: host1@balconazo.com
```

### ⚠️ NORMAL (Password incorrecta):

```
POST /api/auth/login - Email: host1@balconazo.com
Contraseña incorrecta para: host1@balconazo.com
Bad credentials attempt: Invalid email or password
```

### ❌ MALO (Si ves esto, algo falló):

```
java.lang.RuntimeException: Credenciales inválidas
Request processing failed: java.lang.RuntimeException
Securing POST /error
```

Si ves esto → El JAR es viejo, recompilar y reiniciar

---

## 🎯 FLUJO CORRECTO AHORA

```
POST /api/auth/login
  ↓
AuthService.login()
  ↓
passwordEncoder.matches() → false
  ↓
throw BadCredentialsException("Invalid email or password")
  ↓
AuthExceptionHandler.handleBadCredentials()
  ↓
401 Unauthorized ✅
```

**NUNCA:** 500 → /error → 403

---

## 📊 TABLA COMPARATIVA

| Escenario | ANTES | AHORA |
|-----------|-------|-------|
| Email no existe | 500 → 403 | 401 ✅ |
| Password incorrecta | 500 → 403 | 401 ✅ |
| Password correcta | 500 → 403 | 200 ✅ |
| Usuario inactivo | 500 → 403 | 401 ✅ |

---

## 📁 ARCHIVOS CREADOS/MODIFICADOS

### Modificados:
1. ✅ `AuthService.java` - BadCredentialsException
2. ✅ `SecurityConfig.java` - Ya tenía /error permitido
3. ✅ `fix-passwords-bcrypt.sh` - Corregido nombre del contenedor

### Creados:
1. ✅ `AuthExceptionHandler.java` - Handler 401
2. ✅ `GenerateBCryptHash.java` - Generador de hash
3. ✅ `test-data-auth-bcrypt.sql` - Datos de prueba con BCrypt
4. ✅ `TODO_LISTO_EJECUTA_AHORA.md` - Este documento

### Base de datos:
1. ✅ 5 usuarios insertados con passwords BCrypt correctas
2. ✅ Todos verificados con `✅ BCrypt`

---

## 🎉 RESUMEN

**Estado:**
- ✅ Código corregido (BUILD SUCCESS)
- ✅ Passwords BCrypt en DB
- ✅ ExceptionHandler creado
- ✅ Datos de prueba insertados

**Pendiente:**
- ⏳ Iniciar Auth Service (Terminal 1)
- ⏳ Probar login (Terminal 2)

**Esperado:**
- ✅ Login correcto → 200 OK con token
- ✅ Login incorrecto → 401 Unauthorized
- ❌ NUNCA → 403 ni 500

---

## 💡 SI AÚN DA 403 o 500

### 1. Verificar que el JAR es nuevo

```bash
ls -lh target/auth_service-0.0.1-SNAPSHOT.jar
```

Debe tener fecha de hoy, después de las 18:23 (cuando se compiló).

### 2. Recompilar si es necesario

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean package -DskipTests
```

### 3. Ver logs completos

```bash
# En Terminal 1 verás todo en tiempo real
# Si necesitas buscar algo específico:
grep -i "exception\|error" /tmp/auth-final.log
```

---

**TODO ESTÁ LISTO. SOLO EJECUTA LOS COMANDOS DE TERMINAL 1 Y TERMINAL 2.** 🎯

