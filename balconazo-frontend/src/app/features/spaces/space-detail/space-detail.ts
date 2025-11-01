import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, CreateBookingDTO } from '../../../core/services/bookings.service';

@Component({
  selector: 'app-space-detail',
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule],
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

  selectedImageIndex = 0;
  showAllAmenities = false;

  // Mock reviews (TODO: cargar desde backend)
  reviews = [
    {
      id: '1',
      guestName: 'María García',
      rating: 5,
      comment: 'Espacio increíble, perfecto para nuestro evento. El anfitrión fue muy atento.',
      date: '2025-10-15',
      avatar: 'https://i.pravatar.cc/150?img=1'
    },
    {
      id: '2',
      guestName: 'Carlos Rodríguez',
      rating: 4,
      comment: 'Muy buena ubicación y el espacio está muy bien cuidado. Recomendable.',
      date: '2025-10-10',
      avatar: 'https://i.pravatar.cc/150?img=2'
    }
  ];

  constructor() {
    this.bookingForm = this.fb.group({
      startDate: ['', Validators.required],
      startTime: ['10:00', Validators.required],
      endDate: ['', Validators.required],
      endTime: ['18:00', Validators.required],
      numGuests: [1, [Validators.required, Validators.min(1)]]
    });

    // Calcular precio cuando cambian los valores
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
        this.error = 'No se pudo cargar el espacio';
        this.loading = false;

        // Fallback a datos mock
        this.loadMockSpace(id);
      }
    });
  }

  private loadMockSpace(id: string): void {
    console.log('⚠️ Usando espacio mock');
    this.space = {
      id: id,
      title: 'Ático moderno con terraza panorámica',
      description: 'Espacio único en el corazón de Madrid, perfecto para eventos corporativos, celebraciones privadas o sesiones de fotos. Cuenta con una amplia terraza con vistas panorámicas a la ciudad, cocina totalmente equipada y zona de estar confortable.',
      address: 'Calle Gran Vía 28, 28013 Madrid, España',
      lat: 40.4168,
      lon: -3.7038,
      capacity: 8,
      basePriceCents: 2500,
      areaSqm: 50,
      amenities: ['wifi', 'cocina', 'aire_acondicionado', 'calefaccion', 'terraza', 'parking'],
      status: 'ACTIVE',
      ownerId: '11111111-1111-1111-1111-111111111111'
    };
    this.loading = false;
  }

  getImages(): string[] {
    // TODO: Cargar imágenes reales del backend
    return [
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&h=800&fit=crop',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=1200&h=800&fit=crop',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&h=800&fit=crop',
      'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1200&h=800&fit=crop'
    ];
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
      'wifi_pro': 'WiFi profesional'
    };
    return names[amenity] || amenity;
  }

  getAverageRating(): number {
    if (this.reviews.length === 0) return 0;
    const sum = this.reviews.reduce((acc, review) => acc + review.rating, 0);
    return sum / this.reviews.length;
  }

  getRatingStars(rating: number): string {
    return '⭐'.repeat(Math.floor(rating)) + '☆'.repeat(5 - Math.floor(rating));
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
}

