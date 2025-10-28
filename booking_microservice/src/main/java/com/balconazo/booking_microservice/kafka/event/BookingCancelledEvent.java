package com.balconazo.booking_microservice.kafka.event;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookingCancelledEvent {
    private UUID bookingId;
    private UUID spaceId;
    private UUID guestId;
    private String reason;
    private LocalDateTime occurredAt;
}

