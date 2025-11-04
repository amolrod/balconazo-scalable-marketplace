import { Pipe, PipeTransform } from '@angular/core';

/**
 * Date Relative Pipe
 * Convierte fecha a formato relativo en español
 *
 * @example
 * {{ someDate | dateRelative }}  → "hace 2 días"
 * {{ futureDate | dateRelative }} → "en 3 horas"
 */
@Pipe({
  name: 'dateRelative',
  standalone: true
})
export class DateRelativePipe implements PipeTransform {
  transform(date: string | Date | null | undefined): string {
    if (!date) {
      return '';
    }

    const dateObj = typeof date === 'string' ? new Date(date) : date;
    const now = new Date();
    const diffMs = now.getTime() - dateObj.getTime();
    const diffSeconds = Math.floor(diffMs / 1000);
    const diffMinutes = Math.floor(diffSeconds / 60);
    const diffHours = Math.floor(diffMinutes / 60);
    const diffDays = Math.floor(diffHours / 24);
    const diffWeeks = Math.floor(diffDays / 7);
    const diffMonths = Math.floor(diffDays / 30);
    const diffYears = Math.floor(diffDays / 365);

    // Future dates
    if (diffMs < 0) {
      const absDiffSeconds = Math.abs(diffSeconds);
      const absDiffMinutes = Math.abs(diffMinutes);
      const absDiffHours = Math.abs(diffHours);
      const absDiffDays = Math.abs(diffDays);
      const absDiffWeeks = Math.abs(diffWeeks);
      const absDiffMonths = Math.abs(diffMonths);
      const absDiffYears = Math.abs(diffYears);

      if (absDiffSeconds < 60) return 'en unos segundos';
      if (absDiffMinutes === 1) return 'en 1 minuto';
      if (absDiffMinutes < 60) return `en ${absDiffMinutes} minutos`;
      if (absDiffHours === 1) return 'en 1 hora';
      if (absDiffHours < 24) return `en ${absDiffHours} horas`;
      if (absDiffDays === 1) return 'mañana';
      if (absDiffDays < 7) return `en ${absDiffDays} días`;
      if (absDiffWeeks === 1) return 'en 1 semana';
      if (absDiffWeeks < 4) return `en ${absDiffWeeks} semanas`;
      if (absDiffMonths === 1) return 'en 1 mes';
      if (absDiffMonths < 12) return `en ${absDiffMonths} meses`;
      if (absDiffYears === 1) return 'en 1 año';
      return `en ${absDiffYears} años`;
    }

    // Past dates
    if (diffSeconds < 10) return 'ahora mismo';
    if (diffSeconds < 60) return 'hace unos segundos';
    if (diffMinutes === 1) return 'hace 1 minuto';
    if (diffMinutes < 60) return `hace ${diffMinutes} minutos`;
    if (diffHours === 1) return 'hace 1 hora';
    if (diffHours < 24) return `hace ${diffHours} horas`;
    if (diffDays === 1) return 'ayer';
    if (diffDays < 7) return `hace ${diffDays} días`;
    if (diffWeeks === 1) return 'hace 1 semana';
    if (diffWeeks < 4) return `hace ${diffWeeks} semanas`;
    if (diffMonths === 1) return 'hace 1 mes';
    if (diffMonths < 12) return `hace ${diffMonths} meses`;
    if (diffYears === 1) return 'hace 1 año';
    return `hace ${diffYears} años`;
  }
}

