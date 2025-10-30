package com.balconazo.booking_microservice.controller;

import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;
import com.balconazo.booking_microservice.service.BookingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/booking/bookings")
@RequiredArgsConstructor
@Slf4j
public class BookingController {

    private final BookingService bookingService;

    @PostMapping
    public ResponseEntity<BookingDTO> createBooking(@Valid @RequestBody CreateBookingDTO createBookingDTO) {
        log.info("📥 POST /api/booking/bookings - Crear reserva");
        BookingDTO booking = bookingService.createBooking(createBookingDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(booking);
    }

    @PostMapping("/{bookingId}/confirm")
    public ResponseEntity<BookingDTO> confirmBooking(
            @PathVariable UUID bookingId,
            @RequestParam String paymentIntentId) {
        log.info("📥 POST /api/booking/bookings/{}/confirm", bookingId);
        BookingDTO booking = bookingService.confirmBooking(bookingId, paymentIntentId);
        return ResponseEntity.ok(booking);
    }

    @PostMapping("/{bookingId}/cancel")
    public ResponseEntity<BookingDTO> cancelBooking(
            @PathVariable UUID bookingId,
            @RequestParam String reason) {
        log.info("📥 POST /api/booking/bookings/{}/cancel", bookingId);
        BookingDTO booking = bookingService.cancelBooking(bookingId, reason);
        return ResponseEntity.ok(booking);
    }

    @PostMapping("/{bookingId}/complete")
    public ResponseEntity<BookingDTO> completeBooking(@PathVariable UUID bookingId) {
        log.info("📥 POST /api/booking/bookings/{}/complete", bookingId);
        BookingDTO booking = bookingService.completeBooking(bookingId);
        return ResponseEntity.ok(booking);
    }

    @GetMapping("/{bookingId}")
    public ResponseEntity<BookingDTO> getBookingById(@PathVariable UUID bookingId) {
        log.info("📥 GET /api/booking/bookings/{}", bookingId);
        BookingDTO booking = bookingService.getBookingById(bookingId);
        return ResponseEntity.ok(booking);
    }

    @GetMapping
    public ResponseEntity<List<BookingDTO>> getBookings(@RequestParam(required = false) UUID guestId) {
        log.info("📥 GET /api/booking/bookings?guestId={}", guestId);

        if (guestId != null) {
            List<BookingDTO> bookings = bookingService.getBookingsByGuest(guestId);
            return ResponseEntity.ok(bookings);
        }

        return ResponseEntity.badRequest().build();
    }

    @GetMapping("/space/{spaceId}")
    public ResponseEntity<List<BookingDTO>> getBookingsBySpace(@PathVariable UUID spaceId) {
        log.info("📥 GET /api/booking/bookings/space/{}", spaceId);
        List<BookingDTO> bookings = bookingService.getBookingsBySpace(spaceId);
        return ResponseEntity.ok(bookings);
    }

    @GetMapping("/guest/{guestId}")
    public ResponseEntity<List<BookingDTO>> getBookingsByGuest(@PathVariable UUID guestId) {
        log.info("📥 GET /api/booking/bookings/guest/{}", guestId);
        List<BookingDTO> bookings = bookingService.getBookingsByGuest(guestId);
        return ResponseEntity.ok(bookings);
    }
}

