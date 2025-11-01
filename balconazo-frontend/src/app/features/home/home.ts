import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';

interface Space {
  id: string;
  title: string;
  location: string;
  capacity: number;
  area?: number;
  pricePerHour: number;
  rating?: number;
  imageUrl?: string;
  isFeatured?: boolean;
}

@Component({
  selector: 'app-home',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './home.html',
  styleUrl: './home.scss'
})
export class HomeComponent implements OnInit {
  private router = inject(Router);

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
    // TODO: Implementar check real de autenticación
    const token = localStorage.getItem('token');
    this.isAuthenticated = !!token;
  }

  loadFeaturedSpaces(): void {
    this.loading = true;

    // TODO: Reemplazar con llamada real al backend
    setTimeout(() => {
      this.featuredSpaces = [
        {
          id: '1',
          title: 'Ático moderno con terraza panorámica',
          location: 'Madrid, Malasaña',
          capacity: 8,
          area: 50,
          pricePerHour: 25,
          rating: 4.9,
          imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&h=400&fit=crop',
          isFeatured: true
        },
        {
          id: '2',
          title: 'Loft industrial con cocina profesional',
          location: 'Barcelona, Gràcia',
          capacity: 12,
          area: 80,
          pricePerHour: 35,
          rating: 5.0,
          imageUrl: 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=600&h=400&fit=crop'
        },
        {
          id: '3',
          title: 'Apartamento luminoso con jardín privado',
          location: 'Valencia, Ruzafa',
          capacity: 10,
          area: 65,
          pricePerHour: 28,
          rating: 4.7,
          imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=600&h=400&fit=crop'
        },
        {
          id: '4',
          title: 'Estudio minimalista en pleno centro',
          location: 'Sevilla, Centro',
          capacity: 6,
          area: 40,
          pricePerHour: 20,
          rating: 4.8,
          imageUrl: 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=600&h=400&fit=crop',
          isFeatured: true
        }
      ];
      this.loading = false;
    }, 1000);
  }

  onSearch(): void {
    console.log('🔍 Buscando con:', this.searchParams);
    // TODO: Implementar búsqueda real
    this.router.navigate(['/spaces'], {
      queryParams: this.searchParams
    });
  }

  viewSpace(id: string): void {
    this.router.navigate(['/spaces', id]);
  }

  toggleMobileMenu(): void {
    this.showMobileMenu = !this.showMobileMenu;
  }

  logout(): void {
    localStorage.removeItem('token');
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
}

