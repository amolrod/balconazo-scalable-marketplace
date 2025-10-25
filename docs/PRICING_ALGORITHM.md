# Algoritmo de Pricing Dinámico - Balconazo

## 🎯 Objetivo

Calcular precios dinámicos para espacios basados en demanda en tiempo real, aplicando multiplicadores entre **1.0x y 2.5x** sobre el precio base.

---

## 📊 Fórmula de Pricing

### 1. **Input: Métricas de Demanda (por tile geoespacial + ventana temporal)**

Recopilamos métricas cada **5 minutos** por `tileId` (celda H3 o grid custom):

```java
DemandMetrics {
    int searches_last_24h;     // Búsquedas en el tile
    int holds_last_24h;        // Bookings en estado 'held'
    int bookings_last_24h;     // Bookings confirmados
    int available_spaces;      // Espacios disponibles en el tile
}
```

---

### 2. **Cálculo de Demand Score (0.0 - 1.0)**

**Fórmula:**
```
rawScore = (searches_last_24h * 0.01) + (holds_last_24h * 0.1) + (bookings_last_24h * 0.5)

demandScore = min(1.0, rawScore / max(1, available_spaces))
```

**Explicación:**
- **Búsquedas** tienen peso bajo (0.01) → señal débil de interés
- **Holds** tienen peso medio (0.1) → interés activo pero no confirmado
- **Bookings confirmados** tienen peso alto (0.5) → demanda real
- **Normalización por espacios disponibles** → si hay 10 espacios y 5 bookings, demandScore = 0.5

**Ejemplo:**
```
Tile "Madrid-Centro":
- searches_last_24h: 150
- holds_last_24h: 8
- bookings_last_24h: 3
- available_spaces: 5

rawScore = (150 * 0.01) + (8 * 0.1) + (3 * 0.5)
         = 1.5 + 0.8 + 1.5
         = 3.8

demandScore = min(1.0, 3.8 / 5) = min(1.0, 0.76) = 0.76
```

---

### 3. **Cálculo de Price Multiplier (1.0 - 2.5)**

**Fórmula:**
```
multiplier = 1.0 + (demandScore * 1.5)
```

**Rango resultante:**
- demandScore = 0.0 → multiplier = 1.0 (precio base sin cambios)
- demandScore = 0.5 → multiplier = 1.75 (aumento moderado)
- demandScore = 1.0 → multiplier = 2.5 (precio máximo)

**Ejemplo (continuando caso anterior):**
```
multiplier = 1.0 + (0.76 * 1.5) = 1.0 + 1.14 = 2.14
```

---

### 4. **Precio Final**

**Fórmula:**
```
final_price_cents = base_price_cents * multiplier
```

**Ejemplo:**
```
Space "Terraza Retiro":
- base_price_cents: 3500 (35€)
- multiplier: 2.14

final_price_cents = 3500 * 2.14 = 7490 cents (74.90€)
```

---

## 🔄 Implementación con Kafka Streams

### Topología (Simplified View)

```
[analytics.search.v1]        [booking.events.v1]       [space.events.v1]
        │                            │                         │
        │ SearchQueryLogged          │ BookingHeld             │ SpaceCreated
        │                            │ BookingConfirmed        │
        └────────────┬───────────────┴─────────────────────────┘
                     │
                     ▼
         ┌─────────────────────────┐
         │  Group by tileId        │
         │  Window: Tumbling 5min  │
         └─────────────┬───────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │  Aggregate:             │
         │  - Count searches       │
         │  - Count holds          │
         │  - Count bookings       │
         │  - Count spaces         │
         └─────────────┬───────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │  DemandScoreProcessor   │
         │  - Calculate demandScore│
         │  - Calculate multiplier │
         └─────────────┬───────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │  PriceUpdater           │
         │  - For each space in    │
         │    tile: update price   │
         │  - Write to DB          │
         │  - Cache in Redis       │
         │  - Emit PriceUpdated    │
         └─────────────────────────┘
```

---

## 🔧 Código de Referencia (Java)

### DemandScoreCalculator.java

```java
package com.balconazo.search.domain.service;

import java.math.BigDecimal;
import java.math.RoundingMode;

public class DemandScoreCalculator {
    
    private static final BigDecimal SEARCH_WEIGHT = new BigDecimal("0.01");
    private static final BigDecimal HOLD_WEIGHT = new BigDecimal("0.1");
    private static final BigDecimal BOOKING_WEIGHT = new BigDecimal("0.5");
    private static final BigDecimal MIN_MULTIPLIER = new BigDecimal("1.0");
    private static final BigDecimal MAX_MULTIPLIER = new BigDecimal("2.5");
    private static final BigDecimal MULTIPLIER_RANGE = new BigDecimal("1.5");
    
    public static BigDecimal calculateDemandScore(
            int searches, 
            int holds, 
            int bookings, 
            int availableSpaces) {
        
        // Calculate raw score
        BigDecimal rawScore = SEARCH_WEIGHT.multiply(BigDecimal.valueOf(searches))
            .add(HOLD_WEIGHT.multiply(BigDecimal.valueOf(holds)))
            .add(BOOKING_WEIGHT.multiply(BigDecimal.valueOf(bookings)));
        
        // Normalize by available spaces (avoid division by zero)
        int divisor = Math.max(1, availableSpaces);
        BigDecimal normalizedScore = rawScore.divide(
            BigDecimal.valueOf(divisor), 
            4, 
            RoundingMode.HALF_UP
        );
        
        // Cap at 1.0
        return normalizedScore.min(BigDecimal.ONE);
    }
    
    public static BigDecimal calculateMultiplier(BigDecimal demandScore) {
        // multiplier = 1.0 + (demandScore * 1.5)
        return MIN_MULTIPLIER.add(demandScore.multiply(MULTIPLIER_RANGE))
            .setScale(2, RoundingMode.HALF_UP);
    }
    
    public static int calculateFinalPrice(int basePriceCents, BigDecimal multiplier) {
        return BigDecimal.valueOf(basePriceCents)
            .multiply(multiplier)
            .setScale(0, RoundingMode.HALF_UP)
            .intValue();
    }
}
```

### Test Case

```java
@Test
void testPricingCalculation_HighDemand() {
    // Given
    int searches = 150;
    int holds = 8;
    int bookings = 3;
    int availableSpaces = 5;
    int basePriceCents = 3500;
    
    // When
    BigDecimal demandScore = DemandScoreCalculator.calculateDemandScore(
        searches, holds, bookings, availableSpaces
    );
    BigDecimal multiplier = DemandScoreCalculator.calculateMultiplier(demandScore);
    int finalPrice = DemandScoreCalculator.calculateFinalPrice(basePriceCents, multiplier);
    
    // Then
    assertThat(demandScore).isEqualByComparingTo("0.76"); // (1.5+0.8+1.5)/5
    assertThat(multiplier).isEqualByComparingTo("2.14");  // 1.0 + (0.76*1.5)
    assertThat(finalPrice).isEqualTo(7490);               // 3500 * 2.14
}

@Test
void testPricingCalculation_LowDemand() {
    // Given
    int searches = 10;
    int holds = 0;
    int bookings = 0;
    int availableSpaces = 10;
    int basePriceCents = 3500;
    
    // When
    BigDecimal demandScore = DemandScoreCalculator.calculateDemandScore(
        searches, holds, bookings, availableSpaces
    );
    BigDecimal multiplier = DemandScoreCalculator.calculateMultiplier(demandScore);
    int finalPrice = DemandScoreCalculator.calculateFinalPrice(basePriceCents, multiplier);
    
    // Then
    assertThat(demandScore).isEqualByComparingTo("0.01"); // (10*0.01)/10
    assertThat(multiplier).isEqualByComparingTo("1.02");  // Casi precio base
    assertThat(finalPrice).isEqualTo(3570);
}
```

---

## 📈 Ventanas Temporales

### Configuración de Kafka Streams

```yaml
# application.yml (search-pricing-service)
balconazo:
  pricing:
    window-size-minutes: 5           # Tumbling window de 5 minutos
    metrics-retention-hours: 24      # Retener métricas 24h
    price-cache-ttl-minutes: 15      # TTL en Redis
    recompute-schedule: "0 */5 * * * *"  # Cada 5 min (backup si Streams falla)
```

### Agregación de Métricas

**Por tileId + ventana temporal:**
```sql
-- Tabla demand_agg
CREATE TABLE search.demand_agg(
    tile_id TEXT NOT NULL,              -- Ej: "h3_8a2a1072b59ffff"
    window_start TIMESTAMPTZ NOT NULL,  -- Inicio de ventana 5min
    searches INT NOT NULL DEFAULT 0,
    holds INT NOT NULL DEFAULT 0,
    bookings INT NOT NULL DEFAULT 0,
    available_spaces INT NOT NULL DEFAULT 0,
    demand_score NUMERIC(4,2) NOT NULL,
    multiplier NUMERIC(4,2) NOT NULL,
    PRIMARY KEY (tile_id, window_start)
);
```

---

## 🧪 Casos de Prueba

### 1. Demanda Muy Alta (Nochevieja en Madrid Centro)
```
Tile: Madrid-Centro
- searches_last_24h: 500
- holds_last_24h: 25
- bookings_last_24h: 15
- available_spaces: 10

demandScore = min(1.0, (500*0.01 + 25*0.1 + 15*0.5) / 10)
            = min(1.0, (5 + 2.5 + 7.5) / 10)
            = min(1.0, 1.5)
            = 1.0

multiplier = 1.0 + (1.0 * 1.5) = 2.5 (MÁXIMO)

Precio base 3500 → Precio final 8750 cents (87.50€)
```

### 2. Demanda Baja (Lunes en zona residencial)
```
Tile: Getafe-Residencial
- searches_last_24h: 5
- holds_last_24h: 0
- bookings_last_24h: 0
- available_spaces: 20

demandScore = min(1.0, (5*0.01) / 20) = 0.0025

multiplier = 1.0 + (0.0025 * 1.5) = 1.00 (precio base)

Precio base 2500 → Precio final 2500 cents (25€)
```

### 3. Demanda Media (Fin de semana en zona turística)
```
Tile: Malasaña
- searches_last_24h: 80
- holds_last_24h: 5
- bookings_last_24h: 2
- available_spaces: 8

demandScore = (80*0.01 + 5*0.1 + 2*0.5) / 8 = (0.8+0.5+1) / 8 = 0.2875

multiplier = 1.0 + (0.2875 * 1.5) = 1.43

Precio base 4000 → Precio final 5720 cents (57.20€)
```

---

## 🚀 Roadmap de Mejoras (Post-MVP)

### V2: Factores Adicionales
- **Día de la semana:** Multiplicador extra +0.2 en viernes/sábado
- **Eventos locales:** API de eventos públicos → boost automático
- **Clima:** Integración con WeatherAPI → boost en días soleados

### V3: Machine Learning
- Entrenamiento con históricos de bookings
- Predicción de demanda 7 días hacia adelante
- Ajuste automático de pesos (0.01, 0.1, 0.5) con A/B testing

### V4: Personalización
- Precios diferenciados por segmento de usuario (corporativo vs particular)
- Descuentos por fidelización (reviews positivas)

---

## 📝 Notas de Implementación

1. **Kafka Streams vs Scheduler:**
   - **MVP**: Usar `@Scheduled` cada 5 min leyendo de `demand_agg`
   - **Producción**: Migrar a Kafka Streams cuando >50k búsquedas/hora

2. **Caché Redis:**
   - Key: `price:{spaceId}:{timeslotStart}`
   - TTL: 15 minutos
   - Invalidar en eventos: `SpaceUpdated`, `PriceRecomputeRequested`

3. **Fallback:**
   - Si Redis falla → leer de `price_surface` DB
   - Si `price_surface` vacía → usar `base_price_cents`

4. **Monitoreo:**
   - Alertar si `multiplier > 2.3` en >50% de espacios (posible bug)
   - Dashboard: distribución de multipliers por tile

---

**Última actualización:** 25 de octubre de 2025  
**Autor:** Equipo de Data Science Balconazo

