import { Pipe, PipeTransform } from '@angular/core';

/**
 * Price Pipe
 * Convierte centavos a formato de moneda (euros por defecto)
 *
 * @example
 * {{ 2500 | price }}           → "€25.00"
 * {{ 2500 | price:'USD' }}     → "$25.00"
 * {{ 2500 | price:'EUR':false }} → "€25"
 */
@Pipe({
  name: 'price',
  standalone: true
})
export class PricePipe implements PipeTransform {
  transform(
    cents: number | null | undefined,
    currency: 'EUR' | 'USD' = 'EUR',
    showDecimals: boolean = true
  ): string {
    // Handle null/undefined
    if (cents === null || cents === undefined) {
      return currency === 'EUR' ? '€0.00' : '$0.00';
    }

    // Convert cents to currency
    const amount = cents / 100;

    // Format based on currency
    const currencySymbol = currency === 'EUR' ? '€' : '$';

    if (showDecimals) {
      return `${currencySymbol}${amount.toFixed(2)}`;
    } else {
      return `${currencySymbol}${Math.round(amount)}`;
    }
  }
}

