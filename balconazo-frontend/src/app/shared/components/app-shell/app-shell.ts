import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule, NavigationEnd } from '@angular/router';
import { NavbarComponent } from '../navbar/navbar';
import { filter, map } from 'rxjs/operators';

/**
 * AppShell Component
 * Layout wrapper con navbar + router-outlet + footer
 * Oculta navbar y footer en rutas de autenticación
 */
@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [CommonModule, RouterModule, NavbarComponent],
  templateUrl: './app-shell.html',
  styleUrl: './app-shell.scss'
})
export class AppShellComponent {
  private router = inject(Router);

  currentYear = new Date().getFullYear();
  showLayout = true; // Controla si se muestra navbar y footer

  constructor() {
    // Detectar cambios de ruta para ocultar layout en auth pages
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd),
      map((event: NavigationEnd) => event.url)
    ).subscribe(url => {
      // Ocultar navbar y footer en rutas /login y /register
      this.showLayout = !url.startsWith('/login') && !url.startsWith('/register');
    });

    // Verificar ruta inicial
    const currentUrl = this.router.url;
    this.showLayout = !currentUrl.startsWith('/login') && !currentUrl.startsWith('/register');
  }
}

