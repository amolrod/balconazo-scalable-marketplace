package com.balconazo.catalog_microservice.exception;

public class DuplicateResourceException extends CatalogException {
    public DuplicateResourceException(String resource, String field, Object value) {
        super(String.format("%s con %s '%s' ya existe", resource, field, value));
    }

    public DuplicateResourceException(String message) {
        super(message);
    }
}

