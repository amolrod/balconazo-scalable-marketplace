# 🚀 SIGUIENTES FUNCIONALIDADES A IMPLEMENTAR

**Fecha**: 5 de Noviembre de 2025  
**Proyecto**: Balconazo - Marketplace de Espacios  
**Estado Actual**: 8/8 PRs Base Completados + Mejoras Críticas Aplicadas

---

## 📊 **RESUMEN EJECUTIVO**

### **Estado del Proyecto**
- ✅ **Completado**: Design System, Core, Shared Components, Navbar, Home, Explore, Space Detail, Host Dashboard
- ✅ **Funcional**: Login/Logout, Búsqueda, Filtros, CRUD de Espacios, Galería de Imágenes
- ⚠️ **Pendiente**: Sistema de Reservas, Pagos, Mensajería, Reviews Reales

### **Priorización**
Las funcionalidades están organizadas en **3 niveles de prioridad**:
- 🔴 **CRÍTICO**: Sin esto, no hay marketplace funcional (MVP)
- 🟡 **IMPORTANTE**: Mejora significativa de UX y confianza
- 🟢 **DESEABLE**: Features avanzadas que añaden valor

---

## 🔴 **PRIORIDAD CRÍTICA (MVP - 40-50 HORAS)**

### **1. SISTEMA DE RESERVAS COMPLETO** 🔴
**Tiempo Estimado**: 15-18 horas  
**Impacto**: CRÍTICO - Sin reservas no hay transacciones

#### **Funcionalidades**
- **Calendario de Selección de Fechas** (Guest)
  - DateRangePicker para seleccionar fecha/hora inicio y fin
  - Validación de horarios disponibles
  - Cálculo automático de precio total (horas × precio/hora)
  - Visualización de días no disponibles
  - Mínimo de horas por reserva (configurable por espacio)

- **Proceso de Reserva**
  - Paso 1: Selección de fecha/hora
  - Paso 2: Resumen de reserva (espacio, fechas, precio)
  - Paso 3: Confirmación (aún sin pago, solo solicitud)
  - Estado inicial: `PENDING` (pendiente de confirmación del host)

- **Vista de Reservas para Guest** (`/bookings`)
  - Mis Reservas Activas (upcoming)
  - Historial de Reservas (past/completed)
  - Estados: Pending, Confirmed, Completed, Cancelled
  - Botón "Cancelar" (con políticas de cancelación)
  - Detalles de cada reserva (espacio, fecha, precio, estado)

- **Vista de Reservas para Host** (Dashboard)
  - Reservas Recibidas
  - Filtros: Pendientes, Confirmadas, Completadas, Canceladas
  - Acciones: Aceptar/Rechazar solicitud
  - Calendario de ocupación del espacio
  - Timeline de próximas reservas

#### **Backend Necesario**
- Endpoints de reservas ya existen en `booking_microservice`
- `POST /api/booking/bookings` - Crear reserva
- `GET /api/booking/bookings/guest/{guestId}` - Reservas del guest
- `GET /api/booking/bookings/space/{spaceId}` - Reservas del espacio
- `PUT /api/booking/bookings/{id}/confirm` - Confirmar reserva
- `PUT /api/booking/bookings/{id}/cancel` - Cancelar reserva

#### **Componentes a Crear**
```
/src/app/features/bookings/
├── booking-create/
│   ├── booking-create.ts
│   ├── booking-create.html
│   └── booking-create.scss
├── booking-list/
│   ├── booking-list.ts (para guest)
│   └── booking-list.html
├── host-bookings/
│   ├── host-bookings.ts (para host)
│   └── host-bookings.html
└── shared/
    ├── booking-card.ts
    ├── date-range-picker.ts
    └── booking-calendar.ts
```

#### **Criterios de Aceptación**
- [ ] Guest puede seleccionar fechas/horas en un espacio
- [ ] Sistema calcula precio automáticamente
- [ ] Guest puede crear solicitud de reserva
- [ ] Host recibe notificación de nueva reserva
- [ ] Host puede aceptar/rechazar reserva
- [ ] Guest ve estado de su reserva
- [ ] Guest puede cancelar reserva (con políticas)
- [ ] Calendario muestra ocupación del espacio

---

### **2. SISTEMA DE PAGOS CON STRIPE** 🔴
**Tiempo Estimado**: 18-22 horas  
**Impacto**: CRÍTICO - Sin pagos no hay ingresos

#### **Funcionalidades**
- **Integración con Stripe**
  - Configuración de Stripe en backend
  - API Keys (test + production)
  - Webhooks para confirmación de pagos

- **Checkout Page** (`/checkout/:bookingId`)
  - Resumen de reserva (espacio, fechas, precio)
  - Desglose de costos:
    - Subtotal (precio × horas)
    - Comisión de plataforma (10-15%)
    - Total a pagar
  - Stripe Payment Element (tarjeta de crédito)
  - Botón "Pagar Ahora"
  - Loading state durante procesamiento
  - Redirección a página de éxito/error

- **Página de Confirmación** (`/booking-confirmed/:bookingId`)
  - Mensaje de éxito
  - Detalles de la reserva
  - Recibo/Invoice descargable (PDF)
  - Botón "Ver Mis Reservas"
  - Email de confirmación automático

- **Gestión de Pagos en Dashboard (Host)**
  - Historial de pagos recibidos
  - Estado de cada pago (Pending, Completed, Refunded)
  - Balance disponible para retiro
  - Solicitar payout (transferencia a cuenta bancaria)

#### **Backend Necesario**
- Nuevo microservicio `payment_microservice` O endpoints en `booking_microservice`
- `POST /api/payments/create-intent` - Crear PaymentIntent de Stripe
- `POST /api/payments/confirm` - Confirmar pago
- `POST /api/payments/refund` - Reembolsar pago
- `GET /api/payments/host/{hostId}` - Pagos recibidos por host
- `POST /api/webhooks/stripe` - Webhook de Stripe

#### **Dependencias**
- `@stripe/stripe-js` (frontend)
- `stripe` SDK (backend)
- Cuenta de Stripe (test mode)

#### **Criterios de Aceptación**
- [ ] Guest puede pagar con tarjeta de crédito
- [ ] Pago se procesa de forma segura con Stripe
- [ ] Confirmación automática de reserva tras pago exitoso
- [ ] Guest recibe email de confirmación
- [ ] Host ve pago recibido en dashboard
- [ ] Sistema de reembolsos funciona (cancelaciones)
- [ ] Comisión de plataforma se calcula correctamente
- [ ] Webhooks de Stripe funcionan correctamente

---

### **3. SISTEMA DE REVIEWS REAL** 🔴
**Tiempo Estimado**: 8-10 horas  
**Impacto**: ALTO - Confianza y reputación

#### **Funcionalidades**
- **Crear Review (Guest después de reserva completada)**
  - Solo disponible para reservas con estado `COMPLETED`
  - Rating obligatorio (1-5 estrellas)
  - Categorías: Limpieza, Ubicación, Comunicación, Relación calidad-precio
  - Comentario opcional (mín 20 caracteres)
  - Fotos opcionales (hasta 3)
  - Límite de tiempo para dejar review (30 días después de checkout)

- **Responder a Review (Host)**
  - Host puede responder a cada review (1 respuesta por review)
  - Máximo 500 caracteres
  - No editable después de publicar

- **Mostrar Reviews**
  - En Space Detail: todas las reviews con respuestas del host
  - Ordenar por: Más recientes, Mejor valoradas, Peor valoradas
  - Filtros: Con fotos, Por rating (5★, 4★, etc.)
  - Paginación (10 reviews por página)
  - Badge "Reserva verificada" en cada review

- **Rating Promedio**
  - Cálculo automático del rating promedio del espacio
  - Mostrar en SpaceCard y Space Detail
  - Número total de reviews
  - Actualización automática cuando se crea nueva review

#### **Backend Necesario**
- Endpoints ya existen en `booking_microservice`
- `POST /api/booking/reviews` - Crear review
- `GET /api/booking/reviews/space/{spaceId}` - Reviews de un espacio
- `PUT /api/booking/reviews/{id}/respond` - Host responde a review
- `GET /api/booking/reviews/pending/guest/{guestId}` - Reviews pendientes

#### **Componentes a Crear**
```
/src/app/features/reviews/
├── review-create/
│   ├── review-create.ts
│   └── review-create.html
├── review-list/
│   ├── review-list.ts
│   └── review-list.html
└── shared/
    ├── review-card.ts
    └── rating-input.ts
```

#### **Criterios de Aceptación**
- [ ] Guest puede dejar review después de reserva completada
- [ ] Rating es obligatorio, comentario opcional
- [ ] Host puede responder a reviews
- [ ] Reviews se muestran en Space Detail
- [ ] Rating promedio se calcula correctamente
- [ ] Solo guests con reserva verificada pueden dejar review
- [ ] Sistema previene reviews duplicadas

---

## 🟡 **PRIORIDAD IMPORTANTE (POST-MVP - 30-40 HORAS)**

### **4. SISTEMA DE MENSAJERÍA** 🟡
**Tiempo Estimado**: 12-15 horas  
**Impacto**: ALTO - Comunicación esencial

#### **Funcionalidades**
- **Inbox** (`/messages`)
  - Lista de conversaciones
  - Últimos mensajes por conversación
  - Badge de mensajes no leídos
  - Búsqueda de conversaciones
  - Filtro: Todos, No leídos

- **Chat 1-a-1**
  - Vista de mensajes entre guest y host
  - Input para escribir mensaje
  - Envío con Enter
  - Timestamp de cada mensaje
  - Indicador "visto" (opcional)
  - Scroll automático a último mensaje

- **Notificaciones de Mensajes**
  - Badge en navbar con contador de no leídos
  - Notificación in-app cuando llega mensaje nuevo
  - Email opcional (configurable por usuario)

- **Integración con Reservas**
  - Botón "Contactar Host" en Space Detail
  - Botón "Mensaje" en cada reserva
  - Auto-crear conversación al crear reserva

#### **Backend Necesario**
- Nuevo microservicio `messaging_microservice` O tabla en DB
- `POST /api/messages` - Enviar mensaje
- `GET /api/messages/conversations/{userId}` - Conversaciones del usuario
- `GET /api/messages/conversation/{conversationId}` - Mensajes de conversación
- `PUT /api/messages/{id}/read` - Marcar mensaje como leído
- WebSocket para tiempo real (opcional, puede ser polling)

#### **Criterios de Aceptación**
- [ ] Guest puede enviar mensaje a host
- [ ] Host puede responder
- [ ] Mensajes se ordenan cronológicamente
- [ ] Badge muestra número de no leídos
- [ ] Notificación cuando llega mensaje nuevo
- [ ] Conversaciones se asocian a reservas

---

### **5. SISTEMA DE NOTIFICACIONES** 🟡
**Tiempo Estimado**: 8-10 horas  
**Impacto**: MEDIO-ALTO - Engagement

#### **Funcionalidades**
- **Dropdown de Notificaciones en Navbar**
  - Badge con contador de no leídas
  - Lista de últimas 10 notificaciones
  - Click para marcar como leída
  - Botón "Ver todas"

- **Página de Notificaciones** (`/notifications`)
  - Todas las notificaciones
  - Filtros: Todas, No leídas, Leídas
  - Categorías: Reservas, Mensajes, Pagos, Reviews
  - Acción rápida (ir a reserva, mensaje, etc.)
  - Botón "Marcar todas como leídas"

- **Tipos de Notificaciones**
  - Nueva reserva recibida (host)
  - Reserva confirmada (guest)
  - Reserva cancelada
  - Nuevo mensaje recibido
  - Nueva review recibida (host)
  - Pago recibido (host)
  - Recordatorio de reserva (1 día antes)

- **Configuración de Notificaciones** (`/settings/notifications`)
  - Toggle por tipo de notificación
  - Email vs solo in-app
  - Frecuencia de emails (inmediato, diario, semanal)

#### **Backend Necesario**
- Tabla `notifications` en DB
- `GET /api/notifications/{userId}` - Notificaciones del usuario
- `PUT /api/notifications/{id}/read` - Marcar como leída
- `PUT /api/notifications/mark-all-read` - Marcar todas como leídas
- `POST /api/notifications/send` - Crear notificación (interno)

#### **Criterios de Aceptación**
- [ ] Notificaciones aparecen en dropdown
- [ ] Badge muestra contador de no leídas
- [ ] Click marca como leída
- [ ] Cada notificación tiene acción (link)
- [ ] Usuario puede configurar preferencias

---

### **6. SISTEMA DE FAVORITOS** 🟡
**Tiempo Estimado**: 4-6 horas  
**Impacto**: MEDIO - Mejora UX

#### **Funcionalidades**
- **Marcar como Favorito**
  - Icono de corazón en SpaceCard
  - Icono de corazón en Space Detail
  - Toggle on/off (guardar/quitar)
  - Animación al guardar

- **Página de Favoritos** (`/favorites`)
  - Grid de espacios favoritos
  - Misma UI que Explore
  - Botón para quitar de favoritos
  - Empty state si no hay favoritos
  - Sincronización con backend

- **Persistencia**
  - Guardar en backend (tabla `favorites`)
  - Mostrar favoritos en todas las sesiones
  - Sincronizar entre dispositivos

#### **Backend Necesario**
- `POST /api/favorites/{spaceId}` - Añadir a favoritos
- `DELETE /api/favorites/{spaceId}` - Quitar de favoritos
- `GET /api/favorites/user/{userId}` - Favoritos del usuario

#### **Criterios de Aceptación**
- [ ] Usuario puede guardar espacios favoritos
- [ ] Icono de corazón se llena cuando es favorito
- [ ] Página de favoritos muestra todos los guardados
- [ ] Favoritos persisten entre sesiones

---

### **7. BÚSQUEDA AVANZADA** 🟡
**Tiempo Estimado**: 6-8 horas  
**Impacto**: MEDIO - Mejor discovery

#### **Funcionalidades**
- **Geocoding de Ubicación**
  - Input de texto → convertir a lat/lon
  - Integración con Google Maps Geocoding API
  - Autocomplete de direcciones
  - Sugerencias de ciudades

- **Búsqueda por Radio**
  - Slider de distancia (1-50 km)
  - Mostrar espacios dentro del radio
  - Ordenar por distancia

- **Filtros Adicionales**
  - Tipo de espacio (terraza, sala, jardín, rooftop)
  - Verificación (host verificado, fotos verificadas)
  - "Reserva instantánea" (confirmación automática)
  - Servicios (WiFi incluido, catering, decoración)

- **Guardar Búsquedas**
  - Botón "Guardar esta búsqueda"
  - Notificaciones cuando aparezcan nuevos espacios
  - Gestión de búsquedas guardadas

#### **Backend Necesario**
- Mejoras en `/api/search/spaces`
- Soporte para geocoding
- Búsqueda por tipo de espacio
- Filtros adicionales

#### **Criterios de Aceptación**
- [ ] Usuario puede buscar por dirección
- [ ] Sistema convierte dirección a coordenadas
- [ ] Búsqueda por radio funciona
- [ ] Filtros adicionales funcionan
- [ ] Usuario puede guardar búsquedas

---

## 🟢 **PRIORIDAD DESEABLE (FUTURO - 20-30 HORAS)**

### **8. MAPA INTERACTIVO** 🟢
**Tiempo Estimado**: 8-10 horas

- Integración Leaflet o Google Maps
- Marcadores de espacios en mapa
- Cluster de marcadores cercanos
- Click en marcador → popup con info
- "Buscar en esta área" al mover mapa
- Toggle vista mapa/lista

---

### **9. PERFIL DE USUARIO COMPLETO** 🟢
**Tiempo Estimado**: 6-8 horas

- Editar perfil (nombre, bio, foto)
- Verificaciones (email, teléfono, ID)
- Idiomas hablados
- Estadísticas (miembro desde, respuestas)
- Reviews recibidas
- Cambiar contraseña
- Eliminar cuenta

---

### **10. DASHBOARD DE MÉTRICAS (HOST)** 🟢
**Tiempo Estimado**: 10-12 horas

- Gráficos de reservas (Chart.js)
- Gráfico de ingresos por mes
- Tasa de ocupación
- Tasa de conversión (vistas → reservas)
- Rating promedio por espacio
- Comparación con periodo anterior
- Exportar reportes (PDF/CSV)

---

### **11. CALENDARIO DE DISPONIBILIDAD (HOST)** 🟢
**Tiempo Estimado**: 10-12 horas

- Vista de calendario interactivo
- Marcar días disponibles/bloqueados
- Precio variable por día/temporada
- Bloqueos masivos (vacaciones)
- Sincronización con calendarios externos (iCal)

---

### **12. SISTEMA DE CUPONES Y DESCUENTOS** 🟢
**Tiempo Estimado**: 6-8 horas

- Crear cupones (host o admin)
- Aplicar cupón en checkout
- Tipos: % o monto fijo
- Cupones de primera reserva
- Cupones de referido
- Validación (fecha, límite de usos)

---

### **13. SISTEMA DE REFERIDOS** 🟢
**Tiempo Estimado**: 6-8 horas

- Código de referido único por usuario
- Invitar amigos por email
- Créditos por referido exitoso
- Dashboard de referidos
- Tracking de conversiones

---

### **14. MULTILENGUAJE (i18n)** 🟢
**Tiempo Estimado**: 8-10 horas

- Integración Angular i18n
- Traducciones ES/EN/FR/DE
- Selector de idioma en navbar
- Persistir idioma elegido
- Traducir emails

---

## 📅 **ROADMAP SUGERIDO**

### **FASE 1: MVP FUNCIONAL (6-8 SEMANAS)**
```
Semana 1-2: Sistema de Reservas
Semana 3-4: Sistema de Pagos con Stripe
Semana 5-6: Sistema de Reviews
Semana 7-8: Testing y ajustes del MVP

→ RESULTADO: Marketplace completamente funcional end-to-end
```

### **FASE 2: COMUNICACIÓN Y CONFIANZA (4-6 SEMANAS)**
```
Semana 9-10: Sistema de Mensajería
Semana 11-12: Sistema de Notificaciones
Semana 13-14: Sistema de Favoritos + Búsqueda Avanzada

→ RESULTADO: Mejor comunicación y engagement
```

### **FASE 3: OPTIMIZACIÓN Y FEATURES AVANZADAS (6-8 SEMANAS)**
```
Semana 15-16: Mapa Interactivo
Semana 17-18: Perfil de Usuario Completo
Semana 19-20: Dashboard de Métricas
Semana 21-22: Calendario de Disponibilidad

→ RESULTADO: App completa con features avanzadas
```

---

## 🎯 **CRITERIOS DE ÉXITO**

### **MVP (Fase 1)**
- [ ] Usuario puede buscar y reservar un espacio
- [ ] Host puede publicar espacios y gestionar reservas
- [ ] Pagos funcionan de forma segura
- [ ] Reviews funcionan y generan confianza
- [ ] App es usable y no tiene bugs críticos

### **POST-MVP (Fase 2)**
- [ ] Comunicación fluida entre host y guest
- [ ] Notificaciones mantienen a usuarios informados
- [ ] Búsqueda avanzada mejora discovery
- [ ] Favoritos aumentan engagement

### **COMPLETO (Fase 3)**
- [ ] Mapa mejora experiencia visual
- [ ] Perfiles completos generan confianza
- [ ] Métricas ayudan a hosts a optimizar
- [ ] Calendario simplifica gestión

---

## 📊 **ESTIMACIÓN TOTAL**

| Fase | Funcionalidades | Tiempo | Prioridad |
|------|----------------|--------|-----------|
| **Fase 1: MVP** | Reservas + Pagos + Reviews | 40-50h | 🔴 CRÍTICO |
| **Fase 2: Comunicación** | Mensajería + Notificaciones + Favoritos | 30-40h | 🟡 IMPORTANTE |
| **Fase 3: Avanzado** | Mapa + Perfil + Métricas + Calendario | 40-50h | 🟢 DESEABLE |
| **TOTAL** | | **110-140h** | |

**Traducido a sprints de 2 semanas (40h/sprint)**: 3-4 meses de desarrollo

---

## 🚀 **PRÓXIMO PASO INMEDIATO**

**RECOMENDACIÓN**: Empezar con **Sistema de Reservas** (Funcionalidad #1)

### **¿Por qué?**
1. Es la funcionalidad más crítica
2. Sin reservas, no hay marketplace
3. Desbloquea el desarrollo de pagos
4. Es lo que los usuarios necesitan primero

### **Plan de 2 Semanas**
```
Semana 1:
- Día 1-2: Date range picker + validaciones
- Día 3-4: Proceso de reserva (3 pasos)
- Día 5: Vista de reservas para guest

Semana 2:
- Día 1-2: Vista de reservas para host
- Día 3-4: Aceptar/Rechazar reservas
- Día 5: Testing + ajustes
```

---

## 📝 **NOTAS FINALES**

### **Dependencias Técnicas**
- Stripe SDK (para pagos)
- Google Maps API o Leaflet (para mapa)
- Chart.js (para gráficos de métricas)
- FullCalendar (para calendario de disponibilidad)
- Angular i18n (para multilenguaje)

### **Consideraciones de Backend**
- Algunos endpoints ya existen en microservicios actuales
- Payment microservice necesita crearse desde cero
- Messaging puede ir en booking_microservice o separado
- Notifications puede ser tabla en DB compartida

### **Riesgos**
- Integración con Stripe puede tomar más tiempo del estimado
- WebSockets para mensajería en tiempo real es complejo
- Calendario de disponibilidad con precios variables es complejo
- Testing E2E de pagos requiere ambiente de pruebas bien configurado

---

**Documento creado**: 5 de Noviembre de 2025  
**Próxima revisión**: Después de completar MVP  
**Responsable**: Equipo de Desarrollo Balconazo

