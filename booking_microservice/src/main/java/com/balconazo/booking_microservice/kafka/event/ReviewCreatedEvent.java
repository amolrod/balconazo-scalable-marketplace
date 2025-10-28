package com.balconazo.booking_microservice.kafka.event;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewCreatedEvent {
    private UUID reviewId;
    private UUID bookingId;
    private UUID spaceId;
    private UUID guestId;
    private Integer rating;
    private String comment;
    private LocalDateTime occurredAt;
}

