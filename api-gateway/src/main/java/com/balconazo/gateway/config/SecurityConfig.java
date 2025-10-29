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
            // Configuración OAuth2 Resource Server para JWT
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(jwt -> jwt
                    .jwtDecoder(jwtDecoder())
                )
            )
            .build();
    }

    /**
     * Decoder de JWT personalizado con secret key compartido
     */
    @Bean
    public org.springframework.security.oauth2.jwt.ReactiveJwtDecoder jwtDecoder() {
        return token -> {
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

                // Crear JWT de Spring Security
                return Mono.just(org.springframework.security.oauth2.jwt.Jwt.withTokenValue(token)
                    .header("alg", "HS512")
                    .claim("sub", userId)
                    .claim("role", role)
                    .claim("userId", claims.get("userId"))
                    .claim("email", claims.get("email"))
                    .build());

            } catch (Exception e) {
                log.error("Error validando JWT: {}", e.getMessage());
                return Mono.error(new org.springframework.security.oauth2.jwt.JwtException("Invalid JWT token", e));
            }
        };
    }
}

