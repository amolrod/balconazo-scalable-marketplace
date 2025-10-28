package com.balconazo.booking_microservice.dto;

import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewDTO {

    private UUID id;
    private UUID bookingId;
    private UUID spaceId;
    private UUID guestId;
    private Integer rating;
    private String comment;
    private LocalDateTime createdAt;
}

