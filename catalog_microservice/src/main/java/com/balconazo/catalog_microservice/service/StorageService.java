package com.balconazo.catalog_microservice.service;

import org.springframework.web.multipart.MultipartFile;

public interface StorageService {

    /**
     * Guardar imagen y retornar la URL
     */
    String store(MultipartFile file, String folder);

    /**
     * Eliminar imagen por URL
     */
    void delete(String url);

    /**
     * Validar que el archivo sea una imagen válida
     */
    boolean isValidImage(MultipartFile file);
}

