# 🚀 BALCONAZO FRONTEND UPGRADE - RESUMEN EJECUTIVO

## 📊 DIAGNÓSTICO COMPLETADO

### Stack Técnico Confirmado
- ✅ **Angular 20.3** (Standalone Components + SSR)
- ✅ **RxJS 7.8** (State management reactivo)
- ✅ **Leaflet 1.9.4** (Mapas - ya instalado)
- ✅ **ngx-toastr 19.1.0** (Notificaciones - ya instalado)
- ✅ **@auth0/angular-jwt 5.2.0** (JWT handling - ya instalado)
- ✅ **SCSS** como preprocesador
- ✅ **Prettier** configurado
- ✅ **Karma + Jasmine** para testing

### Arquitectura Actual Detectada
```
✅ Core: guards, services, models, interceptors (bien estructurado)
✅ Features: auth, bookings, home, host, spaces (modular)
⚠️  Shared: Casi vacío (necesita componentes reutilizables)
⚠️  Search: Carpeta vacía (por implementar)
```

### Backend Endpoints Disponibles
- `/api/auth/*` - Login, register, me, refresh ✅
- `/api/catalog/spaces/*` - CRUD espacios ✅
- `/api/search/spaces` - Búsqueda geográfica ✅
- `/api/booking/*` - Reservas ✅
- `/api/catalog/spaces/{id}/images` - Gestión imágenes ✅

---

## 🎯 ROADMAP DE 8 PRs (PLAN COMPLETO)

### **PR #1: Design System & Tokens Foundation** 🎨 ✅ COMPLETADO
**Estado**: Ready to merge
**Archivos**: 
- ✨ `src/styles/_tokens.scss` (380 líneas)
- ✨ `src/styles/_utilities.scss` (310 líneas)
- ✨ `src/styles/_animations.scss` (280 líneas)
- 🔄 `src/styles.scss` (refactorizado, 667 líneas)

**Logros**:
- ✅ Sistema de tokens completo (colores, spacing, tipografía, shadows, etc.)
- ✅ 100+ clases utility reutilizables
- ✅ 20+ animaciones profesionales
- ✅ Componentes base mejorados (buttons, forms, cards, badges)
- ✅ Responsive mobile-first
- ✅ Accesibilidad WCAG AA
- ✅ Build exitoso: 25KB CSS → 5KB (gzip)

**Documentación**: `PR-1-DESIGN-SYSTEM.md`

---

### **PR #2: Core Infrastructure (Guards, Pipes, Utils)** 🔧
**Objetivo**: Crear infraestructura reutilizable (guards, pipes, utils, interceptores, models).

**Archivos a crear**:
```typescript
// Guards
src/app/core/guards/role.guard.ts          // Genérico (HOST/GUEST)
src/app/core/guards/guest.guard.ts

// Interceptors
src/app/core/interceptors/error.interceptor.ts  // Global error handling

// Pipes
src/app/shared/pipes/price.pipe.ts         // cents → €2.50
src/app/shared/pipes/distance.pipe.ts      // 1500 → 1.5 km
src/app/shared/pipes/date-relative.pipe.ts // "hace 2 días"

// Utils
src/app/core/utils/price.utils.ts
src/app/core/utils/date.utils.ts
src/app/core/utils/validators.ts

// Models
src/app/core/models/review.model.ts
src/app/core/models/notification.model.ts
src/app/core/models/filter.model.ts

// Tests
*.spec.ts para cada archivo
```

**Criterios de aceptación**:
- [ ] Guards funcionan (redirect según rol)
- [ ] Pipes transforman correctamente
- [ ] Error interceptor muestra toasts
- [ ] Tests unitarios >80% coverage
- [ ] Build sin errores

**Estimación**: 4-6 horas

---

### **PR #3: Shared Components Foundation** 🧩
**Objetivo**: Componentes reutilizables clave.

**Componentes a crear**:
```typescript
SpaceCard          // Card de espacio (imagen, precio, rating, ubicación)
FilterBar          // Barra de filtros (precio, capacidad, fecha, amenities)
RatingStars        // Estrellas de rating
SkeletonList       // Loading skeletons
EmptyState         // Estados vacíos
ConfirmDialog      // Modal de confirmación
AmenityChips       // Badges de amenities
PriceRange         // Slider doble de precio
CapacitySelector   // Selector de capacidad

// Directives
LazyLoadImage      // Lazy loading de imágenes
InfiniteScroll     // Scroll infinito
```

**Estructura por componente**:
```
src/app/shared/components/space-card/
  ├── space-card.component.ts
  ├── space-card.component.html
  ├── space-card.component.scss
  └── space-card.component.spec.ts
```

**Criterios de aceptación**:
- [ ] SpaceCard responsive con hover
- [ ] FilterBar emite eventos correctamente
- [ ] RatingStars muestra estrellas llenas/vacías
- [ ] Skeletons con pulse animation
- [ ] EmptyState con ilustración
- [ ] ConfirmDialog modal funcional
- [ ] Tests unitarios
- [ ] Página /showcase temporal para demo

**Estimación**: 8-10 horas

---

### **PR #4: Navbar 2.0 + App Shell + User Menu** 🧭
**Objetivo**: Navbar profesional sticky, responsive, con menú por rol.

**Componentes**:
```typescript
Navbar             // Sticky navbar con scroll effect
UserMenu           // Dropdown por rol
AppShell           // Layout wrapper (navbar + router-outlet + footer)
```

**Features**:
- Sticky con backdrop-filter blur
- Logo gradient animado
- Buscador compacto (mini hero search)
- CTA "Publica tu espacio" (solo HOST)
- User menu dropdown:
  - No auth: Login, Registro
  - GUEST: Perfil, Mis Reservas, Favoritos, Logout
  - HOST: Mis Espacios, Notificaciones, Logout
- Mobile menu (hamburger)
- Navegación por teclado (accesibilidad)

**Archivos**:
```
src/app/shared/components/navbar/*
src/app/shared/components/user-menu/*
src/app/shared/components/app-shell/*
src/app/app.ts (refactor para usar AppShell)
src/app/app.html (refactor)
```

**Criterios de aceptación**:
- [ ] Navbar sticky con transición suave
- [ ] Menú correcto por rol
- [ ] User menu dropdown funcional
- [ ] Mobile responsive (hamburger)
- [ ] Accesibilidad (Tab, Enter, Esc)
- [ ] Build sin errores

**Estimación**: 6-8 horas

---

### **PR #5: Home Redesign (Hero + Search + Collections)** 🏠
**Objetivo**: Home atractiva estilo Airbnb.

**Componentes**:
```typescript
HeroSearch         // Buscador principal (fechas, ubicación, capacidad)
Collections        // Chips temáticos ("Terrazas con vista", "Para eventos")
```

**Features**:
- Hero con gradient background
- Buscador principal con iconos
- Navegación a /search con params
- Secciones de colecciones/temáticas
- Listado destacados (usando SpaceCard)
- Skeletons mientras carga
- Animaciones de entrada (fade-in, slide-up)

**Archivos**:
```
src/app/features/home/home.ts (refactor)
src/app/features/home/home.html (refactor)
src/app/features/home/home.scss (refactor)
src/app/features/home/components/hero-search/*
src/app/features/home/components/collections/*
```

**Criterios de aceptación**:
- [ ] Hero atractivo con buscador
- [ ] Buscador funcional → /search?...
- [ ] Listado destacados con SpaceCard
- [ ] Skeletons mientras carga
- [ ] Responsive mobile-first
- [ ] Lighthouse: Performance >90, LCP <2.5s

**Estimación**: 6-8 horas

---

### **PR #6: Search/Explore Page (Mapa + Lista + Filtros)** 🗺️
**Objetivo**: Página de exploración pública con mapa (Leaflet), filtros y scroll infinito.

**Componentes**:
```typescript
SearchResults      // Layout mapa + lista
SpaceList          // Grid/lista toggle
SpaceMap           // Wrapper Leaflet
SearchHeader       // Filtros, orden, view toggle
MapViewer          // Componente reutilizable de mapa
```

**Features**:
- Mapa interactivo (Leaflet) con marcadores
- Click en marcador → highlight en lista
- Filtros: precio, capacidad, fecha, radio, amenities, rating
- Orden: distancia, precio, rating
- Infinite scroll (directive)
- Estados: loading (skeletons), empty, error
- Responsive: mobile (mapa colapsable), desktop (split)

**Servicios**:
```typescript
src/app/core/services/search.service.ts  // API /api/search/spaces
```

**Archivos**:
```
src/app/features/search/search-results/*
src/app/features/search/search-results/components/*
src/app/shared/components/map-viewer/*
src/app/app.routes.ts (añadir /search)
```

**Criterios de aceptación**:
- [ ] Mapa muestra marcadores
- [ ] Click marcador → highlight lista
- [ ] Filtros funcionan correctamente
- [ ] Infinite scroll carga más
- [ ] Responsive (mobile/desktop)
- [ ] Accesibilidad (filtros con teclado)
- [ ] Performance: Virtual scroll si >50 items

**Estimación**: 10-12 horas

---

### **PR #7: Space Detail Enhanced (Galería + Reviews + Booking)** 🏡
**Objetivo**: Detalle de espacio con galería, mapa, reviews y CTA reserva.

**Componentes**:
```typescript
SpaceGallery       // Slider/grid con lightbox
SpaceAmenities     // Grid con iconos
SpaceLocation      // Mapa mini + dirección
SpaceReviews       // Listado + form para dejar review
```

**Features**:
- Galería profesional (slider/grid, lightbox, thumbnails)
- Mapa Leaflet mini con ubicación exacta
- Reviews con rating promedio
- Form para dejar review (solo GUEST con reserva)
- CTA "Reservar" sticky (precio + botón)
- Calendario de disponibilidad (tabla simple)
- Breadcrumbs

**Servicios**:
```typescript
src/app/core/services/reviews.service.ts  // GET/POST reviews
```

**Archivos**:
```
src/app/features/spaces/space-detail/* (refactor)
src/app/features/spaces/components/*
src/app/core/services/reviews.service.ts
src/app/core/models/review.model.ts
```

**Criterios de aceptación**:
- [ ] Galería responsive con lightbox
- [ ] Mapa muestra ubicación
- [ ] Reviews cargadas y ordenadas
- [ ] CTA sticky funcional
- [ ] Form review valida campos
- [ ] Imágenes lazy load
- [ ] Accesibilidad (galería con teclado)

**Estimación**: 8-10 horas

---

### **PR #8: Host Dashboard 2.0 (Wizard + Métricas + Management)** 🎛️
**Objetivo**: Dashboard de host profesional.

**Componentes**:
```typescript
SpaceWizard        // Crear/editar en 5 pasos
SpaceMetrics       // Métricas mock (visitas, reservas, rating)
SpaceBookings      // Reservas por espacio
```

**Features**:
- Wizard multi-paso:
  1. Info básica (título, descripción)
  2. Ubicación (mapa + coordenadas)
  3. Precio + capacidad
  4. Amenities (checkboxes)
  5. Fotos (drag & drop)
- Métricas mock con tarjetas
- Listado con acciones rápidas (Activar/Pausar/Eliminar)
- Estados con badges (ACTIVE, SNOOZED, DRAFT)
- Confirmación antes de eliminar
- Toasts en todas las acciones
- Routing lazy por feature

**Rutas**:
```typescript
/host/dashboard         // Overview + listado
/host/spaces/new        // Wizard crear
/host/spaces/:id/edit   // Wizard editar
/host/spaces/:id/bookings // Reservas del espacio
```

**Archivos**:
```
src/app/features/host/host-dashboard/* (refactor)
src/app/features/host/space-wizard/*
src/app/features/host/space-metrics/*
src/app/features/host/space-bookings/*
src/app/app.routes.ts (rutas lazy)
```

**Criterios de aceptación**:
- [ ] Wizard funciona en 5 pasos
- [ ] Validaciones por paso
- [ ] Métricas mock con diseño profesional
- [ ] CRUD funciona (crear/editar/pausar/eliminar)
- [ ] Confirmación antes de eliminar
- [ ] Toasts informativos
- [ ] Responsive
- [ ] Tests e2e del flujo completo

**Estimación**: 10-12 horas

---

## 📊 RESUMEN DE ESTIMACIONES

| PR | Nombre | Horas | Estado |
|----|--------|-------|--------|
| #1 | Design System & Tokens | 6h | ✅ COMPLETADO |
| #2 | Core Infrastructure | 4-6h | 📋 Pendiente |
| #3 | Shared Components | 8-10h | 📋 Pendiente |
| #4 | Navbar 2.0 + App Shell | 6-8h | 📋 Pendiente |
| #5 | Home Redesign | 6-8h | 📋 Pendiente |
| #6 | Search/Explore Page | 10-12h | 📋 Pendiente |
| #7 | Space Detail Enhanced | 8-10h | 📋 Pendiente |
| #8 | Host Dashboard 2.0 | 10-12h | 📋 Pendiente |
| **TOTAL** | **58-72 horas** | **~2 semanas** | |

---

## ✅ CHECKLIST GLOBAL DE CALIDAD

### Accesibilidad (WCAG AA)
- [x] Contraste de colores ≥ 4.5:1
- [x] Focus visible en todos los interactivos
- [ ] Navegación por teclado (Tab, Enter, Esc)
- [ ] ARIA labels en iconos/botones sin texto
- [ ] Roles semánticos (nav, main, article)
- [ ] Alt text en imágenes
- [ ] Form labels asociados
- [ ] Skip links
- [ ] Modales trapean foco

### Performance
- [x] CSS optimizado (25KB → 5KB gzip)
- [ ] OnPush change detection en componentes pesados
- [ ] Lazy loading por feature
- [ ] Lazy images (loading="lazy")
- [ ] Virtual scroll en listas >50 items
- [ ] Tree-shakeable imports
- [ ] Production build optimizado
- [ ] Lighthouse >90 (Performance, Accessibility)
- [ ] LCP < 2.5s, FID < 100ms, CLS < 0.1

### Testing
- [ ] Unit tests: guards, pipes, services (>80% coverage)
- [ ] Component tests: componentes clave
- [ ] E2E tests: flujos críticos (login, crear espacio, reservar)
- [ ] Visual regression tests (opcional)

### Código
- [x] Tipado estricto TypeScript
- [x] Linting sin errores (Prettier configurado)
- [ ] Componentes standalone reutilizables
- [ ] Services con RxJS operators
- [ ] Error handling robusto
- [ ] Documentación inline (JSDoc)

---

## 🚀 COMANDOS PRINCIPALES

```bash
# Desarrollo
npm start                    # http://localhost:4200

# Build
npm run build                # Producción

# Testing
npm test                     # Unit tests
npm run test:coverage        # Con coverage

# Linting
npx prettier --write "src/**/*.{ts,html,scss}"

# Lighthouse
npx lighthouse http://localhost:4200 --view
```

---

## 📁 ESTRUCTURA FINAL (Post PR #8)

```
src/app/
├── core/
│   ├── guards/
│   │   ├── auth.guard.ts ✅
│   │   ├── role.guard.ts 🆕
│   │   └── guest.guard.ts 🆕
│   ├── interceptors/
│   │   └── error.interceptor.ts 🆕
│   ├── models/
│   │   ├── auth.model.ts ✅
│   │   ├── space.model.ts ✅
│   │   ├── booking.model.ts ✅
│   │   ├── review.model.ts 🆕
│   │   ├── notification.model.ts 🆕
│   │   └── filter.model.ts 🆕
│   ├── services/
│   │   ├── auth.service.ts ✅
│   │   ├── spaces.service.ts ✅
│   │   ├── bookings.service.ts ✅
│   │   ├── search.service.ts 🆕
│   │   ├── reviews.service.ts 🆕
│   │   └── toast.service.ts ✅
│   └── utils/
│       ├── price.utils.ts 🆕
│       ├── date.utils.ts 🆕
│       └── validators.ts 🆕
│
├── features/
│   ├── auth/ ✅
│   ├── home/ 🔄
│   ├── search/ 🆕
│   ├── spaces/ 🔄
│   ├── bookings/ ✅
│   ├── host/ 🔄
│   ├── favorites/ 🆕 (stub)
│   └── notifications/ 🆕 (stub)
│
├── shared/
│   ├── components/
│   │   ├── navbar/ 🆕 ⭐
│   │   ├── app-shell/ 🆕
│   │   ├── space-card/ 🆕 ⭐
│   │   ├── filter-bar/ 🆕
│   │   ├── rating-stars/ 🆕
│   │   ├── skeleton-list/ 🆕
│   │   ├── empty-state/ 🆕
│   │   ├── confirm-dialog/ 🆕
│   │   ├── amenity-chips/ 🆕
│   │   ├── price-range/ 🆕
│   │   ├── capacity-selector/ 🆕
│   │   ├── map-viewer/ 🆕
│   │   └── user-menu/ 🆕
│   ├── pipes/
│   │   ├── price.pipe.ts 🆕
│   │   ├── distance.pipe.ts 🆕
│   │   └── date-relative.pipe.ts 🆕
│   ├── directives/
│   │   ├── lazy-load-image.directive.ts 🆕
│   │   └── infinite-scroll.directive.ts 🆕
│   └── image-gallery-manager/ ✅
│
└── styles/
    ├── _tokens.scss ✅
    ├── _utilities.scss ✅
    ├── _animations.scss ✅
    └── styles.scss ✅
```

**Leyenda**:
- ✅ Ya existe (funcional)
- 🔄 Refactorizar/Mejorar
- 🆕 Por crear
- ⭐ Componente crítico

---

## 🎯 PRÓXIMOS PASOS INMEDIATOS

### Para continuar con PR #2:
1. ✅ Merge PR #1 a main
2. Crear branch: `feat/pr-2-core-infrastructure`
3. Implementar guards, pipes, utils
4. Tests unitarios
5. PR review

### Entrega Esperada (PR #2):
- Código completo con tests
- README del PR
- Build exitoso
- Coverage >80%

---

**Estado Actual**: ✅ PR #1 COMPLETADO Y LISTO PARA MERGE
**Próximo**: 🚀 PR #2 - Core Infrastructure

**Fecha**: 2025-11-04
**Autor**: Lead Frontend Engineer

