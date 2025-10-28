package com.balconazo.search_microservice.constants;

public class SearchConstants {

    // Kafka Topics
    public static final String TOPIC_SPACE_EVENTS = "space-events-v1";
    public static final String TOPIC_AVAILABILITY_EVENTS = "availability-events-v1";
    public static final String TOPIC_BOOKING_EVENTS = "booking.events.v1";
    public static final String TOPIC_REVIEW_EVENTS = "review.events.v1";

    // Consumer Group
    public static final String CONSUMER_GROUP = "search-service";

    // Default values
    public static final int DEFAULT_SEARCH_RADIUS_KM = 10;
    public static final int DEFAULT_PAGE_SIZE = 20;
    public static final String DEFAULT_SORT_BY = "distance";

    // Pricing factors
    public static final double DEMAND_FACTOR_WEIGHT = 0.3;
    public static final double SEASONALITY_FACTOR_WEIGHT = 0.2;
    public static final double RATING_FACTOR_WEIGHT = 0.1;
    public static final double LOCATION_FACTOR_WEIGHT = 0.15;

    // Status
    public static final String STATUS_ACTIVE = "active";
    public static final String STATUS_INACTIVE = "inactive";
    public static final String STATUS_DRAFT = "draft";

    private SearchConstants() {
        throw new IllegalStateException("Constants class");
    }
}

