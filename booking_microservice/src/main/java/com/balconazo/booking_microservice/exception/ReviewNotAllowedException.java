package com.balconazo.booking_microservice.exception;

/**
 * Excepción lanzada cuando un usuario intenta crear una review
 * para una reserva que no está en estado COMPLETED
 */
public class ReviewNotAllowedException extends RuntimeException {
    public ReviewNotAllowedException(String message) {
        super(message);
    }
}
