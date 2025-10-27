package com.balconazo.catalog_microservice.dto;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AvailabilitySlotDTO {
    private UUID id;
    private UUID spaceId;
    private LocalDateTime startTs;
    private LocalDateTime endTs;
    private Integer maxGuests;
    private LocalDateTime createdAt;
}
