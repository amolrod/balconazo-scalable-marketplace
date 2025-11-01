# 🎨 Sistema de Diseño BalconazoApp

## Índice
- [Colores](#colores)
- [Tipografía](#tipografía)
- [Espaciado](#espaciado)
- [Sombras](#sombras)
- [Componentes](#componentes)
- [Ejemplos de Uso](#ejemplos-de-uso)

---

## Colores

### Paleta Primaria
```scss
--primary-500: #F43F5E  // Color principal
--primary-600: #E11D48  // Hover states
--primary-700: #BE123C  // Active states
```

**Uso:** Botones principales, enlaces importantes, badges destacados, navbar logo

### Grises Neutros
```scss
--gray-50: #F9FAFB   // Backgrounds sutiles
--gray-100: #F3F4F6  // Hover backgrounds
--gray-200: #E5E7EB  // Borders
--gray-700: #374151  // Texto principal
--gray-900: #111827  // Headings
```

### Colores Semánticos
- ✅ **Success:** `#10B981` - Confirmaciones, estados activos
- ⚠️ **Warning:** `#F59E0B` - Alertas, estados pendientes
- ❌ **Error:** `#EF4444` - Errores, validaciones fallidas
- ℹ️ **Info:** `#3B82F6` - Información adicional

---

## Tipografía

### Jerarquía de Tamaños
```
h1: 36px (--text-4xl) - Títulos de hero, páginas principales
h2: 30px (--text-3xl) - Títulos de sección
h3: 24px (--text-2xl) - Subtítulos importantes
h4: 20px (--text-xl)  - Card titles
body: 16px (--text-base) - Texto general
caption: 14px (--text-sm) - Metadata, labels
```

### Pesos de Fuente
- **400 (Normal):** Texto general
- **500 (Medium):** Links, navbar items
- **600 (Semibold):** Botones, labels importantes
- **700 (Bold):** Headings, precios
- **800 (Extrabold):** Logo, hero titles

### Line Heights
```scss
--leading-tight: 1.25    // Headings
--leading-normal: 1.5    // Body text
--leading-relaxed: 1.625 // Subtitles
```

---

## Espaciado

### Sistema de 4px
```
--space-2:  8px   // Padding interno mínimo
--space-3:  12px  // Padding buttons
--space-4:  16px  // Gap entre elementos pequeños
--space-6:  24px  // Gap cards, padding containers
--space-8:  32px  // Secciones
--space-12: 48px  // Separación entre módulos
--space-20: 80px  // Padding vertical secciones grandes
```

**Regla general:** Usa múltiplos de 4px para mantener consistencia

---

## Sombras

### Niveles de Elevación
```scss
--shadow-sm:  // Elementos sutiles (input focus)
  0 1px 3px 0 rgba(0, 0, 0, 0.1)

--shadow-md:  // Cards estáticos
  0 4px 6px -1px rgba(0, 0, 0, 0.1)

--shadow-lg:  // Cards hover
  0 10px 15px -3px rgba(0, 0, 0, 0.1)

--shadow-xl:  // Search bar, modals
  0 20px 25px -5px rgba(0, 0, 0, 0.1)

--shadow-primary:  // Botones primarios hover
  0 10px 30px -5px rgba(244, 63, 94, 0.3)
```

---

## Componentes

### 🔘 Botones

#### Primary Button
```html
<button class="btn btn-primary">
  Reservar ahora
</button>
```
**Cuándo usar:** Acciones principales, CTAs importantes

#### Secondary Button
```html
<button class="btn btn-secondary">
  Ver más
</button>
```
**Cuándo usar:** Acciones secundarias, navegación

#### Ghost Button
```html
<button class="btn btn-ghost">
  Cancelar
</button>
```
**Cuándo usar:** Acciones terciarias, estados desenfatizados

#### Tamaños
```html
<button class="btn btn-sm btn-primary">Small</button>
<button class="btn btn-primary">Regular</button>
<button class="btn btn-lg btn-primary">Large</button>
```

---

### 🃏 Space Card

#### Estructura HTML
```html
<article class="space-card">
  <div class="space-card-image-wrapper">
    <img src="..." alt="..." class="space-card-image">
    <span class="space-card-badge featured">Destacado</span>
    <span class="space-card-rating">⭐ 4.9</span>
  </div>
  
  <div class="space-card-body">
    <div class="space-card-location">📍 Madrid, Malasaña</div>
    <h3 class="space-card-title">Ático con terraza panorámica</h3>
    
    <div class="space-card-features">
      <span class="space-card-feature">👥 8 personas</span>
      <span class="space-card-feature">📐 50m²</span>
    </div>
    
    <div class="space-card-footer">
      <div class="space-card-price">
        <span class="space-card-price-amount">25€</span>
        <span class="space-card-price-period">/hora</span>
      </div>
      <button class="btn btn-sm btn-primary">Ver más</button>
    </div>
  </div>
</article>
```

#### Variantes de Badge
```html
<span class="space-card-badge">Nuevo</span>
<span class="space-card-badge featured">Destacado</span>
```

---

### 🔍 Search Bar

```html
<div class="search-bar">
  <div class="search-input-group">
    <label class="search-input-label">Ubicación</label>
    <input type="text" class="search-input" placeholder="¿Dónde?">
  </div>
  
  <div class="search-input-group">
    <label class="search-input-label">Fecha</label>
    <input type="date" class="search-input">
  </div>
  
  <div class="search-input-group">
    <label class="search-input-label">Capacidad</label>
    <input type="number" class="search-input" placeholder="Personas">
  </div>
  
  <button class="search-btn">
    <!-- Icono SVG -->
  </button>
</div>
```

**Features:**
- ✨ Efecto de elevación al focus
- 📱 Responsive (se apila en móvil)
- 🎯 Labels uppercase para claridad

---

### 🧭 Navbar

```html
<nav class="navbar" id="navbar">
  <div class="container navbar-container">
    <a href="/" class="navbar-logo">Balconazo</a>
    
    <ul class="navbar-menu">
      <li><a href="#" class="navbar-link active">Explorar</a></li>
      <li><a href="#" class="navbar-link">Mis Reservas</a></li>
    </ul>

    <div class="flex items-center gap-4">
      <button class="btn btn-ghost">Iniciar Sesión</button>
      <button class="btn btn-primary">Registrarse</button>
    </div>
  </div>
</nav>
```

**JavaScript para efecto scroll:**
```javascript
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  if (window.pageYOffset > 50) {
    navbar.classList.add('scrolled');
  } else {
    navbar.classList.remove('scrolled');
  }
});
```

---

### 📝 Formularios

```html
<div class="form-group">
  <label class="form-label" for="email">Email</label>
  <input type="email" id="email" class="form-input" placeholder="tu@email.com">
</div>
```

**Estados:**
- **Focus:** Borde primario + sombra de color + scale 1.01
- **Disabled:** Background gris + cursor not-allowed
- **Error:** Agregar clase `.error` (necesita implementación)

---

### 🏷️ Badges

```html
<span class="badge badge-primary">Destacado</span>
<span class="badge badge-success">Confirmado</span>
<span class="badge badge-warning">Pendiente</span>
<span class="badge badge-error">Cancelado</span>
```

---

## Ejemplos de Uso

### Hero Section Completa
```html
<section class="hero">
  <div class="container">
    <div class="hero-content">
      <h1 class="hero-title animate-fade-in-up">
        Descubre espacios únicos
      </h1>
      <p class="hero-subtitle animate-fade-in-up" style="animation-delay: 0.1s;">
        Miles de espacios verificados te esperan
      </p>
      <div class="search-bar animate-fade-in-up" style="animation-delay: 0.2s;">
        <!-- Search bar aquí -->
      </div>
    </div>
  </div>
</section>
```

### Grid de Espacios Responsive
```html
<div class="container">
  <div class="grid grid-cols-4">
    <!-- Space cards aquí -->
  </div>
</div>
```

**Comportamiento:**
- **Desktop (>1024px):** 4 columnas
- **Tablet (768-1023px):** 2 columnas
- **Mobile (<768px):** 1 columna

---

## Utilidades CSS

### Flexbox
```html
<div class="flex items-center justify-between gap-4">
  <!-- Contenido -->
</div>
```

### Text Utilities
```html
<h2 class="text-center font-bold text-2xl">Título</h2>
```

### Responsive Visibility
```html
<button class="hide-mobile">Solo desktop</button>
<button class="hide-desktop">Solo mobile</button>
```

---

## Animaciones

### Clases de Animación
```html
<div class="animate-fade-in">Aparece suavemente</div>
<div class="animate-fade-in-up">Aparece desde abajo</div>
<div class="animate-slide-in-right">Entra desde la derecha</div>
```

### Delays personalizados
```html
<h1 class="animate-fade-in-up" style="animation-delay: 0s;">Primero</h1>
<p class="animate-fade-in-up" style="animation-delay: 0.1s;">Segundo</p>
<div class="animate-fade-in-up" style="animation-delay: 0.2s;">Tercero</div>
```

---

## Loading States

### Spinner
```html
<div class="spinner"></div>
```

### Skeleton Loading
```html
<div class="skeleton" style="height: 200px; margin-bottom: 12px;"></div>
<div class="skeleton" style="height: 20px; margin-bottom: 8px;"></div>
<div class="skeleton" style="height: 20px; width: 80%;"></div>
```

---

## Mejores Prácticas

### ✅ Hacer
- Usar variables CSS en lugar de valores hardcodeados
- Mantener espaciado consistente con el sistema de 4px
- Aplicar transiciones a todos los elementos interactivos
- Usar clases utilitarias antes de crear CSS custom
- Testear en móvil, tablet y desktop

### ❌ Evitar
- Magic numbers (usa variables)
- Colores hardcodeados (#ccc, #333)
- Sombras sin rgba (usa las variables)
- Crear componentes sin estados hover/focus/active
- Padding/margin inconsistentes

---

## Recursos Adicionales

### Iconos Recomendados
- [Heroicons](https://heroicons.com/) - Free MIT icons
- [Lucide Icons](https://lucide.dev/) - Beautiful SVG icons
- [Feather Icons](https://feathericons.com/) - Simply beautiful

### Fuentes Recomendadas
- **Primary:** System fonts (ya incluidas)
- **Display (opcional):** Inter, Circular, Poppins

### Imágenes de Prueba
- [Unsplash](https://unsplash.com/s/photos/apartment)
- [Pexels](https://pexels.com/)

---

## Archivo de Ejemplo Completo

Consulta `components-showcase.html` para ver todos los componentes implementados con ejemplos funcionales.

---

**Última actualización:** Noviembre 2025  
**Versión:** 1.0.0
 
