package com.balconazo.booking_microservice.controller;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.service.ReviewService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/booking/reviews")
@RequiredArgsConstructor
@Slf4j
public class ReviewController {

    private final ReviewService reviewService;

    @PostMapping
    public ResponseEntity<ReviewDTO> createReview(@Valid @RequestBody CreateReviewDTO createReviewDTO) {
        log.info("📥 POST /api/booking/reviews - Crear review");
        ReviewDTO review = reviewService.createReview(createReviewDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(review);
    }

    @GetMapping("/{reviewId}")
    public ResponseEntity<ReviewDTO> getReviewById(@PathVariable UUID reviewId) {
        log.info("📥 GET /api/booking/reviews/{}", reviewId);
        ReviewDTO review = reviewService.getReviewById(reviewId);
        return ResponseEntity.ok(review);
    }

    @GetMapping("/space/{spaceId}")
    public ResponseEntity<List<ReviewDTO>> getReviewsBySpace(@PathVariable UUID spaceId) {
        log.info("📥 GET /api/booking/reviews/space/{}", spaceId);
        List<ReviewDTO> reviews = reviewService.getReviewsBySpace(spaceId);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/space/{spaceId}/rating")
    public ResponseEntity<Double> getAverageRating(@PathVariable UUID spaceId) {
        log.info("📥 GET /api/booking/reviews/space/{}/rating", spaceId);
        Double avgRating = reviewService.getAverageRatingBySpace(spaceId);
        return ResponseEntity.ok(avgRating);
    }

    @GetMapping
    public ResponseEntity<List<ReviewDTO>> getReviewsByGuest(@RequestParam UUID guestId) {
        log.info("📥 GET /api/booking/reviews?guestId={}", guestId);
        List<ReviewDTO> reviews = reviewService.getReviewsByGuest(guestId);
        return ResponseEntity.ok(reviews);
    }

    @GetMapping("/reviewer/{reviewerId}")
    public ResponseEntity<List<ReviewDTO>> getReviewsByReviewer(@PathVariable UUID reviewerId) {
        log.info("📥 GET /api/booking/reviews/reviewer/{}", reviewerId);
        List<ReviewDTO> reviews = reviewService.getReviewsByGuest(reviewerId);
        return ResponseEntity.ok(reviews);
    }
}

