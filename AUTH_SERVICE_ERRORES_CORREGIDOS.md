# ✅ ERRORES DE COMPILACIÓN CORREGIDOS - AUTH SERVICE

**Fecha:** 28 de octubre de 2025, 17:15

---

## 🐛 ERRORES ENCONTRADOS Y SOLUCIONADOS

### Error 1: `cannot find symbol: method parserBuilder()`

**Problema:**
```
[ERROR] /Users/angel/Desktop/BalconazoApp/auth-service/src/main/java/com/balconazo/auth/service/JwtService.java:[70,20] cannot find symbol
  symbol:   method parserBuilder()
  location: class io.jsonwebtoken.Jwts
```

**Causa:**
La API de JJWT 0.12.x cambió. Los métodos antiguos como `parserBuilder()`, `setSigningKey()`, `parseClaimsJws()` fueron deprecados o eliminados.

**Solución Aplicada:**
Actualicé `JwtService.java` para usar la nueva API de JJWT 0.12.x:

```java
// ANTES (API antigua - deprecada)
private Claims extractAllClaims(String token) {
    return Jwts.parserBuilder()
            .setSigningKey(getSignKey())
            .build()
            .parseClaimsJws(token)
            .getBody();
}

// DESPUÉS (API 0.12.x)
private Claims extractAllClaims(String token) {
    return Jwts.parser()
            .verifyWith(getSignKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
}
```

**Cambios realizados:**
1. ✅ `parserBuilder()` → `parser()`
2. ✅ `setSigningKey()` → `verifyWith()`
3. ✅ `parseClaimsJws()` → `parseSignedClaims()`
4. ✅ `.getBody()` → `.getPayload()`

---

### Error 2: Warning `@Builder will ignore the initializing expression`

**Problema:**
```
[WARNING] /Users/angel/Desktop/BalconazoApp/auth-service/src/main/java/com/balconazo/auth/entity/User.java:[36,21] 
@Builder will ignore the initializing expression entirely. If you want the initializing expression to serve as default, add @Builder.Default.
```

**Causa:**
Lombok `@Builder` ignora los valores por defecto en los campos si no se anota con `@Builder.Default`.

**Solución Aplicada:**
```java
// ANTES
@Column(nullable = false)
private Boolean active = true;

// DESPUÉS
@Builder.Default
@Column(nullable = false)
private Boolean active = true;
```

---

### Error 3: Uso de API deprecada (SignatureAlgorithm)

**Problema:**
```
[INFO] /Users/angel/Desktop/BalconazoApp/auth-service/src/main/java/com/balconazo/auth/service/JwtService.java uses or overrides a deprecated API.
```

**Causa:**
JJWT 0.12.x cambió la forma de firmar tokens. `SignatureAlgorithm` está deprecado.

**Solución Aplicada:**
```java
// ANTES (con SignatureAlgorithm)
private String createToken(Map<String, Object> claims, String subject, Long expiration) {
    return Jwts.builder()
            .setClaims(claims)
            .setSubject(subject)
            .setIssuedAt(new Date(System.currentTimeMillis()))
            .setExpiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getSignKey(), SignatureAlgorithm.HS256)  // ← deprecado
            .compact();
}

// DESPUÉS (sin SignatureAlgorithm)
private String createToken(Map<String, Object> claims, String subject, Long expiration) {
    return Jwts.builder()
            .claims(claims)  // sin 'set'
            .subject(subject)  // sin 'set'
            .issuedAt(new Date(System.currentTimeMillis()))
            .expiration(new Date(System.currentTimeMillis() + expiration))
            .signWith(getSignKey())  // detecta automáticamente HS256
            .compact();
}
```

**Cambios realizados:**
1. ✅ `.setClaims()` → `.claims()`
2. ✅ `.setSubject()` → `.subject()`
3. ✅ `.setIssuedAt()` → `.issuedAt()`
4. ✅ `.setExpiration()` → `.expiration()`
5. ✅ `.signWith(key, algorithm)` → `.signWith(key)` (autodetecta algoritmo)

---

### Error 4: Decodificación de Secret Key

**Problema:**
```java
private Key getSignKey() {
    byte[] keyBytes = Decoders.BASE64.decode(secret);  // ← secret no es Base64
    return Keys.hmacShaKeyFor(keyBytes);
}
```

**Causa:**
El secret configurado en `application.yml` NO está en Base64, es una cadena UTF-8 simple.

**Solución Aplicada:**
```java
// ANTES (asume Base64)
import io.jsonwebtoken.io.Decoders;
private Key getSignKey() {
    byte[] keyBytes = Decoders.BASE64.decode(secret);
    return Keys.hmacShaKeyFor(keyBytes);
}

// DESPUÉS (UTF-8 directo)
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

private SecretKey getSignKey() {
    byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
    return Keys.hmacShaKeyFor(keyBytes);
}
```

**Cambio en application.yml:**
```yaml
# Clave UTF-8 de 256 bits (32 caracteres)
jwt:
  secret: BalconazoSecretKeyForJWTGenerationMustBe256BitsLongMinimumForHS256AlgorithmSecureKey2025
```

---

## ✅ RESULTADO

```bash
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean install -DskipTests
```

**Salida:**
```
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.731 s
```

✅ **Auth Service compila exitosamente sin errores ni warnings**

---

## 📝 ARCHIVOS MODIFICADOS

1. ✅ `JwtService.java` - Actualizado a JJWT 0.12.x API
2. ✅ `User.java` - Agregado `@Builder.Default` a campo `active`
3. ✅ `application.yml` - Secret key ajustado a 256 bits UTF-8

---

## 🔐 NUEVA API DE JWT (JJWT 0.12.x)

### Generar Token:
```java
String token = Jwts.builder()
    .claims(claims)           // sin 'set'
    .subject(userId)
    .issuedAt(new Date())
    .expiration(new Date(System.currentTimeMillis() + 86400000))
    .signWith(secretKey)      // autodetecta HS256
    .compact();
```

### Parsear Token:
```java
Claims claims = Jwts.parser()
    .verifyWith(secretKey)    // nueva API
    .build()
    .parseSignedClaims(token)  // antes: parseClaimsJws
    .getPayload();             // antes: getBody
```

### Secret Key:
```java
SecretKey key = Keys.hmacShaKeyFor(
    secret.getBytes(StandardCharsets.UTF_8)
);
```

---

## ⏭️ PRÓXIMO PASO

Ahora que Auth Service compila correctamente, puedes:

1. **Iniciar el sistema completo:**
   ```bash
   ./start-all-with-eureka.sh
   ```

2. **Probar Auth Service:**
   ```bash
   # Registrar usuario
   curl -X POST http://localhost:8084/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@balconazo.com",
       "password": "password123",
       "role": "HOST"
     }'
   
   # Login
   curl -X POST http://localhost:8084/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@balconazo.com",
       "password": "password123"
     }'
   ```

---

**Estado:** ✅ Auth Service compilado y listo para usar  
**Próximo:** Iniciar sistema completo y crear API Gateway

