package com.balconazo.catalog_microservice.service;

import com.balconazo.catalog_microservice.dto.AvailabilitySlotDTO;
import com.balconazo.catalog_microservice.dto.CreateAvailabilityDTO;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface AvailabilityService {
    AvailabilitySlotDTO addAvailability(CreateAvailabilityDTO dto);
    List<AvailabilitySlotDTO> getAvailabilityBySpace(UUID spaceId);
    List<AvailabilitySlotDTO> getFutureAvailabilityBySpace(UUID spaceId);
    List<AvailabilitySlotDTO> getAvailabilityBySpaceAndDateRange(UUID spaceId, LocalDateTime start, LocalDateTime end);
    void removeAvailability(UUID slotId);
}

