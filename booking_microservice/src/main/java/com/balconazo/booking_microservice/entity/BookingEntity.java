package com.balconazo.booking_microservice.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "bookings", schema = "booking")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookingEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "space_id", nullable = false)
    private UUID spaceId;

    @Column(name = "guest_id", nullable = false)
    private UUID guestId;

    @Column(name = "start_ts", nullable = false)
    private LocalDateTime startTs;

    @Column(name = "end_ts", nullable = false)
    private LocalDateTime endTs;

    @Column(name = "num_guests", nullable = false)
    private Integer numGuests;

    @Column(name = "total_price_cents", nullable = false)
    private Integer totalPriceCents;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private BookingStatus status;

    @Column(name = "payment_intent_id", length = 255)
    private String paymentIntentId;

    @Column(name = "payment_status", length = 50)
    @Enumerated(EnumType.STRING)
    private PaymentStatus paymentStatus;

    @Column(name = "cancellation_reason", columnDefinition = "TEXT")
    private String cancellationReason;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public enum BookingStatus {
        pending,      // Pendiente de confirmación
        confirmed,    // Confirmada y pagada
        cancelled,    // Cancelada
        completed     // Completada (pasó la fecha)
    }

    public enum PaymentStatus {
        pending,      // Pago pendiente
        processing,   // Procesando pago
        succeeded,    // Pago exitoso
        failed,       // Pago fallido
        refunded      // Reembolsado
    }
}

