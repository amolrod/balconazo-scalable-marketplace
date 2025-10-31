export interface User {
  id: string;
  email: string;
  role: 'HOST' | 'GUEST' | 'ADMIN';
  status: string;
  trustScore?: number;
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
  role: 'HOST' | 'GUEST';
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
  userId: string;
  email: string;
  role: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

