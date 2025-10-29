package com.balconazo.auth.controller;

import com.balconazo.auth.dto.LoginRequest;
import com.balconazo.auth.dto.LoginResponse;
import com.balconazo.auth.dto.RegisterRequest;
import com.balconazo.auth.dto.UserResponse;
import com.balconazo.auth.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        log.info("POST /api/auth/register - Email: {}", request.getEmail());
        UserResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        log.info("POST /api/auth/login - Email: {}", request.getEmail());
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<LoginResponse> refresh(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        log.info("POST /api/auth/refresh");

        if (refreshToken == null || refreshToken.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        LoginResponse response = authService.refreshToken(refreshToken);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        log.info("POST /api/auth/logout - UserId: {}", userId);
        authService.logout(userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> getCurrentUser() {
        // Obtener autenticación del contexto de seguridad
        var authentication = org.springframework.security.core.context.SecurityContextHolder
                .getContext()
                .getAuthentication();

        // Verificar que hay autenticación válida
        if (authentication == null || !authentication.isAuthenticated() ||
            authentication.getPrincipal() instanceof String &&
            "anonymousUser".equals(authentication.getPrincipal())) {
            log.warn("GET /api/auth/me called without valid authentication");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String userId = (String) authentication.getPrincipal();
        log.info("GET /api/auth/me - UserId: {}", userId);

        UserResponse response = authService.getUserById(userId);
        return ResponseEntity.ok(response);
    }
}

