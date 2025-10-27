package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.dto.CreateSpaceDTO;
import com.balconazo.catalog_microservice.dto.SpaceDTO;
import com.balconazo.catalog_microservice.entity.SpaceEntity;
import com.balconazo.catalog_microservice.exception.BusinessValidationException;
import com.balconazo.catalog_microservice.exception.ResourceNotFoundException;
import com.balconazo.catalog_microservice.mapper.SpaceMapper;
import com.balconazo.catalog_microservice.repository.SpaceRepository;
import com.balconazo.catalog_microservice.repository.UserRepository;
import com.balconazo.catalog_microservice.service.SpaceService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import static com.balconazo.catalog_microservice.constants.CatalogConstants.*;

@Service
@RequiredArgsConstructor
@Transactional
public class SpaceServiceImpl implements SpaceService {
    private final SpaceRepository repo;
    private final UserRepository userRepo;
    private final SpaceMapper mapper;

    public SpaceDTO createSpace(CreateSpaceDTO dto) {
        var owner = userRepo.findById(dto.getOwnerId())
            .orElseThrow(() -> new ResourceNotFoundException("Usuario", dto.getOwnerId()));
        if (!ROLE_HOST.equals(owner.getRole()))
            throw new BusinessValidationException("Solo hosts pueden crear espacios");
        var space = mapper.toEntity(dto, owner);
        space.setStatus(SPACE_STATUS_DRAFT);
        return mapper.toDTO(repo.save(space));
    }

    @Transactional(readOnly = true)
    public SpaceDTO getSpaceById(UUID id) {
        return mapper.toDTO(repo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", id)));
    }

    @Transactional(readOnly = true)
    public List<SpaceDTO> getSpacesByOwner(UUID ownerId) {
        var owner = userRepo.findById(ownerId)
            .orElseThrow(() -> new ResourceNotFoundException("Usuario", ownerId));
        return repo.findByOwner(owner).stream().map(mapper::toDTO).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SpaceDTO> getActiveSpaces() {
        return repo.findByStatus(SPACE_STATUS_ACTIVE).stream()
            .map(mapper::toDTO).collect(Collectors.toList());
    }

    public SpaceDTO updateSpace(UUID id, CreateSpaceDTO dto) {
        var space = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Espacio", id));
        space.setTitle(dto.getTitle());
        space.setDescription(dto.getDescription());
        space.setCapacity(dto.getCapacity());
        space.setAreaSqm(dto.getAreaSqm());
        space.setAddress(dto.getAddress());
        space.setLat(dto.getLat());
        space.setLon(dto.getLon());
        space.setBasePriceCents(dto.getBasePriceCents());
        return mapper.toDTO(repo.save(space));
    }

    public SpaceDTO activateSpace(UUID id) {
        var space = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Espacio", id));
        space.setStatus(SPACE_STATUS_ACTIVE);
        return mapper.toDTO(repo.save(space));
    }

    public SpaceDTO snoozeSpace(UUID id) {
        var space = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Espacio", id));
        space.setStatus(SPACE_STATUS_SNOOZED);
        return mapper.toDTO(repo.save(space));
    }

    public void deleteSpace(UUID id) {
        var space = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Espacio", id));
        space.setStatus(SPACE_STATUS_DELETED);
        repo.save(space);
    }
}

