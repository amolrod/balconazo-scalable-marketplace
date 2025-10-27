package com.balconazo.catalog_microservice.dto;
import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateAvailabilityDTO {
    @NotNull(message = "El ID del espacio es obligatorio")
    private UUID spaceId;
    
    @NotNull(message = "La fecha de inicio es obligatoria")
    @Future(message = "La fecha de inicio debe ser futura")
    private LocalDateTime startTs;
    
    @NotNull(message = "La fecha de fin es obligatoria")
    @Future(message = "La fecha de fin debe ser futura")
    private LocalDateTime endTs;
    
    @NotNull
    @Min(1)
    private Integer maxGuests;
}
