package com.balconazo.booking_microservice.dto;

import jakarta.validation.constraints.*;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateReviewDTO {

    @NotNull(message = "El ID de la reserva es obligatorio")
    private UUID bookingId;

    @NotNull(message = "La calificación es obligatoria")
    @Min(value = 1, message = "La calificación mínima es 1")
    @Max(value = 5, message = "La calificación máxima es 5")
    private Integer rating;

    @Size(max = 2000, message = "El comentario no puede superar 2000 caracteres")
    private String comment;
}

