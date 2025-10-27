package com.balconazo.catalog_microservice.exception;

public class ResourceNotFoundException extends CatalogException {
    public ResourceNotFoundException(String resource, Object id) {
        super(String.format("%s con id '%s' no encontrado", resource, id));
    }

    public ResourceNotFoundException(String message) {
        super(message);
    }
}

