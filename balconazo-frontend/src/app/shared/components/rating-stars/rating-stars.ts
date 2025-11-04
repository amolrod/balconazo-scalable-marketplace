import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * RatingStars Component
 * Muestra y permite seleccionar rating con estrellas
 *
 * @example
 * <!-- Read-only -->
 * <app-rating-stars [rating]="4.5" [size]="'md'"></app-rating-stars>
 *
 * <!-- Interactive -->
 * <app-rating-stars
 *   [rating]="currentRating"
 *   [interactive]="true"
 *   (ratingChange)="onRatingChange($event)">
 * </app-rating-stars>
 */
@Component({
  selector: 'app-rating-stars',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './rating-stars.html',
  styleUrl: './rating-stars.scss'
})
export class RatingStarsComponent {
  @Input() rating: number = 0; // 0-5, puede ser decimal (ej: 4.5)
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() interactive: boolean = false;
  @Input() showNumber: boolean = true; // Mostrar número al lado
  @Output() ratingChange = new EventEmitter<number>();

  hoveredRating: number = 0;

  /**
   * Array de estrellas (1-5)
   */
  stars = [1, 2, 3, 4, 5];

  /**
   * Determina si una estrella debe estar llena, vacía o media
   */
  getStarType(star: number): 'full' | 'half' | 'empty' {
    const currentRating = this.interactive && this.hoveredRating > 0
      ? this.hoveredRating
      : this.rating;

    if (currentRating >= star) {
      return 'full';
    } else if (currentRating >= star - 0.5) {
      return 'half';
    } else {
      return 'empty';
    }
  }

  /**
   * Maneja el hover sobre una estrella
   */
  onStarHover(star: number): void {
    if (this.interactive) {
      this.hoveredRating = star;
    }
  }

  /**
   * Maneja cuando el mouse sale de las estrellas
   */
  onStarsLeave(): void {
    if (this.interactive) {
      this.hoveredRating = 0;
    }
  }

  /**
   * Maneja el click en una estrella
   */
  onStarClick(star: number): void {
    if (this.interactive) {
      this.rating = star;
      this.ratingChange.emit(star);
    }
  }

  /**
   * Formatea el rating para mostrar
   */
  get formattedRating(): string {
    return this.rating.toFixed(1);
  }
}

