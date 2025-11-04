import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Space } from '../../../core/models/space.model';
import { PricePipe } from '../../pipes/price.pipe';
import { DistancePipe } from '../../pipes/distance.pipe';

/**
 * SpaceCard Component
 * Card reutilizable para mostrar espacios en listados/grids
 *
 * Features:
 * - Imagen principal con lazy loading
 * - Precio por hora
 * - Rating y número de reviews
 * - Distancia (opcional)
 * - Capacidad
 * - Amenities principales
 * - Hover effect con elevación
 * - Click para navegar a detalle
 *
 * @example
 * <app-space-card
 *   [space]="space"
 *   [showDistance]="true"
 *   (clicked)="onSpaceClick($event)">
 * </app-space-card>
 */
@Component({
  selector: 'app-space-card',
  standalone: true,
  imports: [CommonModule, RouterModule, PricePipe, DistancePipe],
  templateUrl: './space-card.html',
  styleUrl: './space-card.scss'
})
export class SpaceCardComponent {
  @Input({ required: true }) space!: Space;
  @Input() showDistance: boolean = false;
  @Input() distance?: number; // En metros
  @Output() clicked = new EventEmitter<Space>();

  /**
   * Obtiene la imagen principal del espacio
   */
  get primaryImage(): string {
    const primary = this.space.images?.find(img => img.isPrimary);
    if (primary) {
      return primary.url;
    }

    // Fallback a primera imagen
    if (this.space.images && this.space.images.length > 0) {
      return this.space.images[0].url;
    }

    // Placeholder si no hay imágenes
    return 'assets/images/placeholder-space.jpg';
  }

  /**
   * Obtiene las amenities principales (máximo 3)
   */
  get topAmenities(): string[] {
    if (!this.space.amenities || this.space.amenities.length === 0) {
      return [];
    }
    return this.space.amenities.slice(0, 3);
  }

  /**
   * Maneja el click en la card
   */
  onCardClick(): void {
    this.clicked.emit(this.space);
  }

  /**
   * Obtiene el badge de estado
   */
  get statusBadge(): { label: string; class: string } | null {
    const status = this.space.status?.toUpperCase();

    switch (status) {
      case 'ACTIVE':
        return null; // No mostrar badge para espacios activos
      case 'DRAFT':
        return { label: 'Borrador', class: 'badge-gray' };
      case 'SNOOZED':
        return { label: 'Pausado', class: 'badge-warning' };
      case 'DELETED':
        return { label: 'Eliminado', class: 'badge-error' };
      default:
        return null;
    }
  }
}

