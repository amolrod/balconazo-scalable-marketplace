package com.balconazo.gateway.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

/**
 * Configuración de seguridad para API Gateway
 *
 * ESTRATEGIA: El Gateway NO valida JWT, solo propaga el header Authorization.
 * Cada microservicio (Catalog, Booking) valida su propio JWT.
 *
 * Ventajas:
 * - Más simple de mantener
 * - Evita duplicación de lógica de validación
 * - Cada micro controla su propia seguridad
 */
@Configuration
@EnableWebFluxSecurity
@Slf4j
public class SecurityConfig {

    /**
     * Configuración del filtro de seguridad
     *
     * El Gateway permite todo el tráfico y propaga headers.
     * Los microservicios deciden si aceptan o rechazan basándose en JWT.
     */
    @Bean
    public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
        log.info("🔓 Configurando Gateway sin validación JWT - los microservicios validarán");

        return http
            .csrf(ServerHttpSecurity.CsrfSpec::disable)
            .cors(cors -> cors.disable()) // CORS se maneja en application.yml
            .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
            .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
            .authorizeExchange(exchanges -> exchanges
                // Permitir todo - los microservicios manejan la autenticación
                .anyExchange().permitAll()
            )
            .build();
    }
}

