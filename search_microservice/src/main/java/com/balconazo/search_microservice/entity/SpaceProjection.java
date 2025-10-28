package com.balconazo.search_microservice.entity;

import io.hypersistence.utils.hibernate.type.json.JsonBinaryType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Type;
import org.locationtech.jts.geom.Point;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "spaces_projection", schema = "search")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SpaceProjection {

    @Id
    private UUID id;

    // Datos del espacio (desde Catalog)
    @Column(name = "owner_id", nullable = false)
    private UUID ownerId;

    @Column(name = "owner_email")
    private String ownerEmail;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String address;

    // Ubicación geoespacial (PostGIS)
    @Column(name = "location", columnDefinition = "geography(Point,4326)", nullable = false)
    private Point location;

    // Características
    @Column(nullable = false)
    private Integer capacity;

    @Column(name = "area_sqm", precision = 6, scale = 2)
    private BigDecimal areaSqm;

    @Column(nullable = false, length = 50)
    private String status;

    // JSONB para reglas
    @Type(JsonBinaryType.class)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> rules;

    // Array de amenidades
    @Column(columnDefinition = "text[]")
    private String[] amenities;

    // Pricing
    @Column(name = "base_price_cents", nullable = false)
    private Integer basePriceCents;

    @Column(name = "current_price_cents", nullable = false)
    private Integer currentPriceCents;

    // Datos agregados desde Booking
    @Column(name = "average_rating")
    private Double averageRating;

    @Column(name = "total_reviews")
    private Integer totalReviews;

    @Column(name = "total_bookings")
    private Integer totalBookings;

    @Column(name = "completed_bookings")
    private Integer completedBookings;

    @Column(name = "last_booking_at")
    private LocalDateTime lastBookingAt;

    // Metadatos
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();

        // Valores por defecto
        if (averageRating == null) averageRating = 0.0;
        if (totalReviews == null) totalReviews = 0;
        if (totalBookings == null) totalBookings = 0;
        if (completedBookings == null) completedBookings = 0;
        if (currentPriceCents == null) currentPriceCents = basePriceCents;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

