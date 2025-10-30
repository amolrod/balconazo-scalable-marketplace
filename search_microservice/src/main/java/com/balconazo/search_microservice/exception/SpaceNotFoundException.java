package com.balconazo.search_microservice.exception;

public class SpaceNotFoundException extends RuntimeException {
    public SpaceNotFoundException(String spaceId) {
        super("Space not found: " + spaceId);
    }
}

