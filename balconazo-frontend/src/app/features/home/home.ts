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

    // Intentar obtener espacios activos del backend
    this.spacesService.getActiveSpaces().subscribe({
      next: (spaces) => {
        console.log('✅ Espacios cargados desde el backend:', spaces);
        this.featuredSpaces = spaces.slice(0, 8); // Mostrar máximo 8
        this.loading = false;
      },
      error: (error) => {
        console.error('❌ Error cargando espacios:', error);
        // Fallback a datos mock si el backend no está disponible
        this.loadMockSpaces();
        this.loading = false;
      }
    });
  }

  private loadMockSpaces(): void {
    console.log('⚠️ Usando datos mock (backend no disponible)');
    this.featuredSpaces = [
      {
        id: '1',
        title: 'Ático moderno con terraza panorámica',
        description: 'Amplio ático con vistas',
        address: 'Calle Gran Vía 28, Madrid',
        lat: 40.4168,
        lon: -3.7038,
        capacity: 8,
        basePriceCents: 2500,
        areaSqm: 50,
        status: 'ACTIVE',
        ownerId: '11111111-1111-1111-1111-111111111111'
      },
      {
        id: '2',
        title: 'Loft industrial con cocina profesional',
        description: 'Loft en zona Gràcia',
        address: 'Carrer de Verdi 12, Barcelona',
        lat: 41.4036,
        lon: 2.1544,
        capacity: 12,
        basePriceCents: 3500,
        areaSqm: 80,
        status: 'ACTIVE',
        ownerId: '11111111-1111-1111-1111-111111111111'
      },
      {
        id: '3',
        title: 'Apartamento luminoso con jardín privado',
        description: 'Apartamento en Ruzafa',
        address: 'Calle Sueca 15, Valencia',
        lat: 39.4633,
        lon: -0.3707,
        capacity: 10,
        basePriceCents: 2800,
        areaSqm: 65,
        status: 'ACTIVE',
        ownerId: '11111111-1111-1111-1111-111111111111'
      },
      {
        id: '4',
        title: 'Estudio minimalista en pleno centro',
        description: 'Estudio moderno',
        address: 'Plaza Nueva 3, Sevilla',
        lat: 37.3886,
        lon: -5.9945,
        capacity: 6,
        basePriceCents: 2000,
        areaSqm: 40,
        status: 'ACTIVE',
        ownerId: '11111111-1111-1111-1111-111111111111'
      }
    ];
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
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('userId');
    this.isAuthenticated = false;
    this.router.navigate(['/']);
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
    // TODO: Implementar cuando tengamos sistema de imágenes
    const images = [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=600&h=400&fit=crop'
    ];
    const hash = space.id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return images[hash % images.length];
  }

  getSpaceLocation(space: Space): string {
    // Extraer ciudad del address
    const parts = space.address.split(',');
    return parts.length > 1 ? parts[parts.length - 1].trim() : space.address;
  }

  getSpacePricePerHour(space: Space): number {
    return Math.round(space.basePriceCents / 100);
  }

  getSpaceRating(space: Space): number {
    // TODO: Implementar cuando tengamos sistema de ratings
    return 4.5 + Math.random() * 0.5; // Mock entre 4.5 y 5.0
  }

  isSpaceFeatured(space: Space): boolean {
    // TODO: Implementar lógica real de espacios destacados
    const hash = space.id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return hash % 3 === 0; // ~33% de espacios destacados
  }
}

