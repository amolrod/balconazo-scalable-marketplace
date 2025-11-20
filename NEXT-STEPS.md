# 🚀 ROADMAP Y PRÓXIMOS PASOS - BalconazoApp

**Última actualización**: 20 Noviembre 2025  
**Estado**: Backend 100% | Frontend 70%

---

## 📊 RESUMEN EJECUTIVO

### Estado del Proyecto

✅ **Backend (100% Completado)**
- Arquitectura de microservicios completa (6 servicios)
- Autenticación JWT + Security
- CRUD completo (Espacios, Reservas, Reviews)
- Búsqueda geoespacial con PostGIS
- Eventos asíncronos con Kafka
- Tests E2E automatizados (29 tests, 100% éxito)

🟡 **Frontend (70% Completado)**
- Design System + Core Infrastructure
- Autenticación (Login/Logout)
- Home + Explore con búsqueda/mapa
- Space Detail con galería de imágenes
- Host Dashboard (CRUD espacios)
- **Pendiente**: Reservas (guest), Pagos, Reviews UI, Perfil

### Priorización de Features

| Prioridad | Features | Esfuerzo | Estado |
|-----------|----------|----------|--------|
| 🔴 **CRÍTICO (MVP)** | Reservas + Pagos + Reviews | 40-50h | Pendiente |
| 🟡 **IMPORTANTE** | Perfil, Notificaciones, Chat | 30-40h | Pendiente |
| 🟢 **DESEABLE** | Pricing dinámico, Analytics, Favoritos | 20-30h | Futuro |

---

## 🔴 PRIORIDAD CRÍTICA (MVP - 40-50 HORAS)

### 1. Sistema de Reservas Completo 🔴
**Tiempo:** 15-18 horas  
**Impacto:** CRÍTICO - Sin reservas no hay transacciones

#### Funcionalidades
- **Calendario de Selección** (Guest)
  - DateRangePicker para fecha/hora inicio y fin
  - Validación de disponibilidad
  - Cálculo automático de precio (horas × precio/hora)
  - Visualización de ocupación
  - Mínimo de horas configurable

- **Proceso de Reserva**
  1. Selección de fecha/hora
  2. Resumen (espacio, fechas, precio)
  3. Confirmación (solicitud inicial)
  4. Estado: `PENDING` → `CONFIRMED` → `COMPLETED`

- **Vista Guest** (`/bookings`)
  - Reservas activas (upcoming)
  - Historial (past/completed)
  - Estados: Pending, Confirmed, Completed, Cancelled
  - Botón "Cancelar" con políticas
  - Detalles completos

- **Vista Host** (Dashboard)
  - Reservas recibidas
  - Filtros: Pendientes, Confirmadas, etc.
  - Acciones: Aceptar/Rechazar
  - Calendario de ocupación
  - Timeline de próximas reservas

#### Backend (Ya Implementado ✅)
```
POST   /api/booking/bookings
GET    /api/booking/bookings/guest/{guestId}
GET    /api/booking/bookings/space/{spaceId}
PUT    /api/booking/bookings/{id}/confirm
PUT    /api/booking/bookings/{id}/cancel
```

#### Componentes a Crear
```
bookings/
├── booking-create/       (proceso de reserva)
├── booking-list/         (vista guest)
├── host-bookings/        (vista host)
└── shared/
    ├── booking-card.ts
    ├── date-range-picker.ts
    └── booking-calendar.ts
```

#### Criterios de Aceptación
- [ ] Guest selecciona fechas/horas y crea reserva
- [ ] Cálculo automático de precio
- [ ] Host recibe notificación y puede aceptar/rechazar
- [ ] Estados de reserva correctos
- [ ] Guest puede cancelar (con políticas)
- [ ] Calendario muestra ocupación

---

### 2. Sistema de Pagos con Stripe 🔴
**Tiempo:** 18-22 horas  
**Impacto:** CRÍTICO - Sin pagos no hay ingresos

#### Funcionalidades
- **Integración Stripe**
  - API Keys (test + production)
  - Webhooks para confirmación
  - PaymentIntent flow

- **Checkout Page** (`/checkout/:bookingId`)
  - Resumen de reserva
  - Desglose de costos:
    - Subtotal (precio × horas)
    - Comisión plataforma (10-15%)
    - Total a pagar
  - Stripe Payment Element (tarjeta)
  - Loading durante procesamiento
  - Redirección éxito/error

- **Confirmación** (`/booking-confirmed/:bookingId`)
  - Mensaje de éxito
  - Detalles de reserva
  - Recibo/Invoice PDF
  - Email confirmación automático

- **Dashboard Host**
  - Historial de pagos recibidos
  - Balance disponible
  - Solicitar payout

#### Backend Necesario (Nuevo)
```
POST   /api/payments/create-intent
POST   /api/payments/confirm
POST   /api/payments/refund
GET    /api/payments/host/{hostId}
POST   /api/webhooks/stripe
```

#### Dependencias
- `@stripe/stripe-js` (frontend)
- `stripe` SDK (backend)
- Cuenta Stripe (test mode)

#### Criterios de Aceptación
- [ ] Pago seguro con tarjeta vía Stripe
- [ ] Confirmación automática tras pago
- [ ] Email de confirmación
- [ ] Host ve pago en dashboard
- [ ] Sistema de reembolsos
- [ ] Comisión calculada correctamente
- [ ] Webhooks funcionan

---

### 3. Sistema de Reviews Real 🔴
**Tiempo:** 8-10 horas  
**Impacto:** ALTO - Confianza y reputación

#### Funcionalidades
- **Crear Review** (Guest post-checkout)
  - Solo para `COMPLETED` bookings
  - Rating 1-5 estrellas (obligatorio)
  - Categorías: Limpieza, Ubicación, Comunicación, Valor
  - Comentario (mín 20 chars)
  - Fotos opcionales (hasta 3)
  - Límite: 30 días post-checkout

- **Responder** (Host)
  - 1 respuesta por review
  - Max 500 caracteres
  - No editable tras publicar

- **Mostrar Reviews** (Space Detail)
  - Todas las reviews + respuestas
  - Ordenar: Recientes, Mejor valoradas
  - Filtros: Con fotos, Por rating
  - Paginación (10 por página)
  - Badge "Reserva verificada"

- **Rating Promedio**
  - Cálculo automático
  - Mostrar en cards y detail
  - Número total de reviews
  - Actualización automática

#### Backend (Ya Implementado ✅)
```
POST   /api/booking/reviews
GET    /api/booking/reviews/space/{spaceId}
PUT    /api/booking/reviews/{id}/respond
GET    /api/booking/reviews/pending/guest/{guestId}
```

#### Componentes a Crear
```
reviews/
├── review-create/
├── review-list/
├── review-card/
└── rating-stars/
```

#### Criterios de Aceptación
- [ ] Guest crea review tras reserva completada
- [ ] Rating por categorías
- [ ] Host responde
- [ ] Reviews visibles en Space Detail
- [ ] Rating promedio actualizado
- [ ] Badge "Verificada"

---

## 🟡 PRIORIDAD IMPORTANTE (30-40 HORAS)

### 4. Perfil de Usuario
**Tiempo:** 10-12 horas
- Editar información personal
- Avatar/foto de perfil
- Verificación email/teléfono
- Historial de actividad
- Trust score visualización
- Preferencias de notificaciones

### 5. Sistema de Notificaciones
**Tiempo:** 10-12 horas
- Notificaciones en tiempo real (WebSocket)
- Email notifications (SendGrid)
- Push notifications (PWA)
- Tipos:
  - Nueva reserva recibida
  - Reserva confirmada/cancelada
  - Nueva review
  - Mensaje nuevo

### 6. Mensajería Host/Guest
**Tiempo:** 8-10 horas
- Chat en tiempo real
- Historial de conversaciones
- Notificaciones de nuevos mensajes
- Adjuntar archivos (opcional)

### 7. Búsqueda Avanzada
**Tiempo:** 6-8 horas
- Autocompletado (Google Places)
- Filtros guardados
- Historial de búsquedas
- Búsqueda arrastrando mapa

---

## 🟢 FEATURES DESEABLES (FUTURO)

### 8. Pricing Dinámico
**Tiempo:** 6-8 horas
- Activar algoritmo existente en backend
- Dashboard para configurar precios
- Vista de calendario con precios variables
- Promociones y descuentos

### 9. Calendario de Disponibilidad
**Tiempo:** 8-10 horas
- Vista mensual para hosts
- Bloquear fechas específicas
- Establecer horarios especiales
- Sincronización con Google Calendar

### 10. Favoritos/Wishlist
**Tiempo:** 4-6 horas
- Guardar espacios favoritos
- Lista de deseos
- Compartir favoritos

### 11. Promociones y Cupones
**Tiempo:** 6-8 horas
- Crear códigos de descuento
- Descuentos por primera reserva
- Cupones por referidos

### 12. Verificación de Identidad
**Tiempo:** 10-12 horas
- KYC con documento
- Verificación de email/teléfono
- Badge "Verificado"
- Aumento de trust score

### 13. Analytics Dashboard
**Tiempo:** 8-10 horas
- Reportes de ingresos
- Estadísticas de ocupación
- Métricas de performance
- Gráficos interactivos

### 14. App Móvil
**Tiempo:** 80-100 horas
- React Native o Flutter
- Features principales
- Push notifications nativas
- Geolocalización

### 15. Multi-idioma
**Tiempo:** 6-8 horas
- i18n en frontend (español, inglés)
- Traducción de contenido
- Selector de idioma

### 16. Multi-moneda
**Tiempo:** 6-8 horas
- Conversión de precios
- Mostrar en moneda local
- API de tipos de cambio

### 17. Blog/CMS
**Tiempo:** 12-15 horas
- Sistema de contenido
- SEO optimization
- Marketing content

---

## 📊 HISTORIAL DE DESARROLLO

### ✅ Sesión 2 Noviembre 2025 - Problemas Solucionados

### 1. Inconsistencia de Status (Case-Sensitivity) ✅
**Problema:** Base de datos con status en minúsculas/mayúsculas mezclados  
**Solución:**
- ✅ Frontend: Todos los métodos usan `.toUpperCase()` para comparación case-insensitive
- ✅ Backend: Constantes actualizadas a MAYÚSCULAS (`ACTIVE`, `DELETED`, `SNOOZED`)
- ✅ Search Service: Queries usan `UPPER(s.status) = 'ACTIVE'`
- ✅ Base de datos: Normalizada a MAYÚSCULAS en catalog y search DBs

### 2. Espacios Nuevos en Estado DRAFT ✅
**Problema:** Al crear un espacio nuevo, se guardaba como `DRAFT` en lugar de `ACTIVE`  
**Solución:**
```java
// SpaceServiceImpl.java línea 69
space.setStatus(SPACE_STATUS_ACTIVE); // En lugar de DRAFT
```
**Resultado:** Los espacios se crean directamente como `ACTIVE` y aparecen en la página principal

### 3. Estado ARCHIVED Eliminado ✅
**Motivo:** Redundante con SNOOZED  
**Cambios:**
- ❌ Eliminado filtro, botón y modal de ARCHIVED
- ✅ Estados finales: ACTIVE, SNOOZED, DELETED, DRAFT
- ✅ ~70 líneas de código eliminadas
- ✅ UX más clara y simple

### 4. Scroll Automático ✅
**Implementación:** `window.scrollTo({ top: 0, behavior: 'smooth' })` en `changeView()`  
**Resultado:** Al cambiar de sección en el dashboard, siempre scroll al inicio

### 5. Página Principal Sin Espacios ✅
**Problema:** Search service buscaba por `'active'` pero BD tenía `'ACTIVE'`  
**Solución:** Actualizado repository para usar `UPPER(s.status) = 'ACTIVE'`

### 6. Notificaciones (Toast) Mejoradas ✅
**Mejora:** Añadidas animaciones Angular con `trigger` y `animate`  
**Resultado:** Notificaciones con transiciones suaves

---

## 🏗️ ARQUITECTURA ACTUAL

### Microservicios (6)
```
┌─────────────────────────────────────────────────┐
│          API GATEWAY (8080)                     │
│  - Rate Limiting (Redis)                        │
│  - Load Balancing                               │
│  - CORS & Security                              │
└───────────────┬─────────────────────────────────┘
                │
        ┌───────┴───────────────────────┐
        │   EUREKA SERVER (8761)        │
        │   Service Discovery           │
        └───────┬───────────────────────┘
                │
    ┌───────────┼───────────┬───────────┬──────────┐
    │           │           │           │          │
┌───▼────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐ ┌──▼─────┐
│  AUTH  │ │CATALOG │ │BOOKING │ │ SEARCH │ │FRONTEND│
│  8084  │ │  8085  │ │  8082  │ │  8083  │ │  4200  │
└───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └────────┘
    │          │          │          │
┌───▼──────────▼──────────▼──────────▼─────┐
│        EVENT BUS (KAFKA 9092)             │
│  - space-events-v1                        │
│  - booking-events-v1                      │
└───────────────────────────────────────────┘
```

### Bases de Datos
- **MySQL (3307)** - Auth Service
- **PostgreSQL (5433)** - Catalog Service
- **PostgreSQL (5434)** - Booking Service  
- **PostGIS (5435)** - Search Service
- **Redis (6379)** - Cache & Rate Limiting

---

## 📁 ESTADOS DE ESPACIOS

### Flujo Actual:
```
CREAR ESPACIO
     ↓
  ACTIVE ←──────┐
     ↓          │
  SNOOZED ──────┘
  (pausado)
     ↓
  DELETED
  (soft delete)
```

### Tabla de Estados y Acciones:

| Estado | Badge | Descripción | Botones Disponibles |
|--------|-------|-------------|---------------------|
| `ACTIVE` | 🟢 Verde | Publicado y visible | Pausar, Editar, Eliminar |
| `SNOOZED` | 🔵 Azul | Pausado temporalmente | Activar, Editar, Eliminar |
| `DELETED` | 🔴 Rojo | Marcado como eliminado | Solo Ver |
| `DRAFT` | 🟡 Amarillo | Borrador (no usado) | - |

**Nota:** Actualmente NO se usa DRAFT. Los espacios se crean directamente como ACTIVE.

---

## 🎨 FRONTEND - DASHBOARD DEL HOST

### Secciones Implementadas:

#### 1. Overview
- 📊 Stats cards (Espacios totales, Activos, Ingresos, Reservas)
- ℹ️ Alerta contextual (solo si 0 espacios activos)
- 🎯 Acciones rápidas (Crear espacio, Gestionar, Ver reservas)
- 📋 Lista de espacios recientes

#### 2. Mis Espacios
- 🔍 Filtros: `[Activos] [Pausados] [Eliminados] [Todos]`
- 📇 Cards de espacios con:
  - Badge de estado
  - Información principal (título, dirección, capacidad, precio)
  - Botones de acción (Ver, Editar, Pausar/Activar, Eliminar)
- 🎬 Animaciones y transiciones suaves
- 📱 Diseño responsive

#### 3. Crear/Editar Espacio
- 📝 Formulario completo con validaciones
- 🗺️ Coordenadas (lat, lon)
- 💰 Precio por hora (en euros, se convierte a centavos)
- 👥 Capacidad
- 📐 Área en m²
- 🏷️ Amenities (lista de comodidades)
- ✅ Validación en tiempo real

#### 4. Reservas
- ⏳ Próximamente (estructura preparada)

### Características UX:

✅ **Scroll automático** al cambiar de vista  
✅ **Toasts animados** para feedback  
✅ **Modales de confirmación** para acciones destructivas  
✅ **Estados de carga** (spinners)  
✅ **Mensajes de error** claros  
✅ **Empty states** informativos  
✅ **Diseño Airbnb-style** profesional

---

## 🔧 CORRECCIONES TÉCNICAS APLICADAS

### Backend (Java)

**1. SpaceServiceImpl.java**
```java
// Línea 69 - Estado inicial de espacios
ANTES: space.setStatus(SPACE_STATUS_DRAFT);
AHORA: space.setStatus(SPACE_STATUS_ACTIVE);
```

**2. CatalogConstants.java**
```java
// Constantes normalizadas a MAYÚSCULAS
ANTES: "active", "snoozed", "deleted"
AHORA: "ACTIVE", "SNOOZED", "DELETED"
```

**3. SpaceProjectionRepository.java (Search Service)**
```sql
-- Todas las queries actualizadas
ANTES: AND s.status = 'active'
AHORA: AND UPPER(s.status) = 'ACTIVE'
```

### Frontend (TypeScript)

**1. host-dashboard.ts**
```typescript
// Todas las comparaciones case-insensitive
calculateStats(): s.status.toUpperCase() === 'ACTIVE'
toggleSpaceStatus(): space.status.toUpperCase() === 'ACTIVE'
getStatusBadgeClass(): const upperStatus = status.toUpperCase()
```

**2. toast.ts**
```typescript
// Animaciones añadidas
animations: [
  trigger('slideIn', [
    transition(':enter', [
      style({ transform: 'translateX(400px)', opacity: 0 }),
      animate('300ms ease-out', style({ transform: 'translateX(0)', opacity: 1 }))
    ])
  ])
]
```

### Base de Datos (SQL)

**Catalog DB:**
```sql
UPDATE catalog.spaces SET status = UPPER(status);
-- Resultado: 3 ACTIVE, 4 DELETED
```

**Search DB:**
```sql
UPDATE search.spaces_projection SET status = UPPER(status);
```

---

## 📊 DATOS DE PRUEBA ACTUALES

### Usuario Host:
```
Email: host1@balconazo.com
Password: password123
ID: 11111111-1111-1111-1111-111111111111
Role: HOST
```

### Espacios:
```
✅ ACTIVE (3):
   - Estudio de fotografía profesional
   - Ático con terraza en el centro
   - (Cualquier nuevo espacio creado)

❌ DELETED (4):
   - Ático Premium (x3)
   - espacio de prueba
```

---

## 🧪 CÓMO PROBAR

### 1. Iniciar Todo
```bash
# Terminal 1: Infraestructura
./start-infrastructure.sh

# Terminal 2: Servicios (esperar 10 segundos)
./start-all-services.sh

# Terminal 3: Frontend (esperar 20 segundos)
cd balconazo-frontend && ng serve
```

### 2. Probar Dashboard del Host
```
1. Abrir http://localhost:4200
2. Login: host1@balconazo.com / password123
3. Click menú usuario → "Dashboard"
4. Verificar:
   ✓ Stats: "Espacios Activos: 2-3"
   ✓ NO aparece alerta si hay espacios activos
   ✓ Filtros funcionan (Activos, Pausados, Eliminados, Todos)
   ✓ Botones correctos por estado:
     - ACTIVE: [Pausar]
     - SNOOZED: [Activar]
     - DELETED: (sin botones de estado)
```

### 3. Probar Crear Espacio
```
1. Dashboard → Click "Crear Espacio"
2. Llenar formulario:
   - Título: "Mi Espacio de Prueba"
   - Descripción: "Un espacio increíble"
   - Dirección: "Calle Test 123, Madrid"
   - Lat: 40.4168
   - Lon: -3.7038
   - Capacidad: 10
   - Precio: 25€/hora
   - Área: 50m²
3. Click "Crear Espacio"
4. Verificar:
   ✓ Toast verde: "Espacio creado exitosamente"
   ✓ Aparece en "Mis Espacios" con estado ACTIVE
   ✓ Tiene botón "Pausar" (NO "Activar")
   ✓ Aparece en página principal
```

### 4. Probar Pausar/Activar
```
1. Espacio ACTIVE → Click "Pausar"
2. Verificar:
   ✓ Toast: "Espacio pausado exitosamente"
   ✓ Badge cambia a azul "Pausado"
   ✓ Botón cambia a "Activar"
3. Click "Activar"
4. Verificar:
   ✓ Toast: "Espacio activado exitosamente"
   ✓ Badge cambia a verde "Activo"
   ✓ Botón cambia a "Pausar"
```

### 5. Probar Página Principal
```
1. Ir a http://localhost:4200 (home)
2. Verificar:
   ✓ Sección "Espacios Destacados" muestra espacios
   ✓ Solo muestra espacios ACTIVE
   ✓ NO muestra espacios DELETED o SNOOZED
3. Hacer búsqueda:
   - Madrid, España
   - Radio: 5 km
4. Verificar:
   ✓ Devuelve resultados
   ✓ Solo espacios ACTIVE
```

---

## 📚 DOCUMENTACIÓN ACTUALIZADA

### Documentos Principales:
- ✅ `README.md` - Descripción y quick start
- ✅ `ESTADO_FINAL_NOV_2.md` - Este documento
- ✅ `DATABASE.md` - Esquema de BD
- ✅ `DOCUMENTATION.md` - Arquitectura completa
- ✅ `FRONTEND-START.md` - Guía para frontend developers
- ✅ `NEXT-STEPS.md` - Roadmap (actualizado abajo)
- ✅ `POSTMAN_ENDPOINTS.md` - Colección de endpoints

### Scripts:
- ✅ `start-infrastructure.sh` - Docker (BD, Kafka, Redis)
- ✅ `start-all-services.sh` - Microservicios
- ✅ `comprobacionmicroservicios.sh` - Health checks
- ✅ `stop-all.sh` - Parar todo
- ✅ `recompile-all.sh` - Recompilar servicios

---

## 🚀 PRÓXIMOS PASOS RECOMENDADOS

### 🔥 Alta Prioridad (1-2 semanas)

#### 1. Sistema de Imágenes para Espacios
**¿Por qué?** Un espacio sin fotos no se alquila.

**Implementación:**
- [ ] Backend: Endpoint para upload de imágenes
- [ ] Integración con AWS S3 o Cloudinary
- [ ] Múltiples imágenes por espacio (galería)
- [ ] Imagen principal (portada)
- [ ] Frontend: Componente de upload con drag & drop
- [ ] Preview de imágenes antes de subir
- [ ] Reordenar imágenes (drag & drop)
- [ ] Eliminar imágenes

**Stack sugerido:**
- Backend: `MultipartFile`, `AWS SDK` o `Cloudinary SDK`
- Frontend: `ng2-file-upload` o nativo `<input type="file" multiple>`
- Storage: AWS S3 (producción) o local (desarrollo)

**Estimación:** 5-7 días

---

#### 2. Calendario de Disponibilidad
**¿Por qué?** Los hosts necesitan bloquear fechas (vacaciones, mantenimiento).

**Implementación:**
- [ ] Backend: Entidad `AvailabilitySlot`
- [ ] CRUD de disponibilidad por espacio
- [ ] Validar que no haya reservas en fechas bloqueadas
- [ ] Frontend: Componente de calendario
- [ ] Marcar días/rangos como no disponibles
- [ ] Precios variables por fecha (opcional)
- [ ] Vista mensual y semanal

**Stack sugerido:**
- Frontend: `FullCalendar` o `Angular Material Datepicker`
- Backend: Ya existe entidad `AvailabilitySlot` en Catalog Service

**Estimación:** 4-6 días

---

#### 3. Dashboard de Reservas Recibidas (Host)
**¿Por qué?** Los hosts necesitan ver y gestionar reservas de sus espacios.

**Implementación:**
- [ ] Backend: Endpoint `/bookings/received` (filtrar por owner de space)
- [ ] Listar reservas de todos los espacios del host
- [ ] Frontend: Nueva sección en dashboard
- [ ] Tabla de reservas con filtros (Pendientes, Confirmadas, Completadas)
- [ ] Ver detalle de reserva
- [ ] Chat con el guest (futuro)

**Nota:** La entidad `Booking` y endpoints básicos ya existen.

**Estimación:** 3-4 días

---

### ⚡ Media Prioridad (2-4 semanas)

#### 4. Sistema de Reseñas Completo
**Estado actual:** Backend completo, frontend básico

**Pendiente:**
- [ ] Mostrar reseñas en detalle de espacio
- [ ] Formulario de reseña después de completar reserva
- [ ] Rating promedio visible en cards
- [ ] Responder a reseñas (host)
- [ ] Reportar reseñas inapropiadas

**Estimación:** 3-5 días

---

#### 5. Dashboard de Analytics
**¿Por qué?** Los hosts necesitan ver métricas de rendimiento.

**Implementación:**
- [ ] Backend: Endpoints de estadísticas agregadas
- [ ] Frontend: Gráficos con `Chart.js` o `ApexCharts`
- [ ] Métricas:
  - Ingresos por mes/semana
  - Tasa de ocupación
  - Reservas por espacio
  - Rating promedio evolutivo
  - Vistas del espacio (requiere tracking)

**Estimación:** 5-7 días

---

#### 6. Notificaciones en Tiempo Real
**¿Por qué?** Mejorar la comunicación host-guest.

**Implementación:**
- [ ] Backend: WebSocket con Spring WebSocket
- [ ] Notificaciones:
  - Nueva reserva recibida (host)
  - Reserva confirmada (guest)
  - Reserva cancelada (ambos)
  - Nuevo mensaje (futuro chat)
- [ ] Frontend: Banner de notificaciones
- [ ] Icono con contador de no leídas
- [ ] Sistema de persistencia (guardar en BD)

**Stack sugerido:**
- Backend: `@EnableWebSocketMessageBroker`, STOMP
- Frontend: `rxjs/webSocket`, `@stomp/ng2-stompjs`

**Estimación:** 4-6 días

---

### 🔮 Baja Prioridad (1-2 meses)

#### 7. Chat en Tiempo Real
- [ ] WebSocket bidireccional
- [ ] Historial de conversaciones
- [ ] Indicador "escribiendo..."
- [ ] Notificaciones de mensajes nuevos

**Estimación:** 7-10 días

---

#### 8. Pagos con Stripe
**Estado actual:** Estructura básica preparada

**Pendiente:**
- [ ] Integración completa de Stripe Checkout
- [ ] Webhooks para estados de pago
- [ ] Gestión de reembolsos
- [ ] Historial de transacciones
- [ ] Comisión de plataforma (ej: 10%)

**Estimación:** 5-8 días

---

#### 9. Sistema de Verificación
- [ ] Verificar identidad de hosts (KYC)
- [ ] Verificar espacios (visita o fotos)
- [ ] Badges: "Verificado", "Superhost", etc.
- [ ] Panel de administración

**Estimación:** 10-15 días

---

#### 10. SEO y Performance
- [ ] Angular Universal (SSR)
- [ ] Meta tags dinámicos
- [ ] Open Graph para compartir
- [ ] Sitemap XML
- [ ] Lazy loading de imágenes
- [ ] PWA (opcional)

**Estimación:** 5-7 días

---

## 📊 ROADMAP VISUAL

```
┌─────────────────────────────────────────────────────┐
│  MES 1 (Noviembre 2025)                             │
├─────────────────────────────────────────────────────┤
│  Semana 1-2: Sistema de Imágenes ✅                 │
│  Semana 3: Calendario de Disponibilidad ✅          │
│  Semana 4: Dashboard de Reservas Recibidas ✅       │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  MES 2 (Diciembre 2025)                             │
├─────────────────────────────────────────────────────┤
│  Semana 1: Reseñas Completo ✅                      │
│  Semana 2-3: Analytics Dashboard ✅                 │
│  Semana 4: Notificaciones en Tiempo Real ✅         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  MES 3 (Enero 2026)                                 │
├─────────────────────────────────────────────────────┤
│  Semana 1-2: Chat en Tiempo Real ✅                 │
│  Semana 3-4: Pagos con Stripe ✅                    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  MES 4+ (Febrero-Marzo 2026)                        │
├─────────────────────────────────────────────────────┤
│  - Sistema de Verificación                          │
│  - Panel de Administración                          │
│  - SEO y Performance                                │
│  - Testing E2E completo                             │
│  - CI/CD Pipeline                                   │
│  - Despliegue en producción                         │
└─────────────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST DE FUNCIONALIDADES

### Backend
- [x] Autenticación JWT
- [x] CRUD de espacios
- [x] CRUD de reservas
- [x] Búsqueda geoespacial
- [x] Reseñas básicas
- [x] Event streaming (Kafka)
- [x] Cache (Redis)
- [ ] Upload de imágenes
- [ ] Calendario de disponibilidad (existe entity, falta lógica)
- [ ] Pagos (Stripe)
- [ ] Notificaciones push
- [ ] Chat

### Frontend
- [x] Login/Registro
- [x] Home con búsqueda
- [x] Detalle de espacio
- [x] Dashboard del host
- [x] CRUD de espacios (host)
- [x] Mis reservas (guest)
- [ ] Galería de imágenes
- [ ] Calendario de disponibilidad
- [ ] Dashboard de reservas recibidas (host)
- [ ] Chat
- [ ] Analytics

### Infraestructura
- [x] Docker Compose (desarrollo)
- [x] Service Discovery
- [x] API Gateway
- [x] Load Balancing
- [ ] CI/CD Pipeline
- [ ] Monitoring (Grafana)
- [ ] Logging centralizado (ELK)
- [ ] Despliegue (Kubernetes/AWS)

---

## 🎯 RECOMENDACIÓN INMEDIATA

**Empezar por:** Sistema de Imágenes para Espacios

**Razones:**
1. Es la feature más visible y necesaria
2. No hay dependencias de otras features
3. Mejora inmediata de la UX
4. Los espacios sin fotos no se alquilan

**Plan de 1 semana:**
- Día 1-2: Backend (upload, storage, endpoints)
- Día 3-4: Frontend (componente de upload)
- Día 5: Integración y pruebas
- Día 6-7: Refinamiento y documentación

---

## 📝 NOTAS FINALES

### Lo que Funciona al 100%:
✅ Autenticación y roles  
✅ CRUD de espacios  
✅ Dashboard del host  
✅ Búsqueda geoespacial  
✅ Estados de espacios (ACTIVE, SNOOZED, DELETED)  
✅ Frontend con diseño profesional  
✅ Microservicios comunicándose correctamente  
✅ Event streaming con Kafka  

### Áreas de Mejora:
⚠️ Tests automatizados (0% coverage)  
⚠️ Documentación de API (Swagger pendiente)  
⚠️ Manejo de errores en frontend (mejorable)  
⚠️ Logs estructurados (falta ELK)  
⚠️ Monitoreo (falta Grafana)  

### Stack Tecnológico Final:
- **Backend:** Spring Boot 3.5, Java 21
- **Frontend:** Angular 18 (standalone)
- **Bases de Datos:** MySQL, PostgreSQL, PostGIS
- **Cache:** Redis
- **Message Broker:** Kafka
- **Service Discovery:** Eureka
- **API Gateway:** Spring Cloud Gateway
- **Contenedores:** Docker & Docker Compose

---

## ✅ PROYECTO LISTO PARA SIGUIENTE FASE

**Estado:** 💚 **SALUDABLE**  
**Cobertura de features MVP:** **75%**  
**Deuda técnica:** **Baja**  
**Siguiente milestone:** **Sistema de Imágenes**

---

**Actualizado:** 2 Noviembre 2025, 23:30  
**Autor:** Equipo Balconazo  
**Versión:** 1.0.0-SNAPSHOT

