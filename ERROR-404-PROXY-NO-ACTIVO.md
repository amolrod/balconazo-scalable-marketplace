# 🚨 ERROR 404 SOLUCIONADO - PROXY NO ESTABA ACTIVO

**Fecha**: 5 de Noviembre de 2025  
**Hora**: 19:20  
**Problema**: Frontend NO usaba el proxy → todas las peticiones dan 404

---

## 🐛 **PROBLEMA IDENTIFICADO**

### **Errores en consola**:
```javascript
❌ Error cargando espacios: status: 200, ok: false
   // Respuesta HTML en lugar de JSON

❌ POST http://localhost:4200/api/catalog/spaces 404 (Not Found)
```

### **Causa Raíz**:
El servidor de desarrollo se inició con `ng serve` en lugar de `npm run dev` (con proxy).

**Resultado**: 
- Peticiones van a `http://localhost:4200/api/*` 
- No hay proxy que las redirija a `http://localhost:8080/api/*`
- Frontend intenta servir esas rutas → 404

---

## ✅ **SOLUCIÓN IMPLEMENTADA**

### **1. Script `dev` añadido a package.json**

```json
{
  "scripts": {
    "dev": "ng serve --proxy-config proxy.conf.json"  // ✅ AÑADIDO
  }
}
```

### **2. Proceso actual terminado**

```bash
kill -9 25893  # ✅ Proceso sin proxy terminado
```

---

## 🚀 **CÓMO REINICIAR CORRECTAMENTE**

### **IMPORTANTE: Usar `npm run dev` (NO `ng serve`)**

```bash
# 1. Ir a la carpeta del frontend
cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend

# 2. Iniciar con proxy (OBLIGATORIO)
npm run dev

# ❌ NO USAR: ng serve
# ❌ NO USAR: npm start
# ✅ SOLO USAR: npm run dev
```

### **Verificar que el proxy esté activo**:

```bash
# En la terminal donde ejecutaste npm run dev, deberías ver:

[HPM] Proxy created: /api -> http://localhost:8080
[HPM] Proxy rewrite rule created: "^/api" ~> ""
[HPM] Subscriptions created.

** Angular Live Development Server is listening on localhost:4200 **
```

**Si NO ves `[HPM] Proxy created`, el proxy NO está activo** ❌

---

## 🧪 **CÓMO VERIFICAR QUE FUNCIONA**

### **Paso 1: Verificar backend corriendo**

```bash
# Gateway debe estar en 8080
curl http://localhost:8080/actuator/health
# Esperado: {"status":"UP"}

# Catalog debe estar en 8082
curl http://localhost:8082/actuator/health
# Esperado: {"status":"UP"}
```

### **Paso 2: Abrir navegador**

```
http://localhost:4200
```

### **Paso 3: Abrir DevTools (F12) → Network**

- Login
- Ir a "Mis Espacios"

**Verificar en Network tab**:
```
Request URL: http://localhost:4200/api/catalog/spaces/owner/{userId}
                   ↑ Puerto 4200 (frontend)
                   
[HPM] GET /api/catalog/spaces/owner/{userId} -> http://localhost:8080/api/catalog/spaces/owner/{userId}
                                                ↑ Redirigido a puerto 8080 (backend)

Status: 200 OK  ✅
Response: [{"id":"...","title":"...",...}]  ✅ JSON válido
```

### **Paso 4: Crear espacio**

- Llenar formulario
- Click "Crear Espacio"

**Verificar en Network tab**:
```
Request URL: http://localhost:4200/api/catalog/spaces
Request Method: POST

[HPM] POST /api/catalog/spaces -> http://localhost:8080/api/catalog/spaces

Status: 201 Created  ✅
Response: {"id":"...","title":"...",...}  ✅
```

---

## 🔍 **SI SIGUE FALLANDO**

### **Problema 1: Proxy no aparece en logs**

```bash
# Verificar que proxy.conf.json existe
ls -la /Users/angel/Desktop/BalconazoApp/balconazo-frontend/proxy.conf.json

# Si no existe, crearlo:
echo '{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "debug"
  }
}' > /Users/angel/Desktop/BalconazoApp/balconazo-frontend/proxy.conf.json

# Reiniciar frontend
npm run dev
```

### **Problema 2: Backend no responde**

```bash
# Verificar que gateway esté corriendo
curl http://localhost:8080/actuator/health

# Si no responde:
cd /Users/angel/Desktop/BalconazoApp/api-gateway
java -jar target/api-gateway-1.0.0.jar &

# Verificar catalog
curl http://localhost:8082/actuator/health

# Si no responde:
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
./mvnw spring-boot:run &
```

### **Problema 3: Error CORS aunque use proxy**

```bash
# Limpiar caché del navegador
# Chrome: DevTools → Application → Clear storage → Clear site data

# Reiniciar frontend
cd balconazo-frontend
npm run dev
```

---

## 📋 **CHECKLIST ANTES DE PROBAR**

Verifica que **TODOS** estos puntos estén ✅:

### **Backend**:
- [ ] PostgreSQL corriendo (puerto 5433 para catalog)
- [ ] Auth service corriendo (puerto 8084)
- [ ] Catalog service corriendo (puerto 8082)
- [ ] Gateway corriendo (puerto 8080)

```bash
# Verificar todos de una vez:
curl -s http://localhost:8080/actuator/health && echo "✅ Gateway OK" || echo "❌ Gateway DOWN"
curl -s http://localhost:8084/actuator/health && echo "✅ Auth OK" || echo "❌ Auth DOWN"
curl -s http://localhost:8082/actuator/health && echo "✅ Catalog OK" || echo "❌ Catalog DOWN"
```

### **Frontend**:
- [ ] `proxy.conf.json` existe
- [ ] `package.json` tiene script `dev`
- [ ] `angular.json` tiene `proxyConfig`
- [ ] Proceso antiguo (sin proxy) terminado
- [ ] Nuevo proceso iniciado con `npm run dev`
- [ ] Logs muestran `[HPM] Proxy created`

---

## 🎯 **COMANDOS FINALES**

### **1. Verificar backend**
```bash
cd /Users/angel/Desktop/BalconazoApp
./test-apis.sh
```

Esperado: 6/7 tests pasando ✅

### **2. Iniciar frontend CON PROXY**
```bash
cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend
npm run dev
```

Esperado en terminal:
```
[HPM] Proxy created: /api -> http://localhost:8080  ✅
** Angular Live Development Server is listening on localhost:4200 **
```

### **3. Probar en navegador**
```
http://localhost:4200
```

**Login → Mis Espacios → Crear Espacio**

Esperado en DevTools (F12) Network:
```
GET /api/catalog/spaces/owner/... → 200 OK ✅
POST /api/catalog/spaces → 201 Created ✅
```

---

## ✅ **RESUMEN**

### **Problema**:
```
❌ Frontend iniciado con ng serve (sin proxy)
❌ Peticiones a /api/* → 404 Not Found
❌ Backend nunca recibía las peticiones
```

### **Solución**:
```
✅ Script dev añadido: npm run dev (con proxy)
✅ Proceso sin proxy terminado
✅ Instrucciones claras para reiniciar
✅ Verificación paso a paso
```

### **Próximo paso**:
```bash
cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend
npm run dev
```

**Y verificar que veas `[HPM] Proxy created` en la terminal** 🎯

---

## 🚨 **REGLA DE ORO**

### **SIEMPRE usar `npm run dev`**

```bash
# ✅ CORRECTO
npm run dev

# ❌ INCORRECTO
ng serve
npm start
ng s
```

**Si NO ves `[HPM] Proxy created`, reinicia con `npm run dev`** ✅

---

**Implementado por**: Claude (Sonnet 4.5)  
**Fecha**: 5 de Noviembre de 2025  
**Hora**: 19:20  
**Estado**: ✅ **SOLUCIONADO - REINICIAR CON `npm run dev`**

**El proxy existe, solo necesitas reiniciar el frontend correctamente** 🎉

