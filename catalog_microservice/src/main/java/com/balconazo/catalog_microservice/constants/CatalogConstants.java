package com.balconazo.catalog_microservice.constants;

public final class CatalogConstants {
    private CatalogConstants() {}

    public static final String ROLE_HOST = "host";
    public static final String ROLE_GUEST = "guest";
    public static final String ROLE_ADMIN = "admin";

    public static final String STATUS_ACTIVE = "active";
    public static final String STATUS_SUSPENDED = "suspended";
    public static final String STATUS_DELETED = "deleted";

    public static final String SPACE_STATUS_DRAFT = "draft";
    public static final String SPACE_STATUS_ACTIVE = "active";
    public static final String SPACE_STATUS_SNOOZED = "snoozed";
    public static final String SPACE_STATUS_DELETED = "deleted";

    public static final String TOPIC_SPACE_EVENTS = "space-events-v1";
    public static final String TOPIC_AVAILABILITY_EVENTS = "availability-events-v1";

    public static final String EVENT_SPACE_CREATED = "SpaceCreated";
    public static final String EVENT_SPACE_UPDATED = "SpaceUpdated";
    public static final String EVENT_SPACE_DEACTIVATED = "SpaceDeactivated";
    public static final String EVENT_AVAILABILITY_ADDED = "AvailabilityAdded";
    public static final String EVENT_AVAILABILITY_REMOVED = "AvailabilityRemoved";
}

