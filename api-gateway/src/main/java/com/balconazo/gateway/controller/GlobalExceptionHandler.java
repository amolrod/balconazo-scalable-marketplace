package com.balconazo.gateway.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Manejador global de excepciones para API Gateway
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(
            AccessDeniedException ex,
            ServerWebExchange exchange) {

        log.error("🚫 Access Denied: {} - Path: {}",
            ex.getMessage(),
            exchange.getRequest().getURI().getPath()
        );

        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(Map.of(
                "error", "ACCESS_DENIED",
                "message", "No tienes permisos para acceder a este recurso",
                "timestamp", LocalDateTime.now(),
                "path", exchange.getRequest().getURI().getPath()
            ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(
            ResponseStatusException ex,
            ServerWebExchange exchange) {

        log.error("⚠️ Response Status Error: {} - Path: {}",
            ex.getMessage(),
            exchange.getRequest().getURI().getPath()
        );

        return ResponseEntity.status(ex.getStatusCode())
            .body(Map.of(
                "error", ex.getStatusCode().toString(),
                "message", ex.getReason() != null ? ex.getReason() : "Error en el servidor",
                "timestamp", LocalDateTime.now(),
                "path", exchange.getRequest().getURI().getPath()
            ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGenericException(
            Exception ex,
            ServerWebExchange exchange) {

        log.error("💥 Unexpected Error: {} - Path: {}",
            ex.getMessage(),
            exchange.getRequest().getURI().getPath(),
            ex
        );

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of(
                "error", "INTERNAL_SERVER_ERROR",
                "message", "Error interno del servidor. Por favor, contacta al soporte si el problema persiste.",
                "timestamp", LocalDateTime.now(),
                "path", exchange.getRequest().getURI().getPath()
            ));
    }
}

