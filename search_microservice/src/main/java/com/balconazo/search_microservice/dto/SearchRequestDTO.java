package com.balconazo.search_microservice.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchRequestDTO {

    @NotNull(message = "La latitud es obligatoria")
    @DecimalMin(value = "-90.0", message = "Latitud inválida")
    @DecimalMax(value = "90.0", message = "Latitud inválida")
    private Double lat;

    @NotNull(message = "La longitud es obligatoria")
    @DecimalMin(value = "-180.0", message = "Longitud inválida")
    @DecimalMax(value = "180.0", message = "Longitud inválida")
    private Double lon;

    @Min(value = 1, message = "El radio debe ser al menos 1 km")
    @Builder.Default
    private Integer radiusKm = 10;

    private Integer minCapacity;

    private Integer minPriceCents;

    private Integer maxPriceCents;

    @DecimalMin(value = "0.0", message = "Rating mínimo inválido")
    @DecimalMax(value = "5.0", message = "Rating mínimo inválido")
    private Double minRating;

    private String[] amenities;

    @Builder.Default
    private String sortBy = "distance"; // distance, price, price_desc, rating, capacity

    @Min(value = 0, message = "La página debe ser >= 0")
    @Builder.Default
    private Integer page = 0;

    @Min(value = 1, message = "El tamaño de página debe ser >= 1")
    @Builder.Default
    private Integer pageSize = 20;
}

