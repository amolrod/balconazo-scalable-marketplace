package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.dto.CreateSpaceDTO;
import com.balconazo.catalog_microservice.dto.SpaceDTO;
import com.balconazo.catalog_microservice.entity.SpaceEntity;
import com.balconazo.catalog_microservice.entity.UserEntity;
import com.balconazo.catalog_microservice.event.EventPublisher;
import com.balconazo.catalog_microservice.event.SpaceCreatedEvent;
import com.balconazo.catalog_microservice.exception.BusinessValidationException;
import com.balconazo.catalog_microservice.exception.ResourceNotFoundException;
import com.balconazo.catalog_microservice.mapper.SpaceMapper;
import com.balconazo.catalog_microservice.repository.SpaceRepository;
import com.balconazo.catalog_microservice.repository.UserRepository;
import com.balconazo.catalog_microservice.service.CacheService;
import com.balconazo.catalog_microservice.service.SpaceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
import static com.balconazo.catalog_microservice.constants.CatalogConstants.*;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class SpaceServiceImpl implements SpaceService {
    private final SpaceRepository repo;
    private final UserRepository userRepo;
    private final SpaceMapper mapper;
    private final CacheService cacheService;
    private final EventPublisher eventPublisher; // ← NUEVO

    private static final String CACHE_KEY_SPACE = "space:";
    private static final long CACHE_TTL_SECONDS = 300; // 5 minutos

    public SpaceDTO createSpace(CreateSpaceDTO dto) {
        // Obtener el rol del usuario autenticado desde el JWT
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean isHost = authentication.getAuthorities().stream()
            .anyMatch(auth -> auth.getAuthority().equals("ROLE_HOST"));

        if (!isHost) {
            throw new BusinessValidationException("Solo hosts pueden crear espacios");
        }

        // Obtener o crear usuario en la BD local
        UserEntity owner = userRepo.findById(dto.getOwnerId())
            .orElseGet(() -> {
                // Crear usuario local si no existe
                UserEntity newUser = UserEntity.builder()
                    .id(dto.getOwnerId())
                    .email("user-" + dto.getOwnerId() + "@balconazo.com") // email dummy
                    .passwordHash("") // no se usa aquí
                    .role("HOST")
                    .status("active")
                    .build();
                return userRepo.save(newUser);
            });

        var space = mapper.toEntity(dto, owner);
        space.setStatus(SPACE_STATUS_DRAFT);
        var saved = repo.save(space);
        log.info("Espacio creado: {}", saved.getId());

        // Publicar evento a Kafka para que Search Service lo indexe
        SpaceCreatedEvent event = SpaceCreatedEvent.builder()
            .spaceId(saved.getId())
            .ownerId(saved.getOwner().getId())
            .title(saved.getTitle())
            .description(saved.getDescription())
            .address(saved.getAddress())
            .lat(saved.getLat())
            .lon(saved.getLon())
            .capacity(saved.getCapacity())
            .areaSqm(saved.getAreaSqm())
            .basePriceCents(saved.getBasePriceCents() != null ? saved.getBasePriceCents().longValue() : 0L)
            .amenities(saved.getAmenities())
            .status(saved.getStatus())
            .createdAt(saved.getCreatedAt())
            .build();

        eventPublisher.publishSpaceCreated(event);

        return mapper.toDTO(saved);
    }

    @Transactional(readOnly = true)
    public SpaceDTO getSpaceById(UUID id) {
        // Intentar obtener del caché primero
        String cacheKey = CACHE_KEY_SPACE + id;
        SpaceDTO cached = cacheService.get(cacheKey, SpaceDTO.class);

        if (cached != null) {
            log.debug("Cache HIT para espacio: {}", id);
            return cached;
        }

        log.debug("Cache MISS para espacio: {}", id);
        SpaceDTO space = mapper.toDTO(repo.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Espacio", id)));

        // Guardar en caché
        cacheService.put(cacheKey, space, CACHE_TTL_SECONDS);

        return space;
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

