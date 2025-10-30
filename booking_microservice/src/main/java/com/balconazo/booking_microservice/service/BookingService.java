package com.balconazo.booking_microservice.service;

import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;

import java.util.List;
import java.util.UUID;

public interface BookingService {

    BookingDTO createBooking(CreateBookingDTO createBookingDTO);

    BookingDTO confirmBooking(UUID bookingId, String paymentIntentId);

    BookingDTO cancelBooking(UUID bookingId, String reason);

    BookingDTO completeBooking(UUID bookingId);

    BookingDTO getBookingById(UUID bookingId);

    List<BookingDTO> getBookingsByGuest(UUID guestId);

    List<BookingDTO> getBookingsBySpace(UUID spaceId);

    void processCompletedBookings();
}

