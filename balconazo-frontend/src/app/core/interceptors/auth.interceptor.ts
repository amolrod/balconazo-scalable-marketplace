import { HttpInterceptorFn, HttpErrorResponse, HttpRequest, HttpHandlerFn, HttpEvent } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError, switchMap, filter, take, Observable, from } from 'rxjs';
import { BehaviorSubject } from 'rxjs';

// Variables compartidas para evitar múltiples refresh simultáneos
let isRefreshing = false;
let refreshTokenSubject: BehaviorSubject<string | null> = new BehaviorSubject<string | null>(null);

export const authInterceptor: HttpInterceptorFn = (req: HttpRequest<unknown>, next: HttpHandlerFn): Observable<HttpEvent<unknown>> => {
  const router = inject(Router);

  // Obtener token de localStorage
  const token = localStorage.getItem('accessToken');

  // Añadir Authorization header si hay token y no es login/register/refresh
  const authReq = addTokenToRequest(req, token);

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      // Solo intentar refresh en errores 401 fuera de rutas de autenticación
      if (error.status === 401 &&
          !req.url.includes('/auth/login') &&
          !req.url.includes('/auth/register') &&
          !req.url.includes('/auth/refresh')) {

        // Verificar si hay refresh token disponible
        const refreshToken = localStorage.getItem('refreshToken');

        if (!refreshToken) {
          // No hay refresh token → logout inmediato
          console.warn('⚠️ No hay refresh token - Redirigiendo a login');
          clearSessionAndRedirect(router);
          return throwError(() => error);
        }

        // Si ya se está refrescando, esperar al resultado
        if (isRefreshing) {
          console.log('⏳ Ya se está refrescando, esperando...');
          return refreshTokenSubject.pipe(
            filter(token => token !== null),
            take(1),
            switchMap(token => {
              console.log('🔄 Token disponible después de espera - reintentando');
              console.log('🔑 Token recibido (primeros 50):', token?.substring(0, 50));
              console.log('🔄 Request a reintentar:', req.method, req.url);

              // Construir headers completamente nuevos
              const headers: any = {
                Authorization: `Bearer ${token}`
              };

              // Preservar Content-Type si existía
              if (req.headers.has('Content-Type')) {
                headers['Content-Type'] = req.headers.get('Content-Type')!;
              }

              // Reintentar request con el nuevo token
              const retryReq = req.clone({
                setHeaders: headers,
                withCredentials: true
              });

              console.log('🔑 Header Authorization en retry (espera):', retryReq.headers.get('Authorization')?.substring(0, 60));

              return next(retryReq);
            })
          );
        }

        // Iniciar proceso de refresh
        isRefreshing = true;
        refreshTokenSubject.next(null);

        return from(doRefreshToken(refreshToken)).pipe(
          switchMap((response: any) => {
            // Refresh exitoso - extraer el nuevo token
            const newToken = response.accessToken;

            if (!newToken) {
              console.error('❌ No se recibió accessToken en la respuesta de refresh');
              isRefreshing = false;
              refreshTokenSubject.next(null);
              clearSessionAndRedirect(router);
              return throwError(() => new Error('No access token in refresh response'));
            }

            isRefreshing = false;
            refreshTokenSubject.next(newToken);

            console.log('✅ Token refrescado exitosamente');
            console.log('🔑 Nuevo token (primeros 50):', newToken.substring(0, 50));
            console.log('🔄 Reintentando request original:', req.method, req.url);

            // CRÍTICO: Verificar que el token está en localStorage
            const storedToken = localStorage.getItem('accessToken');
            console.log('🔍 Token en localStorage (primeros 50):', storedToken?.substring(0, 50));

            if (storedToken !== newToken) {
              console.error('⚠️ Token en localStorage NO coincide con el refrescado');
            }

            // USAR EL TOKEN DEL LOCALSTORAGE (no la variable)
            const tokenToUse = storedToken || newToken;

            // CRÍTICO: Clonar la request ORIGINAL y FORZAR el nuevo token
            // Construir headers completamente nuevos para evitar conflictos
            const headers: any = {
              Authorization: `Bearer ${tokenToUse}`
            };

            // Preservar Content-Type si existía
            if (req.headers.has('Content-Type')) {
              headers['Content-Type'] = req.headers.get('Content-Type')!;
            }

            const retryReq = req.clone({
              setHeaders: headers,
              withCredentials: true
            });

            console.log('📤 Request clonada con nuevo token');
            console.log('🔑 Header Authorization en retry:', retryReq.headers.get('Authorization')?.substring(0, 60));

            // Reintentar request original con el nuevo token
            return next(retryReq);
          }),
          catchError((refreshError) => {
            // Refresh falló → logout
            isRefreshing = false;
            refreshTokenSubject.next(null);

            console.error('❌ Refresh falló:', refreshError);
            clearSessionAndRedirect(router);

            return throwError(() => refreshError);
          })
        );
      }

      // Otros errores (no 401) → propagar sin cambios
      return throwError(() => error);
    })
  );
};

/**
 * Añade el token de autorización a la request
 */
function addTokenToRequest(req: HttpRequest<unknown>, token: string | null): HttpRequest<unknown> {
  // NO añadir token en rutas de autenticación
  if (req.url.includes('/auth/login') || req.url.includes('/auth/register') || req.url.includes('/auth/refresh')) {
    return req.clone({
      withCredentials: true
    });
  }

  // Añadir token si existe
  if (token) {
    console.log('🔐 Añadiendo token a request:', req.method, req.url);
    console.log('🔑 Token (primeros 50):', token.substring(0, 50));
    return req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      },
      withCredentials: true
    });
  }

  // Sin token → solo withCredentials
  return req.clone({
    withCredentials: true
  });
}

/**
 * Realiza el refresh del token (sin usar HttpClient para evitar ciclos)
 */
function doRefreshToken(refreshToken: string): Promise<any> {
  console.log('🔄 Iniciando refresh del token...');

  return new Promise<any>((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', '/api/auth/refresh', true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.withCredentials = true;

    xhr.onload = function() {
      console.log('📡 Refresh response status:', xhr.status);
      console.log('📡 Refresh response text:', xhr.responseText.substring(0, 200));

      if (xhr.status === 200) {
        try {
          const response = JSON.parse(xhr.responseText);

          if (!response.accessToken) {
            console.error('❌ Respuesta de refresh sin accessToken:', response);
            reject(new Error('No accessToken in refresh response'));
            return;
          }

          // Guardar nuevos tokens en localStorage
          console.log('💾 Guardando nuevo accessToken en localStorage...');
          localStorage.setItem('accessToken', response.accessToken);

          if (response.refreshToken) {
            console.log('💾 Guardando nuevo refreshToken en localStorage...');
            localStorage.setItem('refreshToken', response.refreshToken);
          }

          if (response.userId) {
            localStorage.setItem('userId', response.userId);
          }

          // Verificar que se guardó correctamente
          const savedToken = localStorage.getItem('accessToken');
          console.log('✅ Token guardado en localStorage');
          console.log('🔑 Token guardado (primeros 50):', savedToken?.substring(0, 50));
          console.log('🔑 Token en response (primeros 50):', response.accessToken?.substring(0, 50));

          if (savedToken !== response.accessToken) {
            console.error('❌ El token guardado no coincide con el recibido');
          }

          resolve(response); // Devolver el objeto completo
        } catch (e) {
          console.error('❌ Error parseando respuesta de refresh:', e);
          reject(new Error('Invalid refresh response'));
        }
      } else {
        console.error('❌ Refresh falló con status:', xhr.status);
        console.error('❌ Response body:', xhr.responseText);
        reject(new Error(`Refresh failed with status ${xhr.status}`));
      }
    };

    xhr.onerror = function() {
      console.error('❌ Error de red en refresh');
      reject(new Error('Network error during refresh'));
    };

    xhr.send(JSON.stringify({ refreshToken }));
  });
}

/**
 * Limpia la sesión y redirige a login
 */
function clearSessionAndRedirect(router: Router): void {
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('userId');
  localStorage.removeItem('userRole');
  router.navigate(['/login']);
}


