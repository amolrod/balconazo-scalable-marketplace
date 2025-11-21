package com.balconazo.booking_microservice.config;

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

/**
 * Configuración de seguridad para Booking Service
 *
 * - Valida JWT en todas las rutas /api/bookings/**
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
     */
    @Bean
    @Order(1)
    public SecurityFilterChain filterChain(HttpSecurity http, JwtAuthenticationFilter jwtFilter) throws Exception {
        return http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.disable()) // CORS manejado por el Gateway
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Permitir actuator para health checks
                .requestMatchers("/actuator/**").permitAll()
                
                // ============================================
                // REVIEWS - Endpoints públicos (lectura)
                // ============================================
                .requestMatchers("/api/bookings/reviews/space/**").permitAll()  // GET reviews por espacio
                .requestMatchers("/api/bookings/reviews/{id}").permitAll()      // GET review por ID
                
                // ============================================
                // REVIEWS - Endpoints protegidos (escritura y mi data)
                // ============================================
                .requestMatchers("/api/bookings/reviews/my").authenticated()    // GET mis reviews
                .requestMatchers("/api/bookings/reviews").authenticated()       // POST crear review
                
                // ============================================
                // BOOKINGS - Todos protegidos
                // ============================================
                .requestMatchers("/api/bookings/**").authenticated()
                
                .anyRequest().permitAll()
            )
            // Agregar filtro JWT ANTES del UsernamePasswordAuthenticationFilter
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    // CORS desactivado - el API Gateway maneja CORS
    /*
    @Bean
    public org.springframework.web.cors.CorsConfigurationSource corsConfigurationSource() {
        org.springframework.web.cors.CorsConfiguration configuration = new org.springframework.web.cors.CorsConfiguration();
        configuration.setAllowedOrigins(java.util.Arrays.asList("http://localhost:4200", "http://localhost:3000"));
        configuration.setAllowedMethods(java.util.Arrays.asList("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        configuration.setAllowedHeaders(java.util.Arrays.asList("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);
        
        org.springframework.web.cors.UrlBasedCorsConfigurationSource source = new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
    */

    /**
     * Filtro de autenticación JWT
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
            
            log.info("🔍 JwtAuthenticationFilter - {} {}", method, path);

            // ============================================
            // RUTAS PÚBLICAS (no requieren JWT)
            // ============================================
            if (path.startsWith("/api/bookings/reviews/space/")   // GET reviews por espacio
                || path.matches("/api/bookings/reviews/[0-9a-f-]+")  // GET review por ID (UUID)
                || path.startsWith("/actuator/")) {
                
                log.info("🔓 Path {} es público, skipping JWT filter", path);
                filterChain.doFilter(request, response);
                return;
            }

            // ============================================
            // RUTAS QUE NO SON DE BOOKINGS (skip)
            // ============================================
            if (!path.startsWith("/api/bookings")) {
                log.info("🔓 Path {} no es de bookings, skipping filter", path);
                filterChain.doFilter(request, response);
                return;
            }

            // ============================================
            // RUTAS PROTEGIDAS (requieren JWT)
            // ============================================
            try {
                String token = extractToken(request);

                // Si no hay token, retornar 401 UNAUTHORIZED
                if (token == null) {
                    log.warn("⚠️ No JWT token found in request to: {} - returning 401 UNAUTHORIZED", path);
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "JWT token is required");
                    return;
                }

                // Si hay token, validarlo y parsear
                SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
                Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

                String userId = claims.getSubject();
                Boolean isHost = claims.get("isHost", Boolean.class);
                Boolean isGuest = claims.get("isGuest", Boolean.class);

                log.debug("JWT validated - userId: {}, isHost: {}, isGuest: {}", userId, isHost, isGuest);

                // Crear authorities dinámicamente basados en isHost e isGuest
                java.util.List<SimpleGrantedAuthority> authorities = new java.util.ArrayList<>();
                if (Boolean.TRUE.equals(isHost)) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_HOST"));
                }
                if (Boolean.TRUE.equals(isGuest)) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_GUEST"));
                }

                // Crear autenticación
                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                        userId,
                        null,
                        authorities
                    );

                SecurityContextHolder.getContext().setAuthentication(authentication);

                // Continuar con la cadena de filtros
                filterChain.doFilter(request, response);

            } catch (Exception e) {
                log.error("❌ JWT validation error for path: {} - Error: {} - Message: {}", path, e.getClass().getSimpleName(), e.getMessage(), e);
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token: " + e.getMessage());
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
