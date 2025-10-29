package com.balconazo.gateway.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.ReactiveAuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.authentication.AuthenticationWebFilter;
import org.springframework.security.web.server.authentication.ServerAuthenticationConverter;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;

/**
 * Configuración de seguridad para API Gateway
 *
 * - Rutas públicas: /api/auth/**, /api/search/** (solo lectura)
 * - Rutas protegidas: /api/catalog/**, /api/booking/** (requieren JWT)
 * - Validación de JWT sin consultar BD (stateless)
 * - CORS habilitado
 */
@Configuration
@EnableWebFluxSecurity
@Slf4j
public class SecurityConfig {

    @Value("${jwt.secret}")
    private String jwtSecret;

    /**
     * Configuración del filtro de seguridad
     */
    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
            .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
            .authorizeExchange(exchanges -> exchanges
                // Rutas públicas (sin autenticación)
                .pathMatchers("/").permitAll()
                .pathMatchers("/api/auth/**").permitAll()
                .pathMatchers("/api/search/**").permitAll()
                .pathMatchers("/actuator/**").permitAll()
                .pathMatchers("/fallback/**").permitAll()

                // Rutas protegidas (requieren JWT)
                .pathMatchers("/api/catalog/**").authenticated()
                .pathMatchers("/api/booking/**").authenticated()

                // Cualquier otra ruta API requiere autenticación
                .pathMatchers("/api/**").authenticated()

                // Otras rutas son públicas
                .anyExchange().permitAll()
            )
            .addFilterAt(authenticationWebFilter(), SecurityWebFiltersOrder.AUTHENTICATION)
            .build();
    }

    /**
     * Filtro de autenticación JWT
     */
    private AuthenticationWebFilter authenticationWebFilter() {
        AuthenticationWebFilter filter = new AuthenticationWebFilter(authenticationManager());
        filter.setServerAuthenticationConverter(jwtAuthenticationConverter());
        return filter;
    }

    /**
     * Convertidor de JWT a Authentication
     */
    @Bean
    public ServerAuthenticationConverter jwtAuthenticationConverter() {
        return exchange -> {
            String token = extractToken(exchange);
            if (token == null) {
                return Mono.empty();
            }
            return Mono.just(new UsernamePasswordAuthenticationToken(token, token));
        };
    }

    /**
     * Manager de autenticación (valida JWT)
     */
    @Bean
    public ReactiveAuthenticationManager authenticationManager() {
        return authentication -> {
            String token = authentication.getCredentials().toString();

            try {
                SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));

                Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

                String userId = claims.getSubject();
                String role = claims.get("role", String.class);

                log.debug("JWT validado correctamente - userId: {}, role: {}", userId, role);

                List<SimpleGrantedAuthority> authorities = Collections.singletonList(
                    new SimpleGrantedAuthority("ROLE_" + role)
                );

                Authentication auth = new UsernamePasswordAuthenticationToken(
                    userId,
                    null,
                    authorities
                );

                return Mono.just(auth);

            } catch (Exception e) {
                log.error("Error validando JWT: {}", e.getMessage());
                return Mono.empty();
            }
        };
    }

    /**
     * Extrae el token JWT del header Authorization
     */
    private String extractToken(ServerWebExchange exchange) {
        String authHeader = exchange.getRequest().getHeaders().getFirst("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }

        return null;
    }
}

