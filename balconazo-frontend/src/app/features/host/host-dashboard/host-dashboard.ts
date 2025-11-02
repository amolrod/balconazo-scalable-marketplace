import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, Booking } from '../../../core/services/bookings.service';
import { ToastService } from '../../../core/services/toast.service';

interface DashboardStats {
  totalSpaces: number;
  activeSpaces: number;
  totalBookings: number;
  totalEarnings: number;
  pendingBookings: number;
  monthlyEarnings: number;
}

@Component({
  selector: 'app-host-dashboard',
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule],
  templateUrl: './host-dashboard.html',
  styleUrl: './host-dashboard.scss'
})
export class HostDashboardComponent implements OnInit {
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private spacesService = inject(SpacesService);
  private bookingsService = inject(BookingsService);
  private toastService = inject(ToastService);

  // Estado
  loading = true;
  currentView: 'overview' | 'spaces' | 'bookings' | 'create-space' | 'edit-space' = 'overview';
  spacesFilter: 'all' | 'active' | 'snoozed' | 'deleted' = 'active'; // Filtro de espacios (eliminado ARCHIVED)

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
      },
      error: (error) => {
        console.error('❌ Error cargando espacios:', error);
        this.mySpaces = [];
        this.loading = false;
      }
    });

    // TODO: Cargar bookings recibidos cuando el backend lo implemente
    // Por ahora, stats basados solo en espacios
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
        this.mySpaces.unshift(space);
        this.calculateStats();
        this.toastService.success('✓ Espacio creado exitosamente');
        this.changeView('spaces');
        this.resetForm();
        this.formLoading = false;
      },
      error: (error) => {
        console.error('❌ Error creando espacio:', error);
        this.formError = error.error?.message || 'Error al crear el espacio';
        this.toastService.error('Error al crear el espacio');
        this.formLoading = false;
      }
    });
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

  openDeleteModal(space: Space): void {
    this.spaceToDelete = space;
    this.showDeleteModal = true;
  }

  closeDeleteModal(): void {
    this.showDeleteModal = false;
    this.spaceToDelete = null;
  }

  confirmDelete(): void {
    if (!this.spaceToDelete) return;

    const spaceId = this.spaceToDelete.id;

    this.spacesService.deleteSpace(spaceId).subscribe({
      next: () => {
        console.log('✅ Espacio eliminado');
        // NO eliminamos del array, solo actualizamos el estado a DELETED
        const index = this.mySpaces.findIndex(s => s.id === spaceId);
        if (index !== -1) {
          this.mySpaces[index] = {
            ...this.mySpaces[index],
            status: 'DELETED'
          };
        }
        this.calculateStats();
        this.toastService.success('✓ Espacio eliminado exitosamente');
        // Cambiar automáticamente al filtro de eliminados para ver el espacio
        this.changeSpacesFilter('deleted');
        this.closeDeleteModal();
      },
      error: (error) => {
        console.error('❌ Error eliminando espacio:', error);
        this.toastService.error('Error al eliminar el espacio');
        this.closeDeleteModal();
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
}
