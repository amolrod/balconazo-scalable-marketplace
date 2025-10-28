package com.balconazo.booking_microservice.exception;

public class SpaceNotAvailableException extends RuntimeException {
    public SpaceNotAvailableException(String message) {
        super(message);
    }
}

