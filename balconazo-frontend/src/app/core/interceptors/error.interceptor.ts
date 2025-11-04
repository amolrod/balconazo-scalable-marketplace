import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { ToastService } from '../services/toast.service';

/**
 * Error Interceptor
 * Maneja errores HTTP globalmente y muestra mensajes al usuario
 *
 * Funcionalidades:
 * - Captura errores 4xx y 5xx
 * - Muestra toasts informativos
 * - Maneja errores 401 (no autorizado) → redirect a login
 * - Maneja errores 403 (prohibido) → redirect a home
 * - Logs de errores en consola
 */
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const router = inject(Router);
  const toastService = inject(ToastService);

  return next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      let errorMessage = 'Ha ocurrido un error inesperado';

      if (error.error instanceof ErrorEvent) {
        // Client-side error
        errorMessage = `Error: ${error.error.message}`;
        console.error('❌ Error del cliente:', error.error.message);
      } else {
        // Server-side error
        console.error(`❌ Error del servidor: ${error.status}`, error.error);

        // Handle specific error codes
        switch (error.status) {
          case 0:
            errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión.';
            break;

          case 400:
            errorMessage = error.error?.message || 'Solicitud incorrecta. Verifica los datos enviados.';
            break;

          case 401:
            errorMessage = 'No estás autenticado. Inicia sesión nuevamente.';
            // Redirect to login
            setTimeout(() => {
              router.navigate(['/login']);
            }, 1500);
            break;

          case 403:
            errorMessage = 'No tienes permisos para realizar esta acción.';
            // Redirect to home
            setTimeout(() => {
              router.navigate(['/']);
            }, 1500);
            break;

          case 404:
            errorMessage = error.error?.message || 'Recurso no encontrado.';
            break;

          case 409:
            errorMessage = error.error?.message || 'Conflicto. El recurso ya existe o está en uso.';
            break;

          case 422:
            errorMessage = error.error?.message || 'Datos de validación incorrectos.';
            break;

          case 500:
            errorMessage = 'Error interno del servidor. Intenta nuevamente más tarde.';
            break;

          case 503:
            errorMessage = 'Servicio no disponible. Intenta nuevamente más tarde.';
            break;

          default:
            if (error.error?.message) {
              errorMessage = error.error.message;
            } else {
              errorMessage = `Error ${error.status}: ${error.statusText || 'Error desconocido'}`;
            }
        }
      }

      // Show toast notification (except for 401 to avoid double notification on logout)
      if (error.status !== 401 || !req.url.includes('/logout')) {
        toastService.error(errorMessage);
      }

      // Re-throw the error for component-level handling if needed
      return throwError(() => error);
    })
  );
};

