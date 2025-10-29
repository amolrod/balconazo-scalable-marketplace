# ✅ SOLUCIÓN FINAL AL ERROR 403

## 🎯 EL PROBLEMA

El Auth Service sigue dando 403 porque aunque el código está corregido, el servicio no se está iniciando correctamente con los comandos automáticos.

## ✅ LA SOLUCIÓN (EJECUTA ESTO MANUALMENTE)

### Paso 1: Abre una nueva terminal

### Paso 2: Ejecuta estos comandos UNO POR UNO:

```bash
# 1. Ir a la carpeta del proyecto
cd /Users/angel/Desktop/BalconazoApp

# 2. Limpiar el puerto 8084
lsof -ti:8084 | xargs kill -9

# 3. Ir a la carpeta de Auth Service
cd auth-service

# 4. Iniciar el Auth Service (DÉJALO CORRIENDO)
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

**IMPORTANTE:** NO cierres esta terminal. Déjala abierta con el Auth Service corriendo.

### Paso 3: Abre OTRA terminal nueva y prueba el login:

```bash
curl -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**Deberías ver:**
```json
{
  "accessToken": "eyJhbGci...",
  "userId": "11111111-1111-1111-1111-111111111111",
  "role": "HOST"
}
```

---

## 🧪 LUEGO PRUEBA EN POSTMAN

Una vez que el curl funcione:

```
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "email": "host1@balconazo.com",
  "password": "password123"
}
```

Debería devolver **200 OK** con el token.

---

## 📝 QUÉ HICE

1. ✅ Corregí `SecurityConfig.java` añadiendo:
   - `.httpBasic(httpBasic -> httpBasic.disable())`
   - `.formLogin(formLogin -> formLogin.disable())`

2. ✅ Recompilé el Auth Service (BUILD SUCCESS)

3. ⚠️ El servicio no se inicia correctamente con scripts automáticos por un problema con las comillas en el shell

---

## 🔧 ALTERNATIVA: Usar el script

```bash
cd /Users/angel/Desktop/BalconazoApp
./run-auth.sh
```

Deja esta terminal abierta y prueba el login en otra terminal.

---

**El código está corregido. Solo necesitas iniciar el servicio manualmente siguiendo los pasos de arriba.** 🎯

