/**
 * Filter Models
 * Modelos para filtros de búsqueda y ordenamiento
 */

export type SortOrder = 'asc' | 'desc';

export type SpaceSortBy = 'distance' | 'price' | 'rating' | 'createdAt' | 'capacity';

export interface PriceFilter {
  min?: number; // En centavos
  max?: number; // En centavos
}

export interface CapacityFilter {
  min?: number;
  max?: number;
}

export interface DateFilter {
  from?: string; // ISO date string
  to?: string;   // ISO date string
}

export interface LocationFilter {
  lat: number;
  lon: number;
  radius: number; // En metros
}

export interface SpaceFilters {
  location?: LocationFilter;
  price?: PriceFilter;
  capacity?: CapacityFilter;
  date?: DateFilter;
  amenities?: string[]; // Array de amenities requeridos
  rating?: number; // Mínimo rating (1-5)
  availability?: 'available' | 'all'; // Solo disponibles o todos
}

export interface SearchParams {
  filters: SpaceFilters;
  sortBy?: SpaceSortBy;
  sortOrder?: SortOrder;
  page?: number;
  pageSize?: number;
}

export interface FilterOption {
  value: string | number;
  label: string;
  count?: number; // Número de resultados con este filtro
}

export interface AmenityOption extends FilterOption {
  icon?: string; // Nombre del icono o emoji
}

export interface PriceRangeOption {
  min: number;
  max: number;
  label: string;
}

// Opciones de filtros predefinidas
export const PRICE_RANGES: PriceRangeOption[] = [
  { min: 0, max: 2000, label: 'Menos de €20' },
  { min: 2000, max: 5000, label: '€20 - €50' },
  { min: 5000, max: 10000, label: '€50 - €100' },
  { min: 10000, max: 20000, label: '€100 - €200' },
  { min: 20000, max: 999999, label: 'Más de €200' }
];

export const CAPACITY_OPTIONS: FilterOption[] = [
  { value: 1, label: '1-5 personas' },
  { value: 6, label: '6-10 personas' },
  { value: 11, label: '11-20 personas' },
  { value: 21, label: '21-50 personas' },
  { value: 51, label: 'Más de 50' }
];

export const RADIUS_OPTIONS: FilterOption[] = [
  { value: 1000, label: '1 km' },
  { value: 2000, label: '2 km' },
  { value: 5000, label: '5 km' },
  { value: 10000, label: '10 km' },
  { value: 20000, label: '20 km' },
  { value: 50000, label: '50 km' }
];

export const AMENITIES_OPTIONS: AmenityOption[] = [
  { value: 'wifi', label: 'WiFi', icon: '📶' },
  { value: 'parking', label: 'Parking', icon: '🅿️' },
  { value: 'terraza', label: 'Terraza', icon: '🏞️' },
  { value: 'cocina', label: 'Cocina', icon: '🍳' },
  { value: 'barbacoa', label: 'Barbacoa', icon: '🔥' },
  { value: 'piscina', label: 'Piscina', icon: '🏊' },
  { value: 'aire_acondicionado', label: 'Aire Acondicionado', icon: '❄️' },
  { value: 'calefaccion', label: 'Calefacción', icon: '🔥' },
  { value: 'musica', label: 'Sistema de Música', icon: '🎵' },
  { value: 'proyector', label: 'Proyector', icon: '📽️' },
  { value: 'mascotas', label: 'Se permiten mascotas', icon: '🐕' },
  { value: 'fumadores', label: 'Se permite fumar', icon: '🚬' }
];

export const RATING_OPTIONS: FilterOption[] = [
  { value: 4.5, label: '4.5+ estrellas' },
  { value: 4.0, label: '4.0+ estrellas' },
  { value: 3.5, label: '3.5+ estrellas' },
  { value: 3.0, label: '3.0+ estrellas' }
];

