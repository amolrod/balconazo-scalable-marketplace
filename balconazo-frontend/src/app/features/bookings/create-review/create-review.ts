import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { BookingsService, Booking, CreateReviewDTO } from '../../../core/services/bookings.service';

@Component({
  selector: 'app-create-review',
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './create-review.html',
  styleUrl: './create-review.scss'
})
export class CreateReviewComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private bookingsService = inject(BookingsService);

  booking: Booking | null = null;
  loading = true;
  error: string | null = null;

  reviewForm: FormGroup;
  reviewSubmitting = false;
  reviewError: string | null = null;
  reviewSuccess = false;

  constructor() {
    this.reviewForm = this.fb.group({
      rating: [5, [Validators.required, Validators.min(1), Validators.max(5)]],
      comment: ['', [Validators.required, Validators.minLength(10)]]
    });
  }

  ngOnInit(): void {
    const bookingId = this.route.snapshot.paramMap.get('id');
    if (!bookingId) {
      this.router.navigate(['/my-bookings']);
      return;
    }
    this.loadBooking(bookingId);
  }

  loadBooking(bookingId: string): void {
    this.loading = true;
    this.error = null;

    this.bookingsService.getMyBookings().subscribe({
      next: (bookings) => {
        const booking = bookings.find(b => b.id === bookingId);
        
        if (!booking) {
          this.error = 'Reserva no encontrada';
          this.loading = false;
          return;
        }

        if (booking.status !== 'completed') {
          this.error = 'Solo puedes dejar reseñas en reservas completadas';
          this.loading = false;
          return;
        }

        this.booking = booking;
        this.loading = false;
      },
      error: (err) => {
        console.error('❌ Error cargando reserva:', err);
        this.error = 'No se pudo cargar la reserva';
        this.loading = false;
      }
    });
  }

  submitReview(): void {
    if (!this.reviewForm.valid || !this.booking) {
      return;
    }

    this.reviewSubmitting = true;
    this.reviewError = null;

    const reviewData: CreateReviewDTO = {
      bookingId: this.booking.id,
      rating: this.reviewForm.value.rating,
      comment: this.reviewForm.value.comment
    };

    console.log('📤 Enviando review desde Mis Reservas:', JSON.stringify(reviewData, null, 2));

    this.bookingsService.createReview(reviewData).subscribe({
      next: (review) => {
        console.log('✅ Review creada exitosamente:', review);
        this.reviewSuccess = true;
        this.reviewSubmitting = false;
        
        // Redirigir a "Mis Reservas" después de 2 segundos
        setTimeout(() => {
          this.router.navigate(['/my-bookings']);
        }, 2000);
      },
      error: (error) => {
        console.error('❌ Error creando review:', error);
        this.reviewError = error.error?.message || 'No se pudo crear la reseña. Por favor, inténtalo de nuevo.';
        this.reviewSubmitting = false;
      }
    });
  }

  goBack(): void {
    this.router.navigate(['/my-bookings']);
  }

  formatDate(timestamp: string): string {
    return new Date(timestamp).toLocaleDateString('es-ES', { 
      day: '2-digit', 
      month: 'short', 
      year: 'numeric' 
    });
  }

  formatTime(timestamp: string): string {
    return new Date(timestamp).toLocaleTimeString('es-ES', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }
}
