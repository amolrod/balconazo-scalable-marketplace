import { Component, Input, Output, EventEmitter, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * ConfirmDialog Component
 * Modal de confirmación reutilizable
 *
 * @example
 * <app-confirm-dialog
 *   *ngIf="showDialog"
 *   title="Eliminar espacio"
 *   message="¿Estás seguro de que quieres eliminar este espacio?"
 *   confirmText="Eliminar"
 *   confirmType="danger"
 *   (confirmed)="onConfirm()"
 *   (cancelled)="onCancel()">
 * </app-confirm-dialog>
 */
@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './confirm-dialog.html',
  styleUrl: './confirm-dialog.scss'
})
export class ConfirmDialogComponent {
  @Input() title: string = '¿Estás seguro?';
  @Input() message: string = 'Esta acción no se puede deshacer.';
  @Input() confirmText: string = 'Confirmar';
  @Input() cancelText: string = 'Cancelar';
  @Input() confirmType: 'primary' | 'danger' = 'primary';
  @Output() confirmed = new EventEmitter<void>();
  @Output() cancelled = new EventEmitter<void>();

  @HostListener('document:keydown.escape')
  onEscapeKey(): void {
    this.onCancel();
  }

  onConfirm(): void {
    this.confirmed.emit();
  }

  onCancel(): void {
    this.cancelled.emit();
  }

  onBackdropClick(event: MouseEvent): void {
    // Solo cerrar si se hace click en el backdrop, no en el modal
    if (event.target === event.currentTarget) {
      this.onCancel();
    }
  }
}

