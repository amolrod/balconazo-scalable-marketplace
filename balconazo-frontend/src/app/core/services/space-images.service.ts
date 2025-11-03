import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SpaceImage } from '../models/space.model';

@Injectable({
  providedIn: 'root'
})
export class SpaceImagesService {
  private http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiUrl}/catalog/spaces`;

  /**
   * Subir una imagen
   */
  uploadImage(spaceId: string, file: File, isPrimary: boolean = false): Observable<SpaceImage> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('isPrimary', isPrimary.toString());

    return this.http.post<SpaceImage>(`${this.baseUrl}/${spaceId}/images`, formData);
  }

  /**
   * Obtener todas las imágenes de un espacio
   */
  getImages(spaceId: string): Observable<SpaceImage[]> {
    return this.http.get<SpaceImage[]>(`${this.baseUrl}/${spaceId}/images`);
  }

  /**
   * Eliminar una imagen
   */
  deleteImage(spaceId: string, imageId: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${spaceId}/images/${imageId}`);
  }

  /**
   * Marcar una imagen como principal
   */
  setPrimaryImage(spaceId: string, imageId: string): Observable<SpaceImage> {
    return this.http.put<SpaceImage>(`${this.baseUrl}/${spaceId}/images/${imageId}/set-primary`, {});
  }

  /**
   * Reordenar imágenes
   */
  reorderImages(spaceId: string, imageIds: string[]): Observable<SpaceImage[]> {
    return this.http.put<SpaceImage[]>(`${this.baseUrl}/${spaceId}/images/reorder`, imageIds);
  }
}

