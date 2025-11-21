package com.balconazo.booking_microservice.exception;

/**
 * Excepción lanzada cuando ya existe una reseña para una reserva
 */
public class DuplicateReviewException extends RuntimeException {
    public DuplicateReviewException(String message) {
        super(message);
    }
}
