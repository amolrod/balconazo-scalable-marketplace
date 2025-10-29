# 🔍 ANÁLISIS CORRECTO DEL ERROR 403 - DOS PROBLEMAS DISTINTOS

**Fecha:** 29 de Octubre de 2025

---

## 🎯 ACLARACIÓN IMPORTANTE

Tienes razón. HAY **DOS PROBLEMAS DISTINTOS**:

### 1️⃣ 403 al llamar DIRECTAMENTE a Auth Service (puerto 8084)
**Síntoma:** `curl http://localhost:8084/api/auth/login` → 403  
**El Gateway NO interviene aquí** - es un problema del Auth Service mismo

### 2️⃣ 403 al llamar a través del Gateway (puerto 8080)
**Síntoma:** `curl http://localhost:8080/api/auth/login` → 403  
**Aquí SÍ interviene el Gateway** - problema del RequestRateLimiter

---

## 🔍 ANÁLISIS DEL PROBLEMA 1: Auth Service Directo (8084)

### Posibles Causas del 403 Directo:

#### A) ❌ Auth Service NO está corriendo
**Verificación:**
```bash
lsof -i:8084  # Si no muestra nada → NO está corriendo
```

**Causa común:** Puerto ocupado por proceso zombie
```bash
# En los logs apareció:
"Port 8084 was already in use"
```

**Solución:**
```bash
lsof -ti:8084 | xargs kill -9
cd /Users/angel/Desktop/BalconazoApp/auth-service
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

---

#### B) ❌ Auth Service corriendo con JAR VIEJO (sin cambios de SecurityConfig)

**Problema:** Se editó `SecurityConfig.java` pero NO se recompiló, o se reinició con un JAR antiguo.

**Cómo detectar:**
- SecurityConfig tiene `HttpMethod.POST` y `permitAll()` en el código fuente ✅
- Pero al hacer login sigue dando 403 ❌
- En logs aparece: `Pre-authenticated entry point called. Rejecting access`

**Causa:** El JAR ejecutándose NO tiene los cambios nuevos.

**Solución:**
```bash
# 1. Matar proceso
lsof -ti:8084 | xargs kill -9

# 2. Recompilar
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean package -DskipTests

# 3. Verificar que compiló
ls -lh target/auth_service-0.0.1-SNAPSHOT.jar
# Debe mostrar fecha/hora RECIENTE

# 4. Iniciar con JAR NUEVO
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

---

#### C) ❌ SecurityConfig NO se está aplicando

**Problema:** Aunque el código está correcto, Spring no lo carga.

**Causas posibles:**
1. SecurityConfig en paquete incorrecto (fuera del scan de Spring)
2. Falta `@Configuration` o `@EnableWebSecurity`
3. Hay OTRO SecurityConfig que lo sobreescribe
4. Orden incorrecto de las reglas

**Verificación actual:**
```java
// Ubicación: com.balconazo.auth.config.SecurityConfig
@Configuration  // ✅ Presente
@EnableWebSecurity  // ✅ Presente
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) {
        http
            .csrf(csrf -> csrf.disable())  // ✅ Correcto
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))  // ✅ Correcto
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**").permitAll()  // ✅ Correcto
                .requestMatchers(HttpMethod.POST, "/api/auth/login", "/api/auth/register").permitAll()  // ✅ Correcto
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

**Estado:** ✅ **Configuración PERFECTA**

---

#### D) ❌ Spring Security generando UserDetailsService por defecto

**Problema:** Cuando NO hay un `UserDetailsService` bean, Spring crea uno automático en memoria con usuario/password aleatorio.

**Síntoma en logs:**
```
Using generated security password: [random-uuid]
This generated password is for development use only.
```

Y luego:
```
Pre-authenticated entry point called. Rejecting access
```

**Causa:** Spring está aplicando HTTP Basic Authentication por defecto.

**Solución:** Ya aplicada en SecurityConfig:
```java
.csrf(csrf -> csrf.disable())  // Desactiva CSRF
// NO tiene .httpBasic() ni .formLogin() → Correcto
```

---

### 🔬 DIAGNÓSTICO PASO A PASO

#### Paso 1: ¿Está corriendo el Auth Service?

```bash
lsof -i:8084
```

**Si NO muestra nada:**
- ❌ El servicio NO está corriendo
- Solución: Iniciarlo (ver sección A arriba)

**Si muestra algo:**
- ✅ El servicio está corriendo
- Continuar con Paso 2

---

#### Paso 2: ¿Qué versión del JAR está corriendo?

```bash
# Ver última modificación del JAR
ls -lh /Users/angel/Desktop/BalconazoApp/auth-service/target/auth_service-0.0.1-SNAPSHOT.jar

# Ver proceso corriendo
ps aux | grep auth_service | grep -v grep
```

**Comparar:** La fecha del JAR debe ser POSTERIOR a la última edición de `SecurityConfig.java`.

Si el JAR es ANTIGUO:
- ❌ Está corriendo código viejo
- Solución: Recompilar y reiniciar (ver sección B arriba)

---

#### Paso 3: ¿Qué dice el log al hacer login?

```bash
# Hacer login
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'

# Ver logs inmediatamente después
tail -50 /tmp/auth-service.log
```

**Buscar en logs:**

Si aparece:
```
Securing POST /api/auth/login
Pre-authenticated entry point called. Rejecting access
```
→ ❌ **SecurityConfig NO se está aplicando o el JAR es viejo**

Si aparece:
```
POST /api/auth/login - Email: host1@balconazo.com
```
→ ✅ **La petición SÍ llega al controller**

---

## 📊 TABLA DE DIAGNÓSTICO

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `lsof -i:8084` vacío | Auth Service NO corriendo | Iniciar servicio |
| `Port 8084 already in use` | Proceso zombie | `lsof -ti:8084 \| xargs kill -9` |
| JAR antiguo | NO se recompiló | `mvn clean package -DskipTests` |
| Log: "Pre-authenticated entry point" | SecurityConfig no aplicado o JAR viejo | Recompilar y reiniciar |
| Log: "Using generated security password" | UserDetailsService por defecto | Ya solucionado en SecurityConfig |
| 403 pero controller recibe petición | Otro filtro/interceptor | Revisar otros filters |

---

## ✅ CONFIGURACIÓN CORRECTA ACTUAL

### SecurityConfig.java ✅

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())  // ✅ CSRF OFF
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))  // ✅ STATELESS
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/**").permitAll()  // ✅ Actuator público
                .requestMatchers(HttpMethod.POST, "/api/auth/login", "/api/auth/register").permitAll()  // ✅ Login público
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

**Análisis:**
- ✅ NO hay `.httpBasic()` → No aplica HTTP Basic
- ✅ NO hay `.formLogin()` → No aplica Form Login
- ✅ `.csrf(disable)` → No valida CSRF tokens
- ✅ `permitAll()` con `HttpMethod.POST` explícito
- ✅ `/api/auth/login` coincide con `@RequestMapping("/api/auth")` + `@PostMapping("/login")`

---

## 🎯 PASOS PARA RESOLVER EL 403 DIRECTO (8084)

### 1. Verificar si está corriendo

```bash
lsof -i:8084
```

Si NO está corriendo → continuar con paso 2

### 2. Limpiar puerto

```bash
lsof -ti:8084 | xargs kill -9
```

### 3. Recompilar con código nuevo

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean package -DskipTests
```

Verificar: `BUILD SUCCESS`

### 4. Iniciar Auth Service (en terminal separada)

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
java -jar target/auth_service-0.0.1-SNAPSHOT.jar
```

**Dejar esta terminal abierta** para ver logs en tiempo real.

### 5. Esperar 20 segundos

El servicio tarda en iniciar y registrarse en Eureka.

### 6. Probar login DIRECTO

En otra terminal:

```bash
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}'
```

**Respuesta esperada:** HTTP 200 con JSON token

### 7. Ver logs en la terminal 1

Debe aparecer:
```
POST /api/auth/login - Email: host1@balconazo.com
```

**NO debe aparecer:**
```
Pre-authenticated entry point called. Rejecting access
```

---

## 🚨 SI AÚN DA 403 DESPUÉS DE SEGUIR TODOS LOS PASOS

### Verificación Final

```bash
# 1. Ver logs con filtro de seguridad
grep -i "security\|403\|forbidden\|csrf" /tmp/auth-service.log | tail -20

# 2. Verificar que el SecurityConfig se cargó
grep -i "SecurityFilterChain\|SecurityConfig" /tmp/auth-service.log | tail -10

# 3. Ver configuración de filters
grep -i "Will secure\|filters:" /tmp/auth-service.log | tail -5
```

Debe mostrar:
```
Will secure any request with filters: ... AuthorizationFilter
```

**NO debe mostrar:**
```
Will secure any request with filters: ... BasicAuthenticationFilter
```

---

## 🎉 CONCLUSIÓN

El problema del 403 directo en 8084 puede ser:

1. ❌ **Servicio NO corriendo** (puerto ocupado)
2. ❌ **JAR viejo ejecutándose** (sin cambios de SecurityConfig)
3. ❌ **SecurityConfig no aplicándose** (poco probable, está bien configurado)

**Solución definitiva:**
1. Matar proceso
2. Recompilar
3. Reiniciar con JAR NUEVO
4. Verificar en logs que carga correctamente

---

## 📝 RECORDATORIO

**Problema 1 (8084 directo):** SecurityConfig / JAR viejo / Servicio no corriendo  
**Problema 2 (8080 gateway):** RequestRateLimiter sin key-resolver ✅ YA SOLUCIONADO

Ambos causan 403 pero por razones TOTALMENTE DIFERENTES.

