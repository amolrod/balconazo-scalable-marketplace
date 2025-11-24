import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { BookingsService } from '../../../core/services/bookings.service';

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

  bookingId: string = '';
  spaceId: string = '';
  loading = false;
  loadingBooking = true;
  error: string | null = null;

  // Form data
  rating = 0;
  comment = '';
  hoverRating = 0;

  ngOnInit(): void {
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
        } else if (booking.hasReview) {
          this.error = 'Ya has dejado una reseña para esta reserva';
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
    if (!this.rating || this.rating < 1 || this.rating > 5) {
      alert('Por favor, selecciona una calificación entre 1 y 5 estrellas');
      return;
    }

    if (!this.comment.trim()) {
      alert('Por favor, escribe un comentario sobre tu experiencia');
      return;
    }

    if (!this.bookingId) {
      alert('No se encontró el ID de la reserva');
      return;
    }

    if (!this.spaceId) {
      alert('No se pudo obtener la información del espacio');
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
        alert('¡Gracias por tu reseña!');
        this.router.navigate(['/my-bookings']);
      },
      error: (error) => {
        console.error('❌ Error creando reseña:', error);
        this.error = error.error?.message || 'No se pudo enviar la reseña. Inténtalo de nuevo.';
        this.loading = false;
      }
    });
  }

  cancel(): void {
    this.router.navigate(['/my-bookings']);
  }
}
