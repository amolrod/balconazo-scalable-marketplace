export interface Booking {
  id: string;
  spaceId: string;
  guestId: string;
  startTs: string;
  endTs: string;
  numGuests: number;
  totalPriceCents: number;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  paymentStatus: 'pending' | 'processing' | 'succeeded' | 'failed' | 'refunded';
  paymentIntentId?: string;
  cancellationReason?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface CreateBookingRequest {
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

export interface CreateReviewRequest {
  bookingId: string;
  spaceId: string;
  guestId: string;
  rating: number;
  comment?: string;
}

