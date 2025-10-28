package com.balconazo.booking_microservice.kafka.event;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookingCreatedEvent {
    private UUID bookingId;
    private UUID spaceId;
    private UUID guestId;
    private LocalDateTime startTs;
    private LocalDateTime endTs;
    private Integer numGuests;
    private Integer totalPriceCents;
    private LocalDateTime occurredAt;
}

