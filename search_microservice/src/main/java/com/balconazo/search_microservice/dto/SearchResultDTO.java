package com.balconazo.search_microservice.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchResultDTO {

    private List<SpaceSearchResultDTO> spaces;
    private long totalResults;
    private int page;
    private int pageSize;
    private int totalPages;

    // Metadatos de búsqueda
    private Double searchLat;
    private Double searchLon;
    private Integer searchRadiusKm;
}

