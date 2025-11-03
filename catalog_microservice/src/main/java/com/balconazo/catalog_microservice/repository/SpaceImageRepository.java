package com.balconazo.catalog_microservice.repository;

import com.balconazo.catalog_microservice.entity.SpaceImageEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SpaceImageRepository extends JpaRepository<SpaceImageEntity, UUID> {

    List<SpaceImageEntity> findBySpaceIdOrderByDisplayOrderAsc(UUID spaceId);

    void deleteBySpaceId(UUID spaceId);
}

