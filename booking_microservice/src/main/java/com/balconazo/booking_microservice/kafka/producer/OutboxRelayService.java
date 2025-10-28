package com.balconazo.booking_microservice.kafka.producer;

import com.balconazo.booking_microservice.constants.BookingConstants;
import com.balconazo.booking_microservice.entity.OutboxEventEntity;
import com.balconazo.booking_microservice.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Outbox Relay: Publica eventos pendientes a Kafka cada 5 segundos
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OutboxRelayService {

    private final OutboxEventRepository outboxEventRepository;
    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelay = 5000) // Cada 5 segundos
    @Transactional
    public void relayPendingEvents() {
        List<OutboxEventEntity> pendingEvents = outboxEventRepository
                .findTop100ByStatusOrderByCreatedAtAsc(OutboxEventEntity.OutboxStatus.pending);

        if (pendingEvents.isEmpty()) {
            return;
        }

        log.info("📤 Procesando {} eventos pendientes del Outbox", pendingEvents.size());

        for (OutboxEventEntity event : pendingEvents) {
            try {
                String topic = getTopicForEventType(event.getEventType());
                String key = event.getAggregateId().toString();

                // Deserializar el payload
                Object payload = objectMapper.readValue(event.getPayload(), Object.class);

                // Enviar a Kafka
                kafkaTemplate.send(topic, key, payload).whenComplete((result, ex) -> {
                    if (ex == null) {
                        markAsSent(event);
                        log.info("✅ Evento publicado a Kafka: {} - topic={}", event.getEventType(), topic);
                    } else {
                        markAsFailed(event, ex.getMessage());
                        log.error("❌ Error al publicar evento {}: {}", event.getEventType(), ex.getMessage());
                    }
                });

            } catch (Exception e) {
                markAsFailed(event, e.getMessage());
                log.error("❌ Error procesando evento {}: {}", event.getId(), e.getMessage(), e);
            }
        }
    }

    @Transactional
    protected void markAsSent(OutboxEventEntity event) {
        event.setStatus(OutboxEventEntity.OutboxStatus.sent);
        event.setProcessedAt(LocalDateTime.now());
        outboxEventRepository.save(event);
    }

    @Transactional
    protected void markAsFailed(OutboxEventEntity event, String errorMessage) {
        event.setRetryCount(event.getRetryCount() + 1);
        event.setLastError(errorMessage);

        // Después de 5 intentos, marcarlo como failed
        if (event.getRetryCount() >= 5) {
            event.setStatus(OutboxEventEntity.OutboxStatus.failed);
            log.error("❌ Evento {} marcado como FAILED después de {} intentos", event.getId(), event.getRetryCount());
        }

        outboxEventRepository.save(event);
    }

    private String getTopicForEventType(String eventType) {
        return switch (eventType) {
            case BookingConstants.EVENT_BOOKING_CREATED,
                 BookingConstants.EVENT_BOOKING_CONFIRMED,
                 BookingConstants.EVENT_BOOKING_CANCELLED,
                 BookingConstants.EVENT_BOOKING_COMPLETED ->
                    BookingConstants.TOPIC_BOOKING_EVENTS;

            case BookingConstants.EVENT_REVIEW_CREATED ->
                    BookingConstants.TOPIC_REVIEW_EVENTS;

            case BookingConstants.EVENT_PAYMENT_INITIATED,
                 BookingConstants.EVENT_PAYMENT_SUCCEEDED,
                 BookingConstants.EVENT_PAYMENT_FAILED ->
                    BookingConstants.TOPIC_PAYMENT_EVENTS;

            default -> throw new IllegalArgumentException("Tipo de evento desconocido: " + eventType);
        };
    }
}

