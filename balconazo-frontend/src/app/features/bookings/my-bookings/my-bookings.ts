import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { BookingsService, Booking, Review } from '../../../core/services/bookings.service';

@Component({
  selector: 'app-my-bookings',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './my-bookings.html',
  styleUrl: './my-bookings.scss'
})
export class MyBookingsComponent implements OnInit {
  private router = inject(Router);
  private bookingsService = inject(BookingsService);

  bookings: Booking[] = [];
  loading = true;
  error: string | null = null;

  selectedFilter: 'all' | 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED' = 'all';

  showCancelModal = false;
  bookingToCancel: Booking | null = null;
  cancellationReason = '';
  cancelLoading = false;

  ngOnInit(): void {
    this.loadBookings();
  }

  loadBookings(): void {
    this.loading = true;
    this.error = null;

    this.bookingsService.getMyBookings().subscribe({
      next: (bookings) => {
        this.bookings = bookings.sort((a, b) =>
          new Date(b.createdAt || '').getTime() - new Date(a.createdAt || '').getTime()
        );
        this.loading = false;
        console.log('✅ Reservas cargadas:', bookings);
      },
      error: (error) => {
        console.error('❌ Error cargando reservas:', error);
        this.error = 'No se pudieron cargar las reservas';
        this.loading = false;

        // Fallback a datos mock
        this.loadMockBookings();
      }
    });
  }

  private loadMockBookings(): void {
    console.log('⚠️ Usando reservas mock');
    this.bookings = [
      {
        id: '1',
        spaceId: '550e8400-e29b-41d4-a716-446655440001',
        guestId: '11111111-1111-1111-1111-111111111111',
        startTs: '2025-11-05T10:00:00Z',
        endTs: '2025-11-05T18:00:00Z',
        numGuests: 6,
        totalPriceCents: 20000,
        status: 'CONFIRMED',
        paymentStatus: 'succeeded',
        createdAt: '2025-10-28T10:00:00Z'
      },
      {
        id: '2',
        spaceId: '550e8400-e29b-41d4-a716-446655440002',
        guestId: '11111111-1111-1111-1111-111111111111',
        startTs: '2025-10-25T14:00:00Z',
        endTs: '2025-10-25T20:00:00Z',
        numGuests: 4,
        totalPriceCents: 15000,
        status: 'COMPLETED',
        paymentStatus: 'succeeded',
        createdAt: '2025-10-20T09:00:00Z'
      },
      {
        id: '3',
        spaceId: '550e8400-e29b-41d4-a716-446655440003',
        guestId: '11111111-1111-1111-1111-111111111111',
        startTs: '2025-11-15T12:00:00Z',
        endTs: '2025-11-15T22:00:00Z',
        numGuests: 8,
        totalPriceCents: 30000,
        status: 'PENDING',
        paymentStatus: 'pending',
        createdAt: '2025-10-29T15:00:00Z'
      }
    ];
    this.loading = false;
  }

  get filteredBookings(): Booking[] {
    if (this.selectedFilter === 'all') {
      return this.bookings;
    }
    return this.bookings.filter(b => b.status === this.selectedFilter);
  }

  getBookingCount(status: string): number {
    if (status === 'all') return this.bookings.length;
    return this.bookings.filter(b => b.status === status).length;
  }

  getStatusBadgeClass(status: string): string {
    const classes: { [key: string]: string } = {
      'PENDING': 'badge-warning',
      'CONFIRMED': 'badge-info',
      'CANCELLED': 'badge-error',
      'COMPLETED': 'badge-success'
    };
    return classes[status] || 'badge-default';
  }

  getStatusText(status: string): string {
    const texts: { [key: string]: string } = {
      'PENDING': 'Pendiente',
      'CONFIRMED': 'Confirmada',
      'CANCELLED': 'Cancelada',
      'COMPLETED': 'Completada'
    };
    return texts[status] || status;
  }

  getPaymentStatusText(status: string): string {
    const texts: { [key: string]: string } = {
      'pending': 'Pago pendiente',
      'processing': 'Procesando pago',
      'succeeded': 'Pagado',
      'failed': 'Pago fallido',
      'refunded': 'Reembolsado'
    };
    return texts[status] || status;
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('es-ES', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    }).format(date);
  }

  formatTime(dateString: string): string {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('es-ES', {
      hour: '2-digit',
      minute: '2-digit'
    }).format(date);
  }

  formatPrice(cents: number): string {
    return (cents / 100).toFixed(2);
  }

  canCancel(booking: Booking): boolean {
    if (booking.status !== 'PENDING' && booking.status !== 'CONFIRMED') {
      return false;
    }

    const now = new Date();
    const startDate = new Date(booking.startTs);
    const hoursUntilStart = (startDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    return hoursUntilStart >= 48; // Mínimo 48 horas de antelación
  }

  canReview(booking: Booking): boolean {
    return booking.status === 'COMPLETED';
  }

  openCancelModal(booking: Booking): void {
    this.bookingToCancel = booking;
    this.showCancelModal = true;
    this.cancellationReason = '';
  }

  closeCancelModal(): void {
    this.showCancelModal = false;
    this.bookingToCancel = null;
    this.cancellationReason = '';
  }

  confirmCancel(): void {
    if (!this.bookingToCancel || !this.cancellationReason.trim()) {
      return;
    }

    this.cancelLoading = true;

    this.bookingsService.cancelBooking(this.bookingToCancel.id, this.cancellationReason).subscribe({
      next: (updatedBooking) => {
        console.log('✅ Reserva cancelada:', updatedBooking);

        // Actualizar en la lista
        const index = this.bookings.findIndex(b => b.id === updatedBooking.id);
        if (index !== -1) {
          this.bookings[index] = updatedBooking;
        }

        this.closeCancelModal();
        this.cancelLoading = false;
      },
      error: (error) => {
        console.error('❌ Error cancelando reserva:', error);
        alert('No se pudo cancelar la reserva. Inténtalo de nuevo.');
        this.cancelLoading = false;
      }
    });
  }

  viewSpace(spaceId: string): void {
    this.router.navigate(['/spaces', spaceId]);
  }

  goToReview(bookingId: string): void {
    this.router.navigate(['/bookings', bookingId, 'review']);
  }
}

