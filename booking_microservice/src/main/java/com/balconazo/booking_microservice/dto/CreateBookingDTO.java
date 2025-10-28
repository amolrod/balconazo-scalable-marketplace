package com.balconazo.booking_microservice.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateBookingDTO {

    @NotNull(message = "El ID del espacio es obligatorio")
    private UUID spaceId;

    @NotNull(message = "El ID del huésped es obligatorio")
    private UUID guestId;

    @NotNull(message = "La fecha de inicio es obligatoria")
    private LocalDateTime startTs;

    @NotNull(message = "La fecha de fin es obligatoria")
    private LocalDateTime endTs;

    @NotNull(message = "El número de huéspedes es obligatorio")
    @Min(value = 1, message = "Debe haber al menos 1 huésped")
    private Integer numGuests;
}

