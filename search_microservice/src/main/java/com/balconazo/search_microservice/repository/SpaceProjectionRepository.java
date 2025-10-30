package com.balconazo.search_microservice.repository;

import com.balconazo.search_microservice.entity.SpaceProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface SpaceProjectionRepository extends JpaRepository<SpaceProjection, UUID> {

    /**
     * Búsqueda geoespacial por radio con filtros
     */
    @Query(value = """
        SELECT 
            s.*,
            ST_Distance(s.geo::geography, 
                       ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) / 1000 as distance_km
        FROM search.spaces_projection s
        WHERE ST_DWithin(s.geo::geography, 
                        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 
                        :radiusMeters)
          AND s.status = 'active'
          AND (:minCapacity IS NULL OR s.capacity >= :minCapacity)
          AND (:minPrice IS NULL OR s.base_price_cents >= :minPrice)
          AND (:maxPrice IS NULL OR s.base_price_cents <= :maxPrice)
          AND (:minRating IS NULL OR s.avg_rating >= :minRating)
        ORDER BY 
          CASE WHEN :sortBy = 'distance' THEN ST_Distance(s.geo::geography, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) END ASC,
          CASE WHEN :sortBy = 'price' THEN s.base_price_cents END ASC,
          CASE WHEN :sortBy = 'price_desc' THEN s.base_price_cents END DESC,
          CASE WHEN :sortBy = 'rating' THEN s.avg_rating END DESC,
          CASE WHEN :sortBy = 'capacity' THEN s.capacity END DESC
        LIMIT :limit OFFSET :offset
        """, nativeQuery = true)
    List<Object[]> searchByLocation(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") int radiusMeters,
        @Param("minCapacity") Integer minCapacity,
        @Param("minPrice") Integer minPrice,
        @Param("maxPrice") Integer maxPrice,
        @Param("minRating") Double minRating,
        @Param("sortBy") String sortBy,
        @Param("limit") int limit,
        @Param("offset") int offset
    );

    /**
     * Contar resultados de búsqueda
     */
    @Query(value = """
        SELECT COUNT(*)
        FROM search.spaces_projection s
        WHERE ST_DWithin(s.geo::geography, 
                        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography, 
                        :radiusMeters)
          AND s.status = 'active'
          AND (:minCapacity IS NULL OR s.capacity >= :minCapacity)
          AND (:minPrice IS NULL OR s.base_price_cents >= :minPrice)
          AND (:maxPrice IS NULL OR s.base_price_cents <= :maxPrice)
          AND (:minRating IS NULL OR s.avg_rating >= :minRating)
        """, nativeQuery = true)
    long countSearchResults(
        @Param("lat") double lat,
        @Param("lon") double lon,
        @Param("radiusMeters") int radiusMeters,
        @Param("minCapacity") Integer minCapacity,
        @Param("minPrice") Integer minPrice,
        @Param("maxPrice") Integer maxPrice,
        @Param("minRating") Double minRating
    );

    /**
     * Buscar por amenidades específicas
     */
    @Query(value = """
        SELECT s.* FROM search.spaces_projection s
        WHERE s.status = 'active'
          AND s.amenities @> CAST(:amenities AS text[])
        """, nativeQuery = true)
    List<SpaceProjection> findByAmenities(@Param("amenities") String[] amenities);

    /**
     * Buscar espacios por owner
     */
    List<SpaceProjection> findByOwnerId(UUID ownerId);

    /**
     * Buscar espacios activos
     */
    List<SpaceProjection> findByStatus(String status);
}

