package com.balconazo.search_microservice.service;

import com.balconazo.search_microservice.dto.SearchRequestDTO;
import com.balconazo.search_microservice.dto.SearchResultDTO;
import com.balconazo.search_microservice.dto.SpaceSearchResultDTO;
import com.balconazo.search_microservice.entity.SpaceProjection;
import com.balconazo.search_microservice.repository.SpaceProjectionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

@Service
@Slf4j
@RequiredArgsConstructor
public class SearchService {

    private final SpaceProjectionRepository repository;

    @Transactional(readOnly = true)
    public SearchResultDTO searchSpaces(SearchRequestDTO request) {
        log.info("Searching spaces: lat={}, lon={}, radius={}km",
            request.getLat(), request.getLon(), request.getRadiusKm());

        int radiusMeters = request.getRadiusKm() * 1000;
        int limit = request.getPageSize();
        int offset = request.getPage() * request.getPageSize();

        // Realizar búsqueda geoespacial
        List<Object[]> rawResults = repository.searchByLocation(
            request.getLat(),
            request.getLon(),
            radiusMeters,
            request.getMinCapacity(),
            request.getMinPriceCents(),
            request.getMaxPriceCents(),
            request.getMinRating(),
            request.getSortBy() != null ? request.getSortBy() : "distance",
            limit,
            offset
        );

        // Por ahora, retornamos resultado vacío hasta implementar el mapeo correcto
        // TODO: Implementar mapeo de Object[] a SpaceSearchResultDTO
        List<SpaceSearchResultDTO> spaces = List.of();

        // Contar total de resultados
        long totalResults = repository.countSearchResults(
            request.getLat(),
            request.getLon(),
            radiusMeters,
            request.getMinCapacity(),
            request.getMinPriceCents(),
            request.getMaxPriceCents(),
            request.getMinRating()
        );

        int totalPages = (int) Math.ceil((double) totalResults / request.getPageSize());

        log.info("Found {} results (page {} of {})", totalResults, request.getPage() + 1, totalPages);

        return SearchResultDTO.builder()
            .spaces(spaces)
            .totalResults(totalResults)
            .page(request.getPage())
            .pageSize(request.getPageSize())
            .totalPages(totalPages)
            .searchLat(request.getLat())
            .searchLon(request.getLon())
            .searchRadiusKm(request.getRadiusKm())
            .build();
    }

    @Transactional(readOnly = true)
    public SpaceSearchResultDTO getSpaceById(UUID spaceId) {
        log.info("Getting space details: spaceId={}", spaceId);

        SpaceProjection projection = repository.findById(spaceId)
            .orElseThrow(() -> new RuntimeException("Space not found: " + spaceId));

        return mapProjectionToDTO(projection);
    }

    private SpaceSearchResultDTO mapProjectionToDTO(SpaceProjection projection) {
        var geo = projection.getGeo();

        return SpaceSearchResultDTO.builder()
            .id(projection.getSpaceId())
            .ownerId(projection.getOwnerId())
            .ownerEmail(projection.getOwnerEmail())
            .title(projection.getTitle())
            .description(projection.getDescription())
            .address(projection.getAddress())
            .lat(geo != null ? geo.getY() : null)
            .lon(geo != null ? geo.getX() : null)
            .distanceKm(null) // No aplica cuando se consulta por ID
            .capacity(projection.getCapacity())
            .areaSqm(projection.getAreaSqm())
            .rules(projection.getRules())
            .amenities(projection.getAmenities())
            .basePriceCents(projection.getBasePriceCents())
            .currentPriceCents(projection.getBasePriceCents()) // Usar base price como current
            .basePriceEur(centsToEur(projection.getBasePriceCents()))
            .currentPriceEur(centsToEur(projection.getBasePriceCents()))
            .averageRating(projection.getAvgRating())
            .totalReviews(projection.getReviewCount())
            .totalBookings(projection.getCompletedBookings())
            .status(projection.getStatus())
            .createdAt(projection.getCreatedAt())
            .updatedAt(projection.getUpdatedAt())
            .build();
    }

    private BigDecimal centsToEur(Integer cents) {
        if (cents == null) return null;
        return BigDecimal.valueOf(cents)
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }
}

