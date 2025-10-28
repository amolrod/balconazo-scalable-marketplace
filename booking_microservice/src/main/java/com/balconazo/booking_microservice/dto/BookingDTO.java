package com.balconazo.booking_microservice.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookingDTO {

    private UUID id;
    private UUID spaceId;
    private UUID guestId;
    private LocalDateTime startTs;
    private LocalDateTime endTs;
    private Integer numGuests;
    private Integer totalPriceCents;
    private String status;
    private String paymentIntentId;
    private String paymentStatus;
    private String cancellationReason;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}

