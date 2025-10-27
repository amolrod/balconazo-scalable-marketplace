# ✅ ERROR SOLUCIONADO - UserMapper

## 🐛 Problema Detectado

```
[ERROR] Unknown property "passwordHash" in result type UserDTO.UserDTOBuilder
```

## 🔧 Causa

MapStruct intentaba ignorar el campo `passwordHash` en el método `toDTO()`, pero este campo **no existe en UserDTO** (correctamente, porque las contraseñas no deben exponerse en los DTOs).

El campo `passwordHash` solo existe en `UserEntity`, no en `UserDTO`.

## ✅ Solución Aplicada

**Archivo modificado:** `UserMapper.java`

**Cambio realizado:**

1. **Añadido import faltante:**
```java
import org.mapstruct.Mapping;
```

2. **Eliminado @Mapping del método toDTO:**
```java
// ANTES (incorrecto)
@Mapping(target = "passwordHash", ignore = true)
UserDTO toDTO(UserEntity entity);

// DESPUÉS (correcto)
UserDTO toDTO(UserEntity entity);  // Sin @Mapping
```

3. **Mantenido @Mapping solo en toEntity:**
```java
@Mapping(target = "passwordHash", ignore = true)
UserEntity toEntity(UserDTO dto);  // Solo aquí es necesario
```

## ✅ Resultado

**Compilación:** ✅ BUILD SUCCESS  
**Errores:** 0  
**Warnings:** Solo "método no usado" (normal para uso futuro)

---

## 📝 Código Final Correcto

```java
package com.balconazo.catalog_microservice.mapper;

import com.balconazo.catalog_microservice.dto.UserDTO;
import com.balconazo.catalog_microservice.entity.UserEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface UserMapper {
    // No necesita @Mapping porque UserDTO no tiene passwordHash
    UserDTO toDTO(UserEntity entity);
    
    // Sí necesita @Mapping para ignorar passwordHash al crear Entity
    @Mapping(target = "passwordHash", ignore = true)
    UserEntity toEntity(UserDTO dto);
}
```

## 💡 Explicación

- **UserEntity** tiene `passwordHash` (en base de datos)
- **UserDTO** NO tiene `passwordHash` (por seguridad)
- Al mapear `Entity → DTO`: No hay problema, simplemente no se incluye
- Al mapear `DTO → Entity`: Debemos ignorar `passwordHash` porque no viene en el DTO

---

## 🚀 Próximo Paso

```bash
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run
```

**El proyecto ahora compila correctamente** ✅

