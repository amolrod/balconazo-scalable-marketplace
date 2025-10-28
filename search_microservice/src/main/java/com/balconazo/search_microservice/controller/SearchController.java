package com.balconazo.search_microservice.controller;

import com.balconazo.search_microservice.dto.SearchRequestDTO;
import com.balconazo.search_microservice.dto.SearchResultDTO;
import com.balconazo.search_microservice.dto.SpaceSearchResultDTO;
import com.balconazo.search_microservice.service.SearchService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/search")
@RequiredArgsConstructor
@Slf4j
public class SearchController {

    private final SearchService searchService;

    /**
     * Buscar espacios por ubicación y filtros
     *
     * GET /api/search/spaces?lat=40.4168&lon=-3.7038&radius=10&minPrice=5000&maxPrice=15000&capacity=4&sortBy=distance&page=0&size=20
     */
    @GetMapping("/spaces")
    public ResponseEntity<SearchResultDTO> searchSpaces(
            @RequestParam Double lat,
            @RequestParam Double lon,
            @RequestParam(defaultValue = "10") Integer radiusKm,
            @RequestParam(required = false) Integer minCapacity,
            @RequestParam(required = false) Integer minPriceCents,
            @RequestParam(required = false) Integer maxPriceCents,
            @RequestParam(required = false) Double minRating,
            @RequestParam(required = false) String[] amenities,
            @RequestParam(defaultValue = "distance") String sortBy,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize
    ) {
        log.info("GET /api/search/spaces - lat={}, lon={}, radius={}km", lat, lon, radiusKm);

        SearchRequestDTO request = SearchRequestDTO.builder()
            .lat(lat)
            .lon(lon)
            .radiusKm(radiusKm)
            .minCapacity(minCapacity)
            .minPriceCents(minPriceCents)
            .maxPriceCents(maxPriceCents)
            .minRating(minRating)
            .amenities(amenities)
            .sortBy(sortBy)
            .page(page)
            .pageSize(pageSize)
            .build();

        SearchResultDTO result = searchService.searchSpaces(request);
        return ResponseEntity.ok(result);
    }

    /**
     * Obtener detalle de un espacio
     *
     * GET /api/search/spaces/{id}
     */
    @GetMapping("/spaces/{id}")
    public ResponseEntity<SpaceSearchResultDTO> getSpaceById(@PathVariable UUID id) {
        log.info("GET /api/search/spaces/{}", id);

        SpaceSearchResultDTO result = searchService.getSpaceById(id);
        return ResponseEntity.ok(result);
    }
}

