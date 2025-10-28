package com.balconazo.search_microservice.repository;

import com.balconazo.search_microservice.entity.ProcessedEventEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProcessedEventRepository extends JpaRepository<ProcessedEventEntity, UUID> {

    boolean existsByEventId(UUID eventId);
}

