package com.balconazo.catalog_microservice.service;

import com.balconazo.catalog_microservice.dto.SpaceImageDTO;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

public interface SpaceImageService {

    /**
     * Subir imagen para un espacio
     */
    SpaceImageDTO uploadImage(UUID spaceId, MultipartFile file, Boolean isPrimary);

    /**
     * Obtener todas las imágenes de un espacio
     */
    List<SpaceImageDTO> getSpaceImages(UUID spaceId);

    /**
     * Eliminar una imagen
     */
    void deleteImage(UUID imageId);

    /**
     * Marcar una imagen como principal
     */
    SpaceImageDTO setPrimaryImage(UUID spaceId, UUID imageId);

    /**
     * Reordenar imágenes
     */
    List<SpaceImageDTO> reorderImages(UUID spaceId, List<UUID> imageIds);
}

