package com.balconazo.booking_microservice.service;

import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;

import java.util.List;
import java.util.UUID;

public interface ReviewService {

    ReviewDTO createReview(CreateReviewDTO createReviewDTO);

    ReviewDTO getReviewById(UUID reviewId);

    List<ReviewDTO> getReviewsBySpace(UUID spaceId);

    List<ReviewDTO> getReviewsByGuest(UUID guestId);

    Double getAverageRatingBySpace(UUID spaceId);
}

