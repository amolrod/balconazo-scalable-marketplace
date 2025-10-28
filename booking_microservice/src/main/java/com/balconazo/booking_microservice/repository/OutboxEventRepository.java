package com.balconazo.booking_microservice.repository;

import com.balconazo.booking_microservice.entity.OutboxEventEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OutboxEventRepository extends JpaRepository<OutboxEventEntity, UUID> {

    List<OutboxEventEntity> findByStatusOrderByCreatedAtAsc(OutboxEventEntity.OutboxStatus status);

    List<OutboxEventEntity> findTop100ByStatusOrderByCreatedAtAsc(OutboxEventEntity.OutboxStatus status);
}

