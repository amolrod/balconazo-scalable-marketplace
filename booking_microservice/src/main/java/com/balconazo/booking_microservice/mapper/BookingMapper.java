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
    @Mapping(target = "status", ignore = true) // Se establece manualmente en el servicio
    @Mapping(target = "paymentIntentId", ignore = true)
    @Mapping(target = "paymentStatus", ignore = true) // Se establece manualmente en el servicio
    @Mapping(target = "cancellationReason", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    BookingEntity toEntity(CreateBookingDTO dto);

    /**
     * Mapea BookingEntity a BookingDTO.
     * Los enums se convierten automáticamente a String usando .name()
     */
    @Mapping(target = "status", expression = "java(entity.getStatus() != null ? entity.getStatus().name() : null)")
    @Mapping(target = "paymentStatus", expression = "java(entity.getPaymentStatus() != null ? entity.getPaymentStatus().name() : null)")
    BookingDTO toDTO(BookingEntity entity);
}

