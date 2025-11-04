import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * EmptyState Component
 * Muestra un estado vacío con icono, título, mensaje y CTA opcional
 *
 * @example
 * <app-empty-state
 *   icon="search"
 *   title="No se encontraron espacios"
 *   message="Intenta con otros filtros"
 *   ctaText="Limpiar filtros"
 *   (ctaClick)="clearFilters()">
 * </app-empty-state>
 */
@Component({
  selector: 'app-empty-state',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './empty-state.html',
  styleUrl: './empty-state.scss'
})
export class EmptyStateComponent {
  @Input() icon: 'search' | 'inbox' | 'alert' | 'heart' | 'home' = 'inbox';
  @Input() title: string = 'No hay resultados';
  @Input() message?: string;
  @Input() ctaText?: string;
  @Output() ctaClick = new EventEmitter<void>();

  onCtaClick(): void {
    this.ctaClick.emit();
  }
}
