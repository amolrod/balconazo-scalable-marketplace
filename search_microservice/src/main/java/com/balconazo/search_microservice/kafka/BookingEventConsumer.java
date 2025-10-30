package com.balconazo.search_microservice.kafka;

import com.balconazo.search_microservice.entity.ProcessedEventEntity;
import com.balconazo.search_microservice.entity.SpaceProjection;
import com.balconazo.search_microservice.repository.ProcessedEventRepository;
import com.balconazo.search_microservice.repository.SpaceProjectionRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

import static com.balconazo.search_microservice.constants.SearchConstants.TOPIC_BOOKING_EVENTS;
import static com.balconazo.search_microservice.constants.SearchConstants.TOPIC_REVIEW_EVENTS;

@Service
@Slf4j
@RequiredArgsConstructor
public class BookingEventConsumer {

    private final SpaceProjectionRepository spaceRepository;
    private final ProcessedEventRepository processedEventRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @KafkaListener(topics = TOPIC_BOOKING_EVENTS, groupId = "search-service")
    @Transactional
    public void handleBookingEvent(@Payload String eventJson,
                                    @Header(KafkaHeaders.RECEIVED_KEY) String key,
                                    Acknowledgment acknowledgment) {
        log.info("Received booking event: key={}", key);

        try {
            JsonNode eventNode = objectMapper.readTree(eventJson);

            UUID eventId = extractEventId(eventNode);

            // Verificar idempotencia
            if (eventId != null && processedEventRepository.existsByEventId(eventId)) {
                log.info("Event {} already processed, skipping", eventId);
                acknowledgment.acknowledge();
                return;
            }

            String eventType = determineEventType(eventNode);

            // Solo procesar BookingConfirmedEvent
            if ("BookingConfirmedEvent".equals(eventType) ||
                (eventNode.has("status") && "confirmed".equals(eventNode.get("status").asText()))) {
                handleBookingConfirmed(eventNode);
            }

            // Marcar como procesado
            if (eventId != null) {
                ProcessedEventEntity processed = new ProcessedEventEntity();
                processed.setEventId(eventId);
                processed.setAggregateId(extractBookingId(eventNode));
                processed.setEventType(eventType);
                processed.setProcessedAt(LocalDateTime.now());
                processedEventRepository.save(processed);
            }

            acknowledgment.acknowledge();
            log.info("Successfully processed booking event");

        } catch (Exception e) {
            log.error("Error processing booking event: {}", eventJson, e);
        }
    }

    @KafkaListener(topics = TOPIC_REVIEW_EVENTS, groupId = "search-service")
    @Transactional
    public void handleReviewEvent(@Payload String eventJson,
                                   @Header(KafkaHeaders.RECEIVED_KEY) String key,
                                   Acknowledgment acknowledgment) {
        log.info("Received review event: key={}", key);

        try {
            JsonNode eventNode = objectMapper.readTree(eventJson);

            UUID eventId = extractEventId(eventNode);

            // Verificar idempotencia
            if (eventId != null && processedEventRepository.existsByEventId(eventId)) {
                log.info("Event {} already processed, skipping", eventId);
                acknowledgment.acknowledge();
                return;
            }

            handleReviewCreated(eventNode);

            // Marcar como procesado
            if (eventId != null) {
                ProcessedEventEntity processed = new ProcessedEventEntity();
                processed.setEventId(eventId);
                processed.setAggregateId(extractReviewId(eventNode));
                processed.setEventType("ReviewCreatedEvent");
                processed.setProcessedAt(LocalDateTime.now());
                processedEventRepository.save(processed);
            }

            acknowledgment.acknowledge();
            log.info("Successfully processed review event");

        } catch (Exception e) {
            log.error("Error processing review event: {}", eventJson, e);
        }
    }

    private void handleBookingConfirmed(JsonNode event) {
        UUID spaceId = UUID.fromString(event.get("spaceId").asText());
        log.info("Updating space stats for booking confirmed: spaceId={}", spaceId);

        spaceRepository.findById(spaceId).ifPresentOrElse(
            projection -> {
                // Incrementar completedBookings
                projection.setCompletedBookings((projection.getCompletedBookings() != null ? projection.getCompletedBookings() : 0) + 1);
                projection.setLastBookingAt(LocalDateTime.now());
                spaceRepository.save(projection);
                log.info("Updated space stats: completedBookings={}", projection.getCompletedBookings());
            },
            () -> log.warn("Space {} not found in projections, skipping stats update", spaceId)
        );
    }

    private void handleReviewCreated(JsonNode event) {
        UUID spaceId = UUID.fromString(event.get("spaceId").asText());
        int rating = event.get("rating").asInt();

        log.info("Recalculating rating for space: spaceId={}, newRating={}", spaceId, rating);

        spaceRepository.findById(spaceId).ifPresentOrElse(
            projection -> {
                // Recalcular rating promedio
                int currentTotal = projection.getReviewCount() != null ? projection.getReviewCount() : 0;
                double currentAvg = projection.getAvgRating() != null ? projection.getAvgRating() : 0.0;

                double newAvg = ((currentAvg * currentTotal) + rating) / (currentTotal + 1);

                projection.setAvgRating(Math.round(newAvg * 100.0) / 100.0); // 2 decimales
                projection.setReviewCount(currentTotal + 1);

                spaceRepository.save(projection);
                log.info("Updated space rating: avgRating={}, reviewCount={}",
                    projection.getAvgRating(), projection.getReviewCount());
            },
            () -> log.warn("Space {} not found in projections, skipping rating update", spaceId)
        );
    }

    private UUID extractEventId(JsonNode event) {
        if (event.has("eventId")) {
            return UUID.fromString(event.get("eventId").asText());
        }
        return null;
    }

    private UUID extractBookingId(JsonNode event) {
        if (event.has("bookingId")) {
            return UUID.fromString(event.get("bookingId").asText());
        }
        if (event.has("id")) {
            return UUID.fromString(event.get("id").asText());
        }
        return UUID.randomUUID();
    }

    private UUID extractReviewId(JsonNode event) {
        if (event.has("reviewId")) {
            return UUID.fromString(event.get("reviewId").asText());
        }
        if (event.has("id")) {
            return UUID.fromString(event.get("id").asText());
        }
        return UUID.randomUUID();
    }

    private String determineEventType(JsonNode event) {
        if (event.has("eventType")) {
            return event.get("eventType").asText();
        }
        return "UnknownEvent";
    }
}

