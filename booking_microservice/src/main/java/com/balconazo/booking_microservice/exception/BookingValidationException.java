package com.balconazo.booking_microservice.exception;

public class BookingValidationException extends RuntimeException {
    public BookingValidationException(String message) {
        super(message);
    }
}

