package com.balconazo.catalog_microservice.config;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

/**
 * Componente de prueba para verificar conexión a Redis
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RedisTest {

    private final StringRedisTemplate redisTemplate;

    @PostConstruct
    public void checkRedis() {
        try {
            // Prueba de escritura
            redisTemplate.opsForValue().set("testKey", "ok");

            // Prueba de lectura
            String value = redisTemplate.opsForValue().get("testKey");

            log.info("✅ Redis test -> {}", value);
            log.info("✅ Redis conectado correctamente en localhost:6379");

            // Limpiar
            redisTemplate.delete("testKey");

        } catch (Exception e) {
            log.error("❌ Error al conectar con Redis: {}", e.getMessage());
        }
    }
}

