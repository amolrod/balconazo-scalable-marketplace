import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { FavoritesService, FavoriteCollection } from '../../core/services/favorites.service';
import { SpacesService, Space } from '../../core/services/spaces.service';
import { ToastService } from '../../core/services/toast.service';
import { forkJoin, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

interface CollectionWithSpaces extends FavoriteCollection {
  spaces: Space[];
}

@Component({
  selector: 'app-wishlists',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './wishlists.html',
  styleUrl: './wishlists.scss'
})
export class WishlistsComponent implements OnInit {
  private router = inject(Router);
  private favoritesService = inject(FavoritesService);
  private spacesService = inject(SpacesService);
  private toastService = inject(ToastService);

  // Estado
  loading = signal(true);
  view = signal<'boards' | 'list'>('boards');
  
  // Datos
  collections = signal<CollectionWithSpaces[]>([]);
  recentFavorites = signal<Space[]>([]);
  
  // Modal de crear colección
  showCreateModal = signal(false);
  newCollectionName = '';
  newCollectionDescription = '';
  isCreatingCollection = false;

  // Modal de confirmar eliminación
  showDeleteModal = signal(false);
  collectionToDelete = signal<FavoriteCollection | null>(null);

  // Computed
  totalSpaces = computed(() => {
    return this.collections().reduce((acc, col) => acc + col.spaceIds.length, 0);
  });

  ngOnInit(): void {
    this.loadCollections();
  }

  loadCollections(): void {
    this.loading.set(true);
    
    const collections = this.favoritesService.collections();
    
    if (collections.length === 0) {
      this.collections.set([]);
      this.loading.set(false);
      return;
    }

    // Obtener todos los IDs de espacios únicos
    const allSpaceIds = [...new Set(collections.flatMap(c => c.spaceIds))];
    
    if (allSpaceIds.length === 0) {
      this.collections.set(collections.map(c => ({ ...c, spaces: [] })));
      this.loading.set(false);
      return;
    }

    // Cargar todos los espacios
    const spaceRequests = allSpaceIds.map(id =>
      this.spacesService.getSpaceById(id).pipe(
        catchError(() => of(null))
      )
    );

    forkJoin(spaceRequests).subscribe({
      next: (spaces) => {
        const spacesMap = new Map<string, Space>();
        spaces.filter((s): s is Space => s !== null).forEach(space => {
          spacesMap.set(space.id, space);
        });

        // Mapear colecciones con sus espacios
        const collectionsWithSpaces: CollectionWithSpaces[] = collections.map(collection => ({
          ...collection,
          spaces: collection.spaceIds
            .map(id => spacesMap.get(id))
            .filter((s): s is Space => s !== undefined)
        }));

        this.collections.set(collectionsWithSpaces);

        // Cargar favoritos recientes
        const recentIds = this.favoritesService.getRecentFavorites(8).map(f => f.spaceId);
        this.recentFavorites.set(
          recentIds
            .map(id => spacesMap.get(id))
            .filter((s): s is Space => s !== undefined)
        );

        this.loading.set(false);
      },
      error: (error) => {
        console.error('Error loading spaces:', error);
        this.collections.set(collections.map(c => ({ ...c, spaces: [] })));
        this.loading.set(false);
      }
    });
  }

  // ========== NAVEGACIÓN ==========

  viewCollection(collection: FavoriteCollection): void {
    this.router.navigate(['/wishlists', collection.id]);
  }

  viewSpace(spaceId: string): void {
    this.router.navigate(['/spaces', spaceId]);
  }

  // ========== CREAR COLECCIÓN ==========

  openCreateModal(): void {
    this.newCollectionName = '';
    this.newCollectionDescription = '';
    this.showCreateModal.set(true);
  }

  closeCreateModal(): void {
    this.showCreateModal.set(false);
  }

  createCollection(): void {
    if (!this.newCollectionName.trim()) return;
    
    this.isCreatingCollection = true;
    
    try {
      const newCollection = this.favoritesService.createCollection({
        name: this.newCollectionName.trim(),
        description: this.newCollectionDescription.trim() || undefined,
        isPrivate: true
      });

      this.toastService.success(`Colección "${newCollection.name}" creada correctamente`);
      this.closeCreateModal();
      this.loadCollections();
    } catch (error) {
      this.toastService.error('No se pudo crear la colección');
    } finally {
      this.isCreatingCollection = false;
    }
  }

  // ========== ELIMINAR COLECCIÓN ==========

  confirmDeleteCollection(collection: FavoriteCollection, event: Event): void {
    event.stopPropagation();
    this.collectionToDelete.set(collection);
    this.showDeleteModal.set(true);
  }

  closeDeleteModal(): void {
    this.showDeleteModal.set(false);
    this.collectionToDelete.set(null);
  }

  deleteCollection(): void {
    const collection = this.collectionToDelete();
    if (!collection) return;

    try {
      this.favoritesService.deleteCollection(collection.id);
      this.toastService.success(`Colección "${collection.name}" eliminada`);
      this.closeDeleteModal();
      this.loadCollections();
    } catch (error) {
      this.toastService.error('No se pudo eliminar la colección');
    }
  }

  // ========== FAVORITOS ==========

  removeFavorite(spaceId: string, event: Event): void {
    event.stopPropagation();
    this.favoritesService.removeFavorite(spaceId);
    this.toastService.success('Espacio quitado de favoritos');
    this.loadCollections();
  }

  // ========== UTILIDADES ==========

  getCollectionCover(collection: CollectionWithSpaces): string {
    if (collection.coverImage) return collection.coverImage;
    if (collection.spaces.length > 0) {
      const firstSpace = collection.spaces[0];
      if (firstSpace.images && firstSpace.images.length > 0) {
        const primary = firstSpace.images.find(img => img.isPrimary);
        return primary?.url || firstSpace.images[0].url;
      }
    }
    return '/assets/images/placeholder-collection.svg';
  }

  getSpaceImage(space: Space): string {
    if (space.images && space.images.length > 0) {
      const primary = space.images.find(img => img.isPrimary);
      return primary?.url || space.images[0].url;
    }
    return '/assets/images/placeholder-space.svg';
  }

  getSpacePrice(space: Space): number {
    return Math.round(space.basePriceCents / 100);
  }

  formatTimeAgo(dateString: string): string {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffDays === 0) return 'Hoy';
    if (diffDays === 1) return 'Ayer';
    if (diffDays < 7) return `Hace ${diffDays} días`;
    if (diffDays < 30) return `Hace ${Math.floor(diffDays / 7)} semanas`;
    return `Hace ${Math.floor(diffDays / 30)} meses`;
  }

  isDefaultCollection(collection: FavoriteCollection): boolean {
    return collection.name === 'Guardados';
  }

  trackByCollectionId(index: number, collection: CollectionWithSpaces): string {
    return collection.id;
  }

  trackBySpaceId(index: number, space: Space): string {
    return space.id;
  }
}
