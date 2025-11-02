import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { trigger, transition, style, animate } from '@angular/animations';
import { ToastService, Toast } from '../../core/services/toast.service';

@Component({
  selector: 'app-toast',
  imports: [CommonModule],
  templateUrl: './toast.html',
  styleUrl: './toast.scss',
  animations: [
    trigger('slideIn', [
      transition(':enter', [
        style({ transform: 'translateX(400px)', opacity: 0 }),
        animate('300ms ease-out', style({ transform: 'translateX(0)', opacity: 1 }))
      ]),
      transition(':leave', [
        animate('200ms ease-in', style({ transform: 'translateX(400px)', opacity: 0 }))
      ])
    ])
  ]
})
export class ToastComponent implements OnInit {
  private toastService = inject(ToastService);
  toasts: Toast[] = [];

  ngOnInit(): void {
    this.toastService.toasts$.subscribe(toast => {
      this.toasts.push(toast);

      // Auto-remove después de duration
      setTimeout(() => {
        this.removeToast(toast.id);
      }, toast.duration || 3000);
    });
  }

  removeToast(id: string): void {
    this.toasts = this.toasts.filter(t => t.id !== id);
  }

  getIcon(type: string): string {
    const icons: { [key: string]: string } = {
      'success': '✓',
      'error': '✕',
      'warning': '⚠',
      'info': 'ℹ'
    };
    return icons[type] || 'ℹ';
  }
}

