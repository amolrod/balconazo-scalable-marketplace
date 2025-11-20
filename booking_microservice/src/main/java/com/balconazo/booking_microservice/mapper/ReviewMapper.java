package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.entity.ReviewEntity;

/**
 * Interface del mapper de Review
 * Implementación manual en ReviewMapperImpl
 */
public interface ReviewMapper {

    ReviewEntity toEntity(CreateReviewDTO dto);

    ReviewDTO toDTO(ReviewEntity entity);
}

