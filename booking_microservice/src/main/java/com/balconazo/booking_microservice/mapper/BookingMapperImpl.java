package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;
import com.balconazo.booking_microservice.entity.BookingEntity;
import org.springframework.stereotype.Component;

/**
 * Implementación manual del mapper de Booking
 * (evita problemas de MapStruct con Lombok)
 */
@Component
public class BookingMapperImpl implements BookingMapper {

    @Override
    public BookingEntity toEntity(CreateBookingDTO dto) {
        if (dto == null) {
            return null;
        }

        return BookingEntity.builder()
            .spaceId(dto.getSpaceId())
            .guestId(dto.getGuestId())
            .startTs(dto.getStartTs())
            .endTs(dto.getEndTs())
            .numGuests(dto.getNumGuests())
            .build();
    }

    @Override
    public BookingDTO toDTO(BookingEntity entity) {
        if (entity == null) {
            return null;
        }

        return BookingDTO.builder()
            .id(entity.getId())
            .spaceId(entity.getSpaceId())
            .guestId(entity.getGuestId())
            .startTs(entity.getStartTs())
            .endTs(entity.getEndTs())
            .numGuests(entity.getNumGuests())
            .totalPriceCents(entity.getTotalPriceCents())
            .status(entity.getStatus() != null ? entity.getStatus().name() : null)
            .paymentIntentId(entity.getPaymentIntentId())
            .paymentStatus(entity.getPaymentStatus() != null ? entity.getPaymentStatus().name() : null)
            .cancellationReason(entity.getCancellationReason())
            .createdAt(entity.getCreatedAt())
            .updatedAt(entity.getUpdatedAt())
            .build();
    }
}
