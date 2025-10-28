package com.balconazo.auth.service;

import com.balconazo.auth.dto.LoginRequest;
import com.balconazo.auth.dto.LoginResponse;
import com.balconazo.auth.dto.RegisterRequest;
import com.balconazo.auth.dto.UserResponse;
import com.balconazo.auth.entity.RefreshToken;
import com.balconazo.auth.entity.User;
import com.balconazo.auth.repository.RefreshTokenRepository;
import com.balconazo.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Value("${jwt.expiration}")
    private Long jwtExpiration;

    @Value("${jwt.refresh-expiration}")
    private Long refreshExpiration;

    @Transactional
    public UserResponse register(RegisterRequest request) {
        log.info("Registrando nuevo usuario: {}", request.getEmail());

        // Verificar si el email ya existe
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("El email ya está registrado");
        }

        // Crear usuario
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .active(true)
                .build();

        user = userRepository.save(user);
        log.info("Usuario registrado exitosamente con ID: {}", user.getId());

        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .role(user.getRole().name())
                .active(user.getActive())
                .createdAt(user.getCreatedAt())
                .build();
    }

    @Transactional
    public LoginResponse login(LoginRequest request) {
        log.info("Intento de login para: {}", request.getEmail());

        // Buscar usuario por email
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Credenciales inválidas"));

        // Verificar contraseña
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            log.warn("Contraseña incorrecta para: {}", request.getEmail());
            throw new RuntimeException("Credenciales inválidas");
        }

        // Verificar que el usuario esté activo
        if (!user.getActive()) {
            throw new RuntimeException("Usuario inactivo");
        }

        // Generar tokens
        String accessToken = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole().name());
        String refreshToken = jwtService.generateRefreshToken(user.getId());

        // Guardar refresh token
        RefreshToken refreshTokenEntity = RefreshToken.builder()
                .userId(user.getId())
                .token(refreshToken)
                .expiresAt(LocalDateTime.now().plusSeconds(refreshExpiration / 1000))
                .build();
        refreshTokenRepository.save(refreshTokenEntity);

        log.info("Login exitoso para usuario: {}", user.getEmail());

        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public LoginResponse refreshToken(String refreshToken) {
        log.info("Intentando refrescar token");

        // Buscar refresh token
        RefreshToken tokenEntity = refreshTokenRepository.findByToken(refreshToken)
                .orElseThrow(() -> new RuntimeException("Refresh token inválido"));

        // Verificar que no esté expirado
        if (tokenEntity.isExpired()) {
            refreshTokenRepository.delete(tokenEntity);
            throw new RuntimeException("Refresh token expirado");
        }

        // Buscar usuario
        User user = userRepository.findById(tokenEntity.getUserId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        // Generar nuevo access token
        String newAccessToken = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole().name());

        log.info("Token refrescado para usuario: {}", user.getEmail());

        return LoginResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtExpiration / 1000)
                .userId(user.getId())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }

    @Transactional
    public void logout(String userId) {
        log.info("Logout para usuario ID: {}", userId);
        refreshTokenRepository.deleteByUserId(userId);
    }

    public UserResponse getUserById(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        return UserResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .role(user.getRole().name())
                .active(user.getActive())
                .createdAt(user.getCreatedAt())
                .build();
    }
}

