package com.balconazo.catalog_microservice.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;

/**
 * Configuración de seguridad para Catalog Service
 *
 * - Valida JWT en todas las rutas /api/catalog/**
 * - El filtro JWT se ejecuta ANTES de la validación del DTO
 * - Si no hay JWT o es inválido → 401 UNAUTHORIZED
 * - Si JWT válido → continúa al controlador
 */
@Configuration
@EnableWebSecurity
@Slf4j
public class SecurityConfig {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Bean
    public BCryptPasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * Configuración del filtro de seguridad
     * @Order(1) asegura que se ejecute ANTES de otros filtros
     */
    @Bean
    @Order(1)
    public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthenticationFilter jwtFilter) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Permitir actuator para health checks
                .requestMatchers("/actuator/**").permitAll()
                // Permitir GET público para listar y ver espacios (sin autenticación)
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/catalog/spaces/**").permitAll()
                // Todas las demás rutas de API requieren autenticación (POST, PUT, DELETE)
                .requestMatchers("/api/catalog/**").authenticated()
                .anyRequest().permitAll()
            )
            // Agregar filtro JWT ANTES del UsernamePasswordAuthenticationFilter
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    /**
     * Filtro de autenticación JWT
     * Se ejecuta ANTES de validar el DTO
     */
    @Component
    @Slf4j
    public static class JwtAuthenticationFilter extends OncePerRequestFilter {

        @Value("${jwt.secret}")
        private String jwtSecret;

        @Override
        protected void doFilterInternal(HttpServletRequest request,
                                        HttpServletResponse response,
                                        FilterChain filterChain)
                throws ServletException, IOException {

            String path = request.getRequestURI();
            String method = request.getMethod();

            // Solo aplicar a rutas /api/catalog/**
            if (!path.startsWith("/api/catalog/")) {
                filterChain.doFilter(request, response);
                return;
            }

            String token = extractToken(request);

            // Para métodos GET: token es opcional, pero si está presente lo validamos
            if ("GET".equalsIgnoreCase(method)) {
                if (token != null) {
                    try {
                        // Validar JWT si está presente
                        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
                        Claims claims = Jwts.parser()
                            .verifyWith(key)
                            .build()
                            .parseSignedClaims(token)
                            .getPayload();

                        String userId = claims.getSubject();
                        String role = claims.get("role", String.class);

                        log.debug("✅ JWT validated for GET - userId: {}, role: {}", userId, role);

                        // Crear autenticación
                        UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(
                                userId,
                                null,
                                Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role))
                            );

                        SecurityContextHolder.getContext().setAuthentication(authentication);
                    } catch (Exception e) {
                        // Para GET, si el token es inválido, simplemente ignorarlo y continuar sin auth
                        log.warn("⚠️ Invalid JWT in GET request (continuing without auth): {}", e.getMessage());
                        SecurityContextHolder.clearContext();
                    }
                }
                // Continuar sin importar si hay token o no (GET es público)
                filterChain.doFilter(request, response);
                return;
            }

            // Para POST/PUT/DELETE: JWT es OBLIGATORIO
            try {
                if (token == null) {
                    log.warn("❌ No JWT token found in {} request to: {}", method, path);
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Missing JWT token");
                    return;
                }

                log.info("🔍 Validando JWT para {} {}", method, path);
                log.info("🔑 Token (primeros 50 chars): {}...", token.substring(0, Math.min(50, token.length())));
                log.info("🔐 JWT Secret length: {}", jwtSecret.length());

                // Validar y parsear JWT
                SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
                Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

                String userId = claims.getSubject();
                String role = claims.get("role", String.class);
                String email = claims.get("email", String.class);

                log.info("✅ JWT validated for {} - userId: {}, role: {}, email: {}", method, userId, role, email);

                // Crear autenticación
                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                        userId,
                        null,
                        Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role))
                    );

                SecurityContextHolder.getContext().setAuthentication(authentication);

                // Continuar con la cadena de filtros
                filterChain.doFilter(request, response);

            } catch (Exception e) {
                log.error("❌ JWT validation error for {} {}", method, path);
                log.error("❌ Exception type: {}", e.getClass().getName());
                log.error("❌ Error message: {}", e.getMessage());
                log.error("❌ Stack trace:", e);
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token");
            }
        }

        private String extractToken(HttpServletRequest request) {
            String authHeader = request.getHeader("Authorization");

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                return authHeader.substring(7);
            }

            return null;
        }
    }
}

