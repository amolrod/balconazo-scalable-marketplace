/**
 * Review Models
 * Modelos para el sistema de reviews/ratings
 */

export interface Review {
  id: string;
  spaceId: string;
  guestId: string;
  bookingId: string;
  rating: number; // 1-5
  comment: string;
  createdAt: string;
  updatedAt?: string;
  guestName?: string; // Para mostrar en UI
  guestAvatar?: string;
}

export interface CreateReviewRequest {
  spaceId: string;
  bookingId: string;
  rating: number;
  comment: string;
}

export interface UpdateReviewRequest {
  rating?: number;
  comment?: string;
}

export interface ReviewStats {
  averageRating: number;
  totalReviews: number;
  ratingDistribution: {
    5: number;
    4: number;
    3: number;
    2: number;
    1: number;
  };
}

export interface ReviewsResponse {
  reviews: Review[];
  stats: ReviewStats;
  page: number;
  pageSize: number;
  totalPages: number;
}

