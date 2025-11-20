package com.balconazo.catalog_microservice.repository;

import com.balconazo.catalog_microservice.entity.SpaceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SpaceRepository extends JpaRepository<SpaceEntity, UUID> {
    List<SpaceEntity> findByOwnerId(UUID ownerId);
    List<SpaceEntity> findByStatus(String status);
    List<SpaceEntity> findByOwnerIdAndStatus(UUID ownerId, String status);
}

