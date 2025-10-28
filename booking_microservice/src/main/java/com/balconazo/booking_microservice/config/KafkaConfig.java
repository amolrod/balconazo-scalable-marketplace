package com.balconazo.booking_microservice.config;

import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaAdmin;

import java.util.HashMap;
import java.util.Map;

import static com.balconazo.booking_microservice.constants.BookingConstants.*;

@Configuration
public class KafkaConfig {

    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;

    @Bean
    public KafkaAdmin kafkaAdmin() {
        Map<String, Object> configs = new HashMap<>();
        configs.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        configs.put(AdminClientConfig.REQUEST_TIMEOUT_MS_CONFIG, 5000);
        return new KafkaAdmin(configs);
    }

    @Bean
    public NewTopic bookingEventsTopic() {
        return TopicBuilder.name(TOPIC_BOOKING_EVENTS)
                .partitions(12)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic reviewEventsTopic() {
        return TopicBuilder.name(TOPIC_REVIEW_EVENTS)
                .partitions(12)
                .replicas(1)
                .build();
    }

    @Bean
    public NewTopic paymentEventsTopic() {
        return TopicBuilder.name(TOPIC_PAYMENT_EVENTS)
                .partitions(12)
                .replicas(1)
                .build();
    }
}

