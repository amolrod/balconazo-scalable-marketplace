package com.balconazo.booking_microservice.service.impl;

import com.balconazo.booking_microservice.constants.BookingConstants;
import com.balconazo.booking_microservice.dto.BookingDTO;
import com.balconazo.booking_microservice.dto.CreateBookingDTO;
import com.balconazo.booking_microservice.entity.BookingEntity;
import com.balconazo.booking_microservice.exception.BookingValidationException;
import com.balconazo.booking_microservice.exception.SpaceNotAvailableException;
import com.balconazo.booking_microservice.kafka.event.BookingCancelledEvent;
import com.balconazo.booking_microservice.kafka.event.BookingConfirmedEvent;
import com.balconazo.booking_microservice.kafka.event.BookingCreatedEvent;
import com.balconazo.booking_microservice.kafka.producer.OutboxService;
import com.balconazo.booking_microservice.mapper.BookingMapper;
import com.balconazo.booking_microservice.repository.BookingRepository;
import com.balconazo.booking_microservice.service.BookingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BookingServiceImpl implements BookingService {

    private final BookingRepository bookingRepository;
    private final BookingMapper bookingMapper;
    private final OutboxService outboxService;

    @Override
    @Transactional
    public BookingDTO createBooking(CreateBookingDTO createBookingDTO) {
        log.info("🔵 Creando nueva reserva para espacio: {}", createBookingDTO.getSpaceId());

        // Validaciones de negocio
        validateBookingDates(createBookingDTO);
        checkAvailability(createBookingDTO);

        // Crear entidad
        BookingEntity booking = bookingMapper.toEntity(createBookingDTO);
        booking.setStatus(BookingEntity.BookingStatus.pending);
        booking.setPaymentStatus(BookingEntity.PaymentStatus.pending);

        // Calcular precio (simulado - debería venir del servicio de pricing)
        booking.setTotalPriceCents(calculateTotalPrice(createBookingDTO));

        // Guardar
        BookingEntity savedBooking = bookingRepository.save(booking);
        log.info("✅ Reserva creada con ID: {}", savedBooking.getId());

        // Publicar evento vía Outbox
        publishBookingCreatedEvent(savedBooking);

        return bookingMapper.toDTO(savedBooking);
    }

    @Override
    @Transactional
    public BookingDTO confirmBooking(UUID bookingId, String paymentIntentId) {
        log.info("🔵 Confirmando reserva: {} con paymentIntentId: {}", bookingId, paymentIntentId);

        BookingEntity booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new com.balconazo.booking_microservice.exception.BookingNotFoundException(bookingId));

        // Validar estado actual
        if (booking.getStatus() != BookingEntity.BookingStatus.pending) {
            throw new com.balconazo.booking_microservice.exception.BookingStateException(
                booking.getStatus().name(),
                BookingEntity.BookingStatus.pending.name()
            );
        }

        // Actualizar estado
        booking.setStatus(BookingEntity.BookingStatus.confirmed);
        booking.setPaymentStatus(BookingEntity.PaymentStatus.succeeded);
        booking.setPaymentIntentId(paymentIntentId);

        BookingEntity updatedBooking = bookingRepository.save(booking);
        log.info("✅ Reserva confirmada: {} - Estado: {} -> {}",
            bookingId, BookingEntity.BookingStatus.pending, BookingEntity.BookingStatus.confirmed);

        // Publicar evento vía Outbox
        publishBookingConfirmedEvent(updatedBooking);

        return bookingMapper.toDTO(updatedBooking);
    }

    @Override
    @Transactional
    public BookingDTO cancelBooking(UUID bookingId, String reason) {
        log.info("🔵 Cancelando reserva: {} - Razón: {}", bookingId, reason);

        BookingEntity booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new com.balconazo.booking_microservice.exception.BookingNotFoundException(bookingId));

        // Validar que no esté ya cancelada
        if (booking.getStatus() == BookingEntity.BookingStatus.cancelled) {
            throw new com.balconazo.booking_microservice.exception.BookingStateException(
                booking.getStatus().name(),
                "pending o confirmed"
            );
        }

        // Validar que no esté completada
        if (booking.getStatus() == BookingEntity.BookingStatus.completed) {
            throw new com.balconazo.booking_microservice.exception.BookingStateException(
                booking.getStatus().name(),
                "pending o confirmed"
            );
        }

        // Validar deadline de cancelación
        validateCancellationDeadline(booking);

        // Actualizar estado
        booking.setStatus(BookingEntity.BookingStatus.cancelled);
        booking.setCancellationReason(reason);

        BookingEntity cancelledBooking = bookingRepository.save(booking);
        log.info("✅ Reserva cancelada: {} - Estado anterior: {}", bookingId, booking.getStatus());

        // Publicar evento vía Outbox
        publishBookingCancelledEvent(cancelledBooking, reason);

        return bookingMapper.toDTO(cancelledBooking);
    }

    @Override
    @Transactional
    public BookingDTO completeBooking(UUID bookingId) {
        log.info("✅ Completando reserva: {}", bookingId);

        BookingEntity booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new com.balconazo.booking_microservice.exception.BookingNotFoundException(bookingId));

        // Validar que esté confirmada
        if (booking.getStatus() != BookingEntity.BookingStatus.confirmed) {
            throw new com.balconazo.booking_microservice.exception.BookingStateException(
                booking.getStatus().name(),
                BookingEntity.BookingStatus.confirmed.name()
            );
        }

        // Actualizar estado
        booking.setStatus(BookingEntity.BookingStatus.completed);

        BookingEntity completedBooking = bookingRepository.save(booking);
        log.info("✅ Reserva completada: {} - Estado: {} -> {}",
            bookingId, BookingEntity.BookingStatus.confirmed, BookingEntity.BookingStatus.completed);

        return bookingMapper.toDTO(completedBooking);
    }

    @Override
    @Transactional(readOnly = true)
    public BookingDTO getBookingById(UUID bookingId) {
        log.info("🔍 Buscando reserva: {}", bookingId);

        BookingEntity booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new RuntimeException("Reserva no encontrada: " + bookingId));

        return bookingMapper.toDTO(booking);
    }

    @Override
    @Transactional(readOnly = true)
    public List<BookingDTO> getBookingsByGuest(UUID guestId) {
        log.info("🔍 Buscando reservas del huésped: {}", guestId);

        List<BookingEntity> bookings = bookingRepository.findByGuestIdOrderByCreatedAtDesc(guestId);

        return bookings.stream()
                .map(bookingMapper::toDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<BookingDTO> getBookingsBySpace(UUID spaceId) {
        log.info("🔍 Buscando reservas del espacio: {}", spaceId);

        List<BookingEntity> bookings = bookingRepository.findBySpaceIdAndStatusOrderByStartTsAsc(
                spaceId, BookingEntity.BookingStatus.confirmed);

        return bookings.stream()
                .map(bookingMapper::toDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void processCompletedBookings() {
        log.info("🔍 Procesando reservas completadas...");

        List<BookingEntity> completedBookings = bookingRepository
                .findCompletedBookings(LocalDateTime.now());

        for (BookingEntity booking : completedBookings) {
            booking.setStatus(BookingEntity.BookingStatus.completed);
            bookingRepository.save(booking);
            log.info("✅ Reserva marcada como completada: {}", booking.getId());
        }
    }

    // ============================================
    // VALIDACIONES
    // ============================================

    private void validateBookingDates(CreateBookingDTO dto) {
        LocalDateTime now = LocalDateTime.now();

        if (dto.getStartTs().isBefore(now.minusMinutes(5))) { // Margen de 5 min para compensar latencia
            throw new BookingValidationException("La fecha de inicio debe ser futura");
        }

        if (dto.getEndTs().isBefore(dto.getStartTs())) {
            throw new BookingValidationException("La fecha de fin debe ser posterior a la de inicio");
        }

        // Mínimo 4 horas
        long hours = Duration.between(dto.getStartTs(), dto.getEndTs()).toHours();
        if (hours < BookingConstants.MIN_BOOKING_HOURS) {
            throw new BookingValidationException("La reserva debe ser de al menos " + BookingConstants.MIN_BOOKING_HOURS + " horas");
        }

        // Máximo 365 días
        long days = Duration.between(dto.getStartTs(), dto.getEndTs()).toDays();
        if (days > BookingConstants.MAX_BOOKING_DAYS) {
            throw new BookingValidationException("La reserva no puede superar " + BookingConstants.MAX_BOOKING_DAYS + " días");
        }

        // Reservar con al menos 24h de antelación
        long advanceHours = Duration.between(now, dto.getStartTs()).toHours();
        if (advanceHours < BookingConstants.MIN_ADVANCE_HOURS) {
            throw new BookingValidationException("Debes reservar con al menos " + BookingConstants.MIN_ADVANCE_HOURS + " horas de antelación");
        }
    }

    private void checkAvailability(CreateBookingDTO dto) {
        List<BookingEntity> overlapping = bookingRepository.findOverlappingBookings(
                dto.getSpaceId(), dto.getStartTs(), dto.getEndTs());

        if (!overlapping.isEmpty()) {
            BookingEntity existing = overlapping.get(0);
            throw new SpaceNotAvailableException(
                String.format("El espacio no está disponible en esas fechas. Conflicto con reserva #%s del %s al %s",
                    existing.getId(), existing.getStartTs(), existing.getEndTs())
            );
        }
    }

    private void validateCancellationDeadline(BookingEntity booking) {
        LocalDateTime now = LocalDateTime.now();
        long hoursUntilStart = Duration.between(now, booking.getStartTs()).toHours();

        if (hoursUntilStart < BookingConstants.CANCELLATION_DEADLINE_HOURS) {
            throw new BookingValidationException("No se puede cancelar con menos de " +
                    BookingConstants.CANCELLATION_DEADLINE_HOURS + " horas de antelación");
        }
    }

    // ============================================
    // LÓGICA DE PRICING (SIMPLIFICADA)
    // ============================================

    private Integer calculateTotalPrice(CreateBookingDTO dto) {
        // Precio simulado: 100€/día
        long days = Duration.between(dto.getStartTs(), dto.getEndTs()).toDays();
        if (days == 0) days = 1;

        return (int) (days * 10000); // 100€ en centavos
    }

    // ============================================
    // EVENTOS
    // ============================================

    private void publishBookingCreatedEvent(BookingEntity booking) {
        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(booking.getId())
                .spaceId(booking.getSpaceId())
                .guestId(booking.getGuestId())
                .startTs(booking.getStartTs())
                .endTs(booking.getEndTs())
                .numGuests(booking.getNumGuests())
                .totalPriceCents(booking.getTotalPriceCents())
                .occurredAt(LocalDateTime.now())
                .build();

        outboxService.saveEvent("booking", booking.getId(), BookingConstants.EVENT_BOOKING_CREATED, event);
    }

    private void publishBookingConfirmedEvent(BookingEntity booking) {
        BookingConfirmedEvent event = BookingConfirmedEvent.builder()
                .bookingId(booking.getId())
                .spaceId(booking.getSpaceId())
                .guestId(booking.getGuestId())
                .startTs(booking.getStartTs())
                .endTs(booking.getEndTs())
                .totalPriceCents(booking.getTotalPriceCents())
                .paymentIntentId(booking.getPaymentIntentId())
                .occurredAt(LocalDateTime.now())
                .build();

        outboxService.saveEvent("booking", booking.getId(), BookingConstants.EVENT_BOOKING_CONFIRMED, event);
    }

    private void publishBookingCancelledEvent(BookingEntity booking, String reason) {
        BookingCancelledEvent event = BookingCancelledEvent.builder()
                .bookingId(booking.getId())
                .spaceId(booking.getSpaceId())
                .guestId(booking.getGuestId())
                .reason(reason)
                .occurredAt(LocalDateTime.now())
                .build();

        outboxService.saveEvent("booking", booking.getId(), BookingConstants.EVENT_BOOKING_CANCELLED, event);
    }
}
