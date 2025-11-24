import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';
import { AuthService } from './auth.service';

export interface Booking {
  id: string;
  spaceId: string;
  guestId: string;
  startTs: string;
  endTs: string;
  numGuests: number;
  totalPriceCents: number;
  status: 'PENDING' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';
  paymentStatus: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded';
  paymentIntentId?: string;
  cancellationReason?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateBookingDTO {
  spaceId: string;
  guestId: string;
  startTs: string;
  endTs: string;
  numGuests: number;
}

export interface Review {
  id: string;
  bookingId: string;
  spaceId: string;
  guestId: string;
  rating: number;
  comment?: string;
  createdAt: string;
}

export interface CreateReviewDTO {
  bookingId: string;
  spaceId: string;
  rating: number;
  comment?: string;
}

@Injectable({
  providedIn: 'root'
})
export class BookingsService {
  private http = inject(HttpClient);
  private authService = inject(AuthService);
  private readonly baseUrl = `${environment.apiUrl}/bookings`;

  /**
   * Crear una nueva reserva
   */
  createBooking(data: CreateBookingDTO): Observable<Booking> {
    return this.http.post<Booking>(`${this.baseUrl}`, data);
  }

  /**
   * Obtener reserva por ID
   */
  getBookingById(id: string): Observable<Booking> {
    return this.http.get<Booking>(`${this.baseUrl}/${id}`);
  }

  /**
   * Obtener todas las reservas del usuario actual (como guest)
   */
  getMyBookings(): Observable<Booking[]> {
    const userId = this.authService.getUserId();
    if (!userId) {
      return throwError(() => new Error('Usuario no autenticado'));
    }
    return this.http.get<Booking[]>(`${this.baseUrl}/guest/${userId}`);
  }

  /**
   * Obtener reservas de un espacio específico (para el host)
   */
  getBookingsBySpace(spaceId: string): Observable<Booking[]> {
    return this.http.get<Booking[]>(`${this.baseUrl}/space/${spaceId}`);
  }

  /**
   * Confirmar una reserva (después del pago)
   */
  confirmBooking(bookingId: string, paymentIntentId: string): Observable<Booking> {
    return this.http.post<Booking>(
      `${this.baseUrl}/${bookingId}/confirm`,
      null,
      { params: { paymentIntentId } }
    );
  }

  /**
   * Cancelar una reserva
   */
  cancelBooking(bookingId: string, reason: string): Observable<Booking> {
    return this.http.post<Booking>(
      `${this.baseUrl}/${bookingId}/cancel`,
      null,
      { params: { reason } }
    );
  }

  /**
   * Completar una reserva (marcar como realizada)
   */
  completeBooking(bookingId: string): Observable<Booking> {
    return this.http.post<Booking>(`${this.baseUrl}/${bookingId}/complete`, {});
  }

  /**
   * Crear una reseña para una reserva
   */
  createReview(data: CreateReviewDTO): Observable<Review> {
    return this.http.post<Review>(`${this.baseUrl}/reviews`, data);
  }

  /**
   * Obtener reseñas de un espacio
   */
  getReviewsBySpace(spaceId: string): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/reviews/space/${spaceId}`);
  }

  /**
   * Obtener reseñas escritas por el usuario actual
   */
  getMyReviews(): Observable<Review[]> {
    return this.http.get<Review[]>(`${this.baseUrl}/reviews/reviewer/me`);
  }

  /**
   * Calcular el precio estimado de una reserva
   */
  calculatePrice(spaceId: string, startTs: string, endTs: string, numGuests: number): Observable<{ totalPriceCents: number }> {
    const params = new HttpParams()
      .set('spaceId', spaceId)
      .set('startTs', startTs)
      .set('endTs', endTs)
      .set('numGuests', numGuests.toString());

    return this.http.get<{ totalPriceCents: number }>(`${this.baseUrl}/calculate-price`, { params });
  }

  /**
   * Verificar disponibilidad de un espacio
   */
  checkAvailability(spaceId: string, startTs: string, endTs: string): Observable<{ available: boolean }> {
    const params = new HttpParams()
      .set('spaceId', spaceId)
      .set('startTs', startTs)
      .set('endTs', endTs);

    return this.http.get<{ available: boolean }>(`${this.baseUrl}/check-availability`, { params });
  }
}

