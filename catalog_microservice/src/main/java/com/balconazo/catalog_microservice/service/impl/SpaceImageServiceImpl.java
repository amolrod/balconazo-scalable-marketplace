package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.dto.SpaceImageDTO;
import com.balconazo.catalog_microservice.entity.SpaceImageEntity;
import com.balconazo.catalog_microservice.exception.BusinessValidationException;
import com.balconazo.catalog_microservice.exception.ResourceNotFoundException;
import com.balconazo.catalog_microservice.repository.SpaceImageRepository;
import com.balconazo.catalog_microservice.repository.SpaceRepository;
import com.balconazo.catalog_microservice.service.SpaceImageService;
import com.balconazo.catalog_microservice.service.StorageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class SpaceImageServiceImpl implements SpaceImageService {

    private final SpaceImageRepository imageRepo;
    private final SpaceRepository spaceRepo;
    private final StorageService storageService;

    private static final int MAX_IMAGES_PER_SPACE = 10;

    @Override
    public SpaceImageDTO uploadImage(UUID spaceId, MultipartFile file, Boolean isPrimary) {
        // Verificar que el espacio existe
        var space = spaceRepo.findById(spaceId)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", spaceId));

        // Verificar límite de imágenes
        var existingImages = imageRepo.findBySpaceIdOrderByDisplayOrderAsc(spaceId);
        if (existingImages.size() >= MAX_IMAGES_PER_SPACE) {
            throw new BusinessValidationException("Máximo " + MAX_IMAGES_PER_SPACE + " imágenes por espacio");
        }

        // Guardar archivo
        String url = storageService.store(file, "spaces/" + spaceId);

        // Si es la primera imagen o se marca como principal, desmarcar otras
        boolean shouldBePrimary = isPrimary != null ? isPrimary : existingImages.isEmpty();
        if (shouldBePrimary) {
            existingImages.forEach(img -> img.setIsPrimary(false));
            imageRepo.saveAll(existingImages);
        }

        // Crear entidad
        var image = SpaceImageEntity.builder()
            .space(space)
            .url(url)
            .displayOrder(existingImages.size())
            .isPrimary(shouldBePrimary)
            .altText(space.getTitle())
            .build();

        var saved = imageRepo.save(image);
        log.info("Imagen subida para espacio {}: {}", spaceId, url);

        return toDTO(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SpaceImageDTO> getSpaceImages(UUID spaceId) {
        return imageRepo.findBySpaceIdOrderByDisplayOrderAsc(spaceId)
            .stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    @Override
    public void deleteImage(UUID imageId) {
        var image = imageRepo.findById(imageId)
            .orElseThrow(() -> new ResourceNotFoundException("Imagen", imageId));

        // Eliminar archivo físico
        storageService.delete(image.getUrl());

        // Eliminar de BD
        imageRepo.delete(image);

        // Si era la principal, marcar otra como principal
        if (image.getIsPrimary()) {
            var remainingImages = imageRepo.findBySpaceIdOrderByDisplayOrderAsc(image.getSpace().getId());
            if (!remainingImages.isEmpty()) {
                remainingImages.get(0).setIsPrimary(true);
                imageRepo.save(remainingImages.get(0));
            }
        }

        log.info("Imagen eliminada: {}", imageId);
    }

    @Override
    public SpaceImageDTO setPrimaryImage(UUID spaceId, UUID imageId) {
        // Verificar que la imagen pertenece al espacio
        var image = imageRepo.findById(imageId)
            .orElseThrow(() -> new ResourceNotFoundException("Imagen", imageId));

        if (!image.getSpace().getId().equals(spaceId)) {
            throw new BusinessValidationException("La imagen no pertenece a este espacio");
        }

        // Desmarcar todas las imágenes del espacio
        var allImages = imageRepo.findBySpaceIdOrderByDisplayOrderAsc(spaceId);
        allImages.forEach(img -> img.setIsPrimary(false));
        imageRepo.saveAll(allImages);

        // Marcar la seleccionada como principal
        image.setIsPrimary(true);
        var saved = imageRepo.save(image);

        log.info("Imagen {} marcada como principal para espacio {}", imageId, spaceId);
        return toDTO(saved);
    }

    @Override
    public List<SpaceImageDTO> reorderImages(UUID spaceId, List<UUID> imageIds) {
        var images = imageRepo.findBySpaceIdOrderByDisplayOrderAsc(spaceId);

        // Verificar que todas las imágenes pertenecen al espacio
        if (images.size() != imageIds.size()) {
            throw new BusinessValidationException("La lista de IDs no coincide con las imágenes del espacio");
        }

        // Reordenar
        for (int i = 0; i < imageIds.size(); i++) {
            UUID imageId = imageIds.get(i);
            var image = images.stream()
                .filter(img -> img.getId().equals(imageId))
                .findFirst()
                .orElseThrow(() -> new BusinessValidationException("Imagen no encontrada: " + imageId));

            image.setDisplayOrder(i);
        }

        var saved = imageRepo.saveAll(images);
        log.info("Imágenes reordenadas para espacio {}", spaceId);

        return saved.stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    private SpaceImageDTO toDTO(SpaceImageEntity entity) {
        return SpaceImageDTO.builder()
            .id(entity.getId())
            .url(entity.getUrl())
            .displayOrder(entity.getDisplayOrder())
            .isPrimary(entity.getIsPrimary())
            .altText(entity.getAltText())
            .createdAt(entity.getCreatedAt())
            .build();
    }
}

