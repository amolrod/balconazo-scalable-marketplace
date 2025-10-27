package com.balconazo.catalog_microservice.dto;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpaceDTO {
    private UUID id;
    private UUID ownerId;
    private String ownerEmail;
    private String title;
    private String description;
    private Integer capacity;
    private BigDecimal areaSqm;
    private Map<String, Object> rules;
    private List<String> amenities;
    private String address;
    private Double lat;
    private Double lon;
    private Integer basePriceCents;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
