package com.balconazo.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.UUID;

/**
 * Filtro global para agregar Correlation ID a todas las peticiones
 *
 * Beneficios:
 * - Trazabilidad de peticiones a través de microservicios
 * - Facilita debugging en logs distribuidos
 * - Permite rastrear el flujo completo de una petición
 */
@Component
@Slf4j
public class CorrelationIdFilter implements GlobalFilter, Ordered {

    private static final String CORRELATION_ID_HEADER = "X-Correlation-Id";

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();

        // Extraer o generar Correlation ID
        String correlationId = request.getHeaders().getFirst(CORRELATION_ID_HEADER);
        if (correlationId == null || correlationId.isBlank()) {
            correlationId = UUID.randomUUID().toString();
        }

        // Variable final para uso en lambdas
        final String finalCorrelationId = correlationId;

        log.info("🔗 [{}] {} {} - Remote: {}",
            finalCorrelationId,
            request.getMethod(),
            request.getURI().getPath(),
            request.getRemoteAddress()
        );

        // Agregar Correlation ID al request que se envía al microservicio
        ServerHttpRequest mutatedRequest = request.mutate()
            .header(CORRELATION_ID_HEADER, finalCorrelationId)
            .build();

        ServerWebExchange mutatedExchange = exchange.mutate()
            .request(mutatedRequest)
            .build();

        // Agregar Correlation ID a la respuesta
        mutatedExchange.getResponse().getHeaders().add(CORRELATION_ID_HEADER, finalCorrelationId);

        return chain.filter(mutatedExchange)
            .doOnSuccess(aVoid -> log.info("✅ [{}] Request completed successfully", finalCorrelationId))
            .doOnError(error -> log.error("❌ [{}] Request failed: {}", finalCorrelationId, error.getMessage()));
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}

