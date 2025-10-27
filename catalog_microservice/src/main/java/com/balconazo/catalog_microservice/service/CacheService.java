package com.balconazo.catalog_microservice.service;

/**
 * Servicio de caché Redis para optimizar consultas frecuentes
 */
public interface CacheService {

    /**
     * Guarda un valor en caché con TTL
     */
    void put(String key, Object value, long ttlSeconds);

    /**
     * Obtiene un valor del caché
     */
    <T> T get(String key, Class<T> type);

    /**
     * Elimina una clave del caché
     */
    void delete(String key);

    /**
     * Limpia todo el caché
     */
    void clear();

    /**
     * Verifica si una clave existe
     */
    boolean exists(String key);
}

