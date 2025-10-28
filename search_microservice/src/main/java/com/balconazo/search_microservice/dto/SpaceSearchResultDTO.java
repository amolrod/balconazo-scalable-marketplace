package com.balconazo.search_microservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpaceSearchResultDTO {

    private UUID id;
    private UUID ownerId;
    private String ownerEmail;
    private String title;
    private String description;
    private String address;

    // Ubicación
    private Double lat;
    private Double lon;
    private Double distanceKm; // Distancia desde el punto de búsqueda

    // Características
    private Integer capacity;
    private BigDecimal areaSqm;
    private Map<String, Object> rules;
    private String[] amenities;

    // Pricing
    private Integer basePriceCents;
    private Integer currentPriceCents;
    private BigDecimal basePriceEur;
    private BigDecimal currentPriceEur;

    // Estadísticas
    private Double averageRating;
    private Integer totalReviews;
    private Integer totalBookings;

    // Metadatos
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

