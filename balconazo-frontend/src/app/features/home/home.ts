import { Component, OnInit, inject, ViewEncapsulation, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { SpacesService, Space } from '../../core/services/spaces.service';
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

  loading = false;
  error: string | null = null;
  featuredSpaces: Space[] = [];

  // Variable para scroll behavior de category-bar
  hideCategoryBar = false;

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

        // Usar datos REALES del backend sin simulación
        this.featuredSpaces = spaces.slice(0, 8);

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

  toggleFavorite(event: Event, spaceId: string): void {
    event.stopPropagation(); // Evitar que se active el click del card
    console.log('❤️ Toggle favorito para espacio:', spaceId);
    // TODO: Implementar lógica de favoritos cuando esté disponible
  }
}

