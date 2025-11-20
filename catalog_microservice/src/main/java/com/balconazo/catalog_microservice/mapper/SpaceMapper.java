package com.balconazo.catalog_microservice.mapper;

import com.balconazo.catalog_microservice.dto.CreateSpaceDTO;
import com.balconazo.catalog_microservice.dto.SpaceDTO;
import com.balconazo.catalog_microservice.entity.SpaceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface SpaceMapper {
    @Mapping(target = "ownerEmail", ignore = true) // No tenemos email del owner en Catalog
    @Mapping(target = "images", ignore = true)
    SpaceDTO toDTO(SpaceEntity entity);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    SpaceEntity toEntity(CreateSpaceDTO dto);
}

