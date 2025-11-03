package com.balconazo.catalog_microservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpaceImageDTO {
    private UUID id;
    private String url;
    private Integer displayOrder;
    private Boolean isPrimary;
    private String altText;
    private LocalDateTime createdAt;
}

