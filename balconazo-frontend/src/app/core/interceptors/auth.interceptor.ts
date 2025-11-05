import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';
import { catchError, switchMap, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  // Evitar dependencia circular: obtener token directamente de localStorage
  // IMPORTANTE: Usar la misma key que AuthService ('accessToken')
  const token = localStorage.getItem('accessToken');

  // Clonar request y añadir token si existe
  let authReq = req;
  if (token && !req.url.includes('/auth/login') && !req.url.includes('/auth/register')) {
    authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }

  // Manejar respuesta
  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      // Si es 401 y no es la página de login, intentar refresh token
      if (error.status === 401 && !req.url.includes('/auth/')) {
        // Inyectar AuthService solo cuando sea necesario (lazy)
        const authService = inject(AuthService);

        return authService.refreshToken().pipe(
          switchMap(() => {
            // Reintentar request original con nuevo token
            const newToken = localStorage.getItem('accessToken');
            const retryReq = req.clone({
              setHeaders: {
                Authorization: `Bearer ${newToken}`
              }
            });
            return next(retryReq);
          }),
          catchError((refreshError) => {
            // Si el refresh falla, hacer logout
            authService.logout();
            return throwError(() => refreshError);
          })
        );
      }

      return throwError(() => error);
    })
  );
};

