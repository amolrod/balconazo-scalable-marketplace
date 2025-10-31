# 🎨 Frontend Angular - BalconazoApp

## ✅ Estado Actual

**Proyecto creado y configurado con:**
- ✅ Angular 20.3.3
- ✅ TypeScript strict mode
- ✅ SCSS para estilos
- ✅ Routing configurado
- ✅ HttpClient con interceptor JWT
- ✅ Servicio de autenticación completo
- ✅ Guards de autenticación
- ✅ Modelos TypeScript (User, Space, Booking)
- ✅ Componente de Login funcional con estilos

---

## 📁 Estructura del Proyecto

```
balconazo-frontend/
├── src/
│   ├── app/
│   │   ├── core/                          # Servicios singleton y lógica core
│   │   │   ├── guards/
│   │   │   │   └── auth.guard.ts         ✅ Guard de autenticación
│   │   │   ├── interceptors/
│   │   │   │   └── auth.interceptor.ts   ✅ Interceptor JWT
│   │   │   ├── models/
│   │   │   │   ├── auth.model.ts         ✅ Interfaces de autenticación
│   │   │   │   ├── space.model.ts        ✅ Interfaces de espacios
│   │   │   │   └── booking.model.ts      ✅ Interfaces de reservas
│   │   │   └── services/
│   │   │       └── auth.service.ts       ✅ Servicio de autenticación
│   │   ├── features/                      # Módulos por funcionalidad
│   │   │   └── auth/
│   │   │       └── components/
│   │   │           └── login/            ✅ Componente de login
│   │   ├── app.ts                        ✅ Componente principal
│   │   ├── app.routes.ts                 ✅ Rutas configuradas
│   │   └── app.config.ts                 ✅ Configuración de providers
│   ├── environments/
│   │   ├── environment.ts                ✅ Variables de desarrollo
│   │   └── environment.prod.ts           ✅ Variables de producción
│   └── styles.scss                       ✅ Estilos globales
```

---

## 🚀 Comandos Disponibles

### Desarrollo

```bash
# Iniciar servidor de desarrollo
cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend
ng serve

# Abrir en navegador
# http://localhost:4200
```

### Build

```bash
# Build de desarrollo
ng build

# Build de producción
ng build --configuration production
```

### Generar Componentes

```bash
# Generar componente
ng generate component features/spaces/components/space-list

# Generar servicio
ng generate service core/services/space

# Generar guard
ng generate guard core/guards/role
```

---

## 🔐 Autenticación Implementada

### Flujo de Login

1. Usuario ingresa email y password
2. `AuthService.login()` envía petición a `/api/auth/login`
3. Backend devuelve `accessToken`, `refreshToken`, `userId`, `role`
4. Tokens se guardan en `localStorage`
5. `AuthInterceptor` añade automáticamente el Bearer token a todas las peticiones
6. Si el token expira (401), se intenta refresh automático
7. Si el refresh falla, se hace logout y redirect a `/login`

### Uso del AuthService

```typescript
import { AuthService } from './core/services/auth.service';

// Inyectar el servicio
constructor(private authService: AuthService) {}

// Verificar si está autenticado
if (this.authService.isAuthenticated()) {
  // Usuario logueado
}

// Obtener usuario actual
const user = this.authService.getCurrentUser();

// Verificar rol
if (this.authService.isHost()) {
  // Es un host
}

// Logout
this.authService.logout();
```

---

## 🧪 Probar el Login

### Credenciales de Prueba

**HOST:**
- Email: `host1@balconazo.com`
- Password: `password123`

**GUEST:**
- Email: `guest1@balconazo.com`
- Password: `password123`

### Pasos para Probar

1. **Iniciar Backend:**
   ```bash
   cd /Users/angel/Desktop/BalconazoApp
   ./start-all-services.sh
   ```

2. **Verificar que el backend esté UP:**
   ```bash
   ./comprobacionmicroservicios.sh
   ```

3. **Iniciar Frontend:**
   ```bash
   cd balconazo-frontend
   ng serve
   ```

4. **Abrir navegador:** http://localhost:4200

5. **Login con credenciales de prueba**

---

## 📝 Próximos Pasos

### Día 1-2: Componentes de Autenticación
- [ ] Componente de Registro
- [ ] Página de Home/Dashboard
- [ ] Navbar con logout

### Día 3-5: Búsqueda de Espacios
- [ ] Servicio de Search
- [ ] Componente de Mapa (Leaflet)
- [ ] Lista de resultados de búsqueda
- [ ] Filtros de búsqueda

### Día 6-8: Detalle de Espacio
- [ ] Vista de detalle de espacio
- [ ] Galería de imágenes
- [ ] Reseñas del espacio
- [ ] Botón de reserva

### Día 9-12: Sistema de Reservas
- [ ] Servicio de Bookings
- [ ] Formulario de reserva
- [ ] Calendario de disponibilidad
- [ ] Mis reservas (lista)
- [ ] Detalle de reserva

### Día 13-15: Panel de Host
- [ ] Servicio de Spaces
- [ ] Dashboard del host
- [ ] Crear/editar espacio
- [ ] Mis espacios (lista)
- [ ] Gestión de disponibilidad

---

## 🛠️ Tecnologías y Dependencias

### Instaladas

```json
{
  "@auth0/angular-jwt": "^5.x",
  "leaflet": "^1.x",
  "ngx-toastr": "^19.x"
}
```

### Por Instalar (según necesidad)

```bash
# Para formularios complejos
npm install @angular/forms

# Para animaciones
npm install @angular/animations

# Para drag & drop (subida de fotos)
npm install @ng-dnd/core

# Para date pickers
npm install ngx-bootstrap

# Para charts (estadísticas)
npm install ng2-charts chart.js
```

---

## 🎨 Guía de Estilos

### Colores

```scss
// Primarios
--primary: #667eea;
--primary-dark: #764ba2;

// Estados
--success: #48bb78;
--warning: #ed8936;
--error: #f56565;
--info: #4299e1;

// Grises
--gray-50: #f7fafc;
--gray-100: #edf2f7;
--gray-200: #e2e8f0;
--gray-700: #4a5568;
--gray-900: #1a202c;
```

### Tipografía

- **Títulos:** 32px, 24px, 20px
- **Body:** 16px
- **Small:** 14px
- **Tiny:** 12px

### Espaciado

- **xs:** 4px
- **sm:** 8px
- **md:** 16px
- **lg:** 24px
- **xl:** 32px

---

## 🐛 Troubleshooting

### Error: "Cannot find module '@angular/common/http'"

```bash
npm install
```

### Error: CORS al hacer peticiones

- Verificar que el backend esté corriendo en `http://localhost:8080`
- El API Gateway ya tiene CORS configurado

### Token expirado (401)

- El interceptor maneja automáticamente el refresh
- Si persiste, borrar localStorage y volver a hacer login

### Estilos no se aplican

- Verificar que el archivo `.scss` esté importado
- Revisar que no haya errores de sintaxis SCSS

---

## 📚 Recursos

### Documentación Backend
- [README.md](../README.md)
- [FRONTEND-START.md](../FRONTEND-START.md)
- [POSTMAN_ENDPOINTS.md](../POSTMAN_ENDPOINTS.md)

### Documentación Angular
- [Angular Docs](https://angular.dev)
- [Angular Material](https://material.angular.io)
- [RxJS](https://rxjs.dev)

---

## ✅ Checklist de Validación

Antes de continuar con el siguiente componente:

- [x] Backend corriendo y accesible
- [x] Frontend inicia sin errores (`ng serve`)
- [x] Login funciona con credenciales de prueba
- [x] Token se guarda en localStorage
- [x] Interceptor añade Bearer token a las peticiones
- [x] Redirect después de login exitoso
- [ ] Navbar con logout funcional
- [ ] Protección de rutas con authGuard

---

**Última actualización:** 31 de Octubre de 2025  
**Estado:** Login funcional ✅ - Listo para continuar con Registro y Home

