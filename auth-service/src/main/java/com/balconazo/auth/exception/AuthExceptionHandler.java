package com.balconazo.auth.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Manejador global de excepciones para Auth Service
 *
 * Convierte excepciones de seguridad en respuestas HTTP apropiadas
 * en lugar de dejar que se conviertan en 500.
 */
@RestControllerAdvice
@Slf4j
public class AuthExceptionHandler {

    /**
     * Maneja BadCredentialsException (credenciales inválidas)
     * Devuelve 401 Unauthorized en lugar de 500
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, Object>> handleBadCredentials(BadCredentialsException ex) {
        log.warn("Bad credentials attempt: {}", ex.getMessage());

        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", LocalDateTime.now());
        body.put("status", HttpStatus.UNAUTHORIZED.value());
        body.put("error", "Unauthorized");
        body.put("message", "Invalid email or password");

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body);
    }

    /**
     * Maneja cualquier otra RuntimeException no capturada
     * Verifica si es "Usuario no encontrado" para devolver 404 en lugar de 500
     */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException ex) {
        log.error("Runtime exception: {}", ex.getMessage());

        Map<String, Object> body = new HashMap<>();
        body.put("timestamp", LocalDateTime.now());

        // Si es "Usuario no encontrado", devolver 404
        if (ex.getMessage() != null && ex.getMessage().contains("Usuario no encontrado")) {
            body.put("status", HttpStatus.NOT_FOUND.value());
            body.put("error", "Not Found");
            body.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body);
        }

        // Otros errores → 500
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        body.put("error", "Internal Server Error");
        body.put("message", "An unexpected error occurred");

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}

