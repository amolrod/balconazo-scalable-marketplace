package com.balconazo.catalog_microservice.exception;

public class SpaceValidationException extends RuntimeException {
    public SpaceValidationException(String message) {
        super(message);
    }
}

