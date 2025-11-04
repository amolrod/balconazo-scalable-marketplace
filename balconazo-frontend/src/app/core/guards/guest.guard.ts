import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Guest Guard
 * Permite acceso solo a usuarios con rol GUEST
 * Redirige a home si es HOST o no está autenticado
 *
 * @example
 * {
 *   path: 'my-bookings',
 *   component: MyBookingsComponent,
 *   canActivate: [guestOnlyGuard]
 * }
 */
export const guestOnlyGuard = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (!authService.isAuthenticated()) {
    console.warn('🔒 guestOnlyGuard: Usuario no autenticado, redirigiendo a /login');
    router.navigate(['/login']);
    return false;
  }

  const userRole = authService.getUserRole();

  if (userRole !== 'GUEST') {
    console.warn(`🚫 guestOnlyGuard: Acceso denegado para rol "${userRole}". Solo GUEST permitido.`);
    router.navigate(['/']);
    return false;
  }

  console.log('✅ guestOnlyGuard: Acceso permitido para GUEST');
  return true;
};

