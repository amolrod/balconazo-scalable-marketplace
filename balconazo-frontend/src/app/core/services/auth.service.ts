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
  RefreshTokenRequest
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

  constructor() {
    // Cargar usuario del localStorage si existe
    const userId = this.getUserId();
    if (userId && this.isAuthenticated()) {
      this.loadUserProfile();
    }
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
          localStorage.setItem(this.TOKEN_KEY, response.accessToken);
          if (response.refreshToken) {
            localStorage.setItem(this.REFRESH_TOKEN_KEY, response.refreshToken);
          }
        })
      );
  }

  /**
   * Logout
   */
  logout(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.REFRESH_TOKEN_KEY);
    localStorage.removeItem(this.USER_ID_KEY);
    localStorage.removeItem(this.USER_ROLE_KEY);
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
    return localStorage.getItem(this.TOKEN_KEY);
  }

  /**
   * Obtener refresh token
   */
  getRefreshToken(): string | null {
    return localStorage.getItem(this.REFRESH_TOKEN_KEY);
  }

  /**
   * Obtener ID del usuario
   */
  getUserId(): string | null {
    return localStorage.getItem(this.USER_ID_KEY);
  }

  /**
   * Obtener rol del usuario
   */
  getUserRole(): string | null {
    return localStorage.getItem(this.USER_ROLE_KEY);
  }

  /**
   * Verificar si el usuario tiene un rol específico
   */
  hasRole(role: string): boolean {
    return this.getUserRole() === role;
  }

  /**
   * Verificar si el usuario es HOST
   */
  isHost(): boolean {
    return this.hasRole('HOST');
  }

  /**
   * Verificar si el usuario es GUEST
   */
  isGuest(): boolean {
    return this.hasRole('GUEST');
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
    localStorage.setItem(this.TOKEN_KEY, response.accessToken);
    localStorage.setItem(this.REFRESH_TOKEN_KEY, response.refreshToken);
    localStorage.setItem(this.USER_ID_KEY, response.userId);
    localStorage.setItem(this.USER_ROLE_KEY, response.role);
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
        console.error('❌ Error al cargar perfil:', error);
        // Si falla, hacer logout
        this.logout();
      }
    });
  }
}

