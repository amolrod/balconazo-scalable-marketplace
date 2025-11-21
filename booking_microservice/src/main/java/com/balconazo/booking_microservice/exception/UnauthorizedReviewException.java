package com.balconazo.booking_microservice.exception;

/**
 * Excepción lanzada cuando un usuario intenta crear una reseña
 * sin tener autorización (no es el dueño de la reserva)
 */
public class UnauthorizedReviewException extends RuntimeException {
    public UnauthorizedReviewException(String message) {
        super(message);
    }
}
