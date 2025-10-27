package com.balconazo.catalog_microservice.mapper;

import com.balconazo.catalog_microservice.dto.AvailabilitySlotDTO;
import com.balconazo.catalog_microservice.dto.CreateAvailabilityDTO;
import com.balconazo.catalog_microservice.entity.AvailabilitySlotEntity;
import com.balconazo.catalog_microservice.entity.SpaceEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingConstants;

@Mapper(componentModel = MappingConstants.ComponentModel.SPRING)
public interface AvailabilityMapper {
    @Mapping(source = "space.id", target = "spaceId")
    AvailabilitySlotDTO toDTO(AvailabilitySlotEntity entity);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "space", source = "space")
    @Mapping(target = "createdAt", ignore = true)
    AvailabilitySlotEntity toEntity(CreateAvailabilityDTO dto, SpaceEntity space);
}

