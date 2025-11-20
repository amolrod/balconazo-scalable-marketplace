# ADR-002: Modelo de Roles Dinámicos (Usuario = Host + Guest)

## Estado
✅ **Aprobado** - 5 Noviembre 2025  
📦 **Implementado** - Backend + Frontend

---

## Contexto

En el sistema inicial de BalconazoApp, los usuarios debían elegir un rol fijo durante el registro:
- **HOST**: Solo puede publicar espacios
- **GUEST**: Solo puede hacer reservas

Esta decisión forzaba al usuario a elegir un rol antes de explorar la plataforma, creando fricción en el onboarding.

Además, muchos usuarios del mundo real pueden querer:
1. Alquilar espacios cuando viajan (**GUEST**)
2. Publicar su propio espacio cuando no lo usan (**HOST**)

El modelo de roles fijos no reflejaba este comportamiento real de usuarios.

---

## Decisión

**Implementar un modelo de roles dinámicos donde un mismo usuario puede ser HOST y GUEST simultáneamente.**

### Modelo de Datos

```sql
-- Tabla users (auth_db - MySQL)
CREATE TABLE users (
    user_id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image_url VARCHAR(500),
    is_host BOOLEAN DEFAULT FALSE,  -- Nuevo campo
    is_guest BOOLEAN DEFAULT TRUE,  -- Todos son guest por defecto
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Lógica de Negocio

```java
@Service
public class UserService {
    
    // Un usuario se convierte en HOST al crear su primer espacio
    public void promoteToHost(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));
        
        if (!user.isHost()) {
            user.setHost(true);
            userRepository.save(user);
            log.info("User {} promoted to HOST", userId);
        }
    }
    
    // Un usuario siempre puede hacer reservas (is_guest = true)
    public boolean canCreateBooking(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));
        return user.isGuest(); // Siempre true
    }
    
    // Solo hosts pueden crear espacios
    public boolean canCreateSpace(UUID userId) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));
        return user.isHost();
    }
}
```

### Frontend

```typescript
interface User {
  userId: string;
  email: string;
  name: string;
  phone?: string;
  profileImageUrl?: string;
  isHost: boolean;   // Dinámico: true si tiene espacios publicados
  isGuest: boolean;  // Siempre true
  createdAt: string;
}

// Navbar adapta botones según roles
@Component({
  selector: 'app-navbar',
  template: `
    <!-- Todos ven "Explorar" -->
    <a routerLink="/explore">Explorar</a>
    
    <!-- Solo hosts ven "Mis Espacios" -->
    <a *ngIf="currentUser?.isHost" routerLink="/host/dashboard">
      Mis Espacios
    </a>
    
    <!-- Todos ven "Mis Reservas" -->
    <a routerLink="/bookings">Mis Reservas</a>
    
    <!-- Botón para convertirse en host -->
    <button *ngIf="!currentUser?.isHost" (click)="becomeHost()">
      Conviértete en Host
    </button>
  `
})
export class NavbarComponent {
  currentUser = signal<User | null>(null);
  
  becomeHost() {
    this.router.navigate(['/host/create-space']);
  }
}
```

---

## Alternativas Consideradas

### Alternativa 1: Roles Fijos
**Rechazada**
- ❌ Fuerza elección temprana
- ❌ Requiere cambio de cuenta para otro rol
- ❌ No refleja comportamiento real
- ✅ Más simple de implementar

### Alternativa 2: Múltiples Cuentas
**Rechazada**
- ❌ Usuario debe registrarse dos veces
- ❌ Confusión de gestión de cuentas
- ❌ Peor UX
- ✅ Total separación de datos

### Alternativa 3: Roles Dinámicos (Elegida)
**Aprobada**
- ✅ Flexibilidad total
- ✅ UX fluida (explorar antes de registrar)
- ✅ Un solo perfil para todo
- ✅ Modelo similar a Airbnb, Booking.com
- ⚠️ Lógica de permisos más compleja

---

## Consecuencias

### Positivas ✅

1. **UX Mejorada**
   - Usuario puede explorar la plataforma sin comprometerse
   - Registro más simple (solo email/password/nombre)
   - No hay "punto de no retorno" en la elección de rol

2. **Flexibilidad**
   - Un usuario puede publicar Y reservar espacios
   - No necesita crear dos cuentas
   - Modelo más realista (como Airbnb)

3. **Modelo de Negocio**
   - Mayor engagement (usuarios pueden usar todas las features)
   - Más conversiones (guest → host es friction-free)
   - Monetización dual por usuario

4. **Escalabilidad**
   - Fácil añadir más roles en futuro (ADMIN, MODERATOR)
   - Permisos granulares por feature

### Negativas ❌

1. **Complejidad de Permisos**
   - Frontend debe adaptar UI según roles
   - Guards más complejos en Angular
   - Backend debe validar permisos por endpoint

2. **Testing**
   - Más casos de prueba (user sin roles, con 1, con 2)
   - Validación de edge cases

3. **Migración de Datos**
   - Usuarios existentes con rol fijo deben migrarse
   - Script de migración necesario

---

## Implementación

### Backend (Auth Service)

```java
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    
    @PostMapping("/register")
    public ResponseEntity<AuthResponseDTO> register(@RequestBody RegisterDTO dto) {
        User user = new User();
        user.setEmail(dto.getEmail());
        user.setPasswordHash(passwordEncoder.encode(dto.getPassword()));
        user.setName(dto.getName());
        user.setGuest(true);   // Todos son guest por defecto
        user.setHost(false);   // No es host hasta crear un espacio
        
        userRepository.save(user);
        
        String token = jwtService.generateToken(user);
        return ResponseEntity.ok(new AuthResponseDTO(token, user));
    }
    
    @PostMapping("/promote-to-host")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> promoteToHost(@AuthenticationPrincipal UserDetails userDetails) {
        UUID userId = UUID.fromString(userDetails.getUsername());
        userService.promoteToHost(userId);
        return ResponseEntity.ok().build();
    }
}
```

### Frontend (Auth Service)

```typescript
@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly API_URL = `${environment.apiUrl}/api/auth`;
  currentUser = signal<User | null>(null);
  
  register(data: RegisterRequest): Observable<AuthResponse> {
    return this.http.post<AuthResponse>(`${this.API_URL}/register`, data).pipe(
      tap(response => {
        localStorage.setItem('token', response.accessToken);
        this.currentUser.set(response.user);
      })
    );
  }
  
  // Al crear primer espacio, promocionar a host
  promoteToHost(): Observable<void> {
    return this.http.post<void>(`${this.API_URL}/promote-to-host`, {}).pipe(
      tap(() => {
        const user = this.currentUser();
        if (user) {
          this.currentUser.set({ ...user, isHost: true });
        }
      })
    );
  }
}
```

---

## Experiencia de Usuario

### Flujo: Guest → Host

```
1. Usuario se registra (solo email/password)
   → isGuest = true, isHost = false

2. Usuario explora espacios, hace reservas
   → Funciona normalmente como GUEST

3. Usuario decide publicar su espacio
   → Clic en "Conviértete en Host"
   → Redirige a /host/create-space

4. Al crear primer espacio:
   → Backend llama promoteToHost(userId)
   → isHost = true
   → Navbar muestra "Mis Espacios"

5. Usuario ahora puede:
   → Seguir haciendo reservas (GUEST)
   → Gestionar sus espacios (HOST)
```

### UI Adaptativa

```typescript
// Navbar muestra diferentes opciones según roles
<nav>
  <!-- Todos -->
  <a routerLink="/explore">Explorar</a>
  
  <!-- Solo hosts -->
  <a *ngIf="user.isHost" routerLink="/host/dashboard">Mis Espacios</a>
  
  <!-- Todos (guest) -->
  <a routerLink="/bookings">Mis Reservas</a>
  
  <!-- Solo non-hosts -->
  <button *ngIf="!user.isHost" (click)="becomeHost()">
    Publica tu espacio
  </button>
</nav>
```

---

## Referencias

### Inspiración: Airbnb
Airbnb usa el mismo modelo:
- Un usuario puede reservar alojamientos (guest)
- El mismo usuario puede publicar su propio alojamiento (host)
- No requiere cuentas separadas

### Documentos Relacionados
- `AUTH-SIN-SCROLL-FINAL.md` - Implementación registro
- `MIS-ESPACIOS-VISIBLE.md` - Dashboard de host
- `MODELO-AIRBNB-IMPLEMENTADO.md` - Implementación completa

---

## Validación

### Tests E2E

```bash
# Flujo completo guest → host
curl -X POST http://localhost:8080/api/auth/register \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'
# → isGuest=true, isHost=false

TOKEN=$(jq -r '.accessToken' <<< "$RESPONSE")

# Crear espacio (auto-promote a host)
curl -X POST http://localhost:8080/api/catalog/spaces \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Mi Espacio",...}'
# → isHost=true

# Verificar perfil
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
# → isGuest=true, isHost=true ✅
```

---

## Conclusión

El modelo de roles dinámicos es la decisión correcta para BalconazoApp porque:

1. ✅ **Refleja el comportamiento real** de usuarios
2. ✅ **Mejora significativamente el onboarding** (sin fricción)
3. ✅ **Aumenta el engagement** (usuarios pueden usar todas las features)
4. ✅ **Modelo probado** (Airbnb, Booking.com, etc.)

Los trade-offs (complejidad de permisos) son manejables y valen la pena por los beneficios de UX y negocio.

---

**Fecha de Creación:** 20 Noviembre 2025  
**Autor:** Equipo de Desarrollo BalconazoApp  
**Estado:** ✅ Implementado y Validado
