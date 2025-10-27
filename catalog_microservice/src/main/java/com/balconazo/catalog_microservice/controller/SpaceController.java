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
    public SpaceDTO update(@PathVariable UUID id, @Valid @RequestBody CreateSpaceDTO dto) {
        return service.updateSpace(id, dto);
    }

    @PostMapping("/{id}/activate")
    public SpaceDTO activate(@PathVariable UUID id) {
        return service.activateSpace(id);
    }

    @PostMapping("/{id}/snooze")
    public SpaceDTO snooze(@PathVariable UUID id) {
        return service.snoozeSpace(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.deleteSpace(id);
        return ResponseEntity.noContent().build();
    }
}

