package com.balconazo.booking_microservice.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Outbox Pattern: Eventos pendientes de publicar a Kafka
 * Garantiza consistencia transaccional (DB + Kafka)
 */
@Entity
@Table(name = "outbox_events", schema = "booking")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OutboxEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "aggregate_id", nullable = false)
    private UUID aggregateId;

    @Column(name = "aggregate_type", nullable = false, length = 100)
    private String aggregateType; // "booking", "review"

    @Column(name = "event_type", nullable = false, length = 100)
    private String eventType; // "BookingCreated", "BookingConfirmed", etc.

    @Column(name = "payload", nullable = false, columnDefinition = "TEXT")
    private String payload; // JSON del evento

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private OutboxStatus status;

    @Column(name = "retry_count", nullable = false)
    @Builder.Default
    private Integer retryCount = 0;

    @Column(name = "last_error", columnDefinition = "TEXT")
    private String lastError;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    public enum OutboxStatus {
        pending,    // Pendiente de enviar
        sent,       // Enviado correctamente
        failed      // Falló después de reintentos
    }
}

