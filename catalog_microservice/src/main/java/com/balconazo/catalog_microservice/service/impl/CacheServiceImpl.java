package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.service.CacheService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

/**
 * Implementación del servicio de caché usando Redis
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CacheServiceImpl implements CacheService {

    private final RedisTemplate<String, Object> redisTemplate;

    @Override
    public void put(String key, Object value, long ttlSeconds) {
        try {
            redisTemplate.opsForValue().set(key, value, ttlSeconds, TimeUnit.SECONDS);
            log.debug("Cached key '{}' with TTL {} seconds", key, ttlSeconds);
        } catch (Exception e) {
            log.error("Error caching key '{}': {}", key, e.getMessage());
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T get(String key, Class<T> type) {
        try {
            Object value = redisTemplate.opsForValue().get(key);
            if (value != null) {
                log.debug("Cache hit for key '{}'", key);
                return (T) value;
            }
            log.debug("Cache miss for key '{}'", key);
            return null;
        } catch (Exception e) {
            log.error("Error getting cached key '{}': {}", key, e.getMessage());
            return null;
        }
    }

    @Override
    public void delete(String key) {
        try {
            redisTemplate.delete(key);
            log.debug("Deleted cache key '{}'", key);
        } catch (Exception e) {
            log.error("Error deleting key '{}': {}", key, e.getMessage());
        }
    }

    @Override
    public void clear() {
        try {
            redisTemplate.getConnectionFactory().getConnection().flushAll();
            log.info("Cache cleared");
        } catch (Exception e) {
            log.error("Error clearing cache: {}", e.getMessage());
        }
    }

    @Override
    public boolean exists(String key) {
        try {
            Boolean exists = redisTemplate.hasKey(key);
            return exists != null && exists;
        } catch (Exception e) {
            log.error("Error checking if key '{}' exists: {}", key, e.getMessage());
            return false;
        }
    }
}

