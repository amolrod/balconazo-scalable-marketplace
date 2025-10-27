package com.balconazo.catalog_microservice.controller;

import com.balconazo.catalog_microservice.service.CacheService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller para probar funcionalidad de Redis
 */
@RestController
@RequestMapping("/api/catalog/cache")
@RequiredArgsConstructor
public class CacheController {

    private final CacheService cacheService;

    /**
     * Guardar valor en caché
     */
    @PostMapping
    public ResponseEntity<Map<String, String>> putCache(
            @RequestParam String key,
            @RequestParam String value,
            @RequestParam(defaultValue = "300") long ttl) {

        cacheService.put(key, value, ttl);

        return ResponseEntity.ok(Map.of(
            "message", "Value cached successfully",
            "key", key,
            "ttl", ttl + "s"
        ));
    }

    /**
     * Obtener valor del caché
     */
    @GetMapping("/{key}")
    public ResponseEntity<Map<String, Object>> getCache(@PathVariable String key) {
        String value = cacheService.get(key, String.class);

        if (value == null) {
            return ResponseEntity.ok(Map.of(
                "key", key,
                "exists", false,
                "value", "null"
            ));
        }

        return ResponseEntity.ok(Map.of(
            "key", key,
            "exists", true,
            "value", value
        ));
    }

    /**
     * Eliminar clave del caché
     */
    @DeleteMapping("/{key}")
    public ResponseEntity<Map<String, String>> deleteCache(@PathVariable String key) {
        cacheService.delete(key);

        return ResponseEntity.ok(Map.of(
            "message", "Key deleted successfully",
            "key", key
        ));
    }

    /**
     * Verificar si clave existe
     */
    @GetMapping("/{key}/exists")
    public ResponseEntity<Map<String, Object>> exists(@PathVariable String key) {
        boolean exists = cacheService.exists(key);

        return ResponseEntity.ok(Map.of(
            "key", key,
            "exists", exists
        ));
    }

    /**
     * Limpiar todo el caché
     */
    @DeleteMapping
    public ResponseEntity<Map<String, String>> clearCache() {
        cacheService.clear();

        return ResponseEntity.ok(Map.of(
            "message", "Cache cleared successfully"
        ));
    }
}

