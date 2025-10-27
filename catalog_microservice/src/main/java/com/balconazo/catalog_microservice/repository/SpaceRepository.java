package com.balconazo.catalog_microservice.repository;

import com.balconazo.catalog_microservice.entity.SpaceEntity;
import com.balconazo.catalog_microservice.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SpaceRepository extends JpaRepository<SpaceEntity, UUID> {
    List<SpaceEntity> findByOwner(UserEntity owner);
    List<SpaceEntity> findByStatus(String status);
    List<SpaceEntity> findByOwnerAndStatus(UserEntity owner, String status);
}

