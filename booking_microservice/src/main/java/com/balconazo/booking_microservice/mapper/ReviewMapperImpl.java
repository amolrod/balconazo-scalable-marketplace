package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.entity.ReviewEntity;
import org.springframework.stereotype.Component;

/**
 * Implementación manual del mapper de Review
 * (evita problemas de MapStruct con Lombok)
 */
@Component
public class ReviewMapperImpl implements ReviewMapper {

    @Override
    public ReviewEntity toEntity(CreateReviewDTO dto) {
        if (dto == null) {
            return null;
        }

        return ReviewEntity.builder()
            .rating(dto.getRating())
            .comment(dto.getComment())
            .build();
    }

    @Override
    public ReviewDTO toDTO(ReviewEntity entity) {
        if (entity == null) {
            return null;
        }

        return ReviewDTO.builder()
            .id(entity.getId())
            .spaceId(entity.getSpaceId())
            .guestId(entity.getGuestId())
            .rating(entity.getRating())
            .comment(entity.getComment())
            .createdAt(entity.getCreatedAt())
            .build();
    }
}
