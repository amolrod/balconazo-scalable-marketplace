import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { forkJoin } from 'rxjs';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, Booking } from '../../../core/services/bookings.service';
import { ToastService } from '../../../core/services/toast.service';
import { SpaceImagesService } from '../../../core/services/space-images.service';
import { SpaceImage } from '../../../core/models/space.model';
import { ImageGalleryManagerComponent } from '../../../shared/image-gallery-manager/image-gallery-manager';
import { PricePipe } from '../../../shared/pipes/price.pipe';

interface DashboardStats {
  totalSpaces: number;
  activeSpaces: number;
  totalBookings: number;
  totalEarnings: number;
  pendingBookings: number;
  monthlyEarnings: number;
}

// Cache for random heights to avoid re-calculation on each render
const chartHeights: number[] = Array.from({ length: 20 }, () => Math.floor(Math.random() * 80) + 20);

@Component({
  selector: 'app-host-dashboard',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,
    ImageGalleryManagerComponent,
    PricePipe
  ],
  templateUrl: './host-dashboard.html',
  styleUrl: './host-dashboard.scss'
})
export class HostDashboardComponent implements OnInit {
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private spacesService = inject(SpacesService);
  private bookingsService = inject(BookingsService);
  private toastService = inject(ToastService);
  private imagesService = inject(SpaceImagesService);

  // Estado
  loading = true;
  currentView: 'overview' | 'spaces' | 'bookings' | 'create-space' | 'edit-space' = 'overview';
  spacesFilter: 'all' | 'active' | 'snoozed' | 'deleted' = 'active';

  // Datos
  mySpaces: Space[] = [];
  receivedBookings: Booking[] = [];
  stats: DashboardStats = {
    totalSpaces: 0,
    activeSpaces: 0,
    totalBookings: 0,
    totalEarnings: 0,
    pendingBookings: 0,
    monthlyEarnings: 0
  };

  // Formulario de espacio
  spaceForm: FormGroup;
  editingSpaceId: string | null = null;
  formLoading = false;
  formError: string | null = null;

  // Imágenes del espacio en edición
  spaceImages: SpaceImage[] = [];

  // Imágenes pendientes para nuevo espacio
  pendingImages: { file: File; preview: string; name: string }[] = [];

  // Modal de confirmación
  showDeleteModal = false;
  spaceToDelete: Space | null = null;

  constructor() {
    this.spaceForm = this.fb.group({
      title: ['', [Validators.required, Validators.minLength(5)]],
      description: ['', [Validators.required, Validators.minLength(20)]],
      address: ['', Validators.required],
      lat: [null, [Validators.required, Validators.min(-90), Validators.max(90)]],
      lon: [null, [Validators.required, Validators.min(-180), Validators.max(180)]],
      capacity: [1, [Validators.required, Validators.min(1)]],
      basePriceCents: [25.00, [Validators.required, Validators.min(1)]], // Mostrar en euros
      areaSqm: [null, [Validators.min(1)]],
      amenities: [[]]
    });
  }

  ngOnInit(): void {
    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.loading = true;
    const userId = localStorage.getItem('userId');

    if (!userId) {
      this.router.navigate(['/login']);
      return;
    }

    // Cargar espacios del host
    this.spacesService.getSpacesByOwner(userId).subscribe({
      next: (spaces) => {
        this.mySpaces = spaces;
        this.calculateStats();
        this.loading = false;
        console.log('✅ Espacios del host cargados:', spaces);

        // Cargar reservas de todos los espacios del host
        this.loadHostBookings(spaces);
      },
      error: (error) => {
        console.error('❌ Error cargando espacios:', error);
        this.mySpaces = [];
        this.loading = false;
      }
    });
  }

  loadHostBookings(spaces: Space[]): void {
    if (spaces.length === 0) {
      this.receivedBookings = [];
      return;
    }

    // Cargar reservas de cada espacio y combinarlas
    const bookingRequests = spaces.map(space =>
      this.bookingsService.getBookingsBySpace(space.id)
    );

    // Usar forkJoin para esperar todas las requests
    forkJoin(bookingRequests).subscribe({
      next: (bookingsArrays) => {
        // Combinar todas las reservas y ordenar por fecha
        this.receivedBookings = bookingsArrays
          .flat()
          .sort((a, b) => new Date(b.startTs).getTime() - new Date(a.startTs).getTime());

        // Actualizar stats
        this.stats.totalBookings = this.receivedBookings.length;
        this.stats.pendingBookings = this.receivedBookings.filter(
          b => b.status?.toUpperCase() === 'PENDING' || b.status?.toUpperCase() === 'CONFIRMED'
        ).length;
        this.stats.totalEarnings = this.receivedBookings
          .filter(b => b.status?.toUpperCase() === 'COMPLETED')
          .reduce((sum, b) => sum + (b.totalPriceCents || 0), 0);

        console.log('✅ Reservas del host cargadas:', this.receivedBookings.length);
      },
      error: (error) => {
        console.error('❌ Error cargando reservas:', error);
        this.receivedBookings = [];
      }
    });
  }

  calculateStats(): void {
    this.stats.totalSpaces = this.mySpaces.length;
    this.stats.activeSpaces = this.mySpaces.filter(s => s.status.toUpperCase() === 'ACTIVE').length;
    console.log('📊 Stats calculadas:', {
      total: this.stats.totalSpaces,
      activos: this.stats.activeSpaces,
      espacios: this.mySpaces.map(s => ({ title: s.title, status: s.status }))
    });
    // TODO: Calcular bookings y earnings cuando estén disponibles
  }

  // === NAVEGACIÓN ===

  changeView(view: 'overview' | 'spaces' | 'bookings' | 'create-space' | 'edit-space'): void {
    this.currentView = view;

    // Scroll al top cuando cambia la vista
    window.scrollTo({ top: 0, behavior: 'smooth' });

    if (view === 'create-space') {
      this.resetForm();
    }
  }

  // === CRUD DE ESPACIOS ===

  createSpace(): void {
    if (this.spaceForm.invalid) {
      this.markFormGroupTouched(this.spaceForm);
      return;
    }

    this.formLoading = true;
    this.formError = null;

    const userId = localStorage.getItem('userId');
    const formValue = this.spaceForm.value;

    const spaceData = {
      ...formValue,
      ownerId: userId,
      basePriceCents: Math.round(formValue.basePriceCents * 100), // Convertir a centavos
      amenities: formValue.amenities || []
    };

    this.spacesService.createSpace(spaceData).subscribe({
      next: (space) => {
        console.log('✅ Espacio creado:', space);

        // Si hay imágenes pendientes, subirlas
        if (this.pendingImages.length > 0) {
          this.uploadPendingImages(space.id).then(() => {
            this.mySpaces.unshift(space);
            this.calculateStats();
            this.toastService.success('✓ Espacio creado con imágenes');
            this.changeView('spaces');
            this.resetForm();
            this.formLoading = false;
          }).catch(() => {
            // Espacio creado pero error en imágenes
            this.mySpaces.unshift(space);
            this.calculateStats();
            this.toastService.warning('Espacio creado, pero hubo errores con algunas imágenes');
            this.changeView('spaces');
            this.resetForm();
            this.formLoading = false;
          });
        } else {
          this.mySpaces.unshift(space);
          this.calculateStats();
          this.toastService.success('✓ Espacio creado exitosamente');
          this.changeView('spaces');
          this.resetForm();
          this.formLoading = false;
        }
      },
      error: (error) => {
        console.error('❌ Error creando espacio:', error);
        this.formError = error.error?.message || 'Error al crear el espacio';
        this.toastService.error('Error al crear el espacio');
        this.formLoading = false;
      }
    });
  }

  private async uploadPendingImages(spaceId: string): Promise<void> {
    for (let i = 0; i < this.pendingImages.length; i++) {
      const img = this.pendingImages[i];
      try {
        await this.imagesService.uploadImage(spaceId, img.file, i === 0).toPromise();
        console.log(`✅ Imagen ${i + 1} subida`);
      } catch (error) {
        console.error(`❌ Error subiendo imagen ${i + 1}:`, error);
      }
    }
  }

  onNewSpaceImagesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files) return;

    const files = Array.from(input.files);

    for (const file of files) {
      // Validar tamaño (5MB)
      if (file.size > 5 * 1024 * 1024) {
        this.toastService.error(`${file.name} es demasiado grande (máx 5MB)`);
        continue;
      }

      // Validar tipo
      if (!file.type.startsWith('image/')) {
        this.toastService.error(`${file.name} no es una imagen válida`);
        continue;
      }

      // Crear preview
      const reader = new FileReader();
      reader.onload = (e) => {
        this.pendingImages.push({
          file,
          preview: e.target?.result as string,
          name: file.name
        });
      };
      reader.readAsDataURL(file);
    }

    // Reset input para permitir seleccionar el mismo archivo de nuevo
    input.value = '';
  }

  removePendingImage(index: number): void {
    this.pendingImages.splice(index, 1);
  }

  editSpace(space: Space): void {
    this.editingSpaceId = space.id;
    this.spaceForm.patchValue({
      title: space.title,
      description: space.description,
      address: space.address,
      lat: space.lat,
      lon: space.lon,
      capacity: space.capacity,
      basePriceCents: space.basePriceCents / 100, // Convertir de centavos a euros
      areaSqm: space.areaSqm,
      amenities: space.amenities || []
    });

    // Cargar imágenes del espacio
    this.spaceImages = space.images || [];

    this.changeView('edit-space');
  }

  updateSpace(): void {
    if (this.spaceForm.invalid || !this.editingSpaceId) {
      this.markFormGroupTouched(this.spaceForm);
      return;
    }

    this.formLoading = true;
    this.formError = null;

    const formValue = this.spaceForm.value;
    const userId = localStorage.getItem('userId');

    if (!userId) {
      this.formError = 'Usuario no autenticado';
      this.toastService.error('Usuario no autenticado');
      this.formLoading = false;
      return;
    }

    // Solo enviar los campos permitidos por el DTO
    const spaceData = {
      title: formValue.title,
      description: formValue.description,
      address: formValue.address,
      lat: formValue.lat,
      lon: formValue.lon,
      capacity: formValue.capacity,
      basePriceCents: Math.round(formValue.basePriceCents * 100),
      areaSqm: formValue.areaSqm,
      amenities: formValue.amenities || [],
      ownerId: userId
    };

    this.spacesService.updateSpace(this.editingSpaceId, spaceData).subscribe({
      next: (updatedSpace) => {
        console.log('✅ Espacio actualizado:', updatedSpace);
        const index = this.mySpaces.findIndex(s => s.id === this.editingSpaceId);
        if (index !== -1) {
          this.mySpaces[index] = updatedSpace;
        }
        this.toastService.success('✓ Espacio actualizado exitosamente');
        this.changeView('spaces');
        this.resetForm();
        this.formLoading = false;
      },
      error: (error) => {
        console.error('❌ Error actualizando espacio:', error);
        this.formError = error.error?.message || 'Error al actualizar el espacio';
        this.toastService.error('Error al actualizar el espacio');
        this.formLoading = false;
      }
    });
  }

  confirmDelete(space: Space): void {
    this.spaceToDelete = space;
    this.showDeleteModal = true;
  }

  cancelDelete(): void {
    this.showDeleteModal = false;
    this.spaceToDelete = null;
  }

  deleteSpace(): void {
    if (!this.spaceToDelete) return;

    const spaceId = this.spaceToDelete.id;

    this.spacesService.deleteSpace(spaceId).subscribe({
      next: () => {
        console.log('✅ Espacio eliminado');
        const index = this.mySpaces.findIndex(s => s.id === spaceId);
        if (index !== -1) {
          this.mySpaces[index] = {
            ...this.mySpaces[index],
            status: 'DELETED'
          };
        }
        this.calculateStats();
        this.toastService.success('✓ Espacio eliminado exitosamente');
        this.changeSpacesFilter('deleted');
        this.cancelDelete();
      },
      error: (error) => {
        console.error('❌ Error eliminando espacio:', error);
        this.toastService.error('Error al eliminar el espacio');
        this.cancelDelete();
      }
    });
  }

  toggleSpaceStatus(space: Space): void {
    const action = space.status.toUpperCase() === 'ACTIVE' ? 'snooze' : 'activate';

    const request = action === 'activate'
      ? this.spacesService.activateSpace(space.id)
      : this.spacesService.snoozeSpace(space.id);

    request.subscribe({
      next: (updatedSpace) => {
        const actionText = action === 'activate' ? 'activado' : 'pausado';
        console.log(`✅ Espacio ${actionText}:`, updatedSpace);
        const index = this.mySpaces.findIndex(s => s.id === space.id);
        if (index !== -1) {
          this.mySpaces[index] = updatedSpace;
        }
        this.calculateStats();
        this.toastService.success(`✓ Espacio ${actionText} exitosamente`);
      },
      error: (error) => {
        const actionText = action === 'activate' ? 'activar' : 'pausar';
        console.error(`❌ Error al ${actionText} espacio:`, error);
        this.toastService.error(`Error al ${actionText} el espacio`);
      }
    });
  }

  // === FILTRADO DE ESPACIOS ===

  get filteredSpaces(): Space[] {
    if (this.spacesFilter === 'all') {
      return this.mySpaces;
    }
    return this.mySpaces.filter(s => {
      const status = s.status.toUpperCase();
      switch (this.spacesFilter) {
        case 'active':
          return status === 'ACTIVE';
        case 'snoozed':
          return status === 'SNOOZED';
        case 'deleted':
          return status === 'DELETED';
        default:
          return true;
      }
    });
  }

  changeSpacesFilter(filter: 'all' | 'active' | 'snoozed' | 'deleted'): void {
    this.spacesFilter = filter;
  }

  getSpacesCountByStatus(status: string): number {
    if (status === 'all') return this.mySpaces.length;
    return this.mySpaces.filter(s => s.status.toUpperCase() === status.toUpperCase()).length;
  }

  // === FORM HELPERS ===

  resetForm(): void {
    this.spaceForm.reset({
      capacity: 1,
      basePriceCents: 25.00, // Valor por defecto en euros
      amenities: []
    });
    this.editingSpaceId = null;
    this.formError = null;
    this.pendingImages = []; // Limpiar imágenes pendientes
  }

  // === UTILIDADES ===

  getStatusBadgeClass(status: string): string {
    const upperStatus = status.toUpperCase();
    const classes: { [key: string]: string } = {
      'ACTIVE': 'badge-success',
      'DRAFT': 'badge-warning',
      'SNOOZED': 'badge-info',
      'DELETED': 'badge-danger'
    };
    return classes[upperStatus] || 'badge-default';
  }

  getStatusText(status: string): string {
    const upperStatus = status.toUpperCase();
    const texts: { [key: string]: string } = {
      'ACTIVE': 'Activo',
      'DRAFT': 'Borrador',
      'SNOOZED': 'Pausado',
      'DELETED': 'Eliminado'
    };
    return texts[upperStatus] || status;
  }

  formatPrice(cents: number): string {
    return (cents / 100).toFixed(2);
  }

  private markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach(key => {
      const control = formGroup.get(key);
      control?.markAsTouched();
    });
  }

  viewSpaceDetail(spaceId: string): void {
    this.router.navigate(['/spaces', spaceId]);
  }

  toggleAmenity(amenity: string): void {
    const amenities = this.spaceForm.value.amenities || [];
    const index = amenities.indexOf(amenity);

    if (index > -1) {
      amenities.splice(index, 1);
    } else {
      amenities.push(amenity);
    }

    this.spaceForm.patchValue({ amenities });
  }

  getAmenityLabel(amenity: string): string {
    const labels: { [key: string]: string } = {
      'wifi': 'WiFi',
      'terraza': 'Terraza',
      'cocina': 'Cocina',
      'proyector': 'Proyector',
      'sonido': 'Sistema de sonido',
      'aire_acondicionado': 'Aire acondicionado',
      'calefaccion': 'Calefacción',
      'parking': 'Parking',
      'jardin': 'Jardín',
      'pizarra': 'Pizarra',
      'vistas': 'Vistas',
      'iluminacion': 'Iluminación profesional',
      'cafe': 'Café',
      'bao': 'Baño',
      'cocina_exterior': 'Cocina exterior'
    };
    return labels[amenity] || amenity;
  }

  // Helper methods for new template
  getFilteredSpaces(filter: string): Space[] {
    if (filter === 'all') return this.mySpaces;
    return this.mySpaces.filter(s => s.status.toUpperCase() === filter.toUpperCase());
  }

  getSpaceImage(space: Space): string {
    if (space.images && space.images.length > 0) {
      const primary = space.images.find(img => img.isPrimary);
      return primary ? primary.url : space.images[0].url;
    }
    return '/assets/images/placeholder-space.svg';
  }

  getStatusLabel(status: string | undefined): string {
    if (!status) return 'Desconocido';
    const labels: { [key: string]: string } = {
      'ACTIVE': 'Activo',
      'SNOOZED': 'Pausado',
      'DELETED': 'Eliminado',
      'DRAFT': 'Borrador',
      'PENDING': 'Pendiente',
      'CONFIRMED': 'Confirmada',
      'COMPLETED': 'Completada',
      'CANCELLED': 'Cancelada'
    };
    return labels[status.toUpperCase()] || status;
  }

  pauseSpace(space: Space): void {
    this.spacesService.snoozeSpace(space.id).subscribe({
      next: (updated) => {
        const index = this.mySpaces.findIndex(s => s.id === space.id);
        if (index !== -1) this.mySpaces[index] = updated;
        this.calculateStats();
        this.toastService.success('Espacio pausado');
      },
      error: () => this.toastService.error('Error al pausar el espacio')
    });
  }

  activateSpace(space: Space): void {
    this.spacesService.activateSpace(space.id).subscribe({
      next: (updated) => {
        const index = this.mySpaces.findIndex(s => s.id === space.id);
        if (index !== -1) this.mySpaces[index] = updated;
        this.calculateStats();
        this.toastService.success('Espacio activado');
      },
      error: () => this.toastService.error('Error al activar el espacio')
    });
  }

  viewSpace(spaceId: string): void {
    this.router.navigate(['/spaces', spaceId]);
  }

  // Métodos para gestionar reservas
  confirmBooking(booking: Booking): void {
    // TODO: Implementar confirmación de reserva cuando el backend lo soporte
    this.toastService.info('Funcionalidad de confirmar reserva próximamente');
  }

  rejectBooking(booking: Booking): void {
    this.bookingsService.cancelBooking(booking.id, 'Rechazada por el host').subscribe({
      next: () => {
        const index = this.receivedBookings.findIndex(b => b.id === booking.id);
        if (index !== -1) {
          this.receivedBookings[index].status = 'CANCELLED';
        }
        this.toastService.success('Reserva rechazada');
      },
      error: () => this.toastService.error('Error al rechazar la reserva')
    });
  }

  viewBookingSpace(booking: Booking): void {
    this.router.navigate(['/spaces', booking.spaceId]);
  }

  onImagesChanged(images: SpaceImage[]): void {
    console.log('📸 Imágenes actualizadas:', images);

    // Actualizar array local de imágenes (crear nueva referencia)
    this.spaceImages = [...images];

    // Actualizar el espacio en la lista mySpaces para que se refleje inmediatamente
    if (this.editingSpaceId) {
      const index = this.mySpaces.findIndex(s => s.id === this.editingSpaceId);
      if (index !== -1) {
        // Crear nuevo objeto para forzar detección de cambios
        this.mySpaces[index] = {
          ...this.mySpaces[index],
          images: [...images] // Copia del array de imágenes
        };

        // Forzar actualización del array completo
        this.mySpaces = [...this.mySpaces];

        console.log('✅ Espacio actualizado en lista con nuevas imágenes');
      }
    }
  }

  // === NUEVOS MÉTODOS PARA EL DISEÑO PREMIUM ===

  getUserName(): string {
    return localStorage.getItem('userName') || 'Host';
  }

  getGreeting(): string {
    const hour = new Date().getHours();
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  formatEarnings(cents: number): string {
    return (cents / 100).toLocaleString('es-ES', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  getRandomHeight(index: number): number {
    // Use cached heights with fixed index to avoid NG0100 error
    return chartHeights[index % chartHeights.length];
  }

  goToEarnings(): void {
    this.router.navigate(['/host/earnings']);
  }

  downloadReport(): void {
    // Generar CSV con datos de espacios y reservas
    const headers = ['Espacio', 'Estado', 'Precio/hora', 'Capacidad', 'Dirección'];
    const rows = this.mySpaces.map(space => [
      space.title,
      this.getStatusLabel(space.status),
      (space.basePriceCents / 100).toFixed(2) + '€',
      space.capacity.toString(),
      space.address
    ]);

    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
    ].join('\n');

    // Descargar archivo
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `balconazo-espacios-${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    this.toastService.success('Reporte CSV descargado');
  }
}
