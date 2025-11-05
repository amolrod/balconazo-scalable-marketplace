import { Component, OnInit, inject, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { User } from '../../../core/models/auth.model';

/**
 * Navbar Component
 * Barra de navegación profesional con menú por rol
 *
 * Features:
 * - Menú dinámico por rol (HOST/GUEST/No auth)
 * - User dropdown menu
 * - Mobile hamburger menu
 * - Logo con gradient
 * - CTA "Publica tu espacio"
 */
@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './navbar.html',
  styleUrl: './navbar.scss'
})
export class NavbarComponent implements OnInit {
  private authService = inject(AuthService);
  private router = inject(Router);

  isAuthenticated = false;
  currentUser: User | null = null;
  userRole: string | null = null;
  showMobileMenu = false;
  showUserMenu = false;

  ngOnInit(): void {
    // Suscribirse al estado de autenticación
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
      this.isAuthenticated = this.authService.isAuthenticated();
      this.userRole = this.authService.getUserRole();
    });

    // Cargar usuario inicial SOLO si hay token Y userId
    const token = this.authService.getToken();
    const userId = this.authService.getUserId();

    if (token && userId) {
      this.authService.getProfile().subscribe({
        next: (user) => {
          // Usuario cargado exitosamente
        },
        error: (err) => {
          // Silenciar error 401 - puede significar token expirado
          // El interceptor intentará renovarlo automáticamente
          if (err.status === 401) {
            // No hacer nada, el interceptor lo maneja
          }
        }
      });
    }
  }

  /**
   * Close menus when clicking outside
   */
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as HTMLElement;
    const clickedInside = target.closest('.user-menu-wrapper');

    if (!clickedInside && this.showUserMenu) {
      this.showUserMenu = false;
    }
  }

  /**
   * Toggle mobile menu
   */
  toggleMobileMenu(): void {
    this.showMobileMenu = !this.showMobileMenu;
    // Prevenir scroll cuando el menú está abierto
    if (this.showMobileMenu) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
  }

  /**
   * Toggle user dropdown menu
   */
  toggleUserMenu(): void {
    this.showUserMenu = !this.showUserMenu;
  }

  /**
   * Cierra el menú de usuario
   */
  closeUserMenu(): void {
    this.showUserMenu = false;
  }

  /**
   * Cierra el menú móvil
   */
  closeMobileMenu(): void {
    this.showMobileMenu = false;
    document.body.style.overflow = '';
  }

  /**
   * Navega a una ruta y cierra menús
   */
  navigateTo(route: string): void {
    this.router.navigate([route]);
    this.closeMobileMenu();
    this.closeUserMenu();
  }

  /**
   * Logout
   */
  logout(): void {
    this.authService.logout();
    this.closeUserMenu();
    this.closeMobileMenu();
    this.router.navigate(['/']);
  }

  /**
   * Verifica si es HOST
   */
  get isHost(): boolean {
    return this.userRole === 'HOST';
  }

  /**
   * Verifica si es GUEST
   */
  get isGuest(): boolean {
    return this.userRole === 'GUEST';
  }

  /**
   * Obtiene las iniciales del usuario para el avatar
   */
  get userInitials(): string {
    if (!this.currentUser?.email) {
      return 'U';
    }
    return this.currentUser.email.charAt(0).toUpperCase();
  }
}

