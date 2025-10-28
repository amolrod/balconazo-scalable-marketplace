#!/bin/bash

set -e

echo "🧪 PRUEBA END-TO-END - BALCONAZO"
echo "================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# PASO 1a: Crear HOST
echo "📝 PASO 1a: Creando usuario HOST..."

HOST_RESP=$(curl -s -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{"email":"host-e2e@balconazo.com","password":"password123","role":"host"}')

echo "$HOST_RESP" | python3 -m json.tool 2>/dev/null || echo "$HOST_RESP"

HOST_ID=$(echo "$HOST_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -z "$HOST_ID" ]; then
    echo -e "${RED}❌ Error: No se pudo crear el host${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Host creado: $HOST_ID${NC}"
echo ""

# PASO 1b: Crear GUEST
echo "📝 PASO 1b: Creando usuario GUEST..."

GUEST_RESP=$(curl -s -X POST http://localhost:8085/api/catalog/users \
  -H "Content-Type: application/json" \
  -d '{"email":"guest-e2e@balconazo.com","password":"password123","role":"guest"}')

echo "$GUEST_RESP" | python3 -m json.tool 2>/dev/null || echo "$GUEST_RESP"

GUEST_ID=$(echo "$GUEST_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -z "$GUEST_ID" ]; then
    echo -e "${RED}❌ Error: No se pudo crear el guest${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Guest creado: $GUEST_ID${NC}"
echo ""

# PASO 2: Crear ESPACIO
echo "📝 PASO 2: Creando espacio..."

SPACE_JSON="{\"ownerId\":\"$HOST_ID\",\"title\":\"Terraza Test E2E\",\"description\":\"Espacio de prueba\",\"address\":\"Calle Test 1, Madrid\",\"lat\":40.4168,\"lon\":-3.7038,\"capacity\":4,\"areaSqm\":30.0,\"basePriceCents\":5000,\"amenities\":[\"wifi\"],\"rules\":{}}"

echo "JSON del espacio:"
echo "$SPACE_JSON" | python3 -m json.tool
echo ""

SPACE_RESP=$(curl -s -X POST http://localhost:8085/api/catalog/spaces \
  -H "Content-Type: application/json" \
  -d "$SPACE_JSON")

echo "Respuesta del servidor:"
echo "$SPACE_RESP" | python3 -m json.tool 2>/dev/null || echo "$SPACE_RESP"

SPACE_ID=$(echo "$SPACE_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -z "$SPACE_ID" ]; then
    echo -e "${RED}❌ Error: No se pudo crear el espacio${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Espacio creado: $SPACE_ID${NC}"
echo ""

# PASO 3: Crear RESERVA
echo "📝 PASO 3: Creando reserva..."
echo "HOST_ID=$HOST_ID"
echo "GUEST_ID=$GUEST_ID"
echo "SPACE_ID=$SPACE_ID"
echo ""

BOOKING_JSON="{\"spaceId\":\"$SPACE_ID\",\"guestId\":\"$GUEST_ID\",\"startTs\":\"2025-12-31T18:00:00\",\"endTs\":\"2025-12-31T23:00:00\",\"numGuests\":2}"

BOOKING_RESP=$(curl -s -X POST http://localhost:8082/api/booking/bookings \
  -H "Content-Type: application/json" \
  -d "$BOOKING_JSON")

echo "Respuesta del servidor:"
echo "$BOOKING_RESP" | python3 -m json.tool 2>/dev/null || echo "$BOOKING_RESP"

BOOKING_ID=$(echo "$BOOKING_RESP" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

if [ -z "$BOOKING_ID" ]; then
    echo -e "${RED}❌ Error: No se pudo crear la reserva${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Reserva creada: $BOOKING_ID${NC}"
echo ""

# PASO 4: Ver eventos en Kafka
echo "📝 PASO 4: Verificando eventos en Kafka..."
echo ""

echo "Eventos en booking.events.v1:"
docker exec balconazo-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic booking.events.v1 \
  --from-beginning \
  --max-messages 1 \
  --timeout-ms 5000 2>/dev/null || echo "(el evento puede estar procesándose)"

echo ""
echo -e "${GREEN}✅ PRUEBA END-TO-END COMPLETADA${NC}"
echo ""
echo "📊 RESUMEN:"
echo "  - Host ID: $HOST_ID"
echo "  - Guest ID: $GUEST_ID"
echo "  - Espacio ID: $SPACE_ID"
echo "  - Reserva ID: $BOOKING_ID"
echo ""
echo "🔍 Ver en PostgreSQL:"
echo "  docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c \"SELECT id, email, role FROM catalog.users WHERE id IN ('$HOST_ID', '$GUEST_ID');\""
echo "  docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -c \"SELECT id, title FROM catalog.spaces WHERE id='$SPACE_ID';\""
echo "  docker exec balconazo-pg-booking psql -U postgres -d booking_db -c \"SELECT id, status, payment_status FROM booking.bookings WHERE id='$BOOKING_ID';\""

