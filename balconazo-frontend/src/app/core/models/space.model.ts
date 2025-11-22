export interface Space {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  address: string;
  lat: number;
  lon: number;
  capacity: number;
  basePriceCents: number;
  areaSqm?: number;
  amenities?: string[];
  rules?: Record<string, any>;
  status: 'DRAFT' | 'ACTIVE' | 'SNOOZED' | 'DELETED' | 'draft' | 'active' | 'inactive'; // Soportar ambos formatos
  createdAt: string;
  updatedAt?: string;
  images?: SpaceImage[]; // Añadido
  averageRating?: number; // Rating promedio del espacio
  reviewCount?: number; // Número de reseñas
}

export interface SpaceImage {
  id: string;
  url: string;
  displayOrder: number;
  isPrimary: boolean;
  altText?: string;
  createdAt: string;
}

export interface CreateSpaceRequest {
  title: string;
  description: string;
  ownerId: string;
  address: string;
  lat: number;
  lon: number;
  capacity: number;
  basePriceCents: number;
  areaSqm?: number;
  amenities?: string[];
}

export interface SpaceSearchResult {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  address: string;
  lat: number;
  lon: number;
  distanceKm: number;
  capacity: number;
  basePriceCents: number;
  amenities: string[];
  avgRating: number;
  totalReviews: number;
  status: string;
}

export interface SearchRequest {
  lat: number;
  lon: number;
  radius?: number;
  minCapacity?: number;
  minPriceCents?: number;
  maxPriceCents?: number;
  minRating?: number;
  sortBy?: 'distance' | 'price' | 'rating' | 'capacity';
  page?: number;
  pageSize?: number;
}

export interface SearchResponse {
  spaces: SpaceSearchResult[];
  totalResults: number;
  page: number;
  pageSize: number;
  totalPages: number;
  searchLat: number;
  searchLon: number;
  searchRadiusKm: number;
}

