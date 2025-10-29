package com.balconazo.gateway.config;

import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import reactor.core.publisher.Mono;

import java.util.Objects;

/**
 * Configuración de Rate Limiting con Redis
 *
 * Estrategia: Rate limiting por IP address
 */
@Configuration
public class RateLimitConfig {

    /**
     * Key resolver basado en IP address
     *
     * Alternativas:
     * - Por userId (extraído del JWT)
     * - Por combinación IP + userId
     * - Por tenant/organization
     */
    @Bean
    public KeyResolver userKeyResolver() {
        return exchange -> {
            String ipAddress = Objects.requireNonNull(
                exchange.getRequest().getRemoteAddress()
            ).getAddress().getHostAddress();

            return Mono.just(ipAddress);
        };
    }
}

