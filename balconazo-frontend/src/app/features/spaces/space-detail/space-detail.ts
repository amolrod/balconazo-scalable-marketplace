import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { SpacesService, Space } from '../../../core/services/spaces.service';
import { BookingsService, CreateBookingDTO, Review, CreateReviewDTO } from '../../../core/services/bookings.service';
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

  // Reviews (cargadas del backend)
  reviews: Review[] = [];
  averageRating = 0;
  totalReviews = 0;
  reviewsLoading = false;
  reviewsError: string | null = null;

  // Review eligibility
  canWriteReview = false;
  eligibilityLoading = false;
  completedBookingId: string | null = null;

  // Review Form
  showReviewForm = false;
  reviewForm: FormGroup;
  reviewSubmitting = false;
  reviewError: string | null = null;

  constructor() {
    console.log('🔧 SpaceDetailComponent constructor');
    this.bookingForm = this.fb.group({
      startDate: ['', Validators.required],
      startTime: ['10:00', Validators.required],
      endDate: ['', Validators.required],
      endTime: ['18:00', Validators.required],
      numGuests: [1, [Validators.required, Validators.min(1)]]
    });

    this.reviewForm = this.fb.group({
      rating: [5, [Validators.required, Validators.min(1), Validators.max(5)]],
      comment: ['', [Validators.required, Validators.minLength(10), Validators.maxLength(2000)]]
    });

    this.bookingForm.valueChanges.subscribe(() => {
      this.calculatePrice();
    });
  }

  ngOnInit(): void {
    const spaceId = this.route.snapshot.paramMap.get('id');
    if (spaceId) {
      this.loadSpace(spaceId);
      this.loadReviews(spaceId);
      this.checkReviewEligibility(spaceId);
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
      // Placeholder local si no hay imágenes
      return ['/assets/images/placeholder-space.svg'];
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

  // ============================================
  // REVIEWS
  // ============================================

  loadReviews(spaceId: string): void {
    this.reviewsLoading = true;
    this.reviewsError = null;

    this.bookingsService.getReviewsBySpace(spaceId).subscribe({
      next: (reviews) => {
        this.reviews = reviews;
        this.totalReviews = reviews.length;
        this.calculateAverageRating();
        this.reviewsLoading = false;
        console.log('✅ Reviews cargadas:', reviews.length);
      },
      error: (error) => {
        console.error('❌ Error cargando reviews:', error);
        this.reviewsError = 'No se pudieron cargar las reseñas';
        this.reviewsLoading = false;
      }
    });
  }

  /**
   * Verificar si el usuario puede escribir una reseña para este espacio
   */
  checkReviewEligibility(spaceId: string): void {
    const token = localStorage.getItem('accessToken'); // CORREGIDO: era 'authToken'

    console.log('🔍 Verificando elegibilidad para espacio:', spaceId);
    console.log('🔑 Token en localStorage:', token ? 'SÍ' : 'NO');

    // Si no está autenticado, no puede escribir reseñas
    if (!token) {
      console.log('❌ No hay token, canWriteReview = false');
      this.canWriteReview = false;
      return;
    }

    this.eligibilityLoading = true;
    console.log('⏳ Consultando reservas...');

    this.bookingsService.hasCompletedBookingForSpace(spaceId).subscribe({
      next: (result) => {
        console.log('✅ Resultado elegibilidad COMPLETO:', JSON.stringify(result, null, 2));
        
        // Solo puede escribir si tiene reserva completada Y no ha dejado reseña
        this.canWriteReview = result.hasBooking && !result.alreadyReviewed;
        this.completedBookingId = result.bookingId || null;
        this.eligibilityLoading = false;
        
        console.log('🎯 canWriteReview =', this.canWriteReview);
        console.log('📝 Ya dejó reseña =', result.alreadyReviewed);
        console.log('🎫 completedBookingId GUARDADO =', this.completedBookingId);
        console.log('📊 Estado del componente:', {
          canWriteReview: this.canWriteReview,
          completedBookingId: this.completedBookingId,
          alreadyReviewed: result.alreadyReviewed,
          spaceId: this.space?.id
        });
      },
      error: (error) => {
        console.error('❌ Error verificando elegibilidad:', error);
        this.canWriteReview = false;
        this.eligibilityLoading = false;
      }
    });
  }  calculateAverageRating(): void {
    if (this.reviews.length === 0) {
      this.averageRating = 0;
      return;
    }

    const sum = this.reviews.reduce((acc, review) => acc + review.rating, 0);
    this.averageRating = sum / this.reviews.length;
  }

  toggleReviewForm(): void {
    const userId = localStorage.getItem('userId');
    if (!userId) {
      // Redirigir a login
      this.router.navigate(['/login'], {
        queryParams: { returnUrl: this.router.url }
      });
      return;
    }

    this.showReviewForm = !this.showReviewForm;
    if (!this.showReviewForm) {
      this.reviewForm.reset({ rating: 5, comment: '' });
      this.reviewError = null;
    }
  }

  submitReview(): void {
    console.log('📝 submitReview() iniciado');
    console.log('📋 Formulario válido:', this.reviewForm.valid);
    console.log('🏠 Space presente:', !!this.space);

    if (!this.reviewForm.valid || !this.space) {
      console.error('❌ Formulario inválido o sin espacio');
      return;
    }

    const userId = localStorage.getItem('userId');
    if (!userId) {
      console.error('❌ No hay userId en localStorage');
      this.router.navigate(['/login']);
      return;
    }

    console.log('🎫 completedBookingId ANTES de validar:', this.completedBookingId);
    console.log('🔍 Tipo de completedBookingId:', typeof this.completedBookingId);
    console.log('🔍 Valor exacto:', this.completedBookingId);

    if (!this.completedBookingId || this.completedBookingId === 'undefined' || this.completedBookingId === 'null') {
      this.reviewError = 'No se encontró una reserva completada para este espacio. Por favor, recarga la página.';
      console.error('❌ No hay bookingId disponible - ESTADO COMPLETO:', {
        completedBookingId: this.completedBookingId,
        completedBookingIdType: typeof this.completedBookingId,
        canWriteReview: this.canWriteReview,
        spaceId: this.space?.id,
        userId: localStorage.getItem('userId')
      });

      // Intentar recargar eligibilidad
      console.log('🔄 Intentando recargar elegibilidad...');
      if (this.space?.id) {
        this.checkReviewEligibility(this.space.id);
      }
      return;
    }

    this.reviewSubmitting = true;
    this.reviewError = null;

    const reviewData: CreateReviewDTO = {
      bookingId: this.completedBookingId,
      rating: this.reviewForm.value.rating,
      comment: this.reviewForm.value.comment
    };

    console.log('📤 Enviando review con datos COMPLETOS:', {
      bookingId: reviewData.bookingId,
      bookingIdLength: reviewData.bookingId?.length,
      bookingIdType: typeof reviewData.bookingId,
      rating: reviewData.rating,
      comment: reviewData.comment?.substring(0, 50) + '...'
    });

    this.bookingsService.createReview(reviewData).subscribe({
      next: (review) => {
        console.log('✅ Review creada:', review);
        this.reviewSubmitting = false;
        this.showReviewForm = false;
        this.reviewForm.reset({ rating: 5, comment: '' });

        // Recargar reviews
        if (this.space) {
          this.loadReviews(this.space.id);
        }
      },
      error: (error) => {
        console.error('❌ Error creando review:', error);
        this.reviewError = error.error?.message || 'No se pudo crear la reseña. Verifica que tengas una reserva completada para este espacio.';
        this.reviewSubmitting = false;
      }
    });
  }
}
