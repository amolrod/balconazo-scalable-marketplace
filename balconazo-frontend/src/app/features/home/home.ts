import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { SpacesService, Space } from '../../core/services/spaces.service';

@Component({
  selector: 'app-home',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './home.html',
  styleUrl: './home.scss'
})
export class HomeComponent implements OnInit {
  private router = inject(Router);
  private spacesService = inject(SpacesService);

  loading = false;
  isAuthenticated = false;
  showMobileMenu = false;
  error: string | null = null;

  featuredSpaces: Space[] = [];

  searchParams = {
    location: '',
    date: '',
    capacity: null as number | null
  };

  ngOnInit(): void {
    this.loadFeaturedSpaces();
    this.checkAuthentication();
    this.setupNavbarScroll();
  }

  checkAuthentication(): void {
    const token = localStorage.getItem('accessToken');
    this.isAuthenticated = !!token;
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
    this.showMobileMenu = !this.showMobileMenu;
  }

  logout(): void {
    // Limpiar TODO el localStorage
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('userId');
    localStorage.removeItem('userRole');

    // Actualizar estado
    this.isAuthenticated = false;

    // Redirigir al login
    this.router.navigate(['/login']).then(() => {
      // Recargar para limpiar cualquier estado en memoria
      window.location.reload();
    });
  }

  private setupNavbarScroll(): void {
    if (typeof window !== 'undefined') {
      window.addEventListener('scroll', () => {
        const navbar = document.getElementById('navbar');
        if (navbar) {
          if (window.pageYOffset > 50) {
            navbar.classList.add('scrolled');
          } else {
            navbar.classList.remove('scrolled');
          }
        }
      });
    }
  }

  // Helper methods para el template
  getSpaceImageUrl(space: Space): string {
    // TODO: Implementar sistema de imágenes real
    // Por ahora, placeholder genérico hasta que se suba imagen real
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

