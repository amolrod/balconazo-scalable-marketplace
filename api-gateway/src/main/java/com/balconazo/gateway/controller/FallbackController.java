package com.balconazo.gateway.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Controlador de fallback para Circuit Breaker
 *
 * Cuando un microservicio no responde o está fallando,
 * el circuit breaker redirige aquí para dar una respuesta amigable
 */
@RestController
@RequestMapping("/fallback")
@Slf4j
public class FallbackController {

    @RequestMapping("/auth")
    public ResponseEntity<Map<String, Object>> authServiceFallback() {
        log.warn("🔴 Auth Service fallback triggered - Service unavailable");

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(Map.of(
                "error", "AUTH_SERVICE_UNAVAILABLE",
                "message", "El servicio de autenticación no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.",
                "timestamp", LocalDateTime.now(),
                "service", "auth-service"
            ));
    }

    @RequestMapping("/catalog")
    public ResponseEntity<Map<String, Object>> catalogServiceFallback() {
        log.warn("🔴 Catalog Service fallback triggered - Service unavailable");

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(Map.of(
                "error", "CATALOG_SERVICE_UNAVAILABLE",
                "message", "El servicio de catálogo no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.",
                "timestamp", LocalDateTime.now(),
                "service", "catalog-service"
            ));
    }

    @RequestMapping("/booking")
    public ResponseEntity<Map<String, Object>> bookingServiceFallback() {
        log.warn("🔴 Booking Service fallback triggered - Service unavailable");

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(Map.of(
                "error", "BOOKING_SERVICE_UNAVAILABLE",
                "message", "El servicio de reservas no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.",
                "timestamp", LocalDateTime.now(),
                "service", "booking-service"
            ));
    }

    @RequestMapping("/search")
    public ResponseEntity<Map<String, Object>> searchServiceFallback() {
        log.warn("🔴 Search Service fallback triggered - Service unavailable");

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
            .body(Map.of(
                "error", "SEARCH_SERVICE_UNAVAILABLE",
                "message", "El servicio de búsqueda no está disponible temporalmente. Por favor, intenta de nuevo en unos momentos.",
                "timestamp", LocalDateTime.now(),
                "service", "search-service"
            ));
    }
}

