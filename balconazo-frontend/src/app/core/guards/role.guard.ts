import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Role Guard Factory
 * Protege rutas basándose en el rol del usuario
 *
 * @param allowedRoles - Array de roles permitidos ('HOST' | 'GUEST' | 'ADMIN')
 * @returns Guard function
 *
 * @example
 * // En routes
 * {
 *   path: 'host/dashboard',
 *   component: HostDashboardComponent,
 *   canActivate: [roleGuard(['HOST'])]
 * }
 */
export const roleGuard = (allowedRoles: ('HOST' | 'GUEST' | 'ADMIN')[]) => {
  return () => {
    const authService = inject(AuthService);
    const router = inject(Router);

    // Verificar autenticación
    if (!authService.isAuthenticated()) {
      console.warn('🔒 roleGuard: Usuario no autenticado, redirigiendo a /login');
      router.navigate(['/login']);
      return false;
    }

    // Obtener rol del usuario
    const userRole = authService.getUserRole();

    // Verificar si el rol está permitido
    if (!userRole || !allowedRoles.includes(userRole as any)) {
      console.warn(`🚫 roleGuard: Rol "${userRole}" no permitido. Roles permitidos: ${allowedRoles.join(', ')}`);
      router.navigate(['/']);
      return false;
    }

    console.log(`✅ roleGuard: Acceso permitido para rol "${userRole}"`);
    return true;
  };
};

/**
 * Convenience guard for HOST-only routes
 */
export const hostGuard = () => roleGuard(['HOST']);

/**
 * Convenience guard for GUEST-only routes
 */
export const guestGuard = () => roleGuard(['GUEST']);

/**
 * Guard for routes accessible by both HOST and GUEST
 */
export const authenticatedGuard = () => roleGuard(['HOST', 'GUEST']);

