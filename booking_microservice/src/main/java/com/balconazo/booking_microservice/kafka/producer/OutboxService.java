package com.balconazo.booking_microservice.kafka.producer;

import com.balconazo.booking_microservice.entity.OutboxEventEntity;
import com.balconazo.booking_microservice.repository.OutboxEventRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Outbox Service: Guarda eventos en la BD (transaccional)
 * Un scheduler separado los publicará a Kafka
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OutboxService {

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public void saveEvent(String aggregateType, UUID aggregateId, String eventType, Object eventPayload) {
        try {
            String payloadJson = objectMapper.writeValueAsString(eventPayload);

            OutboxEventEntity outboxEvent = OutboxEventEntity.builder()
                    .aggregateId(aggregateId)
                    .aggregateType(aggregateType)
                    .eventType(eventType)
                    .payload(payloadJson)
                    .status(OutboxEventEntity.OutboxStatus.pending)
                    .retryCount(0)
                    .build();

            outboxEventRepository.save(outboxEvent);
            log.info("✅ Evento guardado en Outbox: {} - aggregateId={}", eventType, aggregateId);

        } catch (JsonProcessingException e) {
            log.error("❌ Error al serializar evento {}: {}", eventType, e.getMessage(), e);
            throw new RuntimeException("Error al guardar evento en outbox", e);
        }
    }
}

