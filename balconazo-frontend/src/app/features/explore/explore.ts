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

  // Amenities options with SVG icons
  amenitiesOptions = [
    { value: 'wifi', label: 'WiFi', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/></svg>' },
    { value: 'parking', label: 'Parking', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 17V7h4a3 3 0 0 1 0 6H9"/></svg>' },
    { value: 'terraza', label: 'Terraza', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 21h18"/><path d="M5 21V7l7-4 7 4v14"/><path d="M9 21v-6h6v6"/></svg>' },
    { value: 'cocina', label: 'Cocina', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 7c0-1.1.9-2 2-2h14a2 2 0 0 1 2 2v13H3V7z"/><path d="M8 5V3"/><path d="M16 5V3"/><path d="M12 5V3"/><path d="M3 11h18"/></svg>' },
    { value: 'barbacoa', label: 'Barbacoa', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 12c-2-2.67 0-6-1-8 0 3-2 4-3 6-.57.66-1 1.85-1 3a5 5 0 0 0 10 0c0-.86-.29-2.17-1-3-2 3-2.87 3-4 2z"/><path d="M5 18h14"/><path d="M7 22l3-4"/><path d="M14 22l3-4"/></svg>' },
    { value: 'piscina', label: 'Piscina', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12h20"/><path d="M2 12c1-2 3-3 5-3s4 2 5 4 3 4 5 4 4-1 5-3"/><path d="M2 18c1-2 3-3 5-3s4 2 5 4 3 4 5 4 4-1 5-3"/></svg>' },
    { value: 'aire_acondicionado', label: 'Aire Acond.', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 16a4 4 0 1 0 8 0"/><path d="M12 4v8"/><path d="m6 12 6-4 6 4"/></svg>' },
    { value: 'musica', label: 'Música', icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>' }
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

  toggleSortOrder(): void {
    this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    this.applyFilters();
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

