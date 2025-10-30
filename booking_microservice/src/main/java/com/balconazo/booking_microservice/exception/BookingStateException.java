package com.balconazo.booking_microservice.exception;

public class BookingStateException extends RuntimeException {
    private final String currentState;
    private final String requiredState;

    public BookingStateException(String currentState, String requiredState) {
        super(String.format("Estado inválido: la reserva está en estado '%s', se requiere '%s'",
            currentState, requiredState));
        this.currentState = currentState;
        this.requiredState = requiredState;
    }

    public String getCurrentState() {
        return currentState;
    }

    public String getRequiredState() {
        return requiredState;
    }
}

