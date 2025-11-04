import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * SkeletonList Component
 * Muestra placeholders animados mientras carga el contenido
 *
 * @example
 * <app-skeleton-list [count]="6" [type]="'card'"></app-skeleton-list>
 */
@Component({
  selector: 'app-skeleton-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './skeleton-list.html',
  styleUrl: './skeleton-list.scss'
})
export class SkeletonListComponent {
  @Input() count: number = 3;
  @Input() type: 'card' | 'list' | 'table' = 'card';

  get items(): number[] {
    return Array.from({ length: this.count }, (_, i) => i);
  }
}

