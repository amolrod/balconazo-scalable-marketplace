package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;
import com.balconazo.booking_microservice.entity.BookingEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface BookingMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "totalPriceCents", ignore = true)
    @Mapping(target = "status", constant = "pending")
    @Mapping(target = "paymentIntentId", ignore = true)
    @Mapping(target = "paymentStatus", constant = "pending")
    @Mapping(target = "cancellationReason", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    BookingEntity toEntity(CreateBookingDTO dto);

    @Mapping(source = "status", target = "status")
    @Mapping(source = "paymentStatus", target = "paymentStatus")
    BookingDTO toDTO(BookingEntity entity);
}

