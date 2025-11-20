# Guía de Integración API Frontend - Parte 2: Gestión de Espacios

## 📋 Índice
1. [Introducción](#introducción)
2. [Sistema de Ownership](#sistema-de-ownership)
3. [Endpoints de Espacios](#endpoints-de-espacios)
4. [Gestión de Imágenes](#gestión-de-imágenes)
5. [Validación y Errores](#validación-y-errores)
6. [Ejemplos de Código](#ejemplos-de-código)
7. [Casos de Uso](#casos-de-uso)

---

## Introducción

El módulo de **Espacios** permite a los usuarios:
- **Crear** nuevos espacios (se convierten en HOST automáticamente)
- **Listar** todos los espacios públicos
- **Ver detalles** de un espacio específico
- **Editar** sus propios espacios (solo el propietario)
- **Eliminar** sus propios espacios (solo el propietario)
- **Subir múltiples imágenes** por espacio

**Base URL**: `http://localhost:8080/api/spaces` (vía API Gateway)

**Servicio**: Catalog Microservice (Puerto 8085)

---

## Sistema de Ownership

### Validación de Propietario

Todos los endpoints de edición/eliminación **verifican que el usuario autenticado sea el propietario**:

```
Usuario A crea espacio X → ownerId = Usuario A
Usuario B intenta editar espacio X → HTTP 403 Forbidden
Usuario A edita espacio X → HTTP 200 OK
```

### Promoción a HOST

**Al crear el primer espacio**:
1. El espacio se crea con `ownerId = userId` (del token JWT)
2. El Auth Service actualiza `isHost = true` para el usuario
3. El usuario ya puede gestionar espacios como HOST

**Importante**: Después de crear el primer espacio, llamar a `GET /api/auth/me` para actualizar roles en el frontend.

---

## Endpoints de Espacios

### 1. Crear Espacio

```
POST /api/spaces
```

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:
```json
{
  "name": "Terraza con Vista al Mar",
  "description": "Hermosa terraza de 50m² con vistas panorámicas al océano. Ideal para eventos al aire libre.",
  "location": "Barcelona, España",
  "pricePerHour": 45.00,
  "capacity": 20,
  "amenities": ["WiFi", "Muebles de exterior", "Parrilla", "Sistema de sonido"]
}
```

**Campos**:
- `name`: string (required, max 100 caracteres)
- `description`: string (required, max 500 caracteres)
- `location`: string (required, max 200 caracteres)
- `pricePerHour`: number (required, > 0, formato decimal)
- `capacity`: integer (required, > 0)
- `amenities`: array of strings (opcional)

**Response 201 Created**:
```json
{
  "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "name": "Terraza con Vista al Mar",
  "description": "Hermosa terraza de 50m² con vistas panorámicas al océano. Ideal para eventos al aire libre.",
  "location": "Barcelona, España",
  "pricePerHour": 45.00,
  "capacity": 20,
  "amenities": ["WiFi", "Muebles de exterior", "Parrilla", "Sistema de sonido"],
  "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "available": true,
  "createdAt": "2025-11-20T10:30:00",
  "images": []
}
```

**Response Codes**:
- `201 Created`: Espacio creado exitosamente
- `400 Bad Request`: Datos inválidos
- `401 Unauthorized`: Token inválido
- `500 Internal Server Error`: Error del servidor

### 2. Listar Todos los Espacios

```
GET /api/spaces
```

**Headers**:
```
Authorization: Bearer {token}
```

**Query Parameters** (opcionales):
- Ninguno (devuelve todos los espacios públicos)

**Response 200 OK**:
```json
[
  {
    "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "name": "Terraza con Vista al Mar",
    "description": "Hermosa terraza de 50m²...",
    "location": "Barcelona, España",
    "pricePerHour": 45.00,
    "capacity": 20,
    "amenities": ["WiFi", "Muebles de exterior"],
    "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "available": true,
    "createdAt": "2025-11-20T10:30:00",
    "images": [
      {
        "id": "img-001",
        "url": "http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-001",
        "isPrimary": true
      }
    ]
  },
  {
    "id": "7f31f234-c3ae-5733-bd26-e5e1c81a7bf1",
    "name": "Jardín Privado Centro Ciudad",
    "description": "Oasis urbano en pleno centro...",
    "location": "Madrid, España",
    "pricePerHour": 35.00,
    "capacity": 15,
    "amenities": ["Zona verde", "Pérgola"],
    "ownerId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "available": true,
    "createdAt": "2025-11-20T11:00:00",
    "images": []
  }
]
```

**Nota**: Los espacios incluyen la URL completa de las imágenes para consumo directo en el frontend.

### 3. Obtener Espacio por ID

```
GET /api/spaces/{spaceId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `spaceId`: UUID del espacio

**Response 200 OK**:
```json
{
  "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "name": "Terraza con Vista al Mar",
  "description": "Hermosa terraza de 50m² con vistas panorámicas al océano. Ideal para eventos al aire libre.",
  "location": "Barcelona, España",
  "pricePerHour": 45.00,
  "capacity": 20,
  "amenities": ["WiFi", "Muebles de exterior", "Parrilla", "Sistema de sonido"],
  "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "available": true,
  "createdAt": "2025-11-20T10:30:00",
  "images": [
    {
      "id": "img-001",
      "url": "http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-001",
      "isPrimary": true
    },
    {
      "id": "img-002",
      "url": "http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-002",
      "isPrimary": false
    }
  ]
}
```

**Response Codes**:
- `200 OK`: Espacio encontrado
- `401 Unauthorized`: Token inválido
- `404 Not Found`: Espacio no existe
- `500 Internal Server Error`: Error del servidor

### 4. Actualizar Espacio

```
PUT /api/spaces/{spaceId}
```

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
- `spaceId`: UUID del espacio

**Request Body** (todos los campos son opcionales):
```json
{
  "name": "Terraza con Vista al Mar - Renovada",
  "description": "Hermosa terraza de 50m² completamente renovada...",
  "location": "Barcelona, España",
  "pricePerHour": 50.00,
  "capacity": 25,
  "amenities": ["WiFi", "Muebles nuevos", "Parrilla", "Sistema de sonido premium"]
}
```

**Response 200 OK**:
```json
{
  "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
  "name": "Terraza con Vista al Mar - Renovada",
  "description": "Hermosa terraza de 50m² completamente renovada...",
  "location": "Barcelona, España",
  "pricePerHour": 50.00,
  "capacity": 25,
  "amenities": ["WiFi", "Muebles nuevos", "Parrilla", "Sistema de sonido premium"],
  "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "available": true,
  "createdAt": "2025-11-20T10:30:00",
  "images": [...]
}
```

**Response Codes**:
- `200 OK`: Espacio actualizado exitosamente
- `400 Bad Request`: Datos inválidos
- `401 Unauthorized`: Token inválido
- `403 Forbidden`: No eres el propietario del espacio
- `404 Not Found`: Espacio no existe
- `500 Internal Server Error`: Error del servidor

**Validación de Ownership**:
```
Token → userId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Espacio → ownerId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
✅ userId == ownerId → HTTP 200 OK

Token → userId: b2c3d4e5-f6a7-8901-bcde-f23456789012
Espacio → ownerId: a1b2c3d4-e5f6-7890-abcd-ef1234567890
❌ userId != ownerId → HTTP 403 Forbidden
```

### 5. Eliminar Espacio

```
DELETE /api/spaces/{spaceId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `spaceId`: UUID del espacio

**Response 204 No Content**:
- Sin cuerpo de respuesta
- Espacio eliminado exitosamente

**Response Codes**:
- `204 No Content`: Espacio eliminado exitosamente
- `401 Unauthorized`: Token inválido
- `403 Forbidden`: No eres el propietario del espacio
- `404 Not Found`: Espacio no existe
- `500 Internal Server Error`: Error del servidor

**Nota**: La eliminación es permanente. Considerar implementar "soft delete" en el futuro.

### 6. Listar Espacios del Usuario Actual

```
GET /api/spaces/my-spaces
```

**Headers**:
```
Authorization: Bearer {token}
```

**Descripción**: Devuelve solo los espacios creados por el usuario autenticado.

**Response 200 OK**:
```json
[
  {
    "id": "5e20e123-b2fd-4622-ac15-d4d0b90a6dd9",
    "name": "Terraza con Vista al Mar",
    "description": "Hermosa terraza de 50m²...",
    "location": "Barcelona, España",
    "pricePerHour": 45.00,
    "capacity": 20,
    "amenities": ["WiFi", "Muebles de exterior"],
    "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "available": true,
    "createdAt": "2025-11-20T10:30:00",
    "images": [...]
  },
  {
    "id": "8g42g345-d4bf-6844-ce37-f6f2d92b8cg2",
    "name": "Ático Modernista",
    "description": "Espacio único en edificio histórico...",
    "location": "Barcelona, España",
    "pricePerHour": 60.00,
    "capacity": 30,
    "amenities": ["WiFi", "Proyector", "Cocina equipada"],
    "ownerId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "available": true,
    "createdAt": "2025-11-20T14:00:00",
    "images": []
  }
]
```

**Response Codes**:
- `200 OK`: Lista de espacios (puede ser vacía `[]` si no tiene espacios)
- `401 Unauthorized`: Token inválido

---

## Gestión de Imágenes

### Estructura de Imágenes

Cada espacio puede tener **múltiples imágenes**:
- Una imagen es **primaria** (`isPrimary: true`) → se muestra como thumbnail
- Las demás son secundarias (`isPrimary: false`) → galería de imágenes

### 1. Subir Imagen

```
POST /api/spaces/{spaceId}/images
```

**Headers**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Path Parameters**:
- `spaceId`: UUID del espacio

**Form Data**:
```
file: [archivo de imagen]
isPrimary: true o false (opcional, default: false)
```

**Ejemplo con fetch**:
```typescript
async function uploadImage(spaceId: string, file: File, isPrimary: boolean = false) {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('isPrimary', isPrimary.toString());
  
  const response = await fetch(
    `http://localhost:8080/api/spaces/${spaceId}/images`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      },
      body: formData
    }
  );
  
  return response.json();
}
```

**Response 201 Created**:
```json
{
  "id": "img-003",
  "url": "http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-003",
  "isPrimary": true
}
```

**Response Codes**:
- `201 Created`: Imagen subida exitosamente
- `400 Bad Request`: Archivo inválido o muy grande
- `401 Unauthorized`: Token inválido
- `403 Forbidden`: No eres el propietario del espacio
- `404 Not Found`: Espacio no existe

**Formatos aceptados**: JPG, JPEG, PNG, WebP

**Tamaño máximo**: 5 MB por imagen

### 2. Obtener Imagen

```
GET /api/spaces/{spaceId}/images/{imageId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Response**: Stream de bytes de la imagen (JPEG, PNG, etc.)

**Uso directo en HTML**:
```html
<img 
  src="http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-001"
  alt="Imagen del espacio"
/>
```

**Nota**: Las URLs incluyen la ruta completa, por lo que puedes usarlas directamente desde el objeto `space.images`.

### 3. Eliminar Imagen

```
DELETE /api/spaces/{spaceId}/images/{imageId}
```

**Headers**:
```
Authorization: Bearer {token}
```

**Path Parameters**:
- `spaceId`: UUID del espacio
- `imageId`: ID de la imagen

**Response 204 No Content**:
- Imagen eliminada exitosamente

**Response Codes**:
- `204 No Content`: Imagen eliminada
- `401 Unauthorized`: Token inválido
- `403 Forbidden`: No eres el propietario del espacio
- `404 Not Found`: Espacio o imagen no existe

### 4. Marcar Imagen como Primaria

```
PUT /api/spaces/{spaceId}/images/{imageId}/primary
```

**Headers**:
```
Authorization: Bearer {token}
```

**Response 200 OK**:
```json
{
  "id": "img-002",
  "url": "http://localhost:8085/api/spaces/5e20e123-b2fd-4622-ac15-d4d0b90a6dd9/images/img-002",
  "isPrimary": true
}
```

**Nota**: Al marcar una imagen como primaria, la anterior imagen primaria pasa a ser secundaria automáticamente.

---

## Validación y Errores

### Validaciones de Campos

| Campo | Reglas | Error |
|-------|--------|-------|
| `name` | Requerido, max 100 caracteres | "Name is required" |
| `description` | Requerido, max 500 caracteres | "Description is required" |
| `location` | Requerido, max 200 caracteres | "Location is required" |
| `pricePerHour` | Requerido, > 0 | "Price must be greater than 0" |
| `capacity` | Requerido, > 0 | "Capacity must be greater than 0" |
| `amenities` | Opcional, array de strings | - |

### Errores Comunes

**403 Forbidden - No eres el propietario**:
```json
{
  "message": "You are not the owner of this space"
}
```

**404 Not Found - Espacio no existe**:
```json
{
  "message": "Space not found"
}
```

**400 Bad Request - Datos inválidos**:
```json
{
  "message": "Validation failed",
  "errors": {
    "pricePerHour": "Price must be greater than 0",
    "capacity": "Capacity must be greater than 0"
  }
}
```

---

## Ejemplos de Código

### Service de Espacios

```typescript
// services/spaceService.ts
const API_BASE = 'http://localhost:8080/api/spaces';

export interface CreateSpaceDTO {
  name: string;
  description: string;
  location: string;
  pricePerHour: number;
  capacity: number;
  amenities?: string[];
}

export interface UpdateSpaceDTO {
  name?: string;
  description?: string;
  location?: string;
  pricePerHour?: number;
  capacity?: number;
  amenities?: string[];
}

export interface SpaceImage {
  id: string;
  url: string;
  isPrimary: boolean;
}

export interface Space {
  id: string;
  name: string;
  description: string;
  location: string;
  pricePerHour: number;
  capacity: number;
  amenities: string[];
  ownerId: string;
  available: boolean;
  createdAt: string;
  images: SpaceImage[];
}

function getAuthHeaders(token: string) {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
}

export async function createSpace(token: string, data: CreateSpaceDTO): Promise<Space> {
  const response = await fetch(API_BASE, {
    method: 'POST',
    headers: getAuthHeaders(token),
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message || 'Failed to create space');
  }
  
  return response.json();
}

export async function getAllSpaces(token: string): Promise<Space[]> {
  const response = await fetch(API_BASE, {
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch spaces');
  }
  
  return response.json();
}

export async function getSpaceById(token: string, spaceId: string): Promise<Space> {
  const response = await fetch(`${API_BASE}/${spaceId}`, {
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Space not found');
    }
    throw new Error('Failed to fetch space');
  }
  
  return response.json();
}

export async function updateSpace(
  token: string,
  spaceId: string,
  data: UpdateSpaceDTO
): Promise<Space> {
  const response = await fetch(`${API_BASE}/${spaceId}`, {
    method: 'PUT',
    headers: getAuthHeaders(token),
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    if (response.status === 403) {
      throw new Error('You are not the owner of this space');
    }
    if (response.status === 404) {
      throw new Error('Space not found');
    }
    const error = await response.json();
    throw new Error(error.message || 'Failed to update space');
  }
  
  return response.json();
}

export async function deleteSpace(token: string, spaceId: string): Promise<void> {
  const response = await fetch(`${API_BASE}/${spaceId}`, {
    method: 'DELETE',
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    if (response.status === 403) {
      throw new Error('You are not the owner of this space');
    }
    if (response.status === 404) {
      throw new Error('Space not found');
    }
    throw new Error('Failed to delete space');
  }
}

export async function getMySpaces(token: string): Promise<Space[]> {
  const response = await fetch(`${API_BASE}/my-spaces`, {
    headers: getAuthHeaders(token)
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch your spaces');
  }
  
  return response.json();
}

export async function uploadSpaceImage(
  token: string,
  spaceId: string,
  file: File,
  isPrimary: boolean = false
): Promise<SpaceImage> {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('isPrimary', isPrimary.toString());
  
  const response = await fetch(`${API_BASE}/${spaceId}/images`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });
  
  if (!response.ok) {
    if (response.status === 403) {
      throw new Error('You are not the owner of this space');
    }
    throw new Error('Failed to upload image');
  }
  
  return response.json();
}

export async function deleteSpaceImage(
  token: string,
  spaceId: string,
  imageId: string
): Promise<void> {
  const response = await fetch(`${API_BASE}/${spaceId}/images/${imageId}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (!response.ok) {
    throw new Error('Failed to delete image');
  }
}

export async function setPrimaryImage(
  token: string,
  spaceId: string,
  imageId: string
): Promise<SpaceImage> {
  const response = await fetch(`${API_BASE}/${spaceId}/images/${imageId}/primary`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (!response.ok) {
    throw new Error('Failed to set primary image');
  }
  
  return response.json();
}
```

### Componente de Creación de Espacio

```typescript
// CreateSpaceForm.tsx
import { useState } from 'react';
import { useAuth } from './AuthContext';
import { useNavigate } from 'react-router-dom';
import { createSpace, uploadSpaceImage } from './services/spaceService';

function CreateSpaceForm() {
  const { token, refreshUser } = useAuth();
  const navigate = useNavigate();
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    location: '',
    pricePerHour: 0,
    capacity: 1,
    amenities: [] as string[]
  });
  
  const [images, setImages] = useState<File[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      // 1. Crear el espacio
      const space = await createSpace(token!, formData);
      
      // 2. Subir imágenes
      for (let i = 0; i < images.length; i++) {
        const isPrimary = i === 0; // Primera imagen es primaria
        await uploadSpaceImage(token!, space.id, images[i], isPrimary);
      }
      
      // 3. Actualizar roles del usuario (ahora es HOST)
      await refreshUser();
      
      // 4. Redirigir a la página del espacio
      navigate(`/spaces/${space.id}`);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }
  
  function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    if (e.target.files) {
      setImages(Array.from(e.target.files));
    }
  }
  
  function addAmenity(amenity: string) {
    if (amenity && !formData.amenities.includes(amenity)) {
      setFormData({
        ...formData,
        amenities: [...formData.amenities, amenity]
      });
    }
  }
  
  function removeAmenity(amenity: string) {
    setFormData({
      ...formData,
      amenities: formData.amenities.filter(a => a !== amenity)
    });
  }
  
  return (
    <form onSubmit={handleSubmit}>
      <h2>Publicar tu Espacio</h2>
      
      {error && <div className="error">{error}</div>}
      
      <div>
        <label>Nombre del Espacio *</label>
        <input
          type="text"
          value={formData.name}
          onChange={e => setFormData({ ...formData, name: e.target.value })}
          maxLength={100}
          required
        />
      </div>
      
      <div>
        <label>Descripción *</label>
        <textarea
          value={formData.description}
          onChange={e => setFormData({ ...formData, description: e.target.value })}
          maxLength={500}
          rows={4}
          required
        />
      </div>
      
      <div>
        <label>Ubicación *</label>
        <input
          type="text"
          value={formData.location}
          onChange={e => setFormData({ ...formData, location: e.target.value })}
          maxLength={200}
          placeholder="Ej: Barcelona, España"
          required
        />
      </div>
      
      <div>
        <label>Precio por Hora (€) *</label>
        <input
          type="number"
          value={formData.pricePerHour}
          onChange={e => setFormData({ ...formData, pricePerHour: parseFloat(e.target.value) })}
          min="0.01"
          step="0.01"
          required
        />
      </div>
      
      <div>
        <label>Capacidad (personas) *</label>
        <input
          type="number"
          value={formData.capacity}
          onChange={e => setFormData({ ...formData, capacity: parseInt(e.target.value) })}
          min="1"
          required
        />
      </div>
      
      <div>
        <label>Comodidades</label>
        {formData.amenities.map(amenity => (
          <span key={amenity} className="tag">
            {amenity}
            <button type="button" onClick={() => removeAmenity(amenity)}>×</button>
          </span>
        ))}
        <input
          type="text"
          placeholder="Agregar comodidad"
          onKeyDown={e => {
            if (e.key === 'Enter') {
              e.preventDefault();
              addAmenity(e.currentTarget.value);
              e.currentTarget.value = '';
            }
          }}
        />
      </div>
      
      <div>
        <label>Imágenes (máx. 5)</label>
        <input
          type="file"
          accept="image/*"
          multiple
          onChange={handleImageChange}
          max={5}
        />
        {images.length > 0 && (
          <p>{images.length} imagen(es) seleccionada(s)</p>
        )}
      </div>
      
      <button type="submit" disabled={loading}>
        {loading ? 'Creando...' : 'Publicar Espacio'}
      </button>
    </form>
  );
}
```

### Componente de Lista de Espacios

```typescript
// SpaceList.tsx
import { useEffect, useState } from 'react';
import { useAuth } from './AuthContext';
import { getAllSpaces, Space } from './services/spaceService';
import { Link } from 'react-router-dom';

function SpaceList() {
  const { token } = useAuth();
  const [spaces, setSpaces] = useState<Space[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  
  useEffect(() => {
    loadSpaces();
  }, []);
  
  async function loadSpaces() {
    try {
      const data = await getAllSpaces(token!);
      setSpaces(data);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }
  
  if (loading) return <div>Cargando espacios...</div>;
  if (error) return <div className="error">{error}</div>;
  
  return (
    <div className="space-grid">
      <h2>Espacios Disponibles</h2>
      
      {spaces.length === 0 ? (
        <p>No hay espacios disponibles</p>
      ) : (
        <div className="grid">
          {spaces.map(space => (
            <SpaceCard key={space.id} space={space} />
          ))}
        </div>
      )}
    </div>
  );
}

function SpaceCard({ space }: { space: Space }) {
  const primaryImage = space.images.find(img => img.isPrimary);
  
  return (
    <Link to={`/spaces/${space.id}`} className="space-card">
      <div className="image-container">
        {primaryImage ? (
          <img src={primaryImage.url} alt={space.name} />
        ) : (
          <div className="no-image">Sin imagen</div>
        )}
      </div>
      
      <div className="space-info">
        <h3>{space.name}</h3>
        <p className="location">{space.location}</p>
        <p className="description">{space.description.substring(0, 100)}...</p>
        
        <div className="space-meta">
          <span className="price">{space.pricePerHour}€/hora</span>
          <span className="capacity">👥 {space.capacity} personas</span>
        </div>
        
        {space.amenities.length > 0 && (
          <div className="amenities">
            {space.amenities.slice(0, 3).map(amenity => (
              <span key={amenity} className="tag">{amenity}</span>
            ))}
            {space.amenities.length > 3 && (
              <span className="tag">+{space.amenities.length - 3} más</span>
            )}
          </div>
        )}
      </div>
    </Link>
  );
}
```

---

## Casos de Uso

### 1. Usuario Crea su Primer Espacio (Promoción a HOST)

```typescript
async function createFirstSpace() {
  // 1. Usuario está autenticado como GUEST
  console.log(user.isHost); // false
  
  // 2. Crear espacio
  const space = await createSpace(token, {
    name: "Mi Terraza",
    description: "Hermosa terraza",
    location: "Madrid",
    pricePerHour: 30,
    capacity: 10,
    amenities: ["WiFi"]
  });
  
  // 3. Actualizar roles del usuario
  await refreshUser(); // Llama a GET /api/auth/me
  
  // 4. Usuario ahora es HOST
  console.log(user.isHost); // true
  console.log(user.isGuest); // true (sigue siendo guest también)
  
  // 5. Ahora puede acceder a secciones de HOST
  navigate('/my-spaces');
}
```

### 2. Usuario Edita su Espacio

```typescript
async function editMySpace(spaceId: string) {
  try {
    // Verificar ownership en frontend (opcional, el backend lo valida)
    const space = await getSpaceById(token, spaceId);
    if (space.ownerId !== user.id) {
      alert('No puedes editar este espacio');
      return;
    }
    
    // Actualizar espacio
    const updated = await updateSpace(token, spaceId, {
      pricePerHour: 40, // Nuevo precio
      capacity: 15      // Nueva capacidad
    });
    
    console.log('Espacio actualizado:', updated);
  } catch (err) {
    if (err.message.includes('not the owner')) {
      alert('No tienes permisos para editar este espacio');
    }
  }
}
```

### 3. Subir Múltiples Imágenes

```typescript
async function uploadMultipleImages(spaceId: string, files: File[]) {
  for (let i = 0; i < files.length; i++) {
    const isPrimary = i === 0; // Primera imagen es primaria
    
    try {
      await uploadSpaceImage(token, spaceId, files[i], isPrimary);
      console.log(`Imagen ${i + 1}/${files.length} subida`);
    } catch (err) {
      console.error(`Error subiendo imagen ${i + 1}:`, err);
    }
  }
  
  // Recargar espacio para ver imágenes actualizadas
  const updatedSpace = await getSpaceById(token, spaceId);
  console.log('Imágenes:', updatedSpace.images);
}
```

### 4. Cambiar Imagen Primaria

```typescript
async function changePrimaryImage(spaceId: string, imageId: string) {
  try {
    const updated = await setPrimaryImage(token, spaceId, imageId);
    console.log('Nueva imagen primaria:', updated);
    
    // Recargar espacio
    const space = await getSpaceById(token, spaceId);
    const primary = space.images.find(img => img.isPrimary);
    console.log('Imagen primaria actual:', primary.url);
  } catch (err) {
    console.error('Error cambiando imagen primaria:', err);
  }
}
```

---

## Resumen de Conceptos Clave

1. **Ownership automático**: El espacio se crea con `ownerId = userId` del token JWT
2. **Promoción a HOST**: Automática al crear el primer espacio
3. **Validación de permisos**: Backend valida ownership en PUT/DELETE
4. **Múltiples imágenes**: Un espacio puede tener varias imágenes
5. **Imagen primaria**: Se muestra como thumbnail en listados
6. **URLs completas**: Las imágenes incluyen URL completa para consumo directo
7. **Sincronización de roles**: Llamar a `/api/auth/me` después de crear espacio

---

## Siguiente Documento

Continuar con: **[FRONTEND_API_GUIDE_PART_3_BOOKINGS.md](./FRONTEND_API_GUIDE_PART_3_BOOKINGS.md)** - Gestión de Reservas

