
import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { SpacesService, Space } from '../../core/services/spaces.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-home',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './home.html',
  styleUrl: './home.scss'
})
export class HomeComponent implements OnInit {
  private router = inject(Router);
  private spacesService = inject(SpacesService);
  private authService = inject(AuthService);
  isAuthenticated = false;
  error: string | null = null;

  featuredSpaces: Space[] = [];

  searchParams = {
    location: '',
    date: '',
    capacity: null as number | null
  };

  ngOnInit(): void {
    this.checkAuthentication();
  }

  loadFeaturedSpaces(): void {
    this.loading = true;

    // SOLO cargar desde el backend - sin fallback a mock
    this.spacesService.getActiveSpaces().subscribe({
      next: (spaces) => {
        console.log('✅ Espacios cargados desde el backend:', spaces);
        this.featuredSpaces = spaces.slice(0, 8); // Mostrar máximo 8
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
      // TODO: Geocodificar la ubicación a lat/lon
      // Por ahora usar coordenadas por defecto de Madrid
      const madridLat = 40.4168;
      const madridLon = -3.7038;

      this.spacesService.searchSpaces({
        lat: madridLat,
        lon: madridLon,
        radius: 5000, // 5km
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

  toggleMobileMenu(): void {
  // Helper methods para el template
  getSpaceImageUrl(space: Space): string {
    // Si tiene imágenes, usar la principal o la primera
    if (space.images && space.images.length > 0) {
      const primaryImage = space.images.find(img => img.isPrimary);
      if (primaryImage) {
        return primaryImage.url;
      }
      // Si no hay principal, usar la primera
      return space.images[0].url;
    }

    // Placeholder si no hay imágenes
    return 'https://via.placeholder.com/600x400/E5E7EB/6B7280?text=' + encodeURIComponent(space.title);
  }

  getSpaceLocation(space: Space): string {
    // Extraer ciudad del address
    const parts = space.address.split(',');
    return parts.length > 1 ? parts[parts.length - 1].trim() : space.address;
  }

  getSpacePricePerHour(space: Space): number {
    return Math.round(space.basePriceCents / 100);
  }
}

