package com.balconazo.catalog_microservice.controller;

import com.balconazo.catalog_microservice.dto.SpaceImageDTO;
import com.balconazo.catalog_microservice.service.SpaceImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/catalog/spaces/{spaceId}/images")
@RequiredArgsConstructor
public class SpaceImageController {

    private final SpaceImageService service;

    /**
     * Subir una imagen
     */
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<SpaceImageDTO> uploadImage(
            @PathVariable UUID spaceId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "isPrimary", required = false) Boolean isPrimary) {

        return ResponseEntity.status(HttpStatus.CREATED)
            .body(service.uploadImage(spaceId, file, isPrimary));
    }

    /**
     * Obtener todas las imágenes de un espacio
     */
    @GetMapping
    public List<SpaceImageDTO> getImages(@PathVariable UUID spaceId) {
        return service.getSpaceImages(spaceId);
    }

    /**
     * Eliminar una imagen
     */
    @DeleteMapping("/{imageId}")
    public ResponseEntity<Void> deleteImage(
            @PathVariable UUID spaceId,
            @PathVariable UUID imageId) {

        service.deleteImage(imageId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Marcar una imagen como principal
     */
    @PutMapping("/{imageId}/set-primary")
    public SpaceImageDTO setPrimary(
            @PathVariable UUID spaceId,
            @PathVariable UUID imageId) {

        return service.setPrimaryImage(spaceId, imageId);
    }

    /**
     * Reordenar imágenes
     */
    @PutMapping("/reorder")
    public List<SpaceImageDTO> reorderImages(
            @PathVariable UUID spaceId,
            @RequestBody List<UUID> imageIds) {

        return service.reorderImages(spaceId, imageIds);
    }
}

