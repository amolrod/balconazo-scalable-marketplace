0) Visión general (stack solicitado)

Backend

3 microservicios Spring Boot 3.x (Java 21), empaquetados con spring-boot-maven-plugin.

Spring Cloud Gateway como API Gateway (JWT + rate limit en Redis + CORS).

Kafka (AWS MSK en prod; Confluent/Bitnami en dev) para eventos asíncronos.

PostgreSQL (RDS en prod) — database per service; en dev: 3 DBs en el mismo contenedor para simplificar, cada una con su schema propio.

Redis (ElastiCache en prod) para caché y locks.

Patrones: SOLID, Repository, Service Layer, DTO, Outbox + Kafka.

Frontend

Angular 20 (standalone components) + Tailwind CSS.

HttpClient contra el API Gateway (JWT vía interceptor).

Infra

Docker Compose para dev local (Gateway + 3 servicios + Kafka + ZK + 3 Postgres + Redis).

AWS ECS/EKS para despliegue (imágenes Docker), AWS MSK y AWS RDS para datos.

TAREA 1) Redistribuye 8 bounded contexts en EXACTAMENTE 3 microservicios (con justificación)
Bounded contexts originales

Identidad & Confianza

Catálogo (Listings)

Búsqueda

Precios

Reservas (Bookings)

Pagos

Reputación (Reviews & Disputes)

Notificaciones

Nueva distribución (3 microservicios)

MS‑Catalog (catalog-service)

Agrupa: Identidad & Confianza + Catálogo (Spaces, Availability)

Responsabilidad: gestión de usuarios/roles/trust (a nivel mínimo, verificación simulada), alta/edición de espacios, reglas, disponibilidad base.

Por qué junto: el host y su inventario son acoplados; compartir transacciones simplifica invariantes de “propiedad del espacio” y publicación de eventos consistentes (SpaceCreated, AvailabilityChanged).

Publica (Kafka): space.events.v1 (created/updated), availability.events.v1.

MS‑Booking (booking-service)

Agrupa: Reservas + Pagos + Reputación (Reviews/Disputes) + Notificaciones (como módulo interno que emite NotificationRequested)

Responsabilidad: orquestar la saga de reserva (hold → preauth → confirm/cancel), integrarse con pasarela de pago (stub en dev), emitir reviews y disputas post‑estancia.

Por qué junto: la consistencia entre reserva, cobro y review es crítica; tenerlas juntas evita coreografías excesivas en el camino crítico.

Publica: booking.events.v1, payment.events.v1, review.events.v1, notification.events.v1.

MS‑SearchPricing (search-pricing-service)

Agrupa: Búsqueda + Precios

Responsabilidad: mantener proyección de búsqueda geoespacial (PostGIS) y motor de pricing dinámico (Kafka Streams o scheduler + Kafka), precalcular price_surface y calentar Redis.

Por qué junto: el precio efectivo forma parte del read‑model de búsqueda; precalcular y servir desde el mismo servicio reduce latencia (<100–200 ms P95).

Consume: space.events.v1, availability.events.v1, booking.events.v1, analytics.search.v1; Publica: pricing.events.v1.

Ventajas: 3 servicios con fronteras estables, coherencia transaccional donde importa (Booking/Payment), y read model separado (SearchPricing) que escala horizontalmente. Permite añadir verticales (“Pool‑nazo”) reutilizando Catalog + Booking; SearchPricing solo indexa nuevo tipo.

TAREA 2) Sustituye EventBridge/SQS por Kafka (tópicos y eventos)
Tópicos (nombres y claves)

space.events.v1 — key: space_id

SpaceCreated, SpaceUpdated, SpaceDeactivated

availability.events.v1 — key: space_id

AvailabilityAdded, AvailabilityRemoved, AvailabilityChanged

booking.events.v1 — key: booking_id

BookingRequested, BookingHeld, BookingConfirmed, BookingCancelled, BookingExpired

payment.events.v1 — key: booking_id

PaymentIntentCreated, PaymentAuthorized, PaymentCaptured, PaymentFailed, RefundIssued

review.events.v1 — key: booking_id

ReviewSubmitted, DisputeOpened, DisputeResolved

pricing.events.v1 — key: space_id

PriceRecomputeRequested, PriceUpdated

analytics.search.v1 — key: tile_id (o bboxKey)

SearchQueryLogged (lat, lon, fecha, filtros)

Política por tópico

Particiones: 12 en dev (fácil de escalar a 48/96 en prod).

Retención: 7–14 días para eventos de sistema; 24–48 h para analytics.search.v1 (alto volumen).

DLT por tópico: *.DLT.

Formato: JSON + encabezados (traceId, correlationId, eventType, version, occurredAt). Avro/Schema Registry opcional en prod.

Ejemplo evento JSON (PriceUpdated)

{
"eventType": "PriceUpdated",
"version": 1,
"spaceId": "f3f2d5e0-...",
"timeslotStart": "2025-12-31T22:00:00Z",
"priceCents": 4200,
"source": "search-pricing",
"occurredAt": "2025-10-23T09:12:00Z",
"metadata": { "multiplier": 1.68, "demandScore": 0.82 }
}


Idempotencia

record key = aggregate_id + eventId en payload; consumidores mantienen tabla processed_events(event_id) por servicio.

Productores con enable.idempotence=true y transacciones Kafka cuando se use Outbox.

TAREA 3) DDL Postgres por microservicio (cada uno con su schema)

En dev puedes tener un contenedor Postgres con 3 bases: catalog_db, booking_db, search_db. En cada base, un schema homónimo: catalog, booking, search.
En prod (RDS), database per service (aislamiento), con el mismo schema lógico interno.

MS‑Catalog (DB: catalog_db, schema: catalog)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS catalog;

CREATE TABLE IF NOT EXISTS catalog.users(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
email CITEXT UNIQUE NOT NULL,
role TEXT NOT NULL CHECK (role IN ('host','guest','admin')),
trust_score INT DEFAULT 0,
status TEXT DEFAULT 'active',
created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS catalog.spaces(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
owner_id UUID NOT NULL REFERENCES catalog.users(id),
title TEXT NOT NULL,
capacity INT NOT NULL,
rules JSONB DEFAULT '{}'::jsonb,
address TEXT,
lat DOUBLE PRECISION NOT NULL,
lon DOUBLE PRECISION NOT NULL,
base_price_cents INT NOT NULL,
status TEXT CHECK (status IN ('draft','active','snoozed')) DEFAULT 'active',
created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_spaces_owner ON catalog.spaces(owner_id);
CREATE INDEX IF NOT EXISTS idx_spaces_geo ON catalog.spaces(lat, lon);

CREATE TABLE IF NOT EXISTS catalog.availability_slots(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
space_id UUID NOT NULL REFERENCES catalog.spaces(id),
start_ts TIMESTAMPTZ NOT NULL,
end_ts TIMESTAMPTZ NOT NULL,
max_guests INT NOT NULL,
UNIQUE(space_id, start_ts, end_ts)
);

MS‑Booking (DB: booking_db, schema: booking)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

CREATE SCHEMA IF NOT EXISTS booking;

CREATE TABLE IF NOT EXISTS booking.bookings(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
space_id UUID NOT NULL, -- referencia lógica (no FK cross-DB)
guest_id UUID NOT NULL,
start_ts TIMESTAMPTZ NOT NULL,
end_ts TIMESTAMPTZ NOT NULL,
status TEXT NOT NULL CHECK (status IN ('held','confirmed','cancelled','expired')),
price_cents INT NOT NULL,
deposit_cents INT DEFAULT 0,
payment_intent_id TEXT,
created_at TIMESTAMPTZ DEFAULT now()
);
-- Exclusion para evitar solapes en 'held'/'confirmed'
ALTER TABLE booking.bookings ADD CONSTRAINT IF NOT EXISTS no_overlap
EXCLUDE USING GIST (space_id WITH =, tstzrange(start_ts,end_ts) WITH &&)
WHERE (status IN ('held','confirmed'));

CREATE INDEX IF NOT EXISTS idx_bookings_space_time
ON booking.bookings(space_id, start_ts, end_ts, status);

CREATE TABLE IF NOT EXISTS booking.reviews(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
booking_id UUID UNIQUE REFERENCES booking.bookings(id),
author_id UUID NOT NULL,
target_user_id UUID NOT NULL,
rating INT CHECK (rating BETWEEN 1 AND 5),
text TEXT,
created_at TIMESTAMPTZ DEFAULT now()
);

-- Outbox para eventos de dominio
CREATE TABLE IF NOT EXISTS booking.outbox(
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
aggregate_id UUID NOT NULL,
event_type TEXT NOT NULL,
payload JSONB NOT NULL,
occurred_at TIMESTAMPTZ DEFAULT now(),
published BOOLEAN DEFAULT FALSE
);
CREATE INDEX IF NOT EXISTS idx_outbox_published ON booking.outbox(published, occurred_at);

MS‑SearchPricing (DB: search_db, schema: search)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis; -- para geoespacial

CREATE SCHEMA IF NOT EXISTS search;

-- Proyección de spaces (read model)
CREATE TABLE IF NOT EXISTS search.spaces_projection(
space_id UUID PRIMARY KEY,
title TEXT NOT NULL,
capacity INT NOT NULL,
rating NUMERIC(3,2),
geo GEOGRAPHY(POINT,4326) NOT NULL,
base_price_cents INT NOT NULL,
status TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_spaces_geo ON search.spaces_projection USING GIST (geo);

-- Superficie de precio por timeslot (precalculada)
CREATE TABLE IF NOT EXISTS search.price_surface(
space_id UUID NOT NULL,
timeslot_start TIMESTAMPTZ NOT NULL,
price_cents INT NOT NULL,
multiplier NUMERIC(4,2) NOT NULL,
demand_score NUMERIC(4,2) NOT NULL,
PRIMARY KEY (space_id, timeslot_start)
);

-- Métricas/demanda agregada por celda/ventana
CREATE TABLE IF NOT EXISTS search.demand_agg(
tile_id TEXT NOT NULL,
window_start TIMESTAMPTZ NOT NULL,
searches INT NOT NULL DEFAULT 0,
holds INT NOT NULL DEFAULT 0,
bookings INT NOT NULL DEFAULT 0,
PRIMARY KEY (tile_id, window_start)
);

TAREA 4) Saga de Booking en Spring + Kafka

Estilo: Orquestación centrada en booking-service.

Pasos (happy path)

API POST /bookings (Gateway → booking-service)

Lock Redis: SET lock:booking:{spaceId}:{start}-{end} NX PX=<TTL>

Create booking status='held' con precio de Redis (price:{space}:{slot}) o fallback base_price.

Outbox: insertar evento BookingHeld (transacción DB).

Outbox Publisher (scheduler @fixedDelay=500ms)

Lee outbox no publicados → Kafka produce a booking.events.v1 en una transacción Kafka (opcional) y marca published=true.

Payment (módulo interno del booking-service o subcomponente)

Produce PaymentIntentCreated (y opcionalmente llama a pasarela stub).

Cuando la pasarela responde, emite PaymentAuthorized → Kafka.

booking-service (consumer de payment.events.v1)

PaymentAuthorized → mantiene held; PaymentFailed → cancelled + DEL lock + BookingCancelled.

POST /bookings/{id}/confirm (cliente)

Orquestador captura pago → PaymentCaptured → BookingConfirmed + DEL lock.

expiry worker (scheduler)

Expira held sin confirmación en TTL → expired + DEL lock + BookingExpired.

Compensaciones

Fallo al capturar pago → BookingCancelled + refund si aplica.

Idempotencia

Idempotency-Key en POST /bookings.

Tabla processed_events (consume side) para ignorar duplicados.

TAREA 5) Dependencias Maven (por microservicio)

Usa Spring Boot 3.3.x y Spring Cloud 2024.x.

BOM común (padre)
<dependencyManagement>
<dependencies>
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-dependencies</artifactId>
<version>3.3.3</version>
<type>pom</type>
<scope>import</scope>
</dependency>
<dependency>
<groupId>org.springframework.cloud</groupId>
<artifactId>spring-cloud-dependencies</artifactId>
<version>2024.0.3</version>
<type>pom</type>
<scope>import</scope>
</dependency>
</dependencies>
</dependencyManagement>

catalog-service (JPA + Kafka + Redis)
<dependencies>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
<dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>
<dependency><groupId>org.springframework.kafka</groupId><artifactId>spring-kafka</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-redis</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
<dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>
<dependency><groupId>com.fasterxml.jackson.datatype</groupId><artifactId>jackson-datatype-jsr310</artifactId></dependency>
<dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>1.5.5.Final</version></dependency>
</dependencies>

booking-service (JPA + Kafka + Redis)
<dependencies>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
<dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>
<dependency><groupId>org.springframework.kafka</groupId><artifactId>spring-kafka</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-redis</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
<dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>
<dependency><groupId>com.fasterxml.jackson.datatype</groupId><artifactId>jackson-datatype-jsr310</artifactId></dependency>
<dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>1.5.5.Final</version></dependency>
</dependencies>

search-pricing-service (JPA + PostGIS + Kafka Streams + Redis)
<dependencies>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
<dependency><groupId>org.hibernate</groupId><artifactId>hibernate-spatial</artifactId></dependency>
<dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId></dependency>
<dependency><groupId>org.springframework.kafka</groupId><artifactId>spring-kafka</artifactId></dependency>
<dependency><groupId>org.springframework.kafka</groupId><artifactId>spring-kafka-streams</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-redis</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
<dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.6.0</version></dependency>
<dependency><groupId>com.fasterxml.jackson.datatype</groupId><artifactId>jackson-datatype-jsr310</artifactId></dependency>
<dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>1.5.5.Final</version></dependency>
</dependencies>

api-gateway (Spring Cloud Gateway + Security/JWT)
<dependencies>
<dependency><groupId>org.springframework.cloud</groupId><artifactId>spring-cloud-starter-gateway</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-oauth2-resource-server</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-actuator</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-redis-reactive</artifactId></dependency>
</dependencies>

TAREA 6) Configuración del API Gateway (JWT + enrutamiento)

Supuesto: en dev usamos Keycloak (contenedor) para emitir JWT HS256/RS256. En prod puedes apuntar a Cognito o un IdP corporativo (JWKs).

application.yml (extracto)

server:
port: 8080

spring:
cloud:
gateway:
default-filters:
- AddResponseHeader=X-Request-Id, #{T(java.util.UUID).randomUUID()}
routes:
- id: catalog
uri: http://catalog-service:8081
predicates:
- Path=/api/catalog/**
filters:
- StripPrefix=2
- RequestRateLimiter=#{@redisRateLimiter}
- id: booking
uri: http://booking-service:8082
predicates:
- Path=/api/bookings/**, /api/reviews/**
filters:
- StripPrefix=2
- RequestRateLimiter=#{@redisRateLimiter}
- id: search
uri: http://search-pricing-service:8083
predicates:
- Path=/api/search/**, /api/pricing/**
filters:
- StripPrefix=2
- RequestRateLimiter=#{@redisRateLimiter}

security:
oauth2:
resourceserver:
jwt:
jwk-set-uri: http://keycloak:8080/realms/balconazo/protocol/openid-connect/certs

# Rate limiter (Redis)
spring:
data:
redis:
host: redis
port: 6379

# CORS (si usas config global)
balconazo:
cors:
allowed-origins: "http://localhost:4200"
allowed-methods: "GET,POST,PUT,PATCH,DELETE,OPTIONS"
allowed-headers: "*"
allow-credentials: true


Notas

Path base para el frontend: /api/*.

JWT: roles host, guest en scope/realm_access.

Rate limiting: RedisRateLimiter por principal (resolver custom que lee sub del JWT).

TAREA 7) Arquitectura Angular 20 + Tailwind

Estructura propuesta

/frontend
/src
/app
/core
auth.service.ts
jwt.interceptor.ts
api.config.ts
/features
/search
search.page.ts (standalone)
search.service.ts
/space-detail
space-detail.page.ts
/host
host-dashboard.page.ts
host.service.ts
/booking
booking.page.ts
booking.service.ts
app.routes.ts
app.component.ts
/environments
environment.ts
environment.development.ts
tailwind.config.js
postcss.config.js


Instalación rápida

npm create @angular@latest balconazo-frontend -- --standalone
cd balconazo-frontend
npm i -D tailwindcss postcss autoprefixer
npx tailwindcss init -p


tailwind.config.js

module.exports = {
content: ["./src/**/*.{html,ts}"],
theme: { extend: {} },
plugins: []
};


styles.css

@tailwind base;
@tailwind components;
@tailwind utilities;


api.config.ts

export const API_BASE = 'http://localhost:8080/api'; // Gateway


auth.service.ts (esqueleto)

import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class AuthService {
private token?: string;
setToken(t: string) { this.token = t; }
getToken() { return this.token; } // En prod, integra Keycloak JS adapter
isLoggedIn() { return !!this.token; }
}


jwt.interceptor.ts

import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from './auth.service';

export const jwtInterceptor: HttpInterceptorFn = (req, next) => {
const auth = inject(AuthService);
const token = auth.getToken();
const authReq = token ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }) : req;
return next(authReq);
};


search.service.ts

import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_BASE } from '../../core/api.config';

export interface SearchResult { spaceId: string; title: string; capacity: number; priceCents: number; lat: number; lon: number; rating?: number; }

@Injectable({ providedIn: 'root' })
export class SearchService {
private http = inject(HttpClient);
search(params: { lat: number; lon: number; radius_m: number; capacity: number }) {
return this.http.get<SearchResult[]>(`${API_BASE}/search`, { params: <any>params });
}
}


Rutas (standalone)

import { Routes } from '@angular/router';
import { SearchPage } from './features/search/search.page';
import { SpaceDetailPage } from './features/space-detail/space-detail.page';
import { BookingPage } from './features/booking/booking.page';
import { HostDashboardPage } from './features/host/host-dashboard.page';

export const routes: Routes = [
{ path: '', component: SearchPage },
{ path: 'space/:id', component: SpaceDetailPage },
{ path: 'booking/:id', component: BookingPage },
{ path: 'host', component: HostDashboardPage }
];


Usa HttpClient directo al Gateway; Tailwind para UI rápida; añade un Guard si el endpoint requiere autenticación.

TAREA 8) docker-compose.yml (dev local)

Incluye: Gateway, 3 microservicios, Kafka+ZK, Redis, 3 Postgres (una por servicio), Keycloak opcional para JWT.

version: "3.9"
services:
zookeeper:
image: bitnami/zookeeper:3.9
environment: [ ALLOW_ANONYMOUS_LOGIN=yes ]
ports: ["2181:2181"]

kafka:
image: bitnami/kafka:3.7
depends_on: [ zookeeper ]
environment:
- KAFKA_CFG_ZOOKEEPER_CONNECT=zookeeper:2181
- KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,PLAINTEXT_HOST://:29092
- KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:29092
- ALLOW_PLAINTEXT_LISTENER=yes
ports: ["29092:29092"]

redis:
image: redis:7
ports: ["6379:6379"]

# Bases de datos por servicio
pg-catalog:
image: postgres:16
environment: [ POSTGRES_PASSWORD=postgres, POSTGRES_DB=catalog_db ]
ports: ["5433:5432"]
volumes:
- ./ddl/catalog.sql:/docker-entrypoint-initdb.d/01_catalog.sql:ro
pg-booking:
image: postgres:16
environment: [ POSTGRES_PASSWORD=postgres, POSTGRES_DB=booking_db ]
ports: ["5434:5432"]
volumes:
- ./ddl/booking.sql:/docker-entrypoint-initdb.d/01_booking.sql:ro
pg-search:
image: postgis/postgis:16-3.4
environment: [ POSTGRES_PASSWORD=postgres, POSTGRES_DB=search_db ]
ports: ["5435:5432"]
volumes:
- ./ddl/search.sql:/docker-entrypoint-initdb.d/01_search.sql:ro

# Opcional: Keycloak para JWT
keycloak:
image: quay.io/keycloak/keycloak:25.0
command: start-dev
environment:
- KEYCLOAK_ADMIN=admin
- KEYCLOAK_ADMIN_PASSWORD=admin
ports: ["8081:8080"]

# API Gateway
api-gateway:
build: ./backend/api-gateway
environment:
- SPRING_PROFILES_ACTIVE=dev
ports: ["8080:8080"]
depends_on: [ kafka, redis, keycloak, catalog-service, booking-service, search-pricing-service ]

catalog-service:
build: ./backend/catalog-service
environment:
- SPRING_DATASOURCE_URL=jdbc:postgresql://pg-catalog:5432/catalog_db
- SPRING_DATASOURCE_USERNAME=postgres
- SPRING_DATASOURCE_PASSWORD=postgres
- SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
- SPRING_REDIS_HOST=redis
ports: ["8081:8081"]
depends_on: [ pg-catalog, kafka, redis ]

booking-service:
build: ./backend/booking-service
environment:
- SPRING_DATASOURCE_URL=jdbc:postgresql://pg-booking:5432/booking_db
- SPRING_DATASOURCE_USERNAME=postgres
- SPRING_DATASOURCE_PASSWORD=postgres
- SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
- SPRING_REDIS_HOST=redis
ports: ["8082:8082"]
depends_on: [ pg-booking, kafka, redis ]

search-pricing-service:
build: ./backend/search-pricing-service
environment:
- SPRING_DATASOURCE_URL=jdbc:postgresql://pg-search:5432/search_db
- SPRING_DATASOURCE_USERNAME=postgres
- SPRING_DATASOURCE_PASSWORD=postgres
- SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:9092
- SPRING_REDIS_HOST=redis
ports: ["8083:8083"]
depends_on: [ pg-search, kafka, redis ]

# Opcional: Angular (dev) — puedes ejecutar local fuera de compose
frontend:
build: ./frontend
ports: ["4200:4200"]
environment:
- API_BASE=http://localhost:8080/api
command: ["npm","run","start","--","--host","0.0.0.0","--poll"]
depends_on: [ api-gateway ]


Dockerfiles (patrón multi‑stage, Spring Boot)

# backend/*/Dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
ENV JAVA_OPTS="-XX:+UseG1GC -XX:MaxRAMPercentage=75"
EXPOSE 8081
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar app.jar"]

TAREA 9) Motor de Pricing Dinámico con Kafka Streams (o scheduler + Kafka)
Opción A (recomendada): Kafka Streams en search-pricing-service

Input streams:

analytics.search.v1 (KStream) → (tileId, timestamp)

booking.events.v1 (KStream) → filtrar Held/Confirmed

space.events.v1 (KTable) → base_price por spaceId (tabla compactada)

Topología (ventanas)

Ventana tumbling 5 minutos por tileId

Agrega searches, holds, bookings → demandScore = f(...)

Join con space + availability (si se proyecta) para slots cercanos

Calcula multiplier [1.0–2.5] con topes

Emite PriceUpdated a pricing.events.v1 y setea Redis price:{space}:{ts} (through‑processor)

State stores: RocksDB (default) replicado, changelog topics *-store-changelog.

Config Streams (Java, bean)

@Configuration
@EnableKafkaStreams
class PricingTopology {
@Bean
public KStream<String, SearchEvent> kstream(StreamsBuilder b) {
var search = b.stream("analytics.search.v1", Consumed.with(Serdes.String(), Serdes.serdeFrom(...)));
var holds  = b.stream("booking.events.v1", Consumed.with(Serdes.String(), ...))
.filter((k,v) -> v.type().equals("BookingHeld"));
var confs  = b.stream("booking.events.v1", Consumed.with(Serdes.String(), ...))
.filter((k,v) -> v.type().equals("BookingConfirmed"));

    var agg = search.map((k,v) -> KeyValue.pair(v.tileId(), 1))
      .groupByKey()
      .windowedBy(TimeWindows.ofSizeWithNoGrace(Duration.ofMinutes(5)))
      .count(Materialized.as("search-count"));

    // Combina con holds/confs de forma similar y calcula demandScore...
    // Luego calcula multipliers y produce PriceUpdated
    return search; // placeholder
}
}

Opción B: Scheduler + Kafka

@Scheduled(fixedRate=300000) (cada 5 min): consulta métricas y disponibilidad, recalcula precios, produce PriceUpdated y actualiza Redis.

Útil si aún no quieres Streams; más simple, menos reactivo.

TAREA 10) Cómo aplicar SOLID en código Spring Boot

S (Single Responsibility)

SpaceController solo maneja HTTP → delega en SpaceApplicationService.

SpaceApplicationService orquesta casos de uso (crear/editar/listar) → delega en dominio y SpaceRepository.

Space (entidad de dominio) encapsula invariantes (capacidad > 0, status válido).

O (Open/Closed)

Estrategias de pricing: PricingStrategy (interfaz) con implementaciones (EventBasedPricing, WeatherBasedPricing). Abres con nuevas estrategias sin modificar el servicio.

L (Liskov Substitution)

PaymentGateway interface → StripeGateway, MockGateway se pueden inyectar sin romper contratos.

I (Interface Segregation)

Repos separados: SpaceReadRepository y SpaceWriteRepository si necesitas CQRS.

NotificationPort con métodos específicos (email, push) en interfaces pequeñas.

D (Dependency Inversion)

Controladores y servicios dependen de puertos (interfaces) en el dominio, no de adaptadores concretos (infra).

Config de Spring (@Configuration) hace el wiring: @Bean PaymentGateway stripe(...).

Capas recomendadas

/domain     -> entidades (AggregateRoot), value objects, domain services, ports (interfaces)
/application-> casos de uso, orquestación (sagas), DTOs de comando/resultado
/infrastructure -> repos JPA, eventos Kafka, mapeadores, config
/interfaces -> REST controllers (DTOs de entrada/salida), mappers (MapStruct)


Patrón Repository + Service Layer + DTO

// Dominio
public record SpaceId(UUID value) {}
public class Space { /* invariantes, métodos de negocio */ }

// Puerto
public interface SpaceRepository {
Optional<Space> findById(SpaceId id);
Space save(Space s);
}

// Aplicación
@Service
public class SpaceApplicationService {
private final SpaceRepository repo;
public SpaceApplicationService(SpaceRepository repo) { this.repo = repo; }
@Transactional
public SpaceDto create(CreateSpaceCommand cmd) { /* validar, mapear, repo.save */ }
}

// Infra (JPA)
@Entity @Table(name="spaces", schema="catalog")
class SpaceJpa { /* ... */ }
@Repository
class JpaSpaceRepository implements SpaceRepository { /* ... usa Spring Data JPA */ }

// Interfaces (REST)
@RestController @RequestMapping("/spaces")
class SpaceController {
private final SpaceApplicationService service;
@PostMapping public ResponseEntity<SpaceDto> create(@Valid @RequestBody CreateSpaceRequest req) { /* ... */ }
}

APIs por servicio (resumen)

catalog-service

POST /spaces

GET /spaces/{id}

GET /spaces?ownerId=...

POST /availability (crear slots)

Publica eventos space.events.v1, availability.events.v1

booking-service

POST /bookings (crea hold)

GET /bookings/{id}

POST /bookings/{id}/confirm

POST /reviews (1 por booking)

Publica booking.events.v1, payment.events.v1, review.events.v1

search-pricing-service

GET /search?lat&lon&radius_m&capacity (usa PostGIS + Redis para price)

POST /pricing/recompute (admin/debug) — si usas scheduler, este endpoint dispara manual

Publica pricing.events.v1; consume space.*, availability.*, booking.*, analytics.search.*

Configuración application.yml (por servicio, extracto)

catalog-service

server.port: 8081
spring:
datasource:
url: jdbc:postgresql://pg-catalog:5432/catalog_db
username: postgres
password: postgres
jpa:
hibernate.ddl-auto: validate
properties.hibernate.jdbc.time_zone: UTC
kafka.bootstrap-servers: kafka:9092
redis.host: redis


booking-service

server.port: 8082
spring:
datasource:
url: jdbc:postgresql://pg-booking:5432/booking_db
username: postgres
password: postgres
jpa.hibernate.ddl-auto: validate
kafka.bootstrap-servers: kafka:9092
redis.host: redis

balconazo:
booking:
hold-ttl-ms: 600000


search-pricing-service

server.port: 8083
spring:
datasource:
url: jdbc:postgresql://pg-search:5432/search_db
username: postgres
password: postgres
jpa.hibernate.ddl-auto: validate
kafka:
bootstrap-servers: kafka:9092
streams:
application-id: balconazo-pricing
properties:
processing.guarantee: at_least_once
redis.host: redis

Redis (claves y TTL)

Locks de reserva: lock:booking:{spaceId}:{start}-{end} (TTL = hold).

Precio precalculado: price:{spaceId}:{timeslotStart} (TTL 15 min; warming por Streams).

Resultados de búsqueda: search:hot:{bboxKey}:{date}:{cap} (TTL 60–180 s).

Observabilidad

Actuator en todos los servicios (/actuator/health, /metrics, /prometheus si lo añades).

Tracing: añade micrometer-tracing (opcional) + headers (X-Correlation-Id) inyectados en Gateway.

Pasos siguientes / cómo usarlo

Levanta el Compose.

Crea datos con catalog-service (spaces, availability).

Lanza un par de search queries desde Angular (se autopublican eventos a analytics.search.v1 si lo implementas en frontend → backend).

Observa search-pricing-service recalcular precios (Streams o scheduler) y poblar Redis.

Crea booking → confirma → revisa booking-service y eventos payment.* (simulados).

Revisa métricas y latencias (búsqueda < 100–250 ms P95 con cache caliente).