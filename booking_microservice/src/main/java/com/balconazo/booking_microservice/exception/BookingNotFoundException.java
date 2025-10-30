package com.balconazo.booking_microservice.exception;

import java.util.UUID;

public class BookingNotFoundException extends RuntimeException {
    private final UUID bookingId;

    public BookingNotFoundException(UUID bookingId) {
        super("Reserva no encontrada con ID: " + bookingId);
        this.bookingId = bookingId;
    }

    public UUID getBookingId() {
        return bookingId;
    }
}

