package com.balconazo.catalog_microservice.controller;

import com.balconazo.catalog_microservice.dto.*;
import com.balconazo.catalog_microservice.service.SpaceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/catalog/spaces")
@RequiredArgsConstructor
public class SpaceController {
    private final SpaceService service;

    @PostMapping
    public ResponseEntity<SpaceDTO> create(@Valid @RequestBody CreateSpaceDTO dto) {
        // Extraer userId del SecurityContext (viene del JWT)
        var authentication = org.springframework.security.core.context.SecurityContextHolder
                .getContext()
                .getAuthentication();
        
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        String userId = (String) authentication.getPrincipal();
        dto.setOwnerId(UUID.fromString(userId));
        
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createSpace(dto));
    }

    @GetMapping("/{id}")
    public SpaceDTO getById(@PathVariable UUID id) {
        return service.getSpaceById(id);
    }

    @GetMapping("/owner/{ownerId}")
    public List<SpaceDTO> getByOwner(@PathVariable UUID ownerId) {
        return service.getSpacesByOwner(ownerId);
    }

    @GetMapping
    public List<SpaceDTO> getActive() {
        return service.getActiveSpaces();
    }

    @PutMapping("/{id}")
    public ResponseEntity<SpaceDTO> update(@PathVariable UUID id, @Valid @RequestBody CreateSpaceDTO dto) {
        // Extraer userId del SecurityContext
        var authentication = org.springframework.security.core.context.SecurityContextHolder
                .getContext()
                .getAuthentication();
        
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        String userId = (String) authentication.getPrincipal();
        UUID authenticatedUserId = UUID.fromString(userId);
        
        // Validar ownership antes de actualizar
        SpaceDTO existingSpace = service.getSpaceById(id);
        if (!existingSpace.getOwnerId().equals(authenticatedUserId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        return ResponseEntity.ok(service.updateSpace(id, dto));
    }

    @PostMapping("/{id}/activate")
    public SpaceDTO activate(@PathVariable UUID id) {
        return service.activateSpace(id);
    }

    @PostMapping("/{id}/snooze")
    public SpaceDTO snooze(@PathVariable UUID id) {
        return service.snoozeSpace(id);
    }

    @PostMapping("/{id}/archive")
    public SpaceDTO archive(@PathVariable UUID id) {
        return service.archiveSpace(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        // Extraer userId del SecurityContext
        var authentication = org.springframework.security.core.context.SecurityContextHolder
                .getContext()
                .getAuthentication();
        
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        String userId = (String) authentication.getPrincipal();
        UUID authenticatedUserId = UUID.fromString(userId);
        
        // Validar ownership antes de eliminar
        SpaceDTO existingSpace = service.getSpaceById(id);
        if (!existingSpace.getOwnerId().equals(authenticatedUserId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        service.deleteSpace(id);
        return ResponseEntity.noContent().build();
    }
}

