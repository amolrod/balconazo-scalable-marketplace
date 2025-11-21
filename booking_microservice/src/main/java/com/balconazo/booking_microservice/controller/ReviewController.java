package com.balconazo.booking_microservice.controller;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/bookings/reviews")
@RequiredArgsConstructor
@Slf4j
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * Crear una nueva reseña
     * 🔒 Requiere autenticación: Solo el guest de la reserva puede crear la reseña
     */
    @PostMapping
    public ResponseEntity<ReviewDTO> createReview(
            @Valid @RequestBody CreateReviewDTO createReviewDTO,
            Authentication authentication) {
        
        log.info("📥 POST /api/bookings/reviews - Crear review");
        
        if (authentication == null || authentication.getName() == null) {
            log.warn("⚠️ Usuario no autenticado intentando crear review");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String userId = authentication.getName(); // El JWT tiene el userId en el subject
        log.info("✅ Usuario autenticado: {} creando review para booking: {}", userId, createReviewDTO.getBookingId());
        
        UUID authenticatedUserId = UUID.fromString(userId);
        ReviewDTO review = reviewService.createReview(createReviewDTO, authenticatedUserId);
        
        return ResponseEntity.status(HttpStatus.CREATED).body(review);
    }

    @GetMapping("/{reviewId}")
    public ResponseEntity<ReviewDTO> getReviewById(@PathVariable UUID reviewId) {
        log.info("📥 GET /api/bookings/reviews/{}", reviewId);
        ReviewDTO review = reviewService.getReviewById(reviewId);
        return ResponseEntity.ok(review);
    }

    @GetMapping("/space/{spaceId}")
    public ResponseEntity<List<ReviewDTO>> getReviewsBySpace(@PathVariable UUID spaceId) {
        log.info("📥 GET /api/bookings/reviews/space/{}", spaceId);
        List<ReviewDTO> reviews = reviewService.getReviewsBySpace(spaceId);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/space/{spaceId}/rating")
    public ResponseEntity<Double> getAverageRating(@PathVariable UUID spaceId) {
        log.info("📥 GET /api/bookings/reviews/space/{}/rating", spaceId);
        Double avgRating = reviewService.getAverageRatingBySpace(spaceId);
        return ResponseEntity.ok(avgRating);
    }

    /**
     * Obtener las reseñas escritas por el usuario autenticado
     * 🔒 Requiere autenticación
     */
    @GetMapping("/my")
    public ResponseEntity<List<ReviewDTO>> getMyReviews(Authentication authentication) {
        log.info("📥 GET /api/bookings/reviews/my");
        
        if (authentication == null || authentication.getName() == null) {
            log.warn("⚠️ Usuario no autenticado intentando acceder a /my");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String userId = authentication.getName();
        log.info("✅ Usuario autenticado: {} obteniendo sus reviews", userId);
        
        UUID guestId = UUID.fromString(userId);
        List<ReviewDTO> reviews = reviewService.getReviewsByGuest(guestId);
        
        return ResponseEntity.ok(reviews);
    }
}

