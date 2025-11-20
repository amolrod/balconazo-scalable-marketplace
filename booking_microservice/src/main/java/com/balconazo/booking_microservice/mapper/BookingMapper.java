package com.balconazo.booking_microservice.mapper;

import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;
import com.balconazo.booking_microservice.entity.BookingEntity;

/**
 * Interface del mapper de Booking
 * Implementación manual en BookingMapperImpl
 */
public interface BookingMapper {

    BookingEntity toEntity(CreateBookingDTO dto);

    /**
     * Mapea BookingEntity a BookingDTO.
     */
    BookingDTO toDTO(BookingEntity entity);
}

