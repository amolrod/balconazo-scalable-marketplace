import { Component, OnInit, inject, ViewEncapsulation, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { SpacesService, Space } from '../../core/services/spaces.service';
import { FavoritesService } from '../../core/services/favorites.service';
import { ToastService } from '../../core/services/toast.service';
import { SkeletonListComponent } from '../../shared/components/skeleton-list/skeleton-list';
import { EmptyStateComponent } from '../../shared/components/empty-state/empty-state';

@Component({
  selector: 'app-home',
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    SkeletonListComponent,
    EmptyStateComponent
  ],
  templateUrl: './home.html',
  styleUrl: './home.scss',
  encapsulation: ViewEncapsulation.None
})
export class HomeComponent implements OnInit {
  private router = inject(Router);
  private spacesService = inject(SpacesService);
  private favoritesService = inject(FavoritesService);
  private toastService = inject(ToastService);

  loading = false;
  error: string | null = null;
  allSpaces: Space[] = [];
  featuredSpaces: Space[] = [];

  // Variable para scroll behavior de category-bar
  hideCategoryBar = false;

  // Categorías para filtrar
  categories = [
    { id: 'all', name: 'Todos', icon: 'ph-squares-four', spaceTypes: [] as string[] },
    { id: 'jardin', name: 'Jardines', icon: 'ph-plant', spaceTypes: ['jardin', 'garden'] },
    { id: 'terraza', name: 'Terrazas', icon: 'ph-house', spaceTypes: ['terraza', 'terrace', 'rooftop', 'atico'] },
    { id: 'piscina', name: 'Piscinas', icon: 'ph-swimming-pool', spaceTypes: ['piscina', 'pool'] },
    { id: 'eventos', name: 'Eventos', icon: 'ph-calendar', spaceTypes: ['salon', 'loft', 'estudio'] },
    { id: 'rodajes', name: 'Rodajes', icon: 'ph-camera', spaceTypes: ['loft', 'estudio', 'rooftop'] }
  ];
  selectedCategory = 'all';

  searchParams = {
    location: '',
    date: '',
    capacity: null as number | null
  };

  ngOnInit(): void {
    this.loadFeaturedSpaces();
  }

  @HostListener('window:scroll', [])
  onWindowScroll(): void {
    const currentScroll = window.pageYOffset || document.documentElement.scrollTop;

    // Obtener la posición de la sección "¿Por qué Balconazo?"
    const whyBalconazoSection = document.querySelector('.why-balconazo-section');

    if (!whyBalconazoSection) {
      this.hideCategoryBar = false;
      return;
    }

    // Obtener la posición top de la sección
    const whyBalconazoTop = whyBalconazoSection.getBoundingClientRect().top + currentScroll;

    // Ocultar cuando llegamos a "¿Por qué Balconazo?" (dejando un margen de 100px)
    if (currentScroll + window.innerHeight >= whyBalconazoTop - 100) {
      this.hideCategoryBar = true;
    } else {
      this.hideCategoryBar = false;
    }
  }

  loadFeaturedSpaces(): void {
    this.loading = true;

    this.spacesService.getActiveSpaces().subscribe({
      next: (spaces) => {
        console.log('✅ Espacios cargados desde el backend:', spaces);

        // Guardar todos los espacios
        this.allSpaces = spaces;

        // Aplicar filtro de categoría
        this.applyFilter();

        console.log('📊 Espacios con datos reales:', this.featuredSpaces.map(s => ({
          id: s.id,
          title: s.title,
          rating: s.averageRating,
          reviews: s.reviewCount
        })));

        this.loading = false;
      },
      error: (error) => {
        console.error('❌ Error cargando espacios:', error);
        this.error = 'No se pudieron cargar los espacios. Verifica que el backend esté corriendo.';
        this.featuredSpaces = [];
        this.loading = false;
      }
    });
  }

  selectCategory(categoryId: string): void {
    this.selectedCategory = categoryId;
    this.applyFilter();
  }

  applyFilter(): void {
    const category = this.categories.find(c => c.id === this.selectedCategory);

    if (!category || category.spaceTypes.length === 0) {
      // "Todos" o categoría sin tipos específicos - mostrar todos
      this.featuredSpaces = this.allSpaces.slice(0, 8);
    } else {
      // Filtrar por tipo de espacio
      const filtered = this.allSpaces.filter(space => {
        // Buscar en el título o descripción del espacio
        const titleLower = space.title.toLowerCase();
        const descLower = (space.description || '').toLowerCase();
        const spaceTypeLower = ((space as any).spaceType || '').toLowerCase();

        return category.spaceTypes.some(type =>
          titleLower.includes(type) ||
          descLower.includes(type) ||
          spaceTypeLower.includes(type)
        );
      });

      this.featuredSpaces = filtered.slice(0, 8);
    }
  }

  onSearch(): void {
    console.log('🔍 Buscando con:', this.searchParams);

    if (this.searchParams.location) {
      const madridLat = 40.4168;
      const madridLon = -3.7038;

      this.spacesService.searchSpaces({
        lat: madridLat,
        lon: madridLon,
        radius: 5000,
        minCapacity: this.searchParams.capacity || undefined
      }).subscribe({
        next: (results) => {
          console.log('🎯 Resultados de búsqueda:', results);
          this.router.navigate(['/spaces'], {
            queryParams: {
              lat: madridLat,
              lon: madridLon,
              ...this.searchParams
            }
          });
        },
        error: (error) => {
          console.error('❌ Error en búsqueda:', error);
        }
      });
    } else {
      this.router.navigate(['/spaces'], {
        queryParams: this.searchParams
      });
    }
  }

  viewSpace(id: string): void {
    this.router.navigate(['/spaces', id]);
  }

  getSpaceImageUrl(space: Space): string {
    if (space.images && space.images.length > 0) {
      const primaryImage = space.images.find(img => img.isPrimary);
      if (primaryImage) {
        return primaryImage.url;
      }
      return space.images[0].url;
    }
    return '/assets/images/placeholder-space.svg';
  }

  getSpaceLocation(space: Space): string {
    const parts = space.address.split(',');
    return parts.length > 1 ? parts[parts.length - 1].trim() : space.address;
  }

  getSpacePricePerHour(space: Space): number {
    return Math.round(space.basePriceCents / 100);
  }

  isFavorite(spaceId: string): boolean {
    return this.favoritesService.isFavorite(spaceId);
  }

  toggleFavorite(event: Event, space: Space): void {
    event.stopPropagation();
    const isNowFavorite = this.favoritesService.toggleFavorite(space.id);
    
    if (isNowFavorite) {
      this.toastService.success(`"${space.title}" añadido a favoritos`);
    } else {
      this.toastService.info(`"${space.title}" quitado de favoritos`);
    }
  }
}
