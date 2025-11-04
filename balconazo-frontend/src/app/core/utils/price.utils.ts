/**
 * Price Utilities
 * Funciones helper para manejo de precios
 */

/**
 * Convierte centavos a euros
 */
export function centsToEuros(cents: number): number {
  return cents / 100;
}

/**
 * Convierte euros a centavos
 */
export function eurosToCents(euros: number): number {
  return Math.round(euros * 100);
}

/**
 * Formatea precio en centavos a string con símbolo de moneda
 */
export function formatPrice(
  cents: number,
  currency: 'EUR' | 'USD' = 'EUR',
  showDecimals: boolean = true
): string {
  const amount = centsToEuros(cents);
  const symbol = currency === 'EUR' ? '€' : '$';

  if (showDecimals) {
    return `${symbol}${amount.toFixed(2)}`;
  }
  return `${symbol}${Math.round(amount)}`;
}

/**
 * Formatea precio por hora
 */
export function formatPricePerHour(cents: number): string {
  return `${formatPrice(cents)}/hora`;
}

/**
 * Calcula precio total basado en horas
 */
export function calculateTotalPrice(pricePerHourCents: number, hours: number): number {
  return pricePerHourCents * hours;
}

/**
 * Valida que el precio esté dentro del rango permitido
 */
export function isValidPrice(cents: number, min: number = 500, max: number = 50000): boolean {
  return cents >= min && cents <= max;
}

/**
 * Redondea precio a múltiplo de 50 centavos
 */
export function roundToNearestFiftyCents(cents: number): number {
  return Math.round(cents / 50) * 50;
}

/**
 * Parsea string de precio a centavos
 * Ejemplos: "25.50" → 2550, "€30" → 3000, "$20.99" → 2099
 */
export function parsePriceToCents(priceString: string): number | null {
  // Remove currency symbols and spaces
  const cleaned = priceString.replace(/[€$\s]/g, '').replace(',', '.');
  const parsed = parseFloat(cleaned);

  if (isNaN(parsed)) {
    return null;
  }

  return eurosToCents(parsed);
}

