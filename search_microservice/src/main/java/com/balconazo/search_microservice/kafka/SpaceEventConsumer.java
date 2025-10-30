package com.balconazo.search_microservice.kafka;

import com.balconazo.search_microservice.entity.ProcessedEventEntity;
import com.balconazo.search_microservice.entity.SpaceProjection;
import com.balconazo.search_microservice.repository.ProcessedEventRepository;
import com.balconazo.search_microservice.repository.SpaceProjectionRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

import static com.balconazo.search_microservice.constants.SearchConstants.TOPIC_SPACE_EVENTS;

@Service
@Slf4j
@RequiredArgsConstructor
public class SpaceEventConsumer {

    private final SpaceProjectionRepository spaceRepository;
    private final ProcessedEventRepository processedEventRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @KafkaListener(topics = TOPIC_SPACE_EVENTS, groupId = "search-service")
    @Transactional
    public void handleSpaceEvent(@Payload String eventJson,
                                  @Header(KafkaHeaders.RECEIVED_KEY) String key,
                                  Acknowledgment acknowledgment) {
        log.info("Received space event: key={}", key);

        try {
            JsonNode eventNode = objectMapper.readTree(eventJson);

            // Extraer eventId del payload (puede estar en diferentes lugares)
            UUID eventId = extractEventId(eventNode);

            // Verificar idempotencia
            if (eventId != null && processedEventRepository.existsByEventId(eventId)) {
                log.info("Event {} already processed, skipping", eventId);
                acknowledgment.acknowledge();
                return;
            }

            // Determinar tipo de evento
            String eventType = determineEventType(eventNode);

            // Procesar según tipo
            switch (eventType) {
                case "SpaceCreatedEvent" -> handleSpaceCreated(eventNode);
                case "SpaceUpdatedEvent" -> handleSpaceUpdated(eventNode);
                case "SpaceDeactivatedEvent" -> handleSpaceDeactivated(eventNode);
                default -> log.warn("Unknown event type: {}", eventType);
            }

            // Marcar como procesado si tenemos eventId
            if (eventId != null) {
                ProcessedEventEntity processed = new ProcessedEventEntity();
                processed.setEventId(eventId);
                processed.setAggregateId(extractSpaceId(eventNode));
                processed.setEventType(eventType);
                processed.setProcessedAt(LocalDateTime.now());
                processedEventRepository.save(processed);
            }

            // Confirmar procesamiento
            acknowledgment.acknowledge();
            log.info("Successfully processed {} for space {}", eventType, extractSpaceId(eventNode));

        } catch (Exception e) {
            log.error("Error processing space event: {}", eventJson, e);
            // No hacer acknowledge - Kafka reintentará
        }
    }

    private void handleSpaceCreated(JsonNode event) {
        log.info("Creating space projection...");

        SpaceProjection projection = new SpaceProjection();
        projection.setSpaceId(extractSpaceId(event));
        projection.setOwnerId(UUID.fromString(event.get("ownerId").asText()));
        projection.setOwnerEmail(event.has("ownerEmail") ? event.get("ownerEmail").asText() : null);
        projection.setTitle(event.get("title").asText());
        projection.setDescription(event.has("description") ? event.get("description").asText() : null);
        projection.setAddress(event.get("address").asText());

        // Crear Point de PostGIS
        double lon = event.get("lon").asDouble();
        double lat = event.get("lat").asDouble();
        Point geo = geometryFactory.createPoint(new Coordinate(lon, lat));
        projection.setGeo(geo);

        projection.setCapacity(event.get("capacity").asInt());

        if (event.has("areaSqm")) {
            projection.setAreaSqm(new BigDecimal(event.get("areaSqm").asText()));
        }

        projection.setBasePriceCents(event.get("basePriceCents").asInt());
        projection.setStatus(event.has("status") ? event.get("status").asText() : "draft");

        // Amenities
        if (event.has("amenities") && event.get("amenities").isArray()) {
            List<String> amenities = new ArrayList<>();
            event.get("amenities").forEach(a -> amenities.add(a.asText()));
            projection.setAmenities(amenities.toArray(new String[0]));
        }

        // Rules (JSONB)
        if (event.has("rules") && event.get("rules").isObject()) {
            projection.setRules(objectMapper.convertValue(event.get("rules"), HashMap.class));
        }

        spaceRepository.save(projection);
        log.info("Created space projection: {}", projection.getSpaceId());
    }

    private void handleSpaceUpdated(JsonNode event) {
        UUID spaceId = extractSpaceId(event);
        log.info("Updating space projection: {}", spaceId);

        SpaceProjection projection = spaceRepository.findById(spaceId)
            .orElseThrow(() -> new RuntimeException("Space not found: " + spaceId));

        // Actualizar solo campos que están presentes
        if (event.has("title")) projection.setTitle(event.get("title").asText());
        if (event.has("description")) projection.setDescription(event.get("description").asText());
        if (event.has("capacity")) projection.setCapacity(event.get("capacity").asInt());

        if (event.has("basePriceCents")) {
            projection.setBasePriceCents(event.get("basePriceCents").asInt());
        }

        if (event.has("status")) projection.setStatus(event.get("status").asText());

        spaceRepository.save(projection);
        log.info("Updated space projection: {}", spaceId);
    }

    private void handleSpaceDeactivated(JsonNode event) {
        UUID spaceId = extractSpaceId(event);
        log.info("Deactivating space projection: {}", spaceId);

        SpaceProjection projection = spaceRepository.findById(spaceId)
            .orElseThrow(() -> new RuntimeException("Space not found: " + spaceId));

        projection.setStatus("inactive");
        spaceRepository.save(projection);
        log.info("Deactivated space projection: {}", spaceId);
    }

    private UUID extractEventId(JsonNode event) {
        // Intentar extraer eventId de diferentes lugares
        if (event.has("eventId")) {
            return UUID.fromString(event.get("eventId").asText());
        }
        // Si no hay eventId, retornar null (se puede generar uno basado en spaceId + timestamp)
        return null;
    }

    private UUID extractSpaceId(JsonNode event) {
        if (event.has("spaceId")) {
            return UUID.fromString(event.get("spaceId").asText());
        }
        if (event.has("id")) {
            return UUID.fromString(event.get("id").asText());
        }
        throw new IllegalArgumentException("No spaceId found in event");
    }

    private String determineEventType(JsonNode event) {
        // Intentar determinar el tipo de evento
        if (event.has("eventType")) {
            return event.get("eventType").asText();
        }

        // Inferir por presencia de campos
        if (event.has("status") && "inactive".equals(event.get("status").asText())) {
            return "SpaceDeactivatedEvent";
        }

        // Si tiene todos los campos, es creación
        if (event.has("ownerId") && event.has("lat") && event.has("lon")) {
            return "SpaceCreatedEvent";
        }

        // Por defecto, actualización
        return "SpaceUpdatedEvent";
    }
}

