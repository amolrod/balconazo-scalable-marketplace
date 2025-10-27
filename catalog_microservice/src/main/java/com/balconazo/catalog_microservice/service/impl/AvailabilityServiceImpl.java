package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.dto.*;
import com.balconazo.catalog_microservice.entity.*;
import com.balconazo.catalog_microservice.exception.*;
import com.balconazo.catalog_microservice.mapper.AvailabilityMapper;
import com.balconazo.catalog_microservice.repository.*;
import com.balconazo.catalog_microservice.service.AvailabilityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class AvailabilityServiceImpl implements AvailabilityService {
    private final AvailabilitySlotRepository repo;
    private final SpaceRepository spaceRepo;
    private final AvailabilityMapper mapper;

    public AvailabilitySlotDTO addAvailability(CreateAvailabilityDTO dto) {
        var space = spaceRepo.findById(dto.getSpaceId())
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", dto.getSpaceId()));
        if (!dto.getEndTs().isAfter(dto.getStartTs()))
            throw new BusinessValidationException("Fecha fin debe ser posterior a inicio");
        var slot = mapper.toEntity(dto, space);
        return mapper.toDTO(repo.save(slot));
    }

    @Transactional(readOnly = true)
    public List<AvailabilitySlotDTO> getAvailabilityBySpace(UUID spaceId) {
        var space = spaceRepo.findById(spaceId)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", spaceId));
        return repo.findBySpace(space).stream().map(mapper::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AvailabilitySlotDTO> getFutureAvailabilityBySpace(UUID spaceId) {
        var space = spaceRepo.findById(spaceId)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", spaceId));
        return repo.findFutureSlotsBySpace(space, LocalDateTime.now()).stream()
            .map(mapper::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AvailabilitySlotDTO> getAvailabilityBySpaceAndDateRange(UUID spaceId, LocalDateTime start, LocalDateTime end) {
        var space = spaceRepo.findById(spaceId)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", spaceId));
        return repo.findBySpaceAndTimeRange(space, start, end).stream()
            .map(mapper::toDTO).collect(Collectors.toList());
    }

    public void removeAvailability(UUID slotId) {
        var slot = repo.findById(slotId)
            .orElseThrow(() -> new ResourceNotFoundException("Availability", slotId));
        repo.delete(slot);
    }
}

