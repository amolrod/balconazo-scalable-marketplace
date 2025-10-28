package com.balconazo.booking_microservice.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableScheduling
public class SchedulingConfig {
    // Habilita el procesamiento de @Scheduled para OutboxRelayService
}

