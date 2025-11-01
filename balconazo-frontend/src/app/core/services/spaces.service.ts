import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Space {
  id: string;
  title: string;
  description: string;
  address: string;
  lat: number;
  lon: number;
  capacity: number;
  basePriceCents: number;
  areaSqm?: number;
  amenities?: string[];
  status: string;
  ownerId: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateSpaceDTO {
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

export interface SpaceSearchParams {
  lat: number;
  lon: number;
  radius: number; // en metros
  minCapacity?: number;
  minPrice?: number;
  maxPrice?: number;
  minRating?: number;
  page?: number;
  size?: number;
}

export interface SearchResponse {
  spaces: any[];
  totalResults: number;
  page: number;
  pageSize: number;
  totalPages: number;
  searchLat: number;
  searchLon: number;
  searchRadiusKm: number;
}

@Injectable({
  providedIn: 'root'
})
export class SpacesService {
  private http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/catalog/spaces`;
  private readonly searchUrl = `${environment.apiUrl}/search/spaces`;

  /**
   * Obtener todos los espacios (requiere autenticación)
   */
  getAllSpaces(): Observable<Space[]> {
    return this.http.get<Space[]>(this.baseUrl);
  }

  /**
   * Obtener espacio por ID
   */
  getSpaceById(id: string): Observable<Space> {
    return this.http.get<Space>(`${this.baseUrl}/${id}`);
  }

  /**
   * Obtener espacios del usuario actual (owner)
   */
  getMySpaces(): Observable<Space[]> {
    return this.http.get<Space[]>(`${this.baseUrl}/owner/me`);
  }

  /**
   * Obtener espacios por owner ID
   */
  getSpacesByOwner(ownerId: string): Observable<Space[]> {
    return this.http.get<Space[]>(`${this.baseUrl}/owner/${ownerId}`);
  }

  /**
   * Crear nuevo espacio (solo HOST)
   */
  createSpace(data: CreateSpaceDTO): Observable<Space> {
    return this.http.post<Space>(this.baseUrl, data);
  }

  /**
   * Actualizar espacio existente
   */
  updateSpace(id: string, data: Partial<CreateSpaceDTO>): Observable<Space> {
    return this.http.put<Space>(`${this.baseUrl}/${id}`, data);
  }

  /**
   * Activar espacio
   */
  activateSpace(id: string): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${id}/activate`, {});
  }

  /**
   * Desactivar espacio
   */
  deactivateSpace(id: string): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${id}/deactivate`, {});
  }

  /**
   * Eliminar espacio
   */
  deleteSpace(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  /**
   * Búsqueda geoespacial de espacios (público, no requiere auth)
   */
  searchSpaces(params: SpaceSearchParams): Observable<SearchResponse> {
    let httpParams = new HttpParams()
      .set('lat', params.lat.toString())
      .set('lon', params.lon.toString())
      .set('radius', params.radius.toString());

    if (params.minCapacity) {
      httpParams = httpParams.set('minCapacity', params.minCapacity.toString());
    }
    if (params.minPrice) {
      httpParams = httpParams.set('minPrice', params.minPrice.toString());
    }
    if (params.maxPrice) {
      httpParams = httpParams.set('maxPrice', params.maxPrice.toString());
    }
    if (params.minRating) {
      httpParams = httpParams.set('minRating', params.minRating.toString());
    }
    if (params.page !== undefined) {
      httpParams = httpParams.set('page', params.page.toString());
    }
    if (params.size !== undefined) {
      httpParams = httpParams.set('size', params.size.toString());
    }

    return this.http.get<SearchResponse>(this.searchUrl, { params: httpParams });
  }

  /**
   * Obtener espacios activos (públicos)
   */
  getActiveSpaces(): Observable<Space[]> {
    return this.http.get<Space[]>(`${this.baseUrl}/active`);
  }
}

