package com.balconazo.catalog_microservice.service.impl;

import com.balconazo.catalog_microservice.exception.BusinessValidationException;
import com.balconazo.catalog_microservice.service.StorageService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
public class LocalStorageService implements StorageService {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    @Value("${app.base-url:http://localhost:8085}")
    private String baseUrl;

    private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("jpg", "jpeg", "png", "webp");
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

    @Override
    public String store(MultipartFile file, String folder) {
        if (!isValidImage(file)) {
            throw new BusinessValidationException("Archivo inválido. Solo se permiten imágenes JPG, PNG o WEBP menores a 5MB");
        }

        try {
            // Crear directorio si no existe
            Path uploadPath = Paths.get(uploadDir, folder);
            Files.createDirectories(uploadPath);

            // Generar nombre único
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".")
                ? originalFilename.substring(originalFilename.lastIndexOf("."))
                : ".jpg";
            String filename = UUID.randomUUID().toString() + extension;

            // Guardar archivo
            Path destinationFile = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), destinationFile, StandardCopyOption.REPLACE_EXISTING);

            // Retornar URL pública
            String url = baseUrl + "/uploads/" + folder + "/" + filename;
            log.info("Imagen guardada: {}", url);
            return url;

        } catch (IOException e) {
            log.error("Error al guardar imagen", e);
            throw new BusinessValidationException("Error al guardar la imagen");
        }
    }

    @Override
    public void delete(String url) {
        try {
            if (url == null || !url.contains("/uploads/")) {
                return;
            }

            // Extraer path relativo de la URL
            String relativePath = url.substring(url.indexOf("/uploads/") + 9);
            Path filePath = Paths.get(uploadDir, relativePath);

            Files.deleteIfExists(filePath);
            log.info("Imagen eliminada: {}", url);

        } catch (IOException e) {
            log.warn("No se pudo eliminar imagen: {}", url, e);
        }
    }

    @Override
    public boolean isValidImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return false;
        }

        // Verificar tamaño
        if (file.getSize() > MAX_FILE_SIZE) {
            return false;
        }

        // Verificar extensión
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            return false;
        }

        String extension = originalFilename.substring(originalFilename.lastIndexOf(".") + 1).toLowerCase();
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            return false;
        }

        // Verificar content type
        String contentType = file.getContentType();
        return contentType != null && contentType.startsWith("image/");
    }
}

