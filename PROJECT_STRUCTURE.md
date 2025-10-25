# Estructura de Directorios - Balconazo

Árbol completo del proyecto mostrando la organización en capas hexagonales (domain → application → infrastructure → interfaces) para cada microservicio.

```
BalconazoApp/
│
├── README.md                          # Documentación principal (800-1200 líneas)
├── ARCHITECTURE.md                    # Decisiones arquitectónicas (ADRs, diagramas C4)
├── KAFKA_EVENTS.md                    # Contratos de eventos Kafka con schemas JSON
├── QUICKSTART.md                      # Guía rápida <30 min para levantar el proyecto
├── documentacion.md                   # Especificación técnica original
├── LICENSE                            # MIT License
├── .gitignore
│
├── pom.xml                            # Parent POM (BOM Spring Boot 3.3.3 + Cloud 2024.0.3)
│
├── docker-compose.yml                 # Orquestación completa (9 contenedores)
│
├── ddl/                               # Scripts DDL para inicialización de Postgres
│   ├── catalog.sql                    # Schema: catalog (users, spaces, availability_slots)
│   ├── booking.sql                    # Schema: booking (bookings, reviews, outbox)
│   └── search.sql                     # Schema: search (spaces_projection, price_surface, demand_agg)
│
├── docs/                              # Documentación adicional
│   ├── adr/                           # Architecture Decision Records
│   │   ├── 001-three-microservices.md
│   │   ├── 002-orchestration-saga.md
│   │   ├── 003-outbox-pattern.md
│   │   ├── 004-database-per-service.md
│   │   └── 005-cqrs-read-model.md
│   ├── diagrams/
│   │   ├── c4/
│   │   │   ├── context.puml           # Diagrama C4 nivel 1 (contexto)
│   │   │   ├── containers.puml        # Diagrama C4 nivel 2 (contenedores)
│   │   │   └── components.puml        # Diagrama C4 nivel 3 (componentes)
│   │   └── flows/
│   │       ├── booking-saga.puml      # Secuencia de booking completo
│   │       ├── pricing-streams.puml   # Topología Kafka Streams
│   │       └── search-query.puml      # Flujo de búsqueda geoespacial
│   └── postman/
│       └── Balconazo.postman_collection.json  # Colección de APIs para testing
│
├── backend/
│   │
│   ├── api-gateway/                   # Spring Cloud Gateway (puerto 8080)
│   │   ├── pom.xml
│   │   ├── Dockerfile                 # Multi-stage build (Maven + JRE 21)
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/com/balconazo/gateway/
│   │       │   │   ├── GatewayApplication.java
│   │       │   │   ├── config/
│   │       │   │   │   ├── SecurityConfig.java       # JWT validation con Keycloak
│   │       │   │   │   ├── RateLimiterConfig.java    # RedisRateLimiter
│   │       │   │   │   ├── CorsConfig.java           # CORS para frontend
│   │       │   │   │   └── RoutesConfig.java         # Routing a microservicios
│   │       │   │   └── filter/
│   │       │   │       └── CorrelationIdFilter.java  # Inyecta X-Correlation-Id
│   │       │   └── resources/
│   │       │       ├── application.yml                # Config principal
│   │       │       ├── application-dev.yml            # Keycloak localhost
│   │       │       └── application-prod.yml           # Cognito AWS
│   │       └── test/
│   │           └── java/com/balconazo/gateway/
│   │               └── GatewayApplicationTests.java
│   │
│   ├── catalog-service/               # Microservicio de Catálogo (puerto 8081)
│   │   ├── pom.xml                    # spring-boot-starter-web, JPA, Kafka, Redis, validation
│   │   ├── Dockerfile
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/com/balconazo/catalog/
│   │       │   │   ├── CatalogServiceApplication.java
│   │       │   │   │
│   │       │   │   ├── domain/                        # ⬅️ CAPA DE DOMINIO
│   │       │   │   │   ├── model/                     # Entidades y agregados
│   │       │   │   │   │   ├── User.java              # AggregateRoot: Usuario (host/guest/admin)
│   │       │   │   │   │   ├── Space.java             # AggregateRoot: Espacio publicado
│   │       │   │   │   │   ├── AvailabilitySlot.java  # Entity: Slot de disponibilidad
│   │       │   │   │   │   └── vo/                    # Value Objects
│   │       │   │   │   │       ├── SpaceId.java
│   │       │   │   │   │       ├── UserId.java
│   │       │   │   │   │       ├── Email.java
│   │       │   │   │   │       ├── Address.java
│   │       │   │   │   │       ├── GeoCoordinates.java
│   │       │   │   │   │       ├── Money.java
│   │       │   │   │   │       └── DateRange.java
│   │       │   │   │   ├── repository/                # Ports (interfaces)
│   │       │   │   │   │   ├── UserRepository.java
│   │       │   │   │   │   ├── SpaceRepository.java
│   │       │   │   │   │   └── AvailabilityRepository.java
│   │       │   │   │   ├── event/                     # Domain Events
│   │       │   │   │   │   ├── SpaceCreated.java
│   │       │   │   │   │   ├── SpaceUpdated.java
│   │       │   │   │   │   ├── SpaceDeactivated.java
│   │       │   │   │   │   ├── AvailabilityAdded.java
│   │       │   │   │   │   └── AvailabilityRemoved.java
│   │       │   │   │   └── service/                   # Domain Services
│   │       │   │   │       ├── SpaceDomainService.java
│   │       │   │   │       └── TrustScoreCalculator.java
│   │       │   │   │
│   │       │   │   ├── application/                   # ⬅️ CAPA DE APLICACIÓN
│   │       │   │   │   ├── dto/                       # DTOs de comando y consulta
│   │       │   │   │   │   ├── command/
│   │       │   │   │   │   │   ├── CreateSpaceCommand.java
│   │       │   │   │   │   │   ├── UpdateSpaceCommand.java
│   │       │   │   │   │   │   ├── CreateUserCommand.java
│   │       │   │   │   │   │   └── AddAvailabilityCommand.java
│   │       │   │   │   │   └── response/
│   │       │   │   │   │       ├── SpaceDto.java
│   │       │   │   │   │       ├── UserDto.java
│   │       │   │   │   │       └── AvailabilityDto.java
│   │       │   │   │   └── service/                   # Application Services (casos de uso)
│   │       │   │   │       ├── SpaceApplicationService.java    # Create, Update, List spaces
│   │       │   │   │       ├── UserApplicationService.java     # Create, Update users
│   │       │   │   │       └── AvailabilityApplicationService.java
│   │       │   │   │
│   │       │   │   ├── infrastructure/                # ⬅️ CAPA DE INFRAESTRUCTURA
│   │       │   │   │   ├── persistence/
│   │       │   │   │   │   ├── jpa/                   # Adaptadores JPA
│   │       │   │   │   │   │   ├── entity/
│   │       │   │   │   │   │   │   ├── UserJpaEntity.java
│   │       │   │   │   │   │   │   ├── SpaceJpaEntity.java
│   │       │   │   │   │   │   │   └── AvailabilityJpaEntity.java
│   │       │   │   │   │   │   ├── repository/
│   │       │   │   │   │   │   │   ├── UserJpaRepository.java   # extends JpaRepository
│   │       │   │   │   │   │   │   ├── SpaceJpaRepository.java
│   │       │   │   │   │   │   │   └── AvailabilityJpaRepository.java
│   │       │   │   │   │   │   └── adapter/
│   │       │   │   │   │   │       ├── JpaUserRepositoryAdapter.java  # implements UserRepository
│   │       │   │   │   │   │       ├── JpaSpaceRepositoryAdapter.java
│   │       │   │   │   │   │       └── JpaAvailabilityRepositoryAdapter.java
│   │       │   │   │   │   └── mapper/                # Mappers JPA ↔ Domain
│   │       │   │   │   │       ├── UserJpaMapper.java
│   │       │   │   │   │       └── SpaceJpaMapper.java
│   │       │   │   │   ├── messaging/
│   │       │   │   │   │   └── kafka/
│   │       │   │   │   │       ├── producer/
│   │       │   │   │   │       │   ├── SpaceEventProducer.java        # Publica a space.events.v1
│   │       │   │   │   │       │   └── AvailabilityEventProducer.java
│   │       │   │   │   │       ├── config/
│   │       │   │   │   │       │   └── KafkaProducerConfig.java
│   │       │   │   │   │       └── serializer/
│   │       │   │   │   │           └── DomainEventSerializer.java
│   │       │   │   │   └── config/
│   │       │   │   │       ├── JpaConfig.java
│   │       │   │   │       ├── RedisConfig.java
│   │       │   │   │       └── DataSourceConfig.java
│   │       │   │   │
│   │       │   │   └── interfaces/                    # ⬅️ CAPA DE INTERFACES (REST)
│   │       │   │       └── rest/
│   │       │   │           ├── controller/
│   │       │   │           │   ├── SpaceController.java       # @RestController /spaces
│   │       │   │           │   ├── UserController.java        # @RestController /users
│   │       │   │           │   └── AvailabilityController.java
│   │       │   │           ├── request/                       # DTOs de request HTTP
│   │       │   │           │   ├── CreateSpaceRequest.java
│   │       │   │           │   ├── UpdateSpaceRequest.java
│   │       │   │           │   └── AddAvailabilityRequest.java
│   │       │   │           ├── response/                      # DTOs de response HTTP
│   │       │   │           │   ├── SpaceResponse.java
│   │       │   │           │   └── UserResponse.java
│   │       │   │           ├── mapper/                        # MapStruct mappers
│   │       │   │           │   ├── SpaceRestMapper.java       # Request → Command, Dto → Response
│   │       │   │           │   └── UserRestMapper.java
│   │       │   │           └── exception/
│   │       │   │               ├── GlobalExceptionHandler.java  # @ControllerAdvice
│   │       │   │               └── ErrorResponse.java
│   │       │   │
│   │       │   └── resources/
│   │       │       ├── application.yml                # Config compartida
│   │       │       ├── application-dev.yml            # Dev: localhost, Kafka local
│   │       │       ├── application-prod.yml           # Prod: AWS RDS, MSK
│   │       │       └── db/migration/                  # Flyway migrations (opcional)
│   │       │           ├── V1__create_users_table.sql
│   │       │           ├── V2__create_spaces_table.sql
│   │       │           └── V3__create_availability_table.sql
│   │       │
│   │       └── test/
│   │           └── java/com/balconazo/catalog/
│   │               ├── unit/                          # Tests unitarios (Mockito)
│   │               │   ├── domain/
│   │               │   │   └── SpaceTest.java
│   │               │   └── application/
│   │               │       └── SpaceApplicationServiceTest.java
│   │               ├── integration/                   # Tests de integración (Testcontainers)
│   │               │   ├── repository/
│   │               │   │   └── SpaceRepositoryIT.java
│   │               │   └── messaging/
│   │               │       └── KafkaProducerIT.java
│   │               └── contract/                      # Contract testing (Pact)
│   │                   └── SpaceControllerContractTest.java
│   │
│   ├── booking-service/               # Microservicio de Reservas (puerto 8082)
│   │   ├── pom.xml
│   │   ├── Dockerfile
│   │   └── src/
│   │       ├── main/
│   │       │   ├── java/com/balconazo/booking/
│   │       │   │   ├── BookingServiceApplication.java
│   │       │   │   │
│   │       │   │   ├── domain/                        # ⬅️ CAPA DE DOMINIO
│   │       │   │   │   ├── model/
│   │       │   │   │   │   ├── Booking.java           # AggregateRoot: Reserva
│   │       │   │   │   │   ├── Review.java            # Entity: Review post-estancia
│   │       │   │   │   │   ├── Outbox.java            # Entity: Outbox para eventos
│   │       │   │   │   │   └── vo/
│   │       │   │   │   │       ├── BookingId.java
│   │       │   │   │   │       ├── BookingStatus.java  # Enum: held, confirmed, cancelled, expired
│   │       │   │   │   │       ├── PaymentIntent.java
│   │       │   │   │   │       └── Rating.java        # 1-5 stars
│   │       │   │   │   ├── repository/
│   │       │   │   │   │   ├── BookingRepository.java
│   │       │   │   │   │   ├── ReviewRepository.java
│   │       │   │   │   │   └── OutboxRepository.java
│   │       │   │   │   ├── event/                     # Domain Events
│   │       │   │   │   │   ├── BookingRequested.java
│   │       │   │   │   │   ├── BookingHeld.java
│   │       │   │   │   │   ├── BookingConfirmed.java
│   │       │   │   │   │   ├── BookingCancelled.java
│   │       │   │   │   │   ├── BookingExpired.java
│   │       │   │   │   │   ├── PaymentIntentCreated.java
│   │       │   │   │   │   ├── PaymentAuthorized.java
│   │       │   │   │   │   ├── PaymentCaptured.java
│   │       │   │   │   │   ├── PaymentFailed.java
│   │       │   │   │   │   └── ReviewSubmitted.java
│   │       │   │   │   └── service/                   # Domain Services
│   │       │   │   │       ├── BookingSaga.java        # Saga orquestada
│   │       │   │   │       ├── PaymentGateway.java     # Port (interface)
│   │       │   │   │       └── PricingClient.java      # Port para obtener precio
│   │       │   │   │
│   │       │   │   ├── application/                   # ⬅️ CAPA DE APLICACIÓN
│   │       │   │   │   ├── dto/
│   │       │   │   │   │   ├── command/
│   │       │   │   │   │   │   ├── CreateBookingCommand.java
│   │       │   │   │   │   │   ├── ConfirmBookingCommand.java
│   │       │   │   │   │   │   ├── CancelBookingCommand.java
│   │       │   │   │   │   │   └── SubmitReviewCommand.java
│   │       │   │   │   │   └── response/
│   │       │   │   │   │       ├── BookingDto.java
│   │       │   │   │   │       └── ReviewDto.java
│   │       │   │   │   └── service/
│   │       │   │   │       ├── BookingApplicationService.java  # Orquesta saga
│   │       │   │   │       ├── OutboxPublisher.java            # @Scheduled cada 500ms
│   │       │   │   │       ├── BookingExpiryWorker.java        # @Scheduled cada 30s
│   │       │   │   │       └── ReviewApplicationService.java
│   │       │   │   │
│   │       │   │   ├── infrastructure/                # ⬅️ CAPA DE INFRAESTRUCTURA
│   │       │   │   │   ├── persistence/
│   │       │   │   │   │   └── jpa/
│   │       │   │   │   │       ├── entity/
│   │       │   │   │   │       │   ├── BookingJpaEntity.java
│   │       │   │   │   │       │   ├── ReviewJpaEntity.java
│   │       │   │   │   │       │   └── OutboxJpaEntity.java
│   │       │   │   │   │       ├── repository/
│   │       │   │   │   │       │   ├── BookingJpaRepository.java
│   │       │   │   │   │       │   ├── ReviewJpaRepository.java
│   │       │   │   │   │       │   └── OutboxJpaRepository.java
│   │       │   │   │   │       └── adapter/
│   │       │   │   │   │           ├── JpaBookingRepositoryAdapter.java
│   │       │   │   │   │           └── JpaOutboxRepositoryAdapter.java
│   │       │   │   │   ├── messaging/
│   │       │   │   │   │   └── kafka/
│   │       │   │   │   │       ├── producer/
│   │       │   │   │   │       │   ├── BookingEventProducer.java
│   │       │   │   │   │       │   └── PaymentEventProducer.java
│   │       │   │   │   │       ├── consumer/
│   │       │   │   │   │       │   └── PaymentEventConsumer.java  # Self-consume payment.events.v1
│   │       │   │   │   │       └── config/
│   │       │   │   │   │           ├── KafkaProducerConfig.java
│   │       │   │   │   │           └── KafkaConsumerConfig.java
│   │       │   │   │   ├── payment/                   # Adaptadores de pago
│   │       │   │   │   │   ├── StripeGatewayAdapter.java  # implements PaymentGateway
│   │       │   │   │   │   └── MockGatewayAdapter.java     # Para dev/test
│   │       │   │   │   ├── lock/
│   │       │   │   │   │   └── RedisLockService.java       # Distributed locks
│   │       │   │   │   └── config/
│   │       │   │   │       ├── JpaConfig.java
│   │       │   │   │       ├── RedisConfig.java
│   │       │   │   │       └── SchedulingConfig.java
│   │       │   │   │
│   │       │   │   └── interfaces/                    # ⬅️ CAPA DE INTERFACES
│   │       │   │       └── rest/
│   │       │   │           ├── controller/
│   │       │   │           │   ├── BookingController.java     # @RestController /bookings
│   │       │   │           │   └── ReviewController.java      # @RestController /reviews
│   │       │   │           ├── request/
│   │       │   │           │   ├── CreateBookingRequest.java
│   │       │   │           │   ├── ConfirmBookingRequest.java
│   │       │   │           │   └── SubmitReviewRequest.java
│   │       │   │           ├── response/
│   │       │   │           │   ├── BookingResponse.java
│   │       │   │           │   └── ReviewResponse.java
│   │       │   │           ├── mapper/
│   │       │   │           │   ├── BookingRestMapper.java
│   │       │   │           │   └── ReviewRestMapper.java
│   │       │   │           └── exception/
│   │       │   │               └── GlobalExceptionHandler.java
│   │       │   │
│   │       │   └── resources/
│   │       │       ├── application.yml
│   │       │       ├── application-dev.yml
│   │       │       └── application-prod.yml
│   │       │
│   │       └── test/
│   │           └── java/com/balconazo/booking/
│   │               ├── unit/
│   │               │   ├── domain/
│   │               │   │   └── BookingSagaTest.java
│   │               │   └── application/
│   │               │       └── BookingApplicationServiceTest.java
│   │               └── integration/
│   │                   ├── repository/
│   │                   │   └── BookingRepositoryIT.java
│   │                   └── saga/
│   │                       └── BookingFlowIT.java  # Test end-to-end de saga
│   │
│   └── search-pricing-service/        # Microservicio de Búsqueda y Pricing (puerto 8083)
│       ├── pom.xml                    # + hibernate-spatial, spring-kafka-streams
│       ├── Dockerfile
│       └── src/
│           ├── main/
│           │   ├── java/com/balconazo/search/
│           │   │   ├── SearchPricingServiceApplication.java
│           │   │   │
│           │   │   ├── domain/                        # ⬅️ CAPA DE DOMINIO
│           │   │   │   ├── model/
│           │   │   │   │   ├── SpaceProjection.java   # Read-model: proyección de space
│           │   │   │   │   ├── PriceSurface.java      # Precio precalculado por slot
│           │   │   │   │   ├── DemandAggregate.java   # Agregado de demanda por tile
│           │   │   │   │   └── vo/
│           │   │   │   │       ├── GeoPoint.java      # PostGIS GEOGRAPHY
│           │   │   │   │       ├── TileId.java
│           │   │   │   │       ├── DemandScore.java
│           │   │   │   │       └── PriceMultiplier.java  # 1.0-2.5
│           │   │   │   ├── repository/
│           │   │   │   │   ├── SpaceProjectionRepository.java
│           │   │   │   │   ├── PriceSurfaceRepository.java
│           │   │   │   │   └── DemandAggregateRepository.java
│           │   │   │   ├── event/
│           │   │   │   │   ├── PriceUpdated.java
│           │   │   │   │   └── SearchQueryLogged.java
│           │   │   │   └── service/
│           │   │   │       ├── PricingEngine.java      # Calcula multipliers
│           │   │   │       └── GeoSearchService.java   # Queries PostGIS
│           │   │   │
│           │   │   ├── application/                   # ⬅️ CAPA DE APLICACIÓN
│           │   │   │   ├── dto/
│           │   │   │   │   ├── query/
│           │   │   │   │   │   └── SearchQuery.java    # lat, lon, radius, capacity, dates
│           │   │   │   │   └── response/
│           │   │   │   │       ├── SearchResultDto.java
│           │   │   │   │       └── PricingDto.java
│           │   │   │   └── service/
│           │   │   │       ├── SearchApplicationService.java     # Orquesta búsqueda + pricing
│           │   │   │       └── PricingApplicationService.java    # Recalcula precios
│           │   │   │
│           │   │   ├── infrastructure/                # ⬅️ CAPA DE INFRAESTRUCTURA
│           │   │   │   ├── persistence/
│           │   │   │   │   └── jpa/
│           │   │   │   │       ├── entity/
│           │   │   │   │       │   ├── SpaceProjectionJpaEntity.java  # Usa PostGIS
│           │   │   │   │       │   ├── PriceSurfaceJpaEntity.java
│           │   │   │   │       │   └── DemandAggregateJpaEntity.java
│           │   │   │   │       ├── repository/
│           │   │   │   │       │   ├── SpaceProjectionJpaRepository.java  # Custom query con ST_DWithin
│           │   │   │   │       │   ├── PriceSurfaceJpaRepository.java
│           │   │   │   │       │   └── DemandAggregateJpaRepository.java
│           │   │   │   │       └── adapter/
│           │   │   │   │           └── JpaSpaceProjectionRepositoryAdapter.java
│           │   │   │   ├── messaging/
│           │   │   │   │   └── kafka/
│           │   │   │   │       ├── streams/                      # ⬅️ KAFKA STREAMS
│           │   │   │   │       │   ├── topology/
│           │   │   │   │       │   │   └── PricingTopology.java  # Ventanas 5 min, calcula demanda
│           │   │   │   │       │   ├── processor/
│           │   │   │   │       │   │   ├── DemandScoreProcessor.java
│           │   │   │   │       │   │   └── PriceUpdater.java      # Escribe en DB + Redis
│           │   │   │   │       │   └── serde/
│           │   │   │   │       │       ├── SearchEventSerde.java
│           │   │   │   │       │       └── BookingEventSerde.java
│           │   │   │   │       ├── consumer/
│           │   │   │   │       │   ├── SpaceEventConsumer.java    # Actualiza proyección
│           │   │   │   │       │   └── AvailabilityEventConsumer.java
│           │   │   │   │       ├── producer/
│           │   │   │   │       │   ├── PricingEventProducer.java
│           │   │   │   │       │   └── AnalyticsEventProducer.java
│           │   │   │   │       └── config/
│           │   │   │   │           ├── KafkaStreamsConfig.java
│           │   │   │   │           ├── KafkaConsumerConfig.java
│           │   │   │   │           └── KafkaProducerConfig.java
│           │   │   │   ├── cache/
│           │   │   │   │   └── RedisPriceCache.java    # price:{space}:{slot}
│           │   │   │   └── config/
│           │   │   │       ├── JpaConfig.java
│           │   │   │       ├── PostGisConfig.java      # Hibernate Spatial
│           │   │   │       └── RedisConfig.java
│           │   │   │
│           │   │   └── interfaces/                    # ⬅️ CAPA DE INTERFACES
│           │   │       └── rest/
│           │   │           ├── controller/
│           │   │           │   ├── SearchController.java       # @RestController /search
│           │   │           │   └── PricingController.java      # @RestController /pricing
│           │   │           ├── request/
│           │   │           │   └── SearchRequest.java
│           │   │           ├── response/
│           │   │           │   ├── SearchResponse.java
│           │   │           │   └── PriceResponse.java
│           │   │           ├── mapper/
│           │   │           │   └── SearchRestMapper.java
│           │   │           └── exception/
│           │   │               └── GlobalExceptionHandler.java
│           │   │
│           │   └── resources/
│           │       ├── application.yml
│           │       ├── application-dev.yml
│           │       └── application-prod.yml
│           │
│           └── test/
│               └── java/com/balconazo/search/
│                   ├── unit/
│                   │   └── domain/
│                   │       └── PricingEngineTest.java
│                   ├── integration/
│                   │   ├── repository/
│                   │   │   └── SpaceProjectionRepositoryIT.java  # Con PostGIS container
│                   │   └── streams/
│                   │       └── PricingTopologyIT.java            # TopologyTestDriver
│                   └── e2e/
│                       └── SearchFlowIT.java
│
├── frontend/                          # Angular 20 SPA
│   ├── package.json
│   ├── angular.json
│   ├── tsconfig.json
│   ├── tailwind.config.js             # Tailwind CSS 3.x
│   ├── postcss.config.js
│   ├── Dockerfile
│   ├── .gitignore
│   │
│   └── src/
│       ├── index.html
│       ├── main.ts
│       ├── styles.css                 # @tailwind base, components, utilities
│       │
│       └── app/
│           ├── app.component.ts       # Standalone root component
│           ├── app.component.html
│           ├── app.routes.ts          # Router config
│           │
│           ├── core/                  # Servicios core (singleton)
│           │   ├── auth.service.ts    # JWT token management
│           │   ├── jwt.interceptor.ts # HTTP interceptor para Authorization header
│           │   ├── api.config.ts      # export const API_BASE = 'http://localhost:8080/api'
│           │   └── error.interceptor.ts
│           │
│           ├── shared/                # Componentes compartidos
│           │   ├── components/
│           │   │   ├── header/
│           │   │   │   └── header.component.ts
│           │   │   ├── footer/
│           │   │   │   └── footer.component.ts
│           │   │   └── map/
│           │   │       └── map.component.ts  # Leaflet/Google Maps para geolocalización
│           │   ├── pipes/
│           │   │   ├── currency.pipe.ts
│           │   │   └── date-format.pipe.ts
│           │   └── models/
│           │       ├── space.model.ts
│           │       ├── booking.model.ts
│           │       └── user.model.ts
│           │
│           └── features/              # Módulos por feature (standalone)
│               ├── search/
│               │   ├── search.page.ts         # Standalone component (página)
│               │   ├── search.page.html
│               │   ├── search.service.ts      # HTTP calls a /api/search
│               │   └── components/
│               │       ├── search-form/
│               │       │   └── search-form.component.ts
│               │       └── space-card/
│               │           └── space-card.component.ts
│               │
│               ├── space-detail/
│               │   ├── space-detail.page.ts   # /space/:id
│               │   ├── space-detail.page.html
│               │   └── space-detail.service.ts
│               │
│               ├── booking/
│               │   ├── booking.page.ts        # /booking/:id
│               │   ├── booking.page.html
│               │   ├── booking.service.ts
│               │   └── components/
│               │       ├── booking-summary/
│               │       │   └── booking-summary.component.ts
│               │       └── payment-form/
│               │           └── payment-form.component.ts
│               │
│               ├── host/
│               │   ├── host-dashboard.page.ts # Panel del host
│               │   ├── host-dashboard.page.html
│               │   ├── host.service.ts
│               │   └── components/
│               │       ├── space-list/
│               │       │   └── space-list.component.ts
│               │       └── create-space-form/
│               │           └── create-space-form.component.ts
│               │
│               └── auth/
│                   ├── login.page.ts
│                   ├── login.page.html
│                   ├── register.page.ts
│                   └── register.page.html
│
└── .github/                           # CI/CD con GitHub Actions
    └── workflows/
        ├── backend-ci.yml             # Maven test + build + push ECR
        ├── frontend-ci.yml            # npm test + build + deploy S3
        └── deploy-prod.yml            # Deploy a ECS/EKS
```

---

## 📌 Notas sobre la Arquitectura

### Capas Hexagonales (por microservicio)

Cada microservicio sigue estrictamente la arquitectura hexagonal:

1. **domain/** → Núcleo de negocio, sin dependencias externas
   - `model/`: Agregados, entidades, value objects
   - `repository/`: Ports (interfaces) para persistencia
   - `event/`: Domain events (eventos puros de dominio)
   - `service/`: Domain services (lógica de negocio compleja)

2. **application/** → Casos de uso, orquestación
   - `dto/`: DTOs de comando (write) y respuesta (read)
   - `service/`: Application services (transacciones, publicación de eventos)

3. **infrastructure/** → Adaptadores técnicos
   - `persistence/jpa/`: Implementación de repositorios con JPA
   - `messaging/kafka/`: Productores y consumidores Kafka
   - `payment/`, `lock/`, `cache/`: Adaptadores de servicios externos
   - `config/`: Configuración de Spring

4. **interfaces/** → Adaptadores de entrada (REST, GraphQL, gRPC)
   - `rest/controller/`: Controllers REST
   - `rest/request/`, `rest/response/`: DTOs específicos de HTTP
   - `rest/mapper/`: Mappers entre HTTP DTOs y Application DTOs

### Ventajas de esta Estructura

✅ **Testabilidad:** Domain y Application son 100% testeables sin Spring  
✅ **Independencia:** Cambiar de JPA a MongoDB solo afecta `infrastructure/persistence`  
✅ **Claridad:** Dependencias siempre van de afuera (interfaces) hacia adentro (domain)  
✅ **Onboarding:** Nuevos devs encuentran rápidamente dónde está cada cosa  

---

**Última actualización:** 25 de octubre de 2025  
**Mantenido por:** Equipo de Arquitectura Balconazo

