package com.balconazo.catalog_microservice.dto;
import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateSpaceDTO {
    @NotNull(message = "El ID del propietario es obligatorio")
    private UUID ownerId;
    
    @NotBlank(message = "El título es obligatorio")
    @Size(max = 200)
    private String title;
    
    @Size(max = 2000)
    private String description;
    
    @NotNull
    @Min(1)
    @Max(1000)
    private Integer capacity;
    
    @DecimalMin("0.0")
    private BigDecimal areaSqm;
    
    private Map<String, Object> rules;
    private List<String> amenities;
    
    @NotBlank
    @Size(max = 500)
    private String address;
    
    @NotNull
    @DecimalMin("-90.0")
    @DecimalMax("90.0")
    private Double lat;
    
    @NotNull
    @DecimalMin("-180.0")
    @DecimalMax("180.0")
    private Double lon;
    
    @NotNull
    @Min(0)
    private Integer basePriceCents;
}
