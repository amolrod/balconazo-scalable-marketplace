package com.balconazo.catalog_microservice.controller;

import com.balconazo.catalog_microservice.dto.*;
import com.balconazo.catalog_microservice.service.AvailabilityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/catalog/availability")
@RequiredArgsConstructor
public class AvailabilityController {
    private final AvailabilityService service;

    @PostMapping
    public ResponseEntity<AvailabilitySlotDTO> add(@Valid @RequestBody CreateAvailabilityDTO dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addAvailability(dto));
    }

    @GetMapping("/space/{spaceId}")
    public List<AvailabilitySlotDTO> getBySpace(@PathVariable UUID spaceId) {
        return service.getAvailabilityBySpace(spaceId);
    }

    @GetMapping("/space/{spaceId}/future")
    public List<AvailabilitySlotDTO> getFuture(@PathVariable UUID spaceId) {
        return service.getFutureAvailabilityBySpace(spaceId);
    }

    @GetMapping("/space/{spaceId}/range")
    public List<AvailabilitySlotDTO> getByRange(
        @PathVariable UUID spaceId,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return service.getAvailabilityBySpaceAndDateRange(spaceId, start, end);
    }

    @DeleteMapping("/{slotId}")
    public ResponseEntity<Void> remove(@PathVariable UUID slotId) {
        service.removeAvailability(slotId);
        return ResponseEntity.noContent().build();
    }
}

