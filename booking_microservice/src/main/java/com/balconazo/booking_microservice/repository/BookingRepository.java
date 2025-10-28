package com.balconazo.booking_microservice.repository;

import com.balconazo.booking_microservice.entity.BookingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BookingRepository extends JpaRepository<BookingEntity, UUID> {

    List<BookingEntity> findByGuestIdOrderByCreatedAtDesc(UUID guestId);

    List<BookingEntity> findBySpaceIdAndStatusOrderByStartTsAsc(UUID spaceId, BookingEntity.BookingStatus status);

    @Query("SELECT b FROM BookingEntity b WHERE b.spaceId = :spaceId " +
           "AND b.status IN ('pending', 'confirmed') " +
           "AND ((b.startTs <= :endTs AND b.endTs >= :startTs))")
    List<BookingEntity> findOverlappingBookings(
        @Param("spaceId") UUID spaceId,
        @Param("startTs") LocalDateTime startTs,
        @Param("endTs") LocalDateTime endTs
    );

    Optional<BookingEntity> findByPaymentIntentId(String paymentIntentId);

    @Query("SELECT b FROM BookingEntity b WHERE b.status = 'confirmed' " +
           "AND b.endTs < :now ORDER BY b.endTs ASC")
    List<BookingEntity> findCompletedBookings(@Param("now") LocalDateTime now);
}

