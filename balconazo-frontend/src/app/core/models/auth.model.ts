export interface User {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  avatar?: string;
  bio?: string;

  // Roles dinámicos - un usuario puede ser ambos
  isHost: boolean;        // Puede publicar espacios
  isGuest: boolean;       // Puede hacer reservas (siempre true por defecto)

  // Verificaciones
  emailVerified: boolean;
  phoneVerified: boolean;

  // Estadísticas
  status: string;
  trustScore?: number;
  totalBookings?: number;    // Como guest
  totalSpaces?: number;      // Como host

  createdAt: string;
  updatedAt?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName?: string;
  lastName?: string;
  role?: 'HOST' | 'GUEST';  // Backend actual requiere role
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
  userId: string;
  email: string;
  isHost: boolean;
  isGuest: boolean;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

export interface BecomeHostRequest {
  // Datos adicionales para convertirse en host
  phone?: string;
  bio?: string;
  acceptsTerms: boolean;
}
