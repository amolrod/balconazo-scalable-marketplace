import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { BookingsService } from '../../../core/services/bookings.service';
import { ToastService } from '../../../core/services/toast.service';

@Component({
  selector: 'app-review',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './review.component.html',
  styleUrl: './review.component.scss'
})
export class ReviewComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private bookingsService = inject(BookingsService);
  private toastService = inject(ToastService);

  bookingId: string = '';
  spaceId: string = '';
  loading = false;
  loadingBooking = true;
  error: string | null = null;
  hasExistingReview = false;

  // Form data
  rating = 0;
  comment = '';
  hoverRating = 0;

  ngOnInit(): void {
    // Scroll to top al cargar la página
    window.scrollTo({ top: 0, behavior: 'smooth' });

    this.bookingId = this.route.snapshot.paramMap.get('id') || '';
    if (!this.bookingId) {
      this.router.navigate(['/my-bookings']);
      return;
    }

    // Obtener la información de la reserva para sacar el spaceId
    this.bookingsService.getBookingById(this.bookingId).subscribe({
      next: (booking) => {
        this.spaceId = booking.spaceId;
        this.loadingBooking = false;

        // Verificar que la reserva esté completada y no tenga reseña
        if (booking.status?.toUpperCase() !== 'COMPLETED' && booking.status?.toUpperCase() !== 'CONFIRMED') {
          this.error = 'Solo puedes dejar reseñas para reservas completadas o confirmadas';
          this.hasExistingReview = true; // Bloquear formulario
        } else if (booking.hasReview) {
          this.error = 'Ya has dejado una reseña para esta reserva';
          this.hasExistingReview = true; // Bloquear formulario
        }

        console.log('📋 Booking cargado:', {
          id: this.bookingId,
          spaceId: this.spaceId,
          status: booking.status,
          hasReview: booking.hasReview
        });
      },
      error: (error) => {
        console.error('❌ Error cargando reserva:', error);
        this.error = 'No se pudo cargar la información de la reserva';
        this.loadingBooking = false;
      }
    });
  }

  setRating(rating: number): void {
    this.rating = rating;
  }

  setHoverRating(rating: number): void {
    this.hoverRating = rating;
  }

  clearHoverRating(): void {
    this.hoverRating = 0;
  }

  getStarClass(index: number): string {
    const currentRating = this.hoverRating || this.rating;
    return index <= currentRating ? 'star-filled' : 'star-empty';
  }

  submitReview(): void {
    // Verificar si ya existe reseña
    if (this.hasExistingReview) {
      this.toastService.error('Ya has dejado una reseña para esta reserva');
      return;
    }

    if (!this.rating || this.rating < 1 || this.rating > 5) {
      this.toastService.warning('Por favor, selecciona una calificación entre 1 y 5 estrellas');
      return;
    }

    if (!this.comment.trim()) {
      this.toastService.warning('Por favor, escribe un comentario sobre tu experiencia');
      return;
    }

    if (!this.bookingId) {
      this.toastService.error('No se encontró el ID de la reserva');
      return;
    }

    console.log('📤 Enviando reseña:', {
      bookingId: this.bookingId,
      rating: this.rating,
      comment: this.comment.trim()
    });

    this.loading = true;
    this.error = null;

    this.bookingsService.createReview({
      bookingId: this.bookingId,
      rating: this.rating,
      comment: this.comment.trim()
    }).subscribe({
      next: (response) => {
        console.log('✅ Reseña creada:', response);
        this.hasExistingReview = true; // Marcar como ya reseñada
        this.toastService.success('¡Gracias por tu reseña!');
        this.router.navigate(['/my-bookings']);
      },
      error: (error) => {
        console.error('❌ Error creando reseña:', error);
        // Verificar si el error es por reseña duplicada
        if (error.error?.message?.includes('Ya existe') || error.status === 409) {
          this.hasExistingReview = true;
          this.toastService.error('Ya has dejado una reseña para esta reserva');
        } else {
          this.error = error.error?.message || 'No se pudo enviar la reseña. Inténtalo de nuevo.';
          this.toastService.error(this.error || 'Error desconocido');
        }
        this.loading = false;
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/my-bookings']);
  }
}
