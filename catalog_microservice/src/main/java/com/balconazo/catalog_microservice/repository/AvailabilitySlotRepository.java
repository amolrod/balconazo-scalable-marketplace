package com.balconazo.catalog_microservice.repository;

import com.balconazo.catalog_microservice.entity.AvailabilitySlotEntity;
import com.balconazo.catalog_microservice.entity.SpaceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AvailabilitySlotRepository extends JpaRepository<AvailabilitySlotEntity, UUID> {
    List<AvailabilitySlotEntity> findBySpace(SpaceEntity space);

    @Query("SELECT a FROM AvailabilitySlotEntity a WHERE a.space = ?1 AND a.endTs > ?2")
    List<AvailabilitySlotEntity> findFutureSlotsBySpace(SpaceEntity space, LocalDateTime now);

    @Query("SELECT a FROM AvailabilitySlotEntity a WHERE a.space = ?1 AND a.startTs < ?3 AND a.endTs > ?2")
    List<AvailabilitySlotEntity> findBySpaceAndTimeRange(SpaceEntity space, LocalDateTime start, LocalDateTime end);
}

