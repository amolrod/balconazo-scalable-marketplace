package com.balconazo.booking_microservice.service.impl;

import com.balconazo.booking_microservice.constants.BookingConstants;
import com.balconazo.booking_microservice.dto.CreateReviewDTO;
import com.balconazo.booking_microservice.dto.ReviewDTO;
import com.balconazo.booking_microservice.entity.BookingEntity;
import com.balconazo.booking_microservice.entity.ReviewEntity;
import com.balconazo.booking_microservice.kafka.event.ReviewCreatedEvent;
import com.balconazo.booking_microservice.kafka.producer.OutboxService;
import com.balconazo.booking_microservice.mapper.ReviewMapper;
import com.balconazo.booking_microservice.repository.BookingRepository;
import com.balconazo.booking_microservice.repository.ReviewRepository;
import com.balconazo.booking_microservice.service.ReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReviewServiceImpl implements ReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final ReviewMapper reviewMapper;
    private final OutboxService outboxService;

    @Override
    @Transactional
    public ReviewDTO createReview(CreateReviewDTO createReviewDTO) {
        log.info("🔵 Creando review para booking: {}", createReviewDTO.getBookingId());

        // Validar que la reserva existe y está completada
        BookingEntity booking = bookingRepository.findById(createReviewDTO.getBookingId())
                .orElseThrow(() -> new RuntimeException("Reserva no encontrada: " + createReviewDTO.getBookingId()));

        if (booking.getStatus() != BookingEntity.BookingStatus.completed) {
            throw new RuntimeException("Solo se pueden reseñar reservas completadas");
        }

        // Validar que no exista ya una review para esta reserva
        if (reviewRepository.existsByBookingId(createReviewDTO.getBookingId())) {
            throw new RuntimeException("Ya existe una reseña para esta reserva");
        }

        // Crear entidad
        ReviewEntity review = reviewMapper.toEntity(createReviewDTO);
        review.setSpaceId(booking.getSpaceId());
        review.setGuestId(booking.getGuestId());

        // Guardar
        ReviewEntity savedReview = reviewRepository.save(review);
        log.info("✅ Review creada con ID: {}", savedReview.getId());

        // Publicar evento vía Outbox
        publishReviewCreatedEvent(savedReview);

        return reviewMapper.toDTO(savedReview);
    }

    @Override
    @Transactional(readOnly = true)
    public ReviewDTO getReviewById(UUID reviewId) {
        log.info("🔍 Buscando review: {}", reviewId);

        ReviewEntity review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new RuntimeException("Review no encontrada: " + reviewId));

        return reviewMapper.toDTO(review);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReviewDTO> getReviewsBySpace(UUID spaceId) {
        log.info("🔍 Buscando reviews del espacio: {}", spaceId);

        List<ReviewEntity> reviews = reviewRepository.findBySpaceIdOrderByCreatedAtDesc(spaceId);

        return reviews.stream()
                .map(reviewMapper::toDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<ReviewDTO> getReviewsByGuest(UUID guestId) {
        log.info("🔍 Buscando reviews del huésped: {}", guestId);

        List<ReviewEntity> reviews = reviewRepository.findByGuestIdOrderByCreatedAtDesc(guestId);

        return reviews.stream()
                .map(reviewMapper::toDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public Double getAverageRatingBySpace(UUID spaceId) {
        log.info("🔍 Calculando rating promedio del espacio: {}", spaceId);

        Double avgRating = reviewRepository.findAverageRatingBySpaceId(spaceId);
        return avgRating != null ? avgRating : 0.0;
    }

    // ============================================
    // EVENTOS
    // ============================================

    private void publishReviewCreatedEvent(ReviewEntity review) {
        ReviewCreatedEvent event = ReviewCreatedEvent.builder()
                .reviewId(review.getId())
                .bookingId(review.getBookingId())
                .spaceId(review.getSpaceId())
                .guestId(review.getGuestId())
                .rating(review.getRating())
                .comment(review.getComment())
                .occurredAt(LocalDateTime.now())
                .build();

        outboxService.saveEvent("review", review.getId(), BookingConstants.EVENT_REVIEW_CREATED, event);
    }
}

