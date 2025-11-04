/**
 * Notification Models
 * Modelos para el sistema de notificaciones
 */

export type NotificationType =
  | 'BOOKING_CREATED'
  | 'BOOKING_CONFIRMED'
  | 'BOOKING_CANCELLED'
  | 'REVIEW_RECEIVED'
  | 'MESSAGE_RECEIVED'
  | 'SPACE_APPROVED'
  | 'SPACE_REJECTED'
  | 'PAYMENT_RECEIVED'
  | 'PAYMENT_FAILED';

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  isRead: boolean;
  actionUrl?: string; // URL para navegar al hacer click
  metadata?: Record<string, any>; // Datos adicionales específicos del tipo
  createdAt: string;
  readAt?: string;
}

export interface CreateNotificationRequest {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  actionUrl?: string;
  metadata?: Record<string, any>;
}

export interface NotificationsResponse {
  notifications: Notification[];
  unreadCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface MarkAsReadRequest {
  notificationIds: string[];
}

