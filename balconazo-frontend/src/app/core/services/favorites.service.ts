import { Injectable, inject, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, BehaviorSubject } from 'rxjs';
import { tap, map, catchError } from 'rxjs/operators';
import { AuthService } from './auth.service';
import { Space } from './spaces.service';

export interface FavoriteCollection {
  id: string;
  name: string;
  description?: string;
  coverImage?: string;
  isPrivate: boolean;
  collaborators?: string[];
  spaceIds: string[];
  createdAt: string;
  updatedAt: string;
}

export interface FavoriteSpace {
  spaceId: string;
  collectionId?: string;
  note?: string;
  addedAt: string;
}

export interface CreateCollectionDTO {
  name: string;
  description?: string;
  isPrivate?: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class FavoritesService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);

  // Estado reactivo con signals
  private _collections = signal<FavoriteCollection[]>([]);
  private _favorites = signal<FavoriteSpace[]>([]);
  private _isLoading = signal(false);

  // Exposición pública de solo lectura
  readonly collections = this._collections.asReadonly();
  readonly favorites = this._favorites.asReadonly();
  readonly isLoading = this._isLoading.asReadonly();

  // Computed para obtener contadores
  readonly totalFavorites = computed(() => this._favorites().length);
  readonly totalCollections = computed(() => this._collections().length);

  // Storage key para persistencia local
  private readonly STORAGE_KEY_FAVORITES = 'balconazo_favorites';
  private readonly STORAGE_KEY_COLLECTIONS = 'balconazo_collections';

  constructor() {
    this.loadFromLocalStorage();
  }

  // ========== PERSISTENCIA LOCAL ==========

  private loadFromLocalStorage(): void {
    try {
      const storedFavorites = localStorage.getItem(this.STORAGE_KEY_FAVORITES);
      const storedCollections = localStorage.getItem(this.STORAGE_KEY_COLLECTIONS);

      if (storedFavorites) {
        this._favorites.set(JSON.parse(storedFavorites));
      }

      if (storedCollections) {
        this._collections.set(JSON.parse(storedCollections));
      } else {
        // Crear colección por defecto "Guardados"
        const defaultCollection: FavoriteCollection = {
          id: this.generateId(),
          name: 'Guardados',
          isPrivate: true,
          spaceIds: [],
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        };
        this._collections.set([defaultCollection]);
        this.saveToLocalStorage();
      }
    } catch (error) {
      console.error('Error loading favorites from localStorage:', error);
    }
  }

  private saveToLocalStorage(): void {
    try {
      localStorage.setItem(this.STORAGE_KEY_FAVORITES, JSON.stringify(this._favorites()));
      localStorage.setItem(this.STORAGE_KEY_COLLECTIONS, JSON.stringify(this._collections()));
    } catch (error) {
      console.error('Error saving favorites to localStorage:', error);
    }
  }

  private generateId(): string {
    return 'col_' + Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  // ========== GESTIÓN DE FAVORITOS ==========

  isFavorite(spaceId: string): boolean {
    return this._favorites().some(f => f.spaceId === spaceId);
  }

  toggleFavorite(spaceId: string, collectionId?: string): boolean {
    if (this.isFavorite(spaceId)) {
      this.removeFavorite(spaceId);
      return false;
    } else {
      this.addFavorite(spaceId, collectionId);
      return true;
    }
  }

  addFavorite(spaceId: string, collectionId?: string, note?: string): void {
    if (this.isFavorite(spaceId)) return;

    const targetCollectionId = collectionId || this.getDefaultCollectionId();

    const newFavorite: FavoriteSpace = {
      spaceId,
      collectionId: targetCollectionId,
      note,
      addedAt: new Date().toISOString()
    };

    this._favorites.update(favorites => [...favorites, newFavorite]);

    // Actualizar la colección
    if (targetCollectionId) {
      this._collections.update(collections =>
        collections.map(col =>
          col.id === targetCollectionId
            ? { ...col, spaceIds: [...col.spaceIds, spaceId], updatedAt: new Date().toISOString() }
            : col
        )
      );
    }

    this.saveToLocalStorage();
  }

  removeFavorite(spaceId: string): void {
    const favorite = this._favorites().find(f => f.spaceId === spaceId);
    
    this._favorites.update(favorites => 
      favorites.filter(f => f.spaceId !== spaceId)
    );

    // Remover de todas las colecciones
    this._collections.update(collections =>
      collections.map(col => ({
        ...col,
        spaceIds: col.spaceIds.filter(id => id !== spaceId),
        updatedAt: new Date().toISOString()
      }))
    );

    this.saveToLocalStorage();
  }

  updateFavoriteNote(spaceId: string, note: string): void {
    this._favorites.update(favorites =>
      favorites.map(f =>
        f.spaceId === spaceId ? { ...f, note } : f
      )
    );
    this.saveToLocalStorage();
  }

  getFavoriteNote(spaceId: string): string | undefined {
    return this._favorites().find(f => f.spaceId === spaceId)?.note;
  }

  // ========== GESTIÓN DE COLECCIONES ==========

  getDefaultCollectionId(): string {
    const defaultCollection = this._collections().find(c => c.name === 'Guardados');
    return defaultCollection?.id || this._collections()[0]?.id;
  }

  createCollection(data: CreateCollectionDTO): FavoriteCollection {
    const newCollection: FavoriteCollection = {
      id: this.generateId(),
      name: data.name,
      description: data.description,
      isPrivate: data.isPrivate ?? true,
      spaceIds: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    this._collections.update(collections => [...collections, newCollection]);
    this.saveToLocalStorage();

    return newCollection;
  }

  updateCollection(collectionId: string, data: Partial<FavoriteCollection>): void {
    this._collections.update(collections =>
      collections.map(col =>
        col.id === collectionId
          ? { ...col, ...data, updatedAt: new Date().toISOString() }
          : col
      )
    );
    this.saveToLocalStorage();
  }

  deleteCollection(collectionId: string): void {
    const collection = this._collections().find(c => c.id === collectionId);
    
    if (!collection || collection.name === 'Guardados') {
      console.warn('Cannot delete default collection');
      return;
    }

    // Mover los espacios a la colección por defecto
    const defaultCollectionId = this.getDefaultCollectionId();
    
    this._favorites.update(favorites =>
      favorites.map(f =>
        f.collectionId === collectionId
          ? { ...f, collectionId: defaultCollectionId }
          : f
      )
    );

    // Actualizar colección por defecto con los espacios movidos
    this._collections.update(collections => {
      const movedSpaceIds = collection.spaceIds;
      return collections
        .filter(c => c.id !== collectionId)
        .map(c =>
          c.id === defaultCollectionId
            ? { ...c, spaceIds: [...new Set([...c.spaceIds, ...movedSpaceIds])], updatedAt: new Date().toISOString() }
            : c
        );
    });

    this.saveToLocalStorage();
  }

  getCollection(collectionId: string): FavoriteCollection | undefined {
    return this._collections().find(c => c.id === collectionId);
  }

  getCollectionsBySpace(spaceId: string): FavoriteCollection[] {
    return this._collections().filter(c => c.spaceIds.includes(spaceId));
  }

  moveToCollection(spaceId: string, fromCollectionId: string, toCollectionId: string): void {
    // Remover de la colección origen
    this._collections.update(collections =>
      collections.map(col => {
        if (col.id === fromCollectionId) {
          return { ...col, spaceIds: col.spaceIds.filter(id => id !== spaceId), updatedAt: new Date().toISOString() };
        }
        if (col.id === toCollectionId) {
          return { ...col, spaceIds: [...col.spaceIds, spaceId], updatedAt: new Date().toISOString() };
        }
        return col;
      })
    );

    // Actualizar el favorito
    this._favorites.update(favorites =>
      favorites.map(f =>
        f.spaceId === spaceId ? { ...f, collectionId: toCollectionId } : f
      )
    );

    this.saveToLocalStorage();
  }

  addToCollection(spaceId: string, collectionId: string): void {
    // Si ya es favorito, solo mover a la colección
    if (this.isFavorite(spaceId)) {
      const currentFavorite = this._favorites().find(f => f.spaceId === spaceId);
      if (currentFavorite?.collectionId && currentFavorite.collectionId !== collectionId) {
        this.moveToCollection(spaceId, currentFavorite.collectionId, collectionId);
      }
    } else {
      this.addFavorite(spaceId, collectionId);
    }
  }

  // ========== OBTENER ESPACIOS DE UNA COLECCIÓN ==========

  getSpaceIdsInCollection(collectionId: string): string[] {
    const collection = this._collections().find(c => c.id === collectionId);
    return collection?.spaceIds || [];
  }

  getRecentFavorites(limit: number = 10): FavoriteSpace[] {
    return [...this._favorites()]
      .sort((a, b) => new Date(b.addedAt).getTime() - new Date(a.addedAt).getTime())
      .slice(0, limit);
  }

  // ========== ESTADÍSTICAS ==========

  getCollectionStats(collectionId: string): { count: number; lastUpdated: string } {
    const collection = this._collections().find(c => c.id === collectionId);
    return {
      count: collection?.spaceIds.length || 0,
      lastUpdated: collection?.updatedAt || ''
    };
  }

  // ========== COVER IMAGE ==========

  updateCollectionCover(collectionId: string, coverImage: string): void {
    this._collections.update(collections =>
      collections.map(col =>
        col.id === collectionId
          ? { ...col, coverImage, updatedAt: new Date().toISOString() }
          : col
      )
    );
    this.saveToLocalStorage();
  }
}
