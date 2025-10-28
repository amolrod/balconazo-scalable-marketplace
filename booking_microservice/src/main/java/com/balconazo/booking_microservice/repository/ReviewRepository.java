package com.balconazo.booking_microservice.repository;

import com.balconazo.booking_microservice.entity.ReviewEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReviewRepository extends JpaRepository<ReviewEntity, UUID> {

    List<ReviewEntity> findBySpaceIdOrderByCreatedAtDesc(UUID spaceId);

    List<ReviewEntity> findByGuestIdOrderByCreatedAtDesc(UUID guestId);

    Optional<ReviewEntity> findByBookingId(UUID bookingId);

    boolean existsByBookingId(UUID bookingId);

    @Query("SELECT AVG(r.rating) FROM ReviewEntity r WHERE r.spaceId = :spaceId")
    Double findAverageRatingBySpaceId(@Param("spaceId") UUID spaceId);

    @Query("SELECT COUNT(r) FROM ReviewEntity r WHERE r.spaceId = :spaceId")
    Long countBySpaceId(@Param("spaceId") UUID spaceId);
}

