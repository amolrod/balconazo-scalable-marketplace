import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { SpacesService, Space } from '../../core/services/spaces.service';
import { SpaceCardComponent } from '../../shared/components/space-card/space-card';
import { SkeletonListComponent } from '../../shared/components/skeleton-list/skeleton-list';
import { EmptyStateComponent } from '../../shared/components/empty-state/empty-state';
import { SpaceFilters } from '../../core/models/filter.model';

/**
 * Explore/Search Page Component
 * Página de búsqueda y exploración de espacios con mapa y filtros
 */
@Component({
  selector: 'app-explore',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    SpaceCardComponent,
    SkeletonListComponent,
    EmptyStateComponent
  ],
  templateUrl: './explore.html',
  styleUrl: './explore.scss'
})
export class ExploreComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private spacesService = inject(SpacesService);

  // State
  loading = false;
  spaces: Space[] = [];
  error: string | null = null;

  // View mode
  viewMode: 'grid' | 'list' = 'grid';
  showFilters = true;

  // Filters
  filters: SpaceFilters = {
    price: { min: undefined, max: undefined },
    capacity: { min: undefined, max: undefined },
    amenities: []
  };

  // Search params
  searchLocation = '';
  searchDate = '';
  searchCapacity: number | null = null;

  // Sorting
  sortBy: 'distance' | 'price' | 'rating' = 'distance';
  sortOrder: 'asc' | 'desc' = 'asc';

  // Pagination
  currentPage = 1;
  pageSize = 20;
  hasMore = true;

  // Amenities options
  amenitiesOptions = [
    { value: 'wifi', label: 'WiFi', icon: '📶' },
    { value: 'parking', label: 'Parking', icon: '🅿️' },
    { value: 'terraza', label: 'Terraza', icon: '🏞️' },
    { value: 'cocina', label: 'Cocina', icon: '🍳' },
    { value: 'barbacoa', label: 'Barbacoa', icon: '🔥' },
    { value: 'piscina', label: 'Piscina', icon: '🏊' },
    { value: 'aire_acondicionado', label: 'Aire Acondicionado', icon: '❄️' },
    { value: 'musica', label: 'Sistema de Música', icon: '🎵' }
  ];

  ngOnInit(): void {
    // Get query params from URL
    this.route.queryParams.subscribe(params => {
      this.searchLocation = params['location'] || '';
      this.searchDate = params['date'] || '';
      this.searchCapacity = params['capacity'] ? Number(params['capacity']) : null;

      // Initialize filters from params
      if (params['minPrice']) this.filters.price!.min = Number(params['minPrice']);
      if (params['maxPrice']) this.filters.price!.max = Number(params['maxPrice']);
      if (params['minCapacity']) this.filters.capacity!.min = Number(params['minCapacity']);

      this.loadSpaces();
    });
  }

  loadSpaces(): void {
    this.loading = true;
    this.error = null;

    // For now, load all active spaces
    // TODO: Implement actual search/filter API
    this.spacesService.getActiveSpaces().subscribe({
      next: (spaces) => {
        this.spaces = this.filterSpaces(spaces);
        this.loading = false;
      },
      error: (error) => {
        console.error('❌ Error loading spaces:', error);
        this.error = 'No se pudieron cargar los espacios';
        this.loading = false;
      }
    });
  }

  filterSpaces(spaces: Space[]): Space[] {
    let filtered = [...spaces];

    // Filter by capacity
    if (this.searchCapacity) {
      filtered = filtered.filter(s => s.capacity >= this.searchCapacity!);
    }

    if (this.filters.capacity?.min) {
      filtered = filtered.filter(s => s.capacity >= this.filters.capacity!.min!);
    }

    // Filter by price
    if (this.filters.price?.min) {
      filtered = filtered.filter(s => s.basePriceCents >= this.filters.price!.min! * 100);
    }

    if (this.filters.price?.max) {
      filtered = filtered.filter(s => s.basePriceCents <= this.filters.price!.max! * 100);
    }

    // Filter by amenities
    if (this.filters.amenities && this.filters.amenities.length > 0) {
      filtered = filtered.filter(space => {
        if (!space.amenities) return false;
        return this.filters.amenities!.some(amenity =>
          space.amenities!.includes(amenity)
        );
      });
    }

    // Sort
    filtered = this.sortSpaces(filtered);

    return filtered;
  }

  sortSpaces(spaces: Space[]): Space[] {
    return spaces.sort((a, b) => {
      let comparison = 0;

      switch (this.sortBy) {
        case 'price':
          comparison = a.basePriceCents - b.basePriceCents;
          break;
        case 'distance':
          // TODO: Calculate actual distance
          comparison = 0;
          break;
        case 'rating':
          // TODO: Implement rating
          comparison = 0;
          break;
      }

      return this.sortOrder === 'asc' ? comparison : -comparison;
    });
  }

  applyFilters(): void {
    this.currentPage = 1;
    this.loadSpaces();
  }

  clearFilters(): void {
    this.filters = {
      price: {},
      capacity: {},
      amenities: []
    };
    this.searchCapacity = null;
    this.currentPage = 1;
    this.loadSpaces();
  }

  toggleAmenity(amenity: string): void {
    if (!this.filters.amenities) {
      this.filters.amenities = [];
    }

    const index = this.filters.amenities.indexOf(amenity);
    if (index > -1) {
      this.filters.amenities.splice(index, 1);
    } else {
      this.filters.amenities.push(amenity);
    }

    this.applyFilters();
  }

  isAmenitySelected(amenity: string): boolean {
    return this.filters.amenities?.includes(amenity) || false;
  }

  changeSortBy(sortBy: 'distance' | 'price' | 'rating'): void {
    if (this.sortBy === sortBy) {
      // Toggle order
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = sortBy;
      this.sortOrder = 'asc';
    }
    this.applyFilters();
  }

  toggleViewMode(): void {
    this.viewMode = this.viewMode === 'grid' ? 'list' : 'grid';
  }

  toggleFilters(): void {
    this.showFilters = !this.showFilters;
  }

  viewSpace(space: Space): void {
    this.router.navigate(['/spaces', space.id]);
  }

  loadMore(): void {
    // TODO: Implement pagination
    this.currentPage++;
  }
}

