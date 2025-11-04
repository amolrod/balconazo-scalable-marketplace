# 🏠 Balconazo Frontend

Marketplace de alquiler de espacios (terrazas/balcones) - Frontend en Angular 20

---

## 🚀 Quick Start

```bash
# Instalar dependencias
npm install

# Desarrollo
npm start
# → http://localhost:4200

# Build producción
npm run build

# Tests
npm test

# Herramientas de desarrollo (menú interactivo)
./dev-tools.sh
```

---

## 📁 Estructura del Proyecto

```
src/app/
├── core/           # Guards, services, models, interceptors
├── features/       # Módulos por feature (auth, home, search, host, etc.)
├── shared/         # Componentes reutilizables
└── styles/         # Design system (tokens, utilities, animations)
```

---

## 🎨 Design System (PR #1 - ✅ Completado)

### Tokens CSS
- ✅ 180+ design tokens organizados
- ✅ Colores (Primary, Gray, Semantic)
- ✅ Spacing, Typography, Shadows, Radius
- ✅ Transiciones, Z-index, Layout

### Utilidades
- ✅ 100+ clases utility (flex, grid, spacing, etc.)
- ✅ Responsive mobile-first
- ✅ Accesibilidad (sr-only, focus-visible)

### Animaciones
- ✅ 20+ animaciones profesionales
- ✅ Hover effects, loading states, transitions

**Documentación**: `PR-1-DESIGN-SYSTEM.md`

---

## 📚 Documentación Completa

| Archivo | Descripción |
|---------|-------------|
| `PR-1-DESIGN-SYSTEM.md` | Documentación completa PR #1 |
| `PR-1-ENTREGA.md` | Resumen de entrega PR #1 |
| `../ROADMAP-FRONTEND.md` | Roadmap completo (8 PRs) |

---

## 🛠️ Stack Tecnológico

- **Angular 20.3** (Standalone Components + SSR)
- **RxJS 7.8** (State management)
- **Leaflet 1.9.4** (Mapas interactivos)
- **ngx-toastr 19.1.0** (Notificaciones)
- **@auth0/angular-jwt 5.2.0** (JWT handling)
- **SCSS** (Design system modular)
- **Karma + Jasmine** (Testing)

---

## 📦 Build Output

```
✅ Build exitoso
styles.css:  25.06 kB → 5.10 kB (gzip)
main.js:     505 kB → 119 kB (gzip)
```

---

## 🎯 Roadmap de PRs

| PR | Estado | Descripción |
|----|--------|-------------|
| #1 | ✅ Completado | Design System & Tokens |
| #2 | 📋 Pendiente | Core Infrastructure (Guards, Pipes, Utils) |
| #3 | 📋 Pendiente | Shared Components (SpaceCard, FilterBar, etc.) |
| #4 | 📋 Pendiente | Navbar 2.0 + App Shell |
| #5 | 📋 Pendiente | Home Redesign (Hero + Search) |
| #6 | 📋 Pendiente | Search/Explore Page (Mapa + Filtros) |
| #7 | 📋 Pendiente | Space Detail Enhanced |
| #8 | 📋 Pendiente | Host Dashboard 2.0 |

**Ver**: `../ROADMAP-FRONTEND.md` para detalles completos

---

## 🧪 Testing

```bash
# Unit tests
npm test

# Con coverage
npm run test:coverage
```

---

## 💅 Code Quality

```bash
# Format con Prettier
npx prettier --write "src/**/*.{ts,html,scss}"

# Lint (si configurado)
npm run lint
```

---

## 📊 Performance

```bash
# Lighthouse audit
npx lighthouse http://localhost:4200 --view
```

**Targets**:
- Performance: >90
- Accessibility: >90
- Best Practices: >90
- SEO: >90

---

## 🌐 Backend API

**API Gateway**: `http://localhost:8080/api`

**Endpoints principales**:
- `/auth/*` - Autenticación
- `/catalog/spaces/*` - Gestión de espacios
- `/search/spaces` - Búsqueda geográfica
- `/booking/*` - Reservas

**Configuración**: `src/environments/environment.ts`

---

## 👥 Roles

- **GUEST**: Buscar, reservar, reviews
- **HOST**: Gestionar espacios, ver reservas
- **ADMIN**: (futuro)

---

## 🚧 Estado Actual (Post PR #1)

### ✅ Funcional
- Login/Registro
- Home con listado de espacios
- Navbar básica
- Dashboard de Host (CRUD espacios + fotos)
- Detalle de espacio
- Sistema de diseño completo

### 🔜 Por Implementar (PRs futuros)
- Navbar 2.0 con menú por rol
- Búsqueda avanzada con mapa
- Filtros y ordenamiento
- Reviews y ratings
- Favoritos
- Notificaciones
- Wizard de creación de espacios
- Métricas de host

---

## 📝 Comandos Útiles

```bash
# Desarrollo
npm start                          # http://localhost:4200
npm run build                      # Build producción
npm test                           # Unit tests
npm run test:coverage              # Coverage

# Formato
npx prettier --write "src/**/*.{ts,html,scss}"

# Herramientas
./dev-tools.sh                     # Menú interactivo

# Lighthouse
npx lighthouse http://localhost:4200 --view
```

---

## 🤝 Contribuir

1. Revisar roadmap en `../ROADMAP-FRONTEND.md`
2. Crear branch: `feat/pr-N-nombre`
3. Implementar cambios
4. Tests + Lint
5. PR con documentación

---

## 📄 Licencia

Proyecto privado - Balconazo App

---

## 👤 Autor

Lead Frontend Engineer (AI Agent)

---

## 🙏 Agradecimientos

Stack moderno de Angular + diseño inspirado en Airbnb/Peerspace/Booking.

**¡Construyamos algo increíble! 🚀**

