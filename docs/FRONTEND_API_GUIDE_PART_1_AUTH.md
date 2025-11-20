# Guía de Integración API Frontend - Parte 1: Autenticación y Roles

## 📋 Índice
1. [Introducción](#introducción)
2. [Flujo de Autenticación](#flujo-de-autenticación)
3. [Sistema de Roles Dinámico](#sistema-de-roles-dinámico)
4. [Endpoints de Autenticación](#endpoints-de-autenticación)
5. [Manejo de JWT](#manejo-de-jwt)
6. [Gestión de Estado en Frontend](#gestión-de-estado-en-frontend)
7. [Manejo de Errores](#manejo-de-errores)
8. [Ejemplos de Código](#ejemplos-de-código)

---

## Introducción

La API de **BalconazoApp** utiliza autenticación basada en **JWT (JSON Web Tokens)** con un sistema de roles dinámico donde:
- **Todos los usuarios registrados son GUEST por defecto**
- **Los usuarios se convierten en HOST automáticamente al crear su primer espacio**
- **Un usuario puede ser HOST y GUEST simultáneamente**

**Base URL**: `http://localhost:8080` (API Gateway)

**Servicio de Autenticación**: Puerto 8084 (accesible vía Gateway)

---

## Flujo de Autenticación

### 1. Registro de Usuario

```
POST /api/auth/register
```

**Request Body**:
```json
{
  "username": "maria_garcia",
  "email": "maria@example.com",
  "password": "Password123!",
  "fullName": "María García"
}
```

**Response 201 Created**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "maria_garcia",
  "email": "maria@example.com",
  "fullName": "María García",
  "isHost": false,
  "isGuest": true,
  "createdAt": "2025-11-20T10:30:00"
}
```

**Campos importantes**:
- `id`: UUID único del usuario (usar para referencias)
- `isHost`: `false` inicialmente (cambia a `true` al crear un espacio)
- `isGuest`: `true` siempre para usuarios registrados

### 2. Login

```
POST /api/auth/login
```

**Request Body**:
```json
{
  "username": "maria_garcia",
  "password": "Password123!"
}
```

**Response 200 OK**:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "maria_garcia",
  "isHost": false,
  "isGuest": true
}
```

**Importante**: Guardar el `token` en `localStorage` o `sessionStorage` para requests posteriores.

### 3. Obtener Perfil Actual

```
GET /api/auth/me
Headers:
  Authorization: Bearer {token}
```

**Response 200 OK**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "maria_garcia",
  "email": "maria@example.com",
  "fullName": "María García",
  "isHost": true,
  "isGuest": true,
  "createdAt": "2025-11-20T10:30:00"
}
```

**Usar este endpoint para**:
- Verificar si el token sigue válido
- Obtener roles actualizados (después de crear un espacio)
- Sincronizar estado de usuario en la aplicación

---

## Sistema de Roles Dinámico

### Estados de Usuario

| Estado | isGuest | isHost | Descripción |
|--------|---------|--------|-------------|
| **Nuevo Usuario** | `true` | `false` | Recién registrado, puede buscar/reservar |
| **Usuario con Espacio** | `true` | `true` | Creó al menos un espacio, puede hospedar y reservar |

### Promoción Automática a HOST

**Trigger**: Al crear el primer espacio

**Ejemplo de flujo**:
```
1. Usuario registra → isGuest=true, isHost=false
2. Usuario crea espacio → isGuest=true, isHost=true (automático)
3. GET /api/auth/me → devuelve roles actualizados
```

**Código en frontend**:
```typescript
async function createSpace(spaceData: SpaceCreateDTO) {
  // Crear espacio
  const response = await fetch('/api/spaces', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(spaceData)
  });
  
  if (response.ok) {
    // IMPORTANTE: Actualizar roles del usuario
    const updatedUser = await fetch('/api/auth/me', {
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(r => r.json());
    
    // Ahora updatedUser.isHost === true
    updateUserState(updatedUser);
  }
}
```

### Control de Acceso en Frontend

```typescript
interface User {
  id: string;
  username: string;
  email: string;
  fullName: string;
  isHost: boolean;
  isGuest: boolean;
}

// Componentes condicionales basados en roles
function NavigationMenu({ user }: { user: User }) {
  return (
    <nav>
      {/* Disponible para todos los usuarios autenticados */}
      <Link to="/search">Buscar Espacios</Link>
      <Link to="/my-bookings">Mis Reservas</Link>
      
      {/* Solo para HOSTS */}
      {user.isHost && (
        <>
          <Link to="/my-spaces">Mis Espacios</Link>
          <Link to="/host-bookings">Gestionar Reservas</Link>
        </>
      )}
      
      {/* Botón para convertirse en HOST */}
      {!user.isHost && (
        <Link to="/create-space">Publicar tu Espacio</Link>
      )}
    </nav>
  );
}
```

---

## Endpoints de Autenticación

### POST /api/auth/register

**Descripción**: Registrar nuevo usuario

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "username": "string (required, min 3, max 50)",
  "email": "string (required, formato email)",
  "password": "string (required, min 8)",
  "fullName": "string (required, max 100)"
}
```

**Response Codes**:
- `201 Created`: Usuario creado exitosamente
- `400 Bad Request`: Validación fallida o usuario ya existe
- `500 Internal Server Error`: Error del servidor

**Errores comunes**:
```json
// Username duplicado
{
  "message": "Username already exists"
}

// Email duplicado
{
  "message": "Email already exists"
}

// Password muy corta
{
  "message": "Password must be at least 8 characters"
}
```

### POST /api/auth/login

**Descripción**: Iniciar sesión y obtener JWT

**Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

**Response Codes**:
- `200 OK`: Login exitoso
- `401 Unauthorized`: Credenciales inválidas
- `500 Internal Server Error`: Error del servidor

**Response Body (200 OK)**:
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc0d1ZXN0Ijp0cnVlLCJpc0hvc3QiOmZhbHNlLCJzdWIiOiJhMWIyYzNkNC1lNWY2LTc4OTAtYWJjZC1lZjEyMzQ1Njc4OTAiLCJleHAiOjQ4OTQ1MzE1MzB9.ABC123...",
  "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "maria_garcia",
  "isHost": false,
  "isGuest": true
}
```

### GET /api/auth/me

**Descripción**: Obtener perfil del usuario autenticado

**Headers**:
```
Authorization: Bearer {token}
```

**Response Codes**:
- `200 OK`: Perfil obtenido
- `401 Unauthorized`: Token inválido o expirado
- `500 Internal Server Error`: Error del servidor

**Response Body (200 OK)**:
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "username": "maria_garcia",
  "email": "maria@example.com",
  "fullName": "María García",
  "isHost": true,
  "isGuest": true,
  "createdAt": "2025-11-20T10:30:00"
}
```

---

## Manejo de JWT

### Estructura del Token

El JWT contiene los siguientes claims:

```json
{
  "sub": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",  // User ID
  "isGuest": true,
  "isHost": false,
  "exp": 4894531530  // Timestamp de expiración
}
```

### Uso del Token

**Todos los endpoints protegidos requieren**:
```
Authorization: Bearer {token}
```

**Ejemplo con fetch**:
```typescript
async function authenticatedRequest(url: string, options: RequestInit = {}) {
  const token = localStorage.getItem('authToken');
  
  return fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
}
```

### Expiración del Token

**Duración**: Los tokens tienen una expiración muy larga (para testing)

**Manejo de expiración**:
```typescript
async function makeRequest(url: string, options: RequestInit) {
  const response = await authenticatedRequest(url, options);
  
  if (response.status === 401) {
    // Token expirado o inválido
    logout();
    redirectToLogin();
  }
  
  return response;
}
```

### Almacenamiento Seguro

**Opciones**:

1. **localStorage** (más simple, persiste entre pestañas):
```typescript
// Guardar token
localStorage.setItem('authToken', token);
localStorage.setItem('userId', userId);

// Recuperar token
const token = localStorage.getItem('authToken');

// Eliminar token (logout)
localStorage.removeItem('authToken');
localStorage.removeItem('userId');
```

2. **sessionStorage** (más seguro, se borra al cerrar pestaña):
```typescript
sessionStorage.setItem('authToken', token);
```

3. **Estado de aplicación** (Context API, Redux, Zustand):
```typescript
// Ejemplo con Context API
interface AuthContextType {
  token: string | null;
  user: User | null;
  login: (credentials: LoginDTO) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);
```

---

## Gestión de Estado en Frontend

### Context API (React)

```typescript
// AuthContext.tsx
import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface User {
  id: string;
  username: string;
  email: string;
  fullName: string;
  isHost: boolean;
  isGuest: boolean;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (username: string, password: string) => Promise<void>;
  register: (data: RegisterDTO) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(
    localStorage.getItem('authToken')
  );
  
  // Cargar usuario al iniciar
  useEffect(() => {
    if (token) {
      fetchCurrentUser();
    }
  }, [token]);
  
  async function fetchCurrentUser() {
    try {
      const response = await fetch('http://localhost:8080/api/auth/me', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      
      if (response.ok) {
        const userData = await response.json();
        setUser(userData);
      } else {
        // Token inválido
        logout();
      }
    } catch (error) {
      console.error('Error fetching user:', error);
    }
  }
  
  async function login(username: string, password: string) {
    const response = await fetch('http://localhost:8080/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    if (!response.ok) {
      throw new Error('Login failed');
    }
    
    const data = await response.json();
    setToken(data.token);
    localStorage.setItem('authToken', data.token);
    
    // Cargar perfil completo
    await fetchCurrentUser();
  }
  
  async function register(data: RegisterDTO) {
    const response = await fetch('http://localhost:8080/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Registration failed');
    }
    
    // Auto-login después del registro
    await login(data.username, data.password);
  }
  
  function logout() {
    setToken(null);
    setUser(null);
    localStorage.removeItem('authToken');
  }
  
  async function refreshUser() {
    await fetchCurrentUser();
  }
  
  return (
    <AuthContext.Provider value={{
      user,
      token,
      login,
      register,
      logout,
      refreshUser,
      isAuthenticated: !!user
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
```

### Uso en Componentes

```typescript
// LoginPage.tsx
import { useState } from 'react';
import { useAuth } from './AuthContext';
import { useNavigate } from 'react-router-dom';

function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login } = useAuth();
  const navigate = useNavigate();
  
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    
    try {
      await login(username, password);
      navigate('/dashboard');
    } catch (err) {
      setError('Usuario o contraseña incorrectos');
    }
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={username}
        onChange={e => setUsername(e.target.value)}
        placeholder="Usuario"
        required
      />
      <input
        type="password"
        value={password}
        onChange={e => setPassword(e.target.value)}
        placeholder="Contraseña"
        required
      />
      {error && <p className="error">{error}</p>}
      <button type="submit">Iniciar Sesión</button>
    </form>
  );
}
```

### Protected Routes

```typescript
// ProtectedRoute.tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireHost?: boolean;
}

function ProtectedRoute({ children, requireHost = false }: ProtectedRouteProps) {
  const { user, isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (requireHost && !user?.isHost) {
    return <Navigate to="/become-host" replace />;
  }
  
  return <>{children}</>;
}

// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          
          {/* Rutas protegidas */}
          <Route path="/dashboard" element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          } />
          
          {/* Rutas solo para HOSTS */}
          <Route path="/my-spaces" element={
            <ProtectedRoute requireHost>
              <MySpaces />
            </ProtectedRoute>
          } />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
```

---

## Manejo de Errores

### Códigos de Error Comunes

| Código | Significado | Acción Recomendada |
|--------|-------------|-------------------|
| `400` | Bad Request | Validar datos del formulario |
| `401` | Unauthorized | Token inválido → logout y redirect a login |
| `403` | Forbidden | Usuario no tiene permisos |
| `404` | Not Found | Recurso no existe |
| `409` | Conflict | Conflicto (username/email duplicado) |
| `500` | Server Error | Mostrar error genérico, reintentar |

### Función Helper para Errores

```typescript
interface ApiError {
  message: string;
  status: number;
}

async function handleApiResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let errorMessage = 'Error en la solicitud';
    
    try {
      const errorData = await response.json();
      errorMessage = errorData.message || errorMessage;
    } catch {
      // Si no hay JSON, usar mensaje por defecto
    }
    
    const error: ApiError = {
      message: errorMessage,
      status: response.status
    };
    
    throw error;
  }
  
  return response.json();
}

// Uso
async function loginUser(username: string, password: string) {
  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password })
    });
    
    const data = await handleApiResponse<LoginResponse>(response);
    return data;
  } catch (error) {
    if ((error as ApiError).status === 401) {
      throw new Error('Credenciales incorrectas');
    }
    throw new Error('Error al iniciar sesión');
  }
}
```

---

## Ejemplos de Código

### Flujo Completo de Registro y Login

```typescript
// services/authService.ts
const API_BASE = 'http://localhost:8080/api/auth';

export interface RegisterDTO {
  username: string;
  email: string;
  password: string;
  fullName: string;
}

export interface LoginDTO {
  username: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  userId: string;
  username: string;
  isHost: boolean;
  isGuest: boolean;
}

export interface UserProfile {
  id: string;
  username: string;
  email: string;
  fullName: string;
  isHost: boolean;
  isGuest: boolean;
  createdAt: string;
}

export async function register(data: RegisterDTO): Promise<UserProfile> {
  const response = await fetch(`${API_BASE}/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Registration failed');
  }
  
  return response.json();
}

export async function login(data: LoginDTO): Promise<AuthResponse> {
  const response = await fetch(`${API_BASE}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    throw new Error('Invalid credentials');
  }
  
  return response.json();
}

export async function getCurrentUser(token: string): Promise<UserProfile> {
  const response = await fetch(`${API_BASE}/me`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch user profile');
  }
  
  return response.json();
}
```

### Componente de Registro

```typescript
// RegisterForm.tsx
import { useState } from 'react';
import { useAuth } from './AuthContext';
import { useNavigate } from 'react-router-dom';

function RegisterForm() {
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
    fullName: ''
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const { register } = useAuth();
  const navigate = useNavigate();
  
  function validateForm() {
    const newErrors: Record<string, string> = {};
    
    if (formData.username.length < 3) {
      newErrors.username = 'El usuario debe tener al menos 3 caracteres';
    }
    
    if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email inválido';
    }
    
    if (formData.password.length < 8) {
      newErrors.password = 'La contraseña debe tener al menos 8 caracteres';
    }
    
    if (!formData.fullName.trim()) {
      newErrors.fullName = 'El nombre completo es requerido';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  }
  
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    try {
      await register(formData);
      navigate('/dashboard');
    } catch (error) {
      setErrors({ general: (error as Error).message });
    }
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <h2>Crear Cuenta</h2>
      
      {errors.general && <div className="error">{errors.general}</div>}
      
      <div>
        <label>Usuario</label>
        <input
          type="text"
          value={formData.username}
          onChange={e => setFormData({ ...formData, username: e.target.value })}
          required
        />
        {errors.username && <span className="error">{errors.username}</span>}
      </div>
      
      <div>
        <label>Email</label>
        <input
          type="email"
          value={formData.email}
          onChange={e => setFormData({ ...formData, email: e.target.value })}
          required
        />
        {errors.email && <span className="error">{errors.email}</span>}
      </div>
      
      <div>
        <label>Contraseña</label>
        <input
          type="password"
          value={formData.password}
          onChange={e => setFormData({ ...formData, password: e.target.value })}
          required
        />
        {errors.password && <span className="error">{errors.password}</span>}
      </div>
      
      <div>
        <label>Nombre Completo</label>
        <input
          type="text"
          value={formData.fullName}
          onChange={e => setFormData({ ...formData, fullName: e.target.value })}
          required
        />
        {errors.fullName && <span className="error">{errors.fullName}</span>}
      </div>
      
      <button type="submit">Registrarse</button>
    </form>
  );
}
```

---

## Resumen de Conceptos Clave

1. **Autenticación basada en JWT**: Todos los endpoints protegidos requieren token
2. **Roles dinámicos**: isGuest (siempre true), isHost (true después de crear espacio)
3. **Promoción automática**: Al crear primer espacio → isHost = true
4. **Sincronización de estado**: Usar GET /api/auth/me después de acciones que cambien roles
5. **Manejo de errores**: Códigos HTTP 401 → logout, 403 → sin permisos
6. **Almacenamiento**: localStorage para token persistente
7. **Protected routes**: Validar autenticación y roles antes de renderizar

---

## Siguiente Documento

Continuar con: **[FRONTEND_API_GUIDE_PART_2_SPACES.md](./FRONTEND_API_GUIDE_PART_2_SPACES.md)** - Gestión de Espacios

