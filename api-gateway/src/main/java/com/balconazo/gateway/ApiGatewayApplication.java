package com.balconazo.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * API Gateway - Punto de entrada único para todos los microservicios de Balconazo
 *
 * Responsabilidades:
 * - Enrutamiento a microservicios (Auth, Catalog, Booking, Search)
 * - Validación de JWT (sin consultar BD)
 * - Rate Limiting con Redis (reactive)
 * - Circuit Breaker con Resilience4j
 * - CORS para frontend
 * - Logging con correlation ID
 */
@SpringBootApplication
@EnableDiscoveryClient
public class ApiGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}

