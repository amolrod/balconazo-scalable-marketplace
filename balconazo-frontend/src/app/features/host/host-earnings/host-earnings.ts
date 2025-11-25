import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { forkJoin } from 'rxjs';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, Booking } from '../../../core/services/bookings.service';
import { PricePipe } from '../../../shared/pipes/price.pipe';

interface MonthlyData {
  month: string;
  earnings: number;
  bookings: number;
}

interface SpaceStats {
  spaceId: string;
  title: string;
  earnings: number;
  bookings: number;
  avgPrice: number;
}

@Component({
  selector: 'app-host-earnings',
  standalone: true,
  imports: [CommonModule, RouterModule, PricePipe],
  templateUrl: './host-earnings.html',
  styleUrl: './host-earnings.scss'
})
export class HostEarningsComponent implements OnInit {
  private router = inject(Router);
  private spacesService = inject(SpacesService);
  private bookingsService = inject(BookingsService);

  loading = true;

  // Estadísticas generales
  totalEarnings = 0;
  totalBookings = 0;
  avgBookingValue = 0;
  activeSpaces = 0;

  // Datos por mes (últimos 6 meses)
  monthlyData: MonthlyData[] = [];

  // Datos por espacio
  spaceStats: SpaceStats[] = [];

  // Reservas recientes
  recentBookings: Booking[] = [];

  ngOnInit(): void {
    this.loadData();
  }

  loadData(): void {
    const userId = localStorage.getItem('userId');
    if (!userId) {
      this.router.navigate(['/login']);
      return;
    }

    this.spacesService.getSpacesByOwner(userId).subscribe({
      next: (spaces) => {
        this.activeSpaces = spaces.filter(s => s.status.toUpperCase() === 'ACTIVE').length;

        if (spaces.length === 0) {
          this.loading = false;
          return;
        }

        // Cargar reservas de todos los espacios
        const bookingRequests = spaces.map(space =>
          this.bookingsService.getBookingsBySpace(space.id)
        );

        forkJoin(bookingRequests).subscribe({
          next: (bookingsArrays) => {
            const allBookings = bookingsArrays.flat();
            this.processStats(spaces, allBookings);
            this.loading = false;
          },
          error: () => {
            this.loading = false;
          }
        });
      },
      error: () => {
        this.loading = false;
      }
    });
  }

  private processStats(spaces: Space[], bookings: Booking[]): void {
    // Filtrar solo completadas para ganancias
    const completedBookings = bookings.filter(b =>
      b.status?.toUpperCase() === 'COMPLETED' || b.status?.toUpperCase() === 'CONFIRMED'
    );

    // Totales
    this.totalBookings = bookings.length;
    this.totalEarnings = completedBookings.reduce((sum, b) => sum + (b.totalPriceCents || 0), 0);
    this.avgBookingValue = completedBookings.length > 0
      ? Math.round(this.totalEarnings / completedBookings.length)
      : 0;

    // Reservas recientes
    this.recentBookings = bookings
      .sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime())
      .slice(0, 5);

    // Estadísticas por espacio
    this.spaceStats = spaces.map(space => {
      const spaceBookings = completedBookings.filter(b => b.spaceId === space.id);
      const earnings = spaceBookings.reduce((sum, b) => sum + (b.totalPriceCents || 0), 0);
      return {
        spaceId: space.id,
        title: space.title,
        earnings,
        bookings: spaceBookings.length,
        avgPrice: spaceBookings.length > 0 ? Math.round(earnings / spaceBookings.length) : 0
      };
    }).sort((a, b) => b.earnings - a.earnings);

    // Datos mensuales (últimos 6 meses)
    this.monthlyData = this.calculateMonthlyData(completedBookings);
  }

  private calculateMonthlyData(bookings: Booking[]): MonthlyData[] {
    const months: MonthlyData[] = [];
    const now = new Date();

    for (let i = 5; i >= 0; i--) {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthName = date.toLocaleDateString('es-ES', { month: 'short' });
      const year = date.getFullYear();
      const month = date.getMonth();

      const monthBookings = bookings.filter(b => {
        const bookingDate = new Date(b.createdAt || 0);
        return bookingDate.getMonth() === month && bookingDate.getFullYear() === year;
      });

      months.push({
        month: monthName.charAt(0).toUpperCase() + monthName.slice(1),
        earnings: monthBookings.reduce((sum, b) => sum + (b.totalPriceCents || 0), 0),
        bookings: monthBookings.length
      });
    }

    return months;
  }

  getMaxEarnings(): number {
    return Math.max(...this.monthlyData.map(m => m.earnings), 1);
  }

  formatEarnings(cents: number): string {
    return (cents / 100).toLocaleString('es-ES', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  goBack(): void {
    this.router.navigate(['/host/dashboard']);
  }

  getStatusLabel(status: string | undefined): string {
    if (!status) return 'Desconocido';
    const labels: { [key: string]: string } = {
      'PENDING': 'Pendiente',
      'CONFIRMED': 'Confirmada',
      'COMPLETED': 'Completada',
      'CANCELLED': 'Cancelada'
    };
    return labels[status.toUpperCase()] || status;
  }

  downloadCSV(): void {
    const headers = ['Espacio', 'Reservas', 'Ganancias', 'Precio Medio'];
    const rows = this.spaceStats.map(s => [
      s.title,
      s.bookings.toString(),
      (s.earnings / 100).toFixed(2) + '€',
      (s.avgPrice / 100).toFixed(2) + '€'
    ]);

    const csvContent = [
      'ESTADÍSTICAS DE GANANCIAS - BALCONAZO',
      `Generado: ${new Date().toLocaleDateString('es-ES')}`,
      '',
      `Total Ganancias: ${this.formatEarnings(this.totalEarnings)}€`,
      `Total Reservas: ${this.totalBookings}`,
      `Valor Medio: ${this.formatEarnings(this.avgBookingValue)}€`,
      '',
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
    ].join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.setAttribute('href', URL.createObjectURL(blob));
    link.setAttribute('download', `balconazo-ganancias-${new Date().toISOString().split('T')[0]}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
