import { Pipe, PipeTransform } from '@angular/core';

/**
 * Distance Pipe
 * Convierte metros a formato legible (km o m)
 *
 * @example
 * {{ 1500 | distance }}        → "1.5 km"
 * {{ 500 | distance }}         → "500 m"
 * {{ 250 | distance:0 }}       → "250 m"
 * {{ 1234 | distance:1 }}      → "1.2 km"
 */
@Pipe({
  name: 'distance',
  standalone: true
})
export class DistancePipe implements PipeTransform {
  transform(meters: number | null | undefined, decimals: number = 1): string {
    // Handle null/undefined
    if (meters === null || meters === undefined) {
      return '0 m';
    }

    // Less than 1000m, show in meters
    if (meters < 1000) {
      return `${Math.round(meters)} m`;
    }

    // 1000m or more, show in kilometers
    const kilometers = meters / 1000;
    return `${kilometers.toFixed(decimals)} km`;
  }
}

