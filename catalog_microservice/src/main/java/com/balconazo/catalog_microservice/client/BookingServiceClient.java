package com.balconazo.catalog_microservice.client;

import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;

import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class BookingServiceClient {
    
    private final RestTemplate restTemplate;
    private static final String BOOKING_SERVICE_URL = "http://localhost:8082";
    
    /**
     * Obtener el rating promedio de un espacio desde el servicio de bookings
     */
    public SpaceRatingDTO getSpaceRating(UUID spaceId) {
        try {
            String url = BOOKING_SERVICE_URL + "/api/bookings/reviews/space/" + spaceId + "/rating";
            log.debug("🔍 Consultando rating del espacio {} desde: {}", spaceId, url);
            
            SpaceRatingDTO rating = restTemplate.getForObject(url, SpaceRatingDTO.class);
            log.debug("✅ Rating obtenido para espacio {}: {}", spaceId, rating);
            
            return rating;
        } catch (RestClientException e) {
            log.warn("⚠️ No se pudo obtener rating para espacio {}: {}", spaceId, e.getMessage());
            // Devolver valores por defecto si falla
            return new SpaceRatingDTO(0.0, 0);
        }
    }
    
    @Data
    public static class SpaceRatingDTO {
        private Double averageRating;
        private Integer reviewCount;
        
        public SpaceRatingDTO() {}
        
        public SpaceRatingDTO(Double averageRating, Integer reviewCount) {
            this.averageRating = averageRating;
            this.reviewCount = reviewCount;
        }
    }
}
