package com.balconazo.catalog_microservice.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Evento de dominio publicado cuando se crea un espacio
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpaceCreatedEvent {
    @Builder.Default
    private String eventType = "SpaceCreatedEvent"; // ← Para que Search lo identifique
    private UUID spaceId;
    private UUID ownerId;
    private String title;
    private String description;
    private String address;
    private Double lat;
    private Double lon;
    private Integer capacity;
    private BigDecimal areaSqm;
    private Long basePriceCents;
    private List<String> amenities;
    private String status;
    private LocalDateTime createdAt;
}

