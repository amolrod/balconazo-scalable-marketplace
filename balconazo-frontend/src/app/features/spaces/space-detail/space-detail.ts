import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, CreateBookingDTO } from '../../../core/services/bookings.service';
import { RatingStarsComponent } from '../../../shared/components/rating-stars/rating-stars';
import { PricePipe } from '../../../shared/pipes/price.pipe';

@Component({
  selector: 'app-space-detail',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule,
    RatingStarsComponent,
    PricePipe
  ],
  templateUrl: './space-detail.html',
  styleUrl: './space-detail.scss'
})
export class SpaceDetailComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private spacesService = inject(SpacesService);
  private bookingsService = inject(BookingsService);

  space: Space | null = null;
  loading = true;
  error: string | null = null;

  bookingForm: FormGroup;
  bookingLoading = false;
  bookingError: string | null = null;
  estimatedPrice: number | null = null;

  // Gallery
  selectedImageIndex = 0;
  showGalleryModal = false;

  // Amenities
  showAllAmenities = false;

  // Reviews (mock para este PR, se implementarán con backend)
  reviews: any[] = [
    {
      id: 1,
      guestName: 'María García',
      rating: 5,
      comment: 'Espacio increíble, perfecto para nuestra reunión. El anfitrión fue muy atento.',
      date: '2025-10-15',
      guestAvatar: 'M'
    },
    {
      id: 2,
      guestName: 'Carlos Ruiz',
      rating: 4,
      comment: 'Muy buen lugar, cómodo y bien ubicado. Solo faltaba un poco más de iluminación.',
      date: '2025-10-08',
      guestAvatar: 'C'
    }
  ];
  averageRating = 4.5;
  totalReviews = 2;

  constructor() {
    this.bookingForm = this.fb.group({
      startDate: ['', Validators.required],
      startTime: ['10:00', Validators.required],
      endDate: ['', Validators.required],
      endTime: ['18:00', Validators.required],
      numGuests: [1, [Validators.required, Validators.min(1)]]
    });

    this.bookingForm.valueChanges.subscribe(() => {
      this.calculatePrice();
    });
  }

  ngOnInit(): void {
    const spaceId = this.route.snapshot.paramMap.get('id');
    if (spaceId) {
      this.loadSpace(spaceId);
    } else {
      this.router.navigate(['/']);
    }
  }

  loadSpace(id: string): void {
    this.loading = true;
    this.error = null;

    this.spacesService.getSpaceById(id).subscribe({
      next: (space) => {
        this.space = space;
        this.loading = false;
        console.log('✅ Espacio cargado:', space);
      },
      error: (error) => {
        console.error('❌ Error cargando espacio:', error);
        this.error = 'No se pudo cargar el espacio. Verifica que exista y el backend esté corriendo.';
        this.loading = false;
      }
    });
  }

  getImages(): string[] {
    if (!this.space || !this.space.images || this.space.images.length === 0) {
      // Placeholder si no hay imágenes
      return [
        `https://via.placeholder.com/1200x800/E5E7EB/6B7280?text=${encodeURIComponent(this.space?.title || 'Sin imagen')}`
      ];
    }

    // Retornar las URLs de las imágenes reales, ordenadas (principal primero)
    const sorted = [...this.space.images].sort((a, b) => {
      if (a.isPrimary) return -1;
      if (b.isPrimary) return 1;
      return a.displayOrder - b.displayOrder;
    });

    return sorted.map(img => img.url);
  }

  selectImage(index: number): void {
    this.selectedImageIndex = index;
  }

  calculatePrice(): void {
    if (!this.space || !this.bookingForm.valid) {
      this.estimatedPrice = null;
      return;
    }

    const values = this.bookingForm.value;
    const startDateTime = new Date(`${values.startDate}T${values.startTime}`);
    const endDateTime = new Date(`${values.endDate}T${values.endTime}`);

    const hours = (endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60);

    if (hours > 0) {
      const pricePerHour = this.space.basePriceCents / 100;
      this.estimatedPrice = Math.round(pricePerHour * hours);
    } else {
      this.estimatedPrice = null;
    }
  }

  onSubmitBooking(): void {
    if (!this.bookingForm.valid || !this.space) {
      return;
    }

    const userId = localStorage.getItem('userId');
    if (!userId) {
      this.router.navigate(['/login'], {
        queryParams: { returnUrl: this.router.url }
      });
      return;
    }

    this.bookingLoading = true;
    this.bookingError = null;

    const values = this.bookingForm.value;
    const startTs = new Date(`${values.startDate}T${values.startTime}`).toISOString();
    const endTs = new Date(`${values.endDate}T${values.endTime}`).toISOString();

    const bookingData: CreateBookingDTO = {
      spaceId: this.space.id,
      guestId: userId,
      startTs: startTs,
      endTs: endTs,
      numGuests: values.numGuests
    };

    this.bookingsService.createBooking(bookingData).subscribe({
      next: (booking) => {
        console.log('✅ Reserva creada:', booking);
        this.bookingLoading = false;
        // Redirigir a página de pago o confirmación
        this.router.navigate(['/bookings', booking.id, 'payment']);
      },
      error: (error) => {
        console.error('❌ Error creando reserva:', error);
        this.bookingError = error.error?.message || 'Error al crear la reserva';
        this.bookingLoading = false;
      }
    });
  }

  getAmenityIcon(amenity: string): string {
    const icons: { [key: string]: string } = {
      'wifi': '📶',
      'cocina': '🍳',
      'aire_acondicionado': '❄️',
      'calefaccion': '🔥',
      'terraza': '🏞️',
      'parking': '🅿️',
      'ascensor': '🛗',
      'accesible': '♿',
      'mascotas': '🐕',
      'proyector': '📽️',
      'sonido': '🔊',
      'wifi_pro': '📡'
    };
    return icons[amenity] || '✓';
  }

  getAmenityName(amenity: string): string {
    const names: { [key: string]: string } = {
      'wifi': 'WiFi',
      'cocina': 'Cocina equipada',
      'aire_acondicionado': 'Aire acondicionado',
      'calefaccion': 'Calefacción',
      'terraza': 'Terraza',
      'parking': 'Parking',
      'ascensor': 'Ascensor',
      'accesible': 'Accesible',
      'mascotas': 'Se admiten mascotas',
      'proyector': 'Proyector',
      'sonido': 'Sistema de sonido',
      'wifi_pro': 'WiFi profesional',
      'vistas': 'Vistas',
      'iluminacion': 'Iluminación profesional',
      'pizarra': 'Pizarra',
      'cafe': 'Café',
      'jardin': 'Jardín',
      'bao': 'Baño',
      'cocina_exterior': 'Cocina exterior'
    };
    return names[amenity] || amenity;
  }

  formatDate(dateString: string): string {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('es-ES', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    }).format(date);
  }

  goBack(): void {
    this.router.navigate(['/']);
  }

  shareSpace(): void {
    if (navigator.share && this.space) {
      navigator.share({
        title: this.space.title,
        text: this.space.description,
        url: window.location.href
      }).catch(err => console.log('Error sharing:', err));
    } else {
      // Fallback: copiar al portapapeles
      navigator.clipboard.writeText(window.location.href);
      alert('¡Enlace copiado al portapapeles!');
    }
  }

  toggleFavorite(): void {
    // TODO: Implementar sistema de favoritos
    console.log('Toggle favorite');
  }

  // Gallery methods
  openGallery(index: number): void {
    this.selectedImageIndex = index;
    this.showGalleryModal = true;
    document.body.style.overflow = 'hidden';
  }

  closeGallery(): void {
    this.showGalleryModal = false;
    document.body.style.overflow = '';
  }

  nextImage(): void {
    const images = this.getImages();
    this.selectedImageIndex = (this.selectedImageIndex + 1) % images.length;
  }

  prevImage(): void {
    const images = this.getImages();
    this.selectedImageIndex = (this.selectedImageIndex - 1 + images.length) % images.length;
  }

  get displayedAmenities(): string[] {
    if (!this.space?.amenities) return [];
    return this.showAllAmenities ? this.space.amenities : this.space.amenities.slice(0, 8);
  }

  get hasMoreAmenities(): boolean {
    return (this.space?.amenities?.length || 0) > 8;
  }

  toggleAmenities(): void {
    this.showAllAmenities = !this.showAllAmenities;
  }
}
