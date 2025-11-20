# Guía de Integración API Frontend - Parte 4: Búsqueda de Espacios

## 📋 Índice
1. [Introducción](#introducción)
2. [Endpoint de Búsqueda](#endpoint-de-búsqueda)
3. [Filtros Disponibles](#filtros-disponibles)
4. [Paginación y Ordenamiento](#paginación-y-ordenamiento)
5. [Ejemplos de Código](#ejemplos-de-código)
6. [Casos de Uso](#casos-de-uso)

---

## Introducción

El módulo de **Búsqueda (Search)** permite:
- **Buscar espacios** por ubicación (location)
- **Filtrar** por precio máximo (maxPrice)
- **Filtrar** por capacidad mínima (minCapacity)
- **Combinar múltiples filtros** en una sola consulta
- **Obtener resultados en tiempo real** sin autenticación

**Base URL**: `http://localhost:8080/api/search` (vía API Gateway)

**Servicio**: Search Microservice (Puerto 8083)

**Importante**: El endpoint de búsqueda **NO requiere autenticación**, permitiendo a usuarios anónimos explorar espacios antes de registrarse.

---

## Endpoint de Búsqueda

### GET /api/search

**Descripción**: Busca espacios disponibles aplicando filtros opcionales.

**Headers**:
```
No requiere Authorization (endpoint público)
```

**Query Parameters** (todos opcionales):

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `location` | string | Búsqueda parcial por ubicación (case-insensitive) | `Barcelona` |
| `maxPrice` | number | Precio máximo por hora (inclusive) | `50.00` |
| `minCapacity` | integer | Capacidad mínima de personas (inclusive) | `10` |

**Ejemplos de URLs**:

```
# Sin filtros (todos los espacios)
GET /api/search

# Por ubicación
GET /api/search?location=Barcelona

# Por precio máximo
GET /api/search?maxPrice=50.00

# Por capacidad mínima
GET /api/search?minCapacity=15

# Combinación de filtros
GET /api/search?location=Madrid&maxPrice=40&minCapacity=10
```

**Response 200 OK**:
```json
[
  {
    "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "name": "Terraza con Vista al Mar",
    "description": "Hermosa terraza de 50m² con vistas panorámicas al océano.",
    "location": "Barcelona, España",
    "pricePerHour": 45.00,
    "capacity": 20,
    "amenities": ["WiFi", "Muebles de exterior", "Parrilla"],
    "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "available": true,
    "createdAt": "2025-11-20T10:30:00"
  },
  {
    "id": "7f31f234-c3ae-5733-bd26-e5e1c81a7bf1",
    "name": "Jardín Privado Centro Ciudad",
    "description": "Oasis urbano en pleno centro con zona verde.",
    "location": "Barcelona, Cataluña",
    "pricePerHour": 35.00,
    "capacity": 15,
    "amenities": ["Zona verde", "Pérgola"],
    "ownerId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "available": true,
    "createdAt": "2025-11-20T11:00:00"
  }
]
```

**Response Codes**:
- `200 OK`: Búsqueda exitosa (puede retornar lista vacía `[]` si no hay resultados)
- `400 Bad Request`: Parámetros inválidos (ej: maxPrice negativo)
- `500 Internal Server Error`: Error del servidor

**Respuesta vacía** (sin resultados):
```json
[]
```

---

## Filtros Disponibles

### 1. Filtro por Ubicación (location)

**Comportamiento**:
- Búsqueda **parcial** (substring match)
- **Case-insensitive** (ignora mayúsculas/minúsculas)
- Busca en cualquier parte del campo `location`

**Ejemplos**:

```
# Buscar "barcelona" en ubicación
GET /api/search?location=barcelona

Resultados:
✅ "Barcelona, España"
✅ "Barcelona, Cataluña"
✅ "Zona Universitaria, Barcelona"
❌ "Madrid, España"
```

```
# Buscar "españa"
GET /api/search?location=españa

Resultados:
✅ "Barcelona, España"
✅ "Madrid, España"
✅ "Valencia, España"
❌ "Lisboa, Portugal"
```

**Casos especiales**:
- Espacios en blanco: `location=Madrid Centro` busca "Madrid Centro" literalmente
- Caracteres especiales: Se respetan (ej: `location=São Paulo`)
- URL encoding: Usar `%20` para espacios (ej: `location=New%20York`)

### 2. Filtro por Precio Máximo (maxPrice)

**Comportamiento**:
- Filtra espacios con `pricePerHour <= maxPrice`
- Acepta valores decimales (ej: `50.50`)
- Debe ser mayor que 0

**Ejemplos**:

```
# Espacios de hasta 40€/hora
GET /api/search?maxPrice=40.00

Resultados:
✅ pricePerHour: 30.00
✅ pricePerHour: 40.00  (inclusive)
❌ pricePerHour: 45.00
❌ pricePerHour: 50.00
```

**Validaciones**:
- `maxPrice=0` → Error 400 (precio debe ser > 0)
- `maxPrice=-10` → Error 400 (precio no puede ser negativo)
- `maxPrice=1000000` → Válido (filtra espacios muy caros)

### 3. Filtro por Capacidad Mínima (minCapacity)

**Comportamiento**:
- Filtra espacios con `capacity >= minCapacity`
- Debe ser un número entero
- Debe ser mayor que 0

**Ejemplos**:

```
# Espacios para al menos 15 personas
GET /api/search?minCapacity=15

Resultados:
❌ capacity: 10
✅ capacity: 15  (inclusive)
✅ capacity: 20
✅ capacity: 50
```

**Casos de uso**:
- Eventos grandes: `minCapacity=50`
- Reuniones pequeñas: `minCapacity=5`
- Fiestas medianas: `minCapacity=20`

### 4. Combinación de Filtros

Todos los filtros son **acumulativos** (AND lógico):

```
GET /api/search?location=Barcelona&maxPrice=50&minCapacity=15

Condiciones:
✅ location CONTAINS "Barcelona"
AND
✅ pricePerHour <= 50
AND
✅ capacity >= 15
```

**Ejemplo de resultado válido**:
```json
{
  "name": "Terraza Barcelona",
  "location": "Barcelona, España",  ← Contiene "Barcelona"
  "pricePerHour": 45.00,           ← <= 50
  "capacity": 20                   ← >= 15
}
```

**Ejemplo de resultado inválido**:
```json
{
  "name": "Jardín Madrid",
  "location": "Madrid, España",    ❌ No contiene "Barcelona"
  "pricePerHour": 30.00,           ✅ <= 50
  "capacity": 25                   ✅ >= 15
}
// Este espacio NO aparecería en los resultados
```

---

## Paginación y Ordenamiento

### Estado Actual

**Actualmente NO implementado**:
- No hay paginación (devuelve todos los resultados)
- No hay ordenamiento personalizado

**Orden por defecto**:
- Los resultados se devuelven en orden de inserción en la base de datos

### Recomendaciones para Implementar en Frontend

Mientras no haya paginación en backend, implementar en frontend:

```typescript
// Paginación en cliente
function paginateResults<T>(
  items: T[],
  page: number,
  pageSize: number
): T[] {
  const start = (page - 1) * pageSize;
  const end = start + pageSize;
  return items.slice(start, end);
}

// Ordenamiento en cliente
function sortSpaces(
  spaces: Space[],
  sortBy: 'price' | 'capacity' | 'name',
  order: 'asc' | 'desc' = 'asc'
): Space[] {
  const sorted = [...spaces].sort((a, b) => {
    let comparison = 0;
    
    switch (sortBy) {
      case 'price':
        comparison = a.pricePerHour - b.pricePerHour;
        break;
      case 'capacity':
        comparison = a.capacity - b.capacity;
        break;
      case 'name':
        comparison = a.name.localeCompare(b.name);
        break;
    }
    
    return order === 'asc' ? comparison : -comparison;
  });
  
  return sorted;
}
```

### Futura Implementación (Backend)

**Parámetros sugeridos para futuras versiones**:

```
GET /api/search?location=Barcelona&page=1&size=20&sort=pricePerHour,asc
```

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `page` | Número de página (1-indexed) | `1` |
| `size` | Elementos por página | `20` |
| `sort` | Campo y dirección | `pricePerHour,asc` |

---

## Ejemplos de Código

### Service de Búsqueda

```typescript
// services/searchService.ts
const API_BASE = 'http://localhost:8080/api/search';

export interface SearchFilters {
  location?: string;
  maxPrice?: number;
  minCapacity?: number;
}

export interface Space {
  id: string;
  name: string;
  description: string;
  location: string;
  pricePerHour: number;
  capacity: number;
  amenities: string[];
  ownerId: string;
  available: boolean;
  createdAt: string;
}

export async function searchSpaces(filters: SearchFilters = {}): Promise<Space[]> {
  // Construir query string
  const params = new URLSearchParams();
  
  if (filters.location) {
    params.append('location', filters.location);
  }
  
  if (filters.maxPrice !== undefined && filters.maxPrice > 0) {
    params.append('maxPrice', filters.maxPrice.toString());
  }
  
  if (filters.minCapacity !== undefined && filters.minCapacity > 0) {
    params.append('minCapacity', filters.minCapacity.toString());
  }
  
  const queryString = params.toString();
  const url = queryString ? `${API_BASE}?${queryString}` : API_BASE;
  
  const response = await fetch(url);
  
  if (!response.ok) {
    throw new Error('Failed to search spaces');
  }
  
  return response.json();
}
```

### Componente de Búsqueda

```typescript
// SearchSpaces.tsx
import { useState, useEffect } from 'react';
import { searchSpaces, SearchFilters, Space } from './services/searchService';
import { Link } from 'react-router-dom';

function SearchSpaces() {
  const [filters, setFilters] = useState<SearchFilters>({
    location: '',
    maxPrice: undefined,
    minCapacity: undefined
  });
  
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  // Búsqueda automática al cambiar filtros (con debounce)
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      performSearch();
    }, 500); // Esperar 500ms después de dejar de escribir
    
    return () => clearTimeout(timeoutId);
  }, [filters]);
  
  async function performSearch() {
    setLoading(true);
    setError('');
    
    try {
      const results = await searchSpaces(filters);
      setSpaces(results);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }
  
  function handleFilterChange(key: keyof SearchFilters, value: any) {
    setFilters(prev => ({
      ...prev,
      [key]: value || undefined
    }));
  }
  
  return (
    <div className="search-page">
      <h1>Buscar Espacios</h1>
      
      {/* Filtros */}
      <div className="filters">
        <div className="filter-group">
          <label>Ubicación</label>
          <input
            type="text"
            placeholder="Ej: Barcelona, Madrid..."
            value={filters.location || ''}
            onChange={e => handleFilterChange('location', e.target.value)}
          />
        </div>
        
        <div className="filter-group">
          <label>Precio Máximo (€/hora)</label>
          <input
            type="number"
            placeholder="Ej: 50"
            min="0"
            step="0.01"
            value={filters.maxPrice || ''}
            onChange={e => handleFilterChange('maxPrice', parseFloat(e.target.value) || undefined)}
          />
        </div>
        
        <div className="filter-group">
          <label>Capacidad Mínima</label>
          <input
            type="number"
            placeholder="Ej: 10"
            min="1"
            value={filters.minCapacity || ''}
            onChange={e => handleFilterChange('minCapacity', parseInt(e.target.value) || undefined)}
          />
        </div>
      </div>
      
      {/* Resultados */}
      <div className="results">
        {loading && <div className="loading">Buscando...</div>}
        
        {error && <div className="error">{error}</div>}
        
        {!loading && !error && (
          <>
            <h2>
              {spaces.length} espacio{spaces.length !== 1 ? 's' : ''} encontrado{spaces.length !== 1 ? 's' : ''}
            </h2>
            
            {spaces.length === 0 ? (
              <p className="no-results">
                No se encontraron espacios con estos filtros. Prueba ajustar los criterios de búsqueda.
              </p>
            ) : (
              <div className="space-grid">
                {spaces.map(space => (
                  <SpaceCard key={space.id} space={space} />
                ))}
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function SpaceCard({ space }: { space: Space }) {
  return (
    <Link to={`/spaces/${space.id}`} className="space-card">
      <div className="space-header">
        <h3>{space.name}</h3>
        <span className="price">{space.pricePerHour}€/hora</span>
      </div>
      
      <p className="location">📍 {space.location}</p>
      <p className="description">{space.description}</p>
      
      <div className="space-meta">
        <span className="capacity">👥 Hasta {space.capacity} personas</span>
      </div>
      
      {space.amenities.length > 0 && (
        <div className="amenities">
          {space.amenities.slice(0, 3).map(amenity => (
            <span key={amenity} className="tag">{amenity}</span>
          ))}
          {space.amenities.length > 3 && (
            <span className="tag">+{space.amenities.length - 3}</span>
          )}
        </div>
      )}
    </Link>
  );
}
```

### Búsqueda con Debounce (Hook Personalizado)

```typescript
// hooks/useDebounce.ts
import { useState, useEffect } from 'react';

export function useDebounce<T>(value: T, delay: number = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);
  
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    
    return () => clearTimeout(timeoutId);
  }, [value, delay]);
  
  return debouncedValue;
}

// Uso en componente
function SearchWithDebounce() {
  const [filters, setFilters] = useState<SearchFilters>({});
  const debouncedFilters = useDebounce(filters, 500);
  
  useEffect(() => {
    // Solo se ejecuta 500ms después de dejar de escribir
    performSearch(debouncedFilters);
  }, [debouncedFilters]);
  
  // ...
}
```

### Búsqueda con Filtros Avanzados (Frontend)

```typescript
// AdvancedSearch.tsx
import { useState } from 'react';
import { searchSpaces, Space } from './services/searchService';

interface AdvancedFilters {
  location: string;
  maxPrice: number;
  minCapacity: number;
  amenities: string[]; // Filtro local (no soportado por backend)
  sortBy: 'price' | 'capacity' | 'name';
  sortOrder: 'asc' | 'desc';
}

function AdvancedSearch() {
  const [filters, setFilters] = useState<AdvancedFilters>({
    location: '',
    maxPrice: 0,
    minCapacity: 0,
    amenities: [],
    sortBy: 'price',
    sortOrder: 'asc'
  });
  
  const [spaces, setSpaces] = useState<Space[]>([]);
  
  async function performSearch() {
    // 1. Buscar con filtros soportados por backend
    const results = await searchSpaces({
      location: filters.location,
      maxPrice: filters.maxPrice || undefined,
      minCapacity: filters.minCapacity || undefined
    });
    
    // 2. Aplicar filtros locales (amenities)
    let filtered = results;
    
    if (filters.amenities.length > 0) {
      filtered = results.filter(space =>
        filters.amenities.every(amenity =>
          space.amenities.includes(amenity)
        )
      );
    }
    
    // 3. Ordenar localmente
    filtered = sortSpaces(filtered, filters.sortBy, filters.sortOrder);
    
    setSpaces(filtered);
  }
  
  function sortSpaces(
    spaces: Space[],
    sortBy: string,
    order: string
  ): Space[] {
    return [...spaces].sort((a, b) => {
      let comparison = 0;
      
      if (sortBy === 'price') {
        comparison = a.pricePerHour - b.pricePerHour;
      } else if (sortBy === 'capacity') {
        comparison = a.capacity - b.capacity;
      } else if (sortBy === 'name') {
        comparison = a.name.localeCompare(b.name);
      }
      
      return order === 'asc' ? comparison : -comparison;
    });
  }
  
  return (
    <div>
      {/* Filtros avanzados */}
      <div className="advanced-filters">
        {/* Location, Price, Capacity (igual que antes) */}
        
        {/* Filtro de amenities (local) */}
        <div>
          <label>Comodidades</label>
          <select
            multiple
            value={filters.amenities}
            onChange={e => {
              const selected = Array.from(e.target.selectedOptions, opt => opt.value);
              setFilters({ ...filters, amenities: selected });
            }}
          >
            <option value="WiFi">WiFi</option>
            <option value="Parking">Parking</option>
            <option value="Cocina">Cocina</option>
            <option value="Proyector">Proyector</option>
          </select>
        </div>
        
        {/* Ordenamiento */}
        <div>
          <label>Ordenar por</label>
          <select
            value={filters.sortBy}
            onChange={e => setFilters({ ...filters, sortBy: e.target.value as any })}
          >
            <option value="price">Precio</option>
            <option value="capacity">Capacidad</option>
            <option value="name">Nombre</option>
          </select>
          
          <select
            value={filters.sortOrder}
            onChange={e => setFilters({ ...filters, sortOrder: e.target.value as any })}
          >
            <option value="asc">Ascendente</option>
            <option value="desc">Descendente</option>
          </select>
        </div>
        
        <button onClick={performSearch}>Buscar</button>
      </div>
      
      {/* Resultados */}
      <div className="results">
        {spaces.map(space => (
          <SpaceCard key={space.id} space={space} />
        ))}
      </div>
    </div>
  );
}
```

---

## Casos de Uso

### 1. Búsqueda Simple por Ubicación

```typescript
// Usuario busca espacios en Barcelona
async function searchInBarcelona() {
  const results = await searchSpaces({ location: 'Barcelona' });
  
  console.log(`Encontrados ${results.length} espacios en Barcelona`);
  
  results.forEach(space => {
    console.log(`- ${space.name} (${space.pricePerHour}€/hora)`);
  });
}
```

### 2. Búsqueda por Presupuesto

```typescript
// Usuario busca espacios de hasta 40€/hora
async function searchByBudget() {
  const results = await searchSpaces({ maxPrice: 40 });
  
  const cheapest = results.sort((a, b) => a.pricePerHour - b.pricePerHour)[0];
  
  console.log(`Espacio más económico: ${cheapest.name} (${cheapest.pricePerHour}€/hora)`);
}
```

### 3. Búsqueda para Evento Grande

```typescript
// Usuario necesita espacio para 50+ personas
async function searchForBigEvent() {
  const results = await searchSpaces({ minCapacity: 50 });
  
  console.log(`${results.length} espacios con capacidad para 50+ personas`);
  
  // Ordenar por capacidad (más grande primero)
  const sorted = results.sort((a, b) => b.capacity - a.capacity);
  
  console.log(`El más grande: ${sorted[0].name} (${sorted[0].capacity} personas)`);
}
```

### 4. Búsqueda Combinada

```typescript
// Usuario busca: Barcelona, máx 50€, mín 20 personas
async function searchCombined() {
  const results = await searchSpaces({
    location: 'Barcelona',
    maxPrice: 50,
    minCapacity: 20
  });
  
  console.log('Espacios que cumplen todos los criterios:');
  
  results.forEach(space => {
    console.log(`
      ${space.name}
      📍 ${space.location}
      💰 ${space.pricePerHour}€/hora
      👥 ${space.capacity} personas
    `);
  });
}
```

### 5. Búsqueda sin Autenticación (Landing Page)

```typescript
// En una landing page pública
function PublicSearch() {
  const [location, setLocation] = useState('');
  const [results, setResults] = useState<Space[]>([]);
  
  async function quickSearch() {
    // No requiere token de autenticación
    const spaces = await searchSpaces({ location });
    setResults(spaces);
  }
  
  return (
    <div className="landing-search">
      <h1>Encuentra el espacio perfecto</h1>
      
      <div className="search-bar">
        <input
          type="text"
          placeholder="¿Dónde buscas?"
          value={location}
          onChange={e => setLocation(e.target.value)}
        />
        <button onClick={quickSearch}>Buscar</button>
      </div>
      
      {results.length > 0 && (
        <div className="preview-results">
          <p>{results.length} espacios disponibles</p>
          <Link to="/register">Regístrate para reservar</Link>
        </div>
      )}
    </div>
  );
}
```

### 6. Mapa de Resultados (Integración con Google Maps)

```typescript
// Mostrar resultados en mapa
function SearchMap() {
  const [spaces, setSpaces] = useState<Space[]>([]);
  
  async function searchAndMap() {
    const results = await searchSpaces({ location: 'Barcelona' });
    setSpaces(results);
  }
  
  return (
    <div className="search-map">
      <GoogleMap
        markers={spaces.map(space => ({
          position: parseLocation(space.location), // Necesita geocoding
          title: space.name,
          onClick: () => navigate(`/spaces/${space.id}`)
        }))}
      />
      
      <div className="results-sidebar">
        {spaces.map(space => (
          <SpaceCard key={space.id} space={space} />
        ))}
      </div>
    </div>
  );
}
```

---

## Resumen de Conceptos Clave

1. **Endpoint público**: No requiere autenticación (ideal para landing pages)
2. **Búsqueda flexible**: Filtros opcionales y combinables
3. **Location parcial**: Búsqueda por substring, case-insensitive
4. **Filtros acumulativos**: Todos los filtros se aplican con AND lógico
5. **Sin paginación**: Devuelve todos los resultados (implementar paginación en frontend)
6. **Respuesta vacía**: `[]` si no hay resultados
7. **Extensible**: Fácil agregar filtros locales en frontend (amenities, ordenamiento)

---

## Integración con Otros Módulos

### Flujo Típico Usuario Nuevo

```
1. Usuario visita landing page
   ↓
2. Busca espacios sin autenticación (GET /api/search)
   ↓
3. Ve resultados y hace clic en un espacio
   ↓
4. Se le pide registrarse para reservar
   ↓
5. Completa registro (POST /api/auth/register)
   ↓
6. Crea reserva (POST /api/bookings)
```

### Flujo Usuario Registrado

```
1. Usuario autenticado busca espacios
   ↓
2. Filtra por ubicación y presupuesto
   ↓
3. Selecciona espacio
   ↓
4. Crea reserva directamente
```

---

## Mejoras Futuras Sugeridas

### Backend

1. **Paginación**:
   ```
   GET /api/search?page=1&size=20
   ```

2. **Ordenamiento**:
   ```
   GET /api/search?sort=pricePerHour,asc
   ```

3. **Búsqueda full-text**:
   ```
   GET /api/search?query=terraza+barcelona+wifi
   ```

4. **Filtro por amenities**:
   ```
   GET /api/search?amenities=WiFi,Parking
   ```

5. **Filtro por disponibilidad de fechas**:
   ```
   GET /api/search?startDate=2025-12-01&endDate=2025-12-03
   ```

6. **Búsqueda geográfica**:
   ```
   GET /api/search?lat=41.3851&lon=2.1734&radius=5km
   ```

### Frontend

1. **Autocompletado de ubicaciones**:
   - Integrar Google Places API
   - Sugerencias mientras se escribe

2. **Mapa interactivo**:
   - Mostrar resultados en Google Maps
   - Filtrar por área visible en el mapa

3. **Filtros persistentes**:
   - Guardar filtros en URL (query params)
   - Compartir búsquedas vía enlace

4. **Historial de búsquedas**:
   - Guardar búsquedas recientes en localStorage
   - Sugerencias basadas en historial

---

## Siguiente Documento

Continuar con: **[BACKEND_ARCHITECTURE.md](./BACKEND_ARCHITECTURE.md)** - Arquitectura Completa del Backend

