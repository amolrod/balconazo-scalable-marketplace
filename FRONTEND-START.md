# 🎨 FRONTEND-START.md - Guía para Desarrolladores Frontend

**Destinatario:** Desarrolladores Frontend que integrarán con el backend completado  
**Backend Status:** ✅ 100% Funcional  
**Fecha:** Octubre 2025

---

## 📋 Tabla de Contenidos

1. [Stack Tecnológico Recomendado](#stack-tecnológico-recomendado)
2. [Consumir la API Backend](#consumir-la-api-backend)
3. [Autenticación JWT](#autenticación-jwt)
4. [Endpoints Principales](#endpoints-principales)
5. [Estructura del Proyecto](#estructura-del-proyecto)
6. [Convenciones y Buenas Prácticas](#convenciones-y-buenas-prácticas)
7. [Problemas Comunes y Soluciones](#problemas-comunes-y-soluciones)
8. [Recursos y Documentación](#recursos-y-documentación)

---

## 🛠️ Stack Tecnológico Recomendado

### Opción 1: Angular 18+ (RECOMENDADO)

**¿Por qué Angular?**
- ✅ Framework completo (no necesitas elegir router, HTTP client, state management)
- ✅ TypeScript nativo (type-safe con el backend Java)
- ✅ Reactive programming con RxJS (manejo elegante de JWT refresh)
- ✅ Dependency Injection (arquitectura escalable)
- ✅ CLI potente (`ng generate`)
- ✅ Comunidad grande y estable

**Setup:**
```bash
# Instalar Angular CLI
npm install -g @angular/cli

# Crear proyecto
ng new balconazo-frontend --routing --style=scss --strict

cd balconazo-frontend

# Instalar dependencias adicionales
npm install @auth0/angular-jwt      # Manejo de JWT
npm install leaflet @asymmetrik/ngx-leaflet  # Mapas
npm install ngx-toastr              # Notificaciones
npm install @ngrx/store @ngrx/effects  # State management (opcional)

# Iniciar
ng serve
```

**Estructura de Carpetas:**
```
src/
├── app/
│   ├── core/                    # Servicios singleton
│   │   ├── auth/
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.guard.ts
│   │   │   └── token.interceptor.ts
│   │   ├── api/
│   │   │   └── api.service.ts
│   │   └── models/              # Interfaces TypeScript
│   ├── features/                # Módulos por funcionalidad
│   │   ├── auth/
│   │   ├── spaces/
│   │   ├── bookings/
│   │   └── search/
│   ├── shared/                  # Componentes reutilizables
│   │   ├── components/
│   │   ├── pipes/
│   │   └── directives/
│   └── app.component.ts
├── assets/
├── environments/
│   ├── environment.ts           # Desarrollo
│   └── environment.prod.ts      # Producción
└── styles.scss
```

---

### Opción 2: React 18+ con TypeScript

**¿Por qué React?**
- ✅ Ecosistema más grande
- ✅ Flexibilidad (elige tus propias librerías)
- ✅ Learning curve más suave
- ✅ Mejor para proyectos pequeños/medianos

**Setup:**
```bash
# Crear proyecto con Vite (más rápido que CRA)
npm create vite@latest balconazo-frontend -- --template react-ts

cd balconazo-frontend
npm install

# Dependencias adicionales
npm install axios                    # HTTP client
npm install react-router-dom         # Routing
npm install @tanstack/react-query    # Data fetching
npm install react-hook-form          # Forms
npm install leaflet react-leaflet    # Mapas
npm install react-hot-toast          # Notificaciones
npm install zustand                  # State management

npm run dev
```

**Estructura de Carpetas:**
```
src/
├── api/
│   └── client.ts                # Axios instance
├── components/
│   ├── auth/
│   ├── spaces/
│   ├── bookings/
│   └── shared/
├── hooks/                       # Custom hooks
│   ├── useAuth.ts
│   ├── useSpaces.ts
│   └── useBookings.ts
├── pages/
│   ├── LoginPage.tsx
│   ├── SearchPage.tsx
│   └── BookingPage.tsx
├── store/                       # Zustand store
│   └── authStore.ts
├── types/                       # TypeScript interfaces
│   └── api.types.ts
├── utils/
│   └── api.utils.ts
├── App.tsx
└── main.tsx
```

---

### Opción 3: Vue 3 + TypeScript

**¿Por qué Vue?**
- ✅ Sintaxis más simple y legible
- ✅ Composition API potente
- ✅ Ecosystem oficial completo (Pinia, Router)

**Setup:**
```bash
npm create vue@latest balconazo-frontend

# Seleccionar:
# - TypeScript: Yes
# - Router: Yes
# - Pinia: Yes
# - ESLint: Yes

cd balconazo-frontend
npm install

# Dependencias adicionales
npm install axios
npm install vue3-leaflet
npm install vue-toastification

npm run dev
```

---

## 🌐 Consumir la API Backend

### 1. Configuración Base

**Angular (`environment.ts`):**
```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080/api',
  apiGateway: 'http://localhost:8080'
};
```

**React (`src/config/api.config.ts`):**
```typescript
export const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_URL || 'http://localhost:8080/api',
  TIMEOUT: 30000
};
```

### 2. Cliente HTTP con Interceptores

**Angular (`auth.interceptor.ts`):**
```typescript
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler } from '@angular/common/http';
import { AuthService } from './auth.service';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private authService: AuthService) {}

  intercept(req: HttpRequest<any>, next: HttpHandler) {
    const token = this.authService.getToken();
    
    if (token) {
      req = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
    }
    
    return next.handle(req);
  }
}
```

**React (`api/client.ts`):**
```typescript
import axios from 'axios';
import { API_CONFIG } from '../config/api.config';

export const apiClient = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor (añadir JWT)
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor (manejar refresh token)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      const refreshToken = localStorage.getItem('refreshToken');
      if (refreshToken) {
        try {
          const { data } = await axios.post(`${API_CONFIG.BASE_URL}/auth/refresh`, {
            refreshToken
          });
          
          localStorage.setItem('accessToken', data.accessToken);
          originalRequest.headers.Authorization = `Bearer ${data.accessToken}`;
          
          return apiClient(originalRequest);
        } catch (refreshError) {
          // Redirect to login
          window.location.href = '/login';
        }
      }
    }
    
    return Promise.reject(error);
  }
);
```

---

## 🔐 Autenticación JWT

### Flujo Completo

```typescript
// 1. REGISTRO
interface RegisterRequest {
  email: string;
  password: string;
  role: 'HOST' | 'GUEST';
}

async function register(data: RegisterRequest) {
  const response = await apiClient.post('/auth/register', data);
  return response.data;
}

// 2. LOGIN
interface LoginRequest {
  email: string;
  password: string;
}

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
  userId: string;
  email: string;
  role: string;
}

async function login(credentials: LoginRequest): Promise<LoginResponse> {
  const { data } = await apiClient.post<LoginResponse>('/auth/login', credentials);
  
  // Guardar tokens
  localStorage.setItem('accessToken', data.accessToken);
  localStorage.setItem('refreshToken', data.refreshToken);
  localStorage.setItem('userId', data.userId);
  localStorage.setItem('userRole', data.role);
  
  return data;
}

// 3. OBTENER PERFIL
interface User {
  id: string;
  email: string;
  role: string;
  status: string;
  trustScore: number;
  createdAt: string;
}

async function getProfile(): Promise<User> {
  const { data } = await apiClient.get<User>('/auth/me');
  return data;
}

// 4. LOGOUT
function logout() {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('userId');
  localStorage.removeItem('userRole');
  window.location.href = '/login';
}

// 5. VERIFICAR SI ESTÁ AUTENTICADO
function isAuthenticated(): boolean {
  return !!localStorage.getItem('accessToken');
}

// 6. VERIFICAR ROL
function hasRole(role: string): boolean {
  return localStorage.getItem('userRole') === role;
}
```

### Guard de Autenticación

**Angular (`auth.guard.ts`):**
```typescript
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './auth.service';

export const authGuard = () => {
  const authService = inject(AuthService);
  const router = inject(Router);
  
  if (authService.isAuthenticated()) {
    return true;
  }
  
  router.navigate(['/login']);
  return false;
};

// Uso en routing
{
  path: 'bookings',
  component: BookingsComponent,
  canActivate: [authGuard]
}
```

**React (Hook personalizado):**
```typescript
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuth();
  const navigate = useNavigate();
  
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
    }
  }, [isAuthenticated, navigate]);
  
  return isAuthenticated ? <>{children}</> : null;
}

// Uso
<Route path="/bookings" element={
  <ProtectedRoute>
    <BookingsPage />
  </ProtectedRoute>
} />
```

---

## 📡 Endpoints Principales

### Autenticación

```typescript
// POST /api/auth/register
interface RegisterDTO {
  email: string;
  password: string;
  role: 'HOST' | 'GUEST';
}

// POST /api/auth/login
interface LoginDTO {
  email: string;
  password: string;
}

// GET /api/auth/me (requiere JWT)
// Response: User object

// POST /api/auth/refresh
interface RefreshDTO {
  refreshToken: string;
}
```

### Búsqueda de Espacios

```typescript
// GET /api/search/spaces
interface SearchParams {
  lat: number;
  lon: number;
  radius?: number;           // km (default: 10)
  minCapacity?: number;
  minPriceCents?: number;
  maxPriceCents?: number;
  minRating?: number;
  sortBy?: 'distance' | 'price' | 'rating' | 'capacity';
  page?: number;             // default: 0
  pageSize?: number;         // default: 20
}

interface SpaceSearchResult {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  address: string;
  lat: number;
  lon: number;
  distanceKm: number;        // Calculado desde punto de búsqueda
  capacity: number;
  basePriceCents: number;
  amenities: string[];
  avgRating: number;
  totalReviews: number;
  status: string;
}

interface SearchResponse {
  spaces: SpaceSearchResult[];
  totalResults: number;
  page: number;
  pageSize: number;
  totalPages: number;
  searchLat: number;
  searchLon: number;
  searchRadiusKm: number;
}

// Ejemplo de uso
async function searchSpaces(lat: number, lon: number) {
  const { data } = await apiClient.get<SearchResponse>('/search/spaces', {
    params: { lat, lon, radius: 5, minCapacity: 4 }
  });
  return data.spaces;
}
```

### Gestión de Espacios (Host)

```typescript
// POST /api/catalog/spaces (requiere JWT + rol HOST)
interface CreateSpaceDTO {
  title: string;
  description: string;
  ownerId: string;           // Del JWT
  address: string;
  lat: number;
  lon: number;
  capacity: number;
  basePriceCents: number;
  areaSqm?: number;
  amenities?: string[];
  rules?: Record<string, any>;
}

// GET /api/catalog/spaces/{id}
// PUT /api/catalog/spaces/{id}
// POST /api/catalog/spaces/{id}/activate

// GET /api/catalog/spaces/owner/{ownerId}
// Response: Space[]
```

### Reservas

```typescript
// POST /api/booking/bookings (requiere JWT)
interface CreateBookingDTO {
  spaceId: string;
  guestId: string;           // Del JWT
  startTs: string;           // ISO 8601: "2025-11-01T10:00:00"
  endTs: string;
  numGuests: number;
}

interface BookingResponse {
  id: string;
  spaceId: string;
  guestId: string;
  startTs: string;
  endTs: string;
  numGuests: number;
  totalPriceCents: number;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  paymentStatus: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded';
  paymentIntentId?: string;
  cancellationReason?: string;
  createdAt: string;
  updatedAt: string;
}

// POST /api/booking/bookings/{id}/confirm?paymentIntentId=pi_xxx
// POST /api/booking/bookings/{id}/complete
// POST /api/booking/bookings/{id}/cancel?reason=xxx

// GET /api/booking/bookings/guest/{guestId}
// Response: Booking[]
```

### Reseñas

```typescript
// POST /api/booking/reviews (requiere JWT)
interface CreateReviewDTO {
  bookingId: string;
  spaceId: string;
  guestId: string;
  rating: number;            // 1-5
  comment?: string;
}

// GET /api/booking/reviews/space/{spaceId}
// Response: Review[]
```

---

## 🗂️ Estructura del Proyecto Frontend

### Recomendación de Organización

```
balconazo-frontend/
├── public/
│   └── favicon.ico
├── src/
│   ├── api/                       # Llamadas a la API
│   │   ├── auth.api.ts
│   │   ├── spaces.api.ts
│   │   ├── bookings.api.ts
│   │   └── search.api.ts
│   ├── components/                # Componentes reutilizables
│   │   ├── Button/
│   │   ├── Card/
│   │   ├── Modal/
│   │   ├── Navbar/
│   │   └── ...
│   ├── features/                  # Módulos por funcionalidad
│   │   ├── auth/
│   │   │   ├── LoginForm.tsx
│   │   │   ├── RegisterForm.tsx
│   │   │   └── useAuth.hook.ts
│   │   ├── search/
│   │   │   ├── SearchMap.tsx
│   │   │   ├── SearchFilters.tsx
│   │   │   ├── SpaceCard.tsx
│   │   │   └── useSearch.hook.ts
│   │   ├── spaces/
│   │   │   ├── CreateSpaceForm.tsx
│   │   │   ├── EditSpaceForm.tsx
│   │   │   ├── SpaceDetail.tsx
│   │   │   └── useSpaces.hook.ts
│   │   └── bookings/
│   │       ├── BookingWizard.tsx
│   │       ├── BookingList.tsx
│   │       ├── BookingDetail.tsx
│   │       └── useBookings.hook.ts
│   ├── layouts/
│   │   ├── MainLayout.tsx
│   │   └── AuthLayout.tsx
│   ├── pages/
│   │   ├── HomePage.tsx
│   │   ├── SearchPage.tsx
│   │   ├── SpaceDetailPage.tsx
│   │   ├── BookingPage.tsx
│   │   ├── DashboardPage.tsx
│   │   └── ProfilePage.tsx
│   ├── store/                     # State management
│   │   ├── authStore.ts
│   │   └── searchStore.ts
│   ├── types/                     # TypeScript types
│   │   ├── auth.types.ts
│   │   ├── space.types.ts
│   │   └── booking.types.ts
│   ├── utils/
│   │   ├── dateUtils.ts
│   │   ├── priceUtils.ts
│   │   └── validationUtils.ts
│   ├── styles/
│   │   ├── variables.scss
│   │   └── mixins.scss
│   ├── App.tsx
│   └── main.tsx
├── .env
├── .env.example
├── package.json
└── tsconfig.json
```

---

## 📝 Convenciones y Buenas Prácticas

### URLs y Rutas

**Convención de URLs frontend:**
```
/                      → Página de inicio
/search                → Búsqueda de espacios
/spaces/:id            → Detalle de espacio
/bookings              → Mis reservas
/bookings/:id          → Detalle de reserva
/host/dashboard        → Dashboard del host
/host/spaces           → Gestión de espacios
/host/spaces/new       → Crear espacio
/host/spaces/:id/edit  → Editar espacio
/profile               → Perfil del usuario
/login                 → Login
/register              → Registro
```

### Headers HTTP

**Headers obligatorios en requests autenticados:**
```http
Content-Type: application/json
Authorization: Bearer {accessToken}
```

**Headers opcionales:**
```http
Accept-Language: es-ES
X-Client-Version: 1.0.0
```

### Estructura de Datos Esperada

**Fechas:** ISO 8601 (`2025-11-01T10:00:00`)  
**Precios:** Siempre en centavos (2500 = 25.00€)  
**Coordenadas:** Latitud antes que Longitud (`lat, lon`)  
**IDs:** UUID v4 como strings  
**Roles:** Uppercase (`HOST`, `GUEST`, `ADMIN`)  
**Estados:** Lowercase (`pending`, `confirmed`)

### Manejo de Errores

```typescript
interface ErrorResponse {
  timestamp: string;
  status: number;
  error: string;
  message: string;
  errors?: Record<string, string>;  // Errores de validación
}

// Ejemplo de manejo
try {
  await createBooking(data);
} catch (error) {
  if (axios.isAxiosError(error)) {
    const errorData = error.response?.data as ErrorResponse;
    
    if (errorData.errors) {
      // Errores de validación por campo
      setFormErrors(errorData.errors);
    } else {
      // Error general
      showToast(errorData.message, 'error');
    }
  }
}
```

---

## ⚠️ Problemas Comunes y Soluciones

### 1. CORS Error

**Problema:**
```
Access to XMLHttpRequest at 'http://localhost:8080/api/auth/login' 
from origin 'http://localhost:5173' has been blocked by CORS policy
```

**Solución:**
- El API Gateway ya tiene CORS configurado
- Asegúrate de usar `http://localhost:8080` (no IP)
- Si usas HTTPS en frontend, backend debe tener HTTPS

### 2. JWT Expirado

**Problema:**
```
401 Unauthorized - JWT token expired
```

**Solución:**
- Implementar refresh token automático en interceptor
- Redirigir a login si refresh falla
- Mostrar countdown antes de expiración (opcional)

### 3. Fechas Incorrectas

**Problema:**
```
400 Bad Request - Invalid date format
```

**Solución:**
```typescript
// ✅ Correcto
const startTs = new Date('2025-11-01T10:00:00').toISOString();

// ❌ Incorrecto
const startTs = '01/11/2025 10:00';
```

### 4. Precios en Centavos

**Problema:**
Usuario ve 2500€ en lugar de 25.00€

**Solución:**
```typescript
function formatPrice(cents: number): string {
  return `${(cents / 100).toFixed(2)}€`;
}

// 2500 → "25.00€"
```

### 5. Mapas No Cargan (Leaflet)

**Problema:**
Mapa aparece gris/blanco

**Solución:**
```typescript
// Importar CSS de Leaflet
import 'leaflet/dist/leaflet.css';

// Configurar iconos por defecto
import L from 'leaflet';
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png';
import iconUrl from 'leaflet/dist/images/marker-icon.png';
import shadowUrl from 'leaflet/dist/images/marker-shadow.png';

delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl,
  iconUrl,
  shadowUrl
});
```

### 6. Local Storage No Persiste en Incógnito

**Solución:**
- Validar `typeof Storage !== 'undefined'`
- Fallback a memoria temporal
- Avisar al usuario

---

## 📚 Recursos y Documentación

### Documentación del Backend

- **README.md**: Inicio rápido y arquitectura
- **DOCUMENTATION.md**: Detalles técnicos completos
- **DATABASE.md**: Esquemas de base de datos
- **POSTMAN_ENDPOINTS.md**: Lista completa de endpoints con ejemplos

### Herramientas Recomendadas

- **Postman/Insomnia**: Testing de API
- **Redux DevTools**: Debugging de estado (React)
- **Angular DevTools**: Debugging de componentes (Angular)
- **React Query DevTools**: Debugging de cache de datos

### Librerías Útiles

**UI Components:**
- Angular Material / MUI / Ant Design / Chakra UI
- TailwindCSS para estilos utility-first

**Mapas:**
- Leaflet (open source, recomendado)
- Google Maps API (requiere API key de pago)

**Formularios:**
- React Hook Form / Formik (React)
- Reactive Forms (Angular nativo)

**Date Pickers:**
- date-fns / dayjs (lightweight)
- moment.js (legacy)

**Charts:**
- Chart.js / Recharts (simple)
- D3.js (avanzado)

---

## 🎨 Sugerencias UX

### Flujo de Usuario Ideal

1. **Homepage**: Búsqueda prominente con mapa
2. **Resultados**: Cards con imagen, precio, rating, distancia
3. **Detalle**: Galería, descripción, mapa, calendario, reviews
4. **Booking**: Wizard de 3 pasos (fecha → invitados → pago)
5. **Confirmación**: Email + vista de resumen

### Consideraciones de UX

- **Skeleton screens** durante carga
- **Infinite scroll** en listados largos
- **Optimistic UI updates** en acciones (like, bookmark)
- **Toast notifications** para confirmaciones
- **Empty states** con CTAs claros
- **Error boundaries** para fallos inesperados
- **Responsive** mobile-first

---

## 🚀 Próximos Pasos

1. **Setup del proyecto** (día 1)
2. **Módulo de autenticación** (3-4 días)
3. **Búsqueda con mapa** (5 días)
4. **Detalle y booking** (5 días)
5. **Dashboard host** (5 días)
6. **Reviews y perfil** (3 días)

**Total estimado:** 3-4 semanas para MVP funcional

---

**¿Dudas? Consulta:**
- Documentación técnica: `DOCUMENTATION.md`
- Endpoints completos: `POSTMAN_ENDPOINTS.md`
- Esquema de BD: `DATABASE.md`

**¡Éxito con el desarrollo frontend! 🚀**

