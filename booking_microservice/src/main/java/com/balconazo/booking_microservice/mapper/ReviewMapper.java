package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.entity.ReviewEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface ReviewMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "spaceId", ignore = true)
    @Mapping(target = "guestId", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    ReviewEntity toEntity(CreateReviewDTO dto);

    ReviewDTO toDTO(ReviewEntity entity);
}

