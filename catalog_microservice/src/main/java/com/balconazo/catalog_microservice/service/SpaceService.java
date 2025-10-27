package com.balconazo.catalog_microservice.service;

import com.balconazo.catalog_microservice.dto.CreateSpaceDTO;
import com.balconazo.catalog_microservice.dto.SpaceDTO;
import java.util.List;
import java.util.UUID;

public interface SpaceService {
    SpaceDTO createSpace(CreateSpaceDTO dto);
    SpaceDTO getSpaceById(UUID id);
    List<SpaceDTO> getSpacesByOwner(UUID ownerId);
    List<SpaceDTO> getActiveSpaces();
    SpaceDTO updateSpace(UUID id, CreateSpaceDTO dto);
    SpaceDTO activateSpace(UUID id);
    SpaceDTO snoozeSpace(UUID id);
    void deleteSpace(UUID id);
}

