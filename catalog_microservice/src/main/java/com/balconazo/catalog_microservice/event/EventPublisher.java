package com.balconazo.catalog_microservice.event;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

/**
 * Servicio para publicar eventos de dominio a Kafka
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EventPublisher {

    private final KafkaTemplate<String, Object> kafkaTemplate;

    @Value("${balconazo.catalog.kafka.topics.space-events:space.events.v1}")
    private String spaceEventsTopic;

    /**
     * Publica un evento SpaceCreated a Kafka
     */
    public void publishSpaceCreated(SpaceCreatedEvent event) {
        try {
            log.info("Publicando evento SpaceCreated para espacio: {}", event.getSpaceId());
            kafkaTemplate.send(spaceEventsTopic, event.getSpaceId().toString(), event);
            log.info("Evento SpaceCreated publicado exitosamente: {}", event.getSpaceId());
        } catch (Exception e) {
            log.error("Error publicando evento SpaceCreated para espacio {}: {}",
                event.getSpaceId(), e.getMessage(), e);
            // No lanzar excepción para no interrumpir la creación del espacio
        }
    }
}

