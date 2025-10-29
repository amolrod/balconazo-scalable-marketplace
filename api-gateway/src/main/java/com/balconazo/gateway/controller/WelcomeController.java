package com.balconazo.gateway.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Controlador para la página principal del API Gateway
 */
@RestController
public class WelcomeController {

    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> welcome() {
        return ResponseEntity.ok(Map.of(
            "service", "Balconazo API Gateway",
            "version", "1.0.0",
            "status", "UP",
            "timestamp", LocalDateTime.now(),
            "description", "API Gateway para el marketplace de espacios Balconazo",
            "endpoints", Map.of(
                "health", "/actuator/health",
                "routes", "/actuator/gateway/routes",
                "auth", Map.of(
                    "register", "POST /api/auth/register",
                    "login", "POST /api/auth/login"
                ),
                "catalog", Map.of(
                    "spaces", "GET /api/catalog/spaces (requiere JWT)",
                    "users", "GET /api/catalog/users (requiere JWT)"
                ),
                "booking", Map.of(
                    "bookings", "GET /api/booking/bookings (requiere JWT)",
                    "reviews", "GET /api/booking/reviews (requiere JWT)"
                ),
                "search", Map.of(
                    "spaces", "GET /api/search/spaces?lat=40.4168&lon=-3.7038&radius=10 (público)"
                )
            ),
            "documentation", "Ver /actuator/gateway/routes para todas las rutas configuradas"
        ));
    }
}

