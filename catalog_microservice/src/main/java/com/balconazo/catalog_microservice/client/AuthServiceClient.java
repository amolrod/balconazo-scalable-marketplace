package com.balconazo.catalog_microservice.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.UUID;

/**
 * Cliente para comunicarse con Auth Service
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AuthServiceClient {

    private final RestTemplate restTemplate;

    @Value("${auth.service.url:http://localhost:8084}")
    private String authServiceUrl;

    /**
     * Promociona un usuario a host
     * @param userId ID del usuario
     */
    public void promoteToHost(UUID userId) {
        try {
            String url = authServiceUrl + "/api/auth/users/" + userId + "/promote-to-host";
            restTemplate.put(url, null);
            log.info("Usuario {} promovido a host exitosamente", userId);
        } catch (Exception e) {
            log.error("Error al promover usuario {} a host: {}", userId, e.getMessage());
            // No lanzamos excepción para no bloquear la creación del espacio
        }
    }
}
