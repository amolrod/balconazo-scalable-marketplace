# Wireframes de UI - Balconazo

Diseños básicos de las 5 pantallas principales del frontend Angular 20.

---

## 🏠 1. HOME + BÚSQUEDA

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo Balconazo]         Buscar  Publicar  Login/Registro         │
└─────────────────────────────────────────────────────────────────────┘
│                                                                     │
│   ┌───────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │         🏡 Encuentra el balcón perfecto para tu evento     │   │
│   │                                                             │   │
│   │   ┌────────────────────────────────────────────────────┐  │   │
│   │   │  📍 Ubicación: [Madrid_____________] [📍 Mapa]    │  │   │
│   │   ├────────────────────────────────────────────────────┤  │   │
│   │   │  📅 Fecha: [31/12/2025__] Hora: [22:00-06:00]    │  │   │
│   │   ├────────────────────────────────────────────────────┤  │   │
│   │   │  👥 Capacidad: [10 personas_____]  [  Buscar  ]   │  │   │
│   │   └────────────────────────────────────────────────────┘  │   │
│   │                                                             │   │
│   └───────────────────────────────────────────────────────────┘   │
│                                                                     │
│   🔥 Espacios Destacados                                           │
│                                                                     │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│   │  [Foto]      │  │  [Foto]      │  │  [Foto]      │           │
│   │              │  │              │  │              │           │
│   │ Terraza      │  │ Ático con    │  │ Balcón       │           │
│   │ Retiro       │  │ vistas       │  │ Malasaña     │           │
│   │              │  │              │  │              │           │
│   │ 👥 15 • ⭐4.8 │  │ 👥 20 • ⭐4.9 │  │ 👥 8 • ⭐4.7  │           │
│   │ 💰 35€/hora  │  │ 💰 50€/hora  │  │ 💰 28€/hora  │           │
│   └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                     │
│   📊 ¿Cómo funciona?                                               │
│   ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐                   │
│   │ 🔍   │ →  │ 📅   │ →  │ 💳   │ →  │ 🎉   │                   │
│   │Busca │    │Reserva│   │Paga  │    │Disfruta│                 │
│   └──────┘    └──────┘    └──────┘    └──────┘                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
│  © 2025 Balconazo | Términos | Privacidad | Contacto             │
└─────────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- `HeaderComponent` (logo, nav)
- `SearchFormComponent` (formulario principal)
- `SpaceCardComponent` (tarjetas destacados)
- `FooterComponent`

---

## 🗺️ 2. RESULTADOS DE BÚSQUEDA (Lista + Mapa)

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  Buscar  Publicar  [Avatar▼]                               │
└─────────────────────────────────────────────────────────────────────┘
│                                                                     │
│  📍 Madrid • 📅 31/12/2025 22:00-06:00 • 👥 10 personas  [✏️Editar]│
│                                                                     │
│  🔽 Filtros: [Precio: 0-100€] [Rating: 4+] [Amenities: WiFi🗹...]  │
│                                                                     │
│  ┌─────────────────────────┬───────────────────────────────────┐  │
│  │  LISTA (24 resultados)  │         MAPA                      │  │
│  │  Ordenar: [Precio▼]     │  ┌─────────────────────────────┐ │  │
│  │                          │  │ ╔═══╗                       │ │  │
│  │  ┌──────────────────┐   │  │ ║ 📍 ║  Madrid Centro      │ │  │
│  │  │ [📷]  Terraza    │   │  │ ╚═══╝   🔴15  🔴8  🔴12   │ │  │
│  │  │       Retiro     │   │  │         🔴10  🔴20         │ │  │
│  │  │                  │   │  │     🔴25       🔴18        │ │  │
│  │  │ 📍 C/ Alcalá 123│   │  │                             │ │  │
│  │  │ 👥 15  ⭐ 4.8    │   │  │  [Zoom +/-]  [Fullscreen]  │ │  │
│  │  │ 💰 74.90€        │   │  └─────────────────────────────┘ │  │
│  │  │ ⚡ Precio dinámico│  │                                   │  │
│  │  │                  │   │  🔴 = Marker con precio          │  │
│  │  │ [Ver detalle →]  │   │  Click marker → popup con info   │  │
│  │  └──────────────────┘   │                                   │  │
│  │                          │                                   │  │
│  │  ┌──────────────────┐   │                                   │  │
│  │  │ [📷]  Ático      │   │                                   │  │
│  │  │       Chamberí   │   │                                   │  │
│  │  │                  │   │                                   │  │
│  │  │ 📍 P. Rosales 45│   │                                   │  │
│  │  │ 👥 20  ⭐ 4.9    │   │                                   │  │
│  │  │ 💰 50.00€        │   │                                   │  │
│  │  │                  │   │                                   │  │
│  │  │ [Ver detalle →]  │   │                                   │  │
│  │  └──────────────────┘   │                                   │  │
│  │                          │                                   │  │
│  │  [Ver más...]            │                                   │  │
│  └─────────────────────────┴───────────────────────────────────┘  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- `SearchResultsPageComponent`
- `FilterBarComponent`
- `SpaceListComponent` (izquierda)
- `MapComponent` (derecha - Leaflet/Google Maps)
- `SpaceCardComponent` (reutilizado)

**Features:**
- Toggle Lista/Mapa
- Filtros dinámicos (sin reload)
- Markers en mapa con precio visible
- Click en marker → highlight en lista

---

## 🏡 3. DETALLE DE ESPACIO

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  Buscar  Publicar  [Avatar▼]                   [← Volver]  │
└─────────────────────────────────────────────────────────────────────┘
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  [═══════════════ Galería de Fotos ═══════════════════════]  │  │
│  │  [  Foto principal (click → fullscreen)                   ]  │  │
│  │  [ 📷📷📷 Miniaturas abajo                                ]  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌────────────────────────────┬──────────────────────────────────┐ │
│  │  Terraza con vistas Retiro │  💰 74.90€/hora                  │ │
│  │  ⭐ 4.8 (23 reviews)        │  ⚡ Precio dinámico (+114%)     │ │
│  │  📍 Calle Alcalá 123        │                                  │ │
│  │  👤 Host: Ana García (⭐4.9)│  ┌────────────────────────────┐ │ │
│  │                             │  │ 📅 31/12/2025              │ │ │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━ │  │ ⏰ 22:00 - 06:00 (8h)      │ │ │
│  │                             │  │ 👥 10 personas             │ │ │
│  │  📝 Descripción             │  │                            │ │ │
│  │  Amplia terraza de 40m²     │  │ Total: 599.20€            │ │ │
│  │  con vistas al Parque del   │  │ (74.90€ × 8h)             │ │ │
│  │  Retiro. Perfecta para      │  │                            │ │ │
│  │  eventos nocturnos...       │  │ [🔒 Reservar →]           │ │ │
│  │                             │  └────────────────────────────┘ │ │
│  │  ✨ Características         │                                  │ │
│  │  👥 Capacidad: 15 personas  │  ⚠️ Cancelación gratuita       │ │
│  │  📏 40 m²                   │     hasta 24h antes            │ │
│  │  🚫 No fumar               │                                  │ │
│  │  🔊 Ruido moderado         │                                  │ │
│  │  📶 WiFi incluido          │                                  │ │
│  │  🔌 Enchufes exteriores    │                                  │ │
│  │                             │                                  │ │
│  │  📍 Ubicación               │                                  │ │
│  │  ┌──────────────────────┐  │                                  │ │
│  │  │  [Mapa integrado]    │  │                                  │ │
│  │  │   📍 Marker exacto   │  │                                  │ │
│  │  └──────────────────────┘  │                                  │ │
│  │                             │                                  │ │
│  │  ⭐ Reviews (23)            │                                  │ │
│  │  ┌─────────────────────┐   │                                  │ │
│  │  │ ⭐⭐⭐⭐⭐ María L.    │   │                                  │ │
│  │  │ "Increíble espacio   │   │                                  │ │
│  │  │  para Nochevieja"    │   │                                  │ │
│  │  │  01/01/2025          │   │                                  │ │
│  │  └─────────────────────┘   │                                  │ │
│  │  [Ver más reviews...]       │                                  │ │
│  └─────────────────────────────┴──────────────────────────────────┘ │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- `SpaceDetailPageComponent`
- `PhotoGalleryComponent`
- `BookingSummaryComponent` (card derecha sticky)
- `MapComponent`
- `ReviewListComponent`
- `HostInfoComponent`

**Interacciones:**
- Click [Reservar] → Redirect a `/booking/{spaceId}?date=...&time=...`
- Galería con lightbox
- Mostrar precio dinámico con tooltip explicativo

---

## 💳 4. CHECKOUT (BOOKING)

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  Buscar  Publicar  [Avatar▼]                               │
└─────────────────────────────────────────────────────────────────────┘
│                                                                     │
│  🔒 Checkout Seguro                                  [🔙 Volver]   │
│                                                                     │
│  ┌──────────────────────────────┬──────────────────────────────┐  │
│  │  📋 DETALLES DE RESERVA      │  📝 RESUMEN                  │  │
│  │                               │                              │  │
│  │  ┌────────────────────────┐  │  ┌────────────────────────┐ │  │
│  │  │ [📷] Terraza Retiro    │  │  │ Terraza Retiro         │ │  │
│  │  │      C/ Alcalá 123     │  │  │                        │ │  │
│  │  └────────────────────────┘  │  │ 📅 31/12/2025          │ │  │
│  │                               │  │ ⏰ 22:00 - 06:00 (8h)  │ │  │
│  │  📅 Fecha y hora              │  │ 👥 10 personas         │ │  │
│  │  31 Dic 2025, 22:00-06:00     │  │                        │ │  │
│  │  (8 horas)                    │  │ ━━━━━━━━━━━━━━━━━━━━ │ │  │
│  │                               │  │ Precio base: 3,500€    │ │  │
│  │  👥 Invitados                 │  │ Multiplicador: ×2.14   │ │  │
│  │  [10] personas                │  │ Subtotal: 5,992€       │ │  │
│  │  (máx: 15)                    │  │ Comisión (15%): 899€   │ │  │
│  │                               │  │ ━━━━━━━━━━━━━━━━━━━━ │ │  │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━ │  │ TOTAL: 6,891€          │ │  │
│  │                               │  │                        │ │  │
│  │  💳 MÉTODO DE PAGO           │  │ ⚠️ Se cobrará al       │ │  │
│  │                               │  │    confirmar reserva   │ │  │
│  │  ○ Tarjeta de crédito        │  └────────────────────────┘ │  │
│  │  ● Tarjeta de débito         │                              │  │
│  │  ○ PayPal                    │  📋 Política Cancelación   │  │
│  │                               │                              │  │
│  │  ┌────────────────────────┐  │  • Cancelación gratuita    │  │
│  │  │ Número tarjeta         │  │    hasta 24h antes         │  │
│  │  │ [________________]     │  │  • Entre 24-6h: 50% reem.  │  │
│  │  │                        │  │  • <6h: sin reembolso      │  │
│  │  │ Vencimiento  CVV       │  │                              │  │
│  │  │ [MM/YY] [___]          │  │                              │  │
│  │  │                        │  │  ✅ Aceptas términos       │  │
│  │  │ Nombre titular         │  │  □ Newsletter              │  │
│  │  │ [________________]     │  │                              │  │
│  │  └────────────────────────┘  │  [   Confirmar Reserva   ] │  │
│  │                               │                              │  │
│  │  🔐 Pago seguro con SSL      │                              │  │
│  │     [Stripe logo]             │                              │  │
│  └───────────────────────────────┴──────────────────────────────┘  │
│                                                                     │
│  ⏱️ Esta reserva expira en: 09:45  (hold de 10 min)               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- `BookingPageComponent`
- `BookingSummaryComponent` (sticky)
- `PaymentFormComponent` (Stripe Elements)
- `PolicyComponent`

**Flujo:**
1. POST `/api/bookings` → Status `held` (10 min TTL)
2. Usuario completa form de pago
3. POST `/api/bookings/{id}/confirm` → Status `confirmed`
4. Redirect a confirmación

**Features:**
- Timer countdown (10 min)
- Validación de tarjeta en tiempo real
- Loading state durante payment capture

---

## 🏠 5. DASHBOARD HOST

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  Dashboard  Reservas  Ingresos  [Avatar Ana▼]              │
└─────────────────────────────────────────────────────────────────────┘
│                                                                     │
│  👋 Hola Ana,  ⭐ Rating: 4.9 (12 reviews)                          │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  📊 RESUMEN ESTE MES                                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐  │
│  │ 💰 Ingresos│  │ 📅 Reservas│  │ 👁️ Vistas  │  │ ⭐ Rating  │  │
│  │   2,450€   │  │     8      │  │    142     │  │   4.9      │  │
│  │   +23% ↑   │  │   +2 ↑     │  │   +15% ↑   │  │   ━       │  │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘  │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  🏡 MIS ESPACIOS (2)                        [+ Publicar nuevo]     │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ [📷]  Terraza Retiro              Status: ✅ Activo          │   │
│  │                                                              │   │
│  │       📍 Calle Alcalá 123         Precio base: 35€/h        │   │
│  │       👥 15 personas               Precio actual: 74.90€/h   │   │
│  │       ⭐ 4.8 (23 reviews)          Multiplicador: ×2.14      │   │
│  │                                                              │   │
│  │       📅 Próximas reservas (3):                             │   │
│  │       • 31 Dic 22:00-06:00 - María L. - 599€ [Confirmar]   │   │
│  │       • 15 Ene 18:00-22:00 - Juan P. - 150€ [Confirmada]   │   │
│  │                                                              │   │
│  │       [✏️ Editar] [📊 Estadísticas] [🔕 Pausar]              │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │ [📷]  Ático Chamberí              Status: ⏸️ Pausado         │   │
│  │                                                              │   │
│  │       📍 Paseo Rosales 45         Precio base: 50€/h        │   │
│  │       👥 20 personas               No disponible            │   │
│  │       ⭐ 4.9 (8 reviews)                                     │   │
│  │                                                              │   │
│  │       [✏️ Editar] [▶️ Activar]                               │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                                     │
│  📅 CALENDARIO DE DISPONIBILIDAD                                   │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  Diciembre 2025          [◀ Prev] [Hoy] [Next ▶]          │   │
│  │                                                             │   │
│  │  L  M  X  J  V  S  D                                       │   │
│  │        1  2  3  4  5     Leyenda:                          │   │
│  │  6  7  8  9 10 11 12     🟢 Disponible                     │   │
│  │ 13 14 15 16 17 18 19     🔴 Reservado                      │   │
│  │ 20 21 22 23 24 25 26     🟡 Bloqueado (host)               │   │
│  │ 27 28 29 30 [31]         ⚪ No disponible                  │   │
│  │                                                             │   │
│  │ 31 Dic: 🔴🔴🔴🔴🔴🔴🔴🔴 (22:00-06:00 - María L.)          │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

**Componentes:**
- `HostDashboardPageComponent`
- `HostStatsComponent` (4 cards de métricas)
- `SpaceListComponent` (versión host con acciones)
- `CalendarComponent` (disponibilidad)

**Features:**
- Ver precio dinámico actual vs base
- Gestionar reservas (confirmar/cancelar)
- Activar/pausar espacios
- Calendario de disponibilidad
- Gráficos de ingresos (opcional: Chart.js)

---

## 🎨 Paleta de Colores (Tailwind)

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          500: '#0ea5e9',  // Azul principal (botones, links)
          600: '#0284c7',
          700: '#0369a1',
        },
        secondary: {
          500: '#f59e0b',  // Ámbar (pricing, destacados)
        },
        success: '#10b981',   // Verde (confirmado)
        warning: '#f59e0b',   // Naranja (held)
        error: '#ef4444',     // Rojo (cancelado)
        neutral: {
          50: '#f9fafb',
          100: '#f3f4f6',
          700: '#374151',
          900: '#111827',
        }
      }
    }
  }
}
```

---

## 📱 Responsive (Mobile)

Todos los diseños son **mobile-first**:

- **Home:** Stack vertical (search form arriba, cards abajo)
- **Resultados:** Toggle Lista/Mapa (1 a la vez en móvil)
- **Detalle:** Gallery fullscreen, booking summary fixed bottom
- **Checkout:** Form completo scrollable, resumen sticky bottom
- **Dashboard:** Cards 1 columna, calendario scrollable horizontal

---

## 🧩 Componentes Reutilizables

```typescript
// Shared components
- SpaceCardComponent       // Tarjeta de espacio (3 variantes: grid, list, featured)
- MapComponent             // Mapa con Leaflet (markers, popups)
- CalendarComponent        // Calendario de disponibilidad
- RatingStarsComponent     // ⭐⭐⭐⭐⭐ (read-only o editable)
- PriceBadgeComponent      // Precio con tooltip de pricing dinámico
- AvatarComponent          // Avatar de usuario con status
- LoadingSpinnerComponent  // Loading state
- ErrorAlertComponent      // Error messages
- ModalComponent           // Modal genérico
```

---

## ✅ Próximos Pasos

1. ✅ **Implementar HOME** con search form funcional
2. ✅ **Integrar Leaflet** para mapa en resultados
3. ✅ **SpaceDetailPage** con galería + booking CTA
4. ⏸️ Checkout con Stripe Elements (después de backend)
5. ⏸️ Dashboard host con calendario

**Prioridad:** Home → Resultados → Detalle (son el 80% del flujo de usuario).

---

**Última actualización:** 25 de octubre de 2025  
**Diseñador:** Equipo de UX Balconazo

