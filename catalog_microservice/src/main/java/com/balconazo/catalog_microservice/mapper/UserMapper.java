package com.balconazo.catalog_microservice.mapper;

import com.balconazo.catalog_microservice.dto.UserDTO;
import com.balconazo.catalog_microservice.entity.UserEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface UserMapper {
    UserDTO toDTO(UserEntity entity);

    @Mapping(target = "passwordHash", ignore = true)
    UserEntity toEntity(UserDTO dto);
}

