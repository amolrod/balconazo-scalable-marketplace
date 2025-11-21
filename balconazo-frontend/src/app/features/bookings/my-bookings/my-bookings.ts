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
  reviewedSpaceIds: Set<string> = new Set(); // Para rastrear espacios con reseña

  selectedFilter: 'all' | 'pending' | 'confirmed' | 'cancelled' | 'completed' = 'all';

  showCancelModal = false;
  bookingToCancel: Booking | null = null;
  cancellationReason = '';
  cancelLoading = false;

  ngOnInit(): void {
    this.loadBookings();
    this.loadUserReviews();
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
        this.error = 'No se pudieron cargar las reservas. Verifica que estés autenticado y el backend esté corriendo.';
        this.bookings = [];
        this.loading = false;
      }
    });
  }

  loadUserReviews(): void {
    const userId = localStorage.getItem('userId');
    if (!userId) return;

    // Cargar todas las reseñas del usuario para saber qué espacios ya reseñó
    this.bookingsService.getMyReviews().subscribe({
      next: (reviews) => {
        this.reviewedSpaceIds = new Set(reviews.map(r => r.spaceId));
        console.log('✅ Espacios con reseña:', Array.from(this.reviewedSpaceIds));
      },
      error: (err) => {
        console.error('❌ Error cargando reseñas del usuario:', err);
      }
    });
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
      'pending': 'badge-warning',
      'confirmed': 'badge-info',
      'cancelled': 'badge-error',
      'completed': 'badge-success'
    };
    return classes[status] || 'badge-default';
  }

  getStatusText(status: string): string {
    const texts: { [key: string]: string } = {
      'pending': 'Pendiente',
      'confirmed': 'Confirmada',
      'cancelled': 'Cancelada',
      'completed': 'Completada'
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
    if (booking.status !== 'pending' && booking.status !== 'confirmed') {
      return false;
    }

    const now = new Date();
    const startDate = new Date(booking.startTs);
    const hoursUntilStart = (startDate.getTime() - now.getTime()) / (1000 * 60 * 60);

    return hoursUntilStart >= 48; // Mínimo 48 horas de antelación
  }

  canReview(booking: Booking): boolean {
    // Solo puede dejar reseña si está completada Y no ha dejado reseña para ese espacio
    return booking.status === 'completed' && !this.reviewedSpaceIds.has(booking.spaceId);
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

