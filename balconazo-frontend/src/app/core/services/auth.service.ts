import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { Router } from '@angular/router';
import { environment } from '../../../environments/environment';
import {
  User,
  LoginRequest,
  RegisterRequest,
  LoginResponse,
  RefreshTokenRequest,
  BecomeHostRequest
} from '../models/auth.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);

  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  private readonly TOKEN_KEY = 'accessToken';
  private readonly REFRESH_TOKEN_KEY = 'refreshToken';
  private readonly USER_ID_KEY = 'userId';
  private readonly USER_ROLE_KEY = 'userRole';

  // Helper para verificar si localStorage está disponible
  private get isLocalStorageAvailable(): boolean {
    try {
      return typeof window !== 'undefined' && typeof localStorage !== 'undefined';
    } catch {
      return false;
    }
  }

  constructor() {
    // No cargar perfil automáticamente para evitar errores 401
    // El perfil se cargará después del login exitoso
  }

  /**
   * Registrar nuevo usuario
   */
  register(data: RegisterRequest): Observable<any> {
    return this.http.post(`${environment.apiUrl}/auth/register`, data);
  }

  /**
   * Login de usuario
   */
  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/login`, credentials)
      .pipe(
        tap(response => {
          this.setSession(response);
          this.loadUserProfile();
        })
      );
  }

  /**
   * Obtener perfil del usuario actual
   */
  getProfile(): Observable<User> {
    return this.http.get<User>(`${environment.apiUrl}/auth/me`)
      .pipe(
        tap(user => this.currentUserSubject.next(user))
      );
  }

  /**
   * Refresh token
   */
  refreshToken(): Observable<LoginResponse> {
    const refreshToken = this.getRefreshToken();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }

    const request: RefreshTokenRequest = { refreshToken };
    return this.http.post<LoginResponse>(`${environment.apiUrl}/auth/refresh`, request)
      .pipe(
        tap(response => {
          if (this.isLocalStorageAvailable) {
            localStorage.setItem(this.TOKEN_KEY, response.accessToken);
            if (response.refreshToken) {
              localStorage.setItem(this.REFRESH_TOKEN_KEY, response.refreshToken);
            }
          }
        })
      );
  }

  /**
   * Logout
   */
  logout(): void {
    if (this.isLocalStorageAvailable) {
      localStorage.removeItem(this.TOKEN_KEY);
      localStorage.removeItem(this.REFRESH_TOKEN_KEY);
      localStorage.removeItem(this.USER_ID_KEY);
      localStorage.removeItem(this.USER_ROLE_KEY);
    }
    this.currentUserSubject.next(null);
    this.router.navigate(['/login']);
  }

  /**
   * Verificar si el usuario está autenticado
   */
  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  /**
   * Obtener token de acceso
   */
  getToken(): string | null {
    if (!this.isLocalStorageAvailable) {
      return null;
    }
    return localStorage.getItem(this.TOKEN_KEY);
  }

  /**
   * Verificar si el token está expirado (con tolerancia de 60s para clock skew)
   */
  isTokenExpired(token: string | null = null): boolean {
    if (!token) {
      token = this.getToken();
    }

    if (!token) {
      return true;
    }

    try {
      const payload = this.decodeToken(token);
      if (!payload || !payload.exp) {
        return true;
      }

      // Tolerancia de 60 segundos para clock skew
      const CLOCK_SKEW_TOLERANCE = 60;
      const expirationTime = payload.exp * 1000; // Convertir a milisegundos
      const now = Date.now();

      return (expirationTime - CLOCK_SKEW_TOLERANCE * 1000) < now;
    } catch (e) {
      console.error('Error al decodificar token:', e);
      return true;
    }
  }

  /**
   * Decodificar JWT sin verificar firma (solo para leer payload)
   */
  private decodeToken(token: string): any {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) {
        throw new Error('Invalid JWT format');
      }

      const payload = parts[1];
      const decoded = atob(payload.replace(/-/g, '+').replace(/_/g, '/'));
      return JSON.parse(decoded);
    } catch (e) {
      console.error('Error decodificando JWT:', e);
      return null;
    }
  }

  /**
   * Obtener datos del token actual
   */
  getTokenPayload(): any {
    const token = this.getToken();
    return token ? this.decodeToken(token) : null;
  }

  /**
   * Obtener refresh token
   */
  getRefreshToken(): string | null {
    if (!this.isLocalStorageAvailable) {
      return null;
    }
    return localStorage.getItem(this.REFRESH_TOKEN_KEY);
  }

  /**
   * Obtener ID del usuario
   */
  getUserId(): string | null {
    if (!this.isLocalStorageAvailable) {
      return null;
    }
    return localStorage.getItem(this.USER_ID_KEY);
  }

  /**
   * Obtener rol del usuario
   */
  getUserRole(): string | null {
    if (!this.isLocalStorageAvailable) {
      return null;
    }
    return localStorage.getItem(this.USER_ROLE_KEY);
  }

  /**
   * Verificar si el usuario tiene un rol específico
   * DEPRECATED - usar isHost() o isGuest() directamente
   */
  hasRole(role: string): boolean {
    const user = this.getCurrentUser();
    if (!user) return false;

    if (role === 'HOST') return user.isHost;
    if (role === 'GUEST') return user.isGuest;
    return false;
  }

  /**
   * Verificar si el usuario es HOST (puede publicar espacios)
   */
  isHost(): boolean {
    const user = this.getCurrentUser();
    return user?.isHost || false;
  }

  /**
   * Verificar si el usuario es GUEST (puede hacer reservas)
   */
  isGuest(): boolean {
    const user = this.getCurrentUser();
    return user?.isGuest !== false; // Por defecto true
  }

  /**
   * Convertirse en Host - cualquier usuario puede hacerlo
   */
  becomeHost(data: BecomeHostRequest): Observable<User> {
    return this.http.post<User>(`${environment.apiUrl}/auth/become-host`, data)
      .pipe(
        tap(user => {
          this.currentUserSubject.next(user);
          console.log('✅ Usuario ahora es HOST:', user);
        })
      );
  }

  /**
   * Obtener usuario actual
   */
  getCurrentUser(): User | null {
    return this.currentUserSubject.value;
  }

  /**
   * Guardar sesión en localStorage
   */
  private setSession(response: LoginResponse): void {
    if (this.isLocalStorageAvailable) {
      localStorage.setItem(this.TOKEN_KEY, response.accessToken);
      localStorage.setItem(this.REFRESH_TOKEN_KEY, response.refreshToken);
      localStorage.setItem(this.USER_ID_KEY, response.userId);
      // Ya no guardamos role fijo - los roles vienen del user profile
    }
  }

  /**
   * Cargar perfil del usuario
   */
  private loadUserProfile(): void {
    this.getProfile().subscribe({
      next: (user) => {
        console.log('✅ Usuario cargado:', user);
      },
      error: (error) => {
        // Silenciar errores 401 - simplemente el token no es válido o expiró
        if (error.status !== 401) {
          console.error('❌ Error al cargar perfil:', error);
        }
        // NO hacer logout automático - el interceptor maneja el refresh
      }
    });
  }
}

