#!/bin/bash

echo "🧪 SUITE DE TESTS COMPLETA - SISTEMA BALCONAZO"
echo "==============================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Función para test
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected_code="$3"

    echo -n "Testing: $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$response" == "$expected_code" ]; then
        echo -e "${GREEN}✅ PASSED${NC} (HTTP $response)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED${NC} (Expected $expected_code, got $response)"
        ((FAILED++))
        return 1
    fi
}

# Función para test con JSON
test_json_endpoint() {
    local name="$1"
    local url="$2"
    local method="${3:-GET}"
    local data="$4"

    echo -n "Testing: $name... "

    if [ "$method" == "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" "$url")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✅ PASSED${NC} (HTTP $http_code)"
        ((PASSED++))
        echo "$body" | python3 -m json.tool 2>/dev/null | head -10
        return 0
    else
        echo -e "${RED}❌ FAILED${NC} (HTTP $http_code)"
        ((FAILED++))
        echo "$body" | head -5
        return 1
    fi
}

echo "═══════════════════════════════════════════════════════"
echo "TEST 1: HEALTH CHECKS DE TODOS LOS SERVICIOS"
echo "═══════════════════════════════════════════════════════"
echo ""

test_endpoint "Eureka Server Health" "http://localhost:8761/actuator/health" "200"
test_endpoint "Auth Service Health" "http://localhost:8084/actuator/health" "200"
test_endpoint "Catalog Service Health" "http://localhost:8085/actuator/health" "200"
test_endpoint "Booking Service Health" "http://localhost:8082/actuator/health" "200"
test_endpoint "Search Service Health" "http://localhost:8083/actuator/health" "200"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 2: EUREKA - VERIFICAR SERVICIOS REGISTRADOS"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Consultando servicios registrados en Eureka..."
EUREKA_APPS=$(curl -s http://localhost:8761/eureka/apps | grep -o '<name>[^<]*</name>' | sed 's/<name>//g' | sed 's/<\/name>//g' | sort -u)

if [ ! -z "$EUREKA_APPS" ]; then
    echo -e "${GREEN}✅ Servicios registrados:${NC}"
    echo "$EUREKA_APPS" | while read app; do
        echo "   - $app"
    done
    ((PASSED++))
else
    echo -e "${RED}❌ No hay servicios registrados en Eureka${NC}"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 3: AUTH SERVICE - REGISTRO DE USUARIO"
echo "═══════════════════════════════════════════════════════"
echo ""

# Generar email único con timestamp
TIMESTAMP=$(date +%s)
TEST_EMAIL="test${TIMESTAMP}@balconazo.com"

echo "Registrando usuario: $TEST_EMAIL"
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8084/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"password123\",
    \"role\": \"HOST\"
  }")

if echo "$REGISTER_RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✅ Usuario registrado exitosamente${NC}"
    echo "$REGISTER_RESPONSE" | python3 -m json.tool
    ((PASSED++))

    # Guardar USER_ID
    USER_ID=$(echo "$REGISTER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', ''))")
    echo ""
    echo "USER_ID: $USER_ID"
else
    echo -e "${RED}❌ Error al registrar usuario${NC}"
    echo "$REGISTER_RESPONSE"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 4: AUTH SERVICE - LOGIN Y OBTENER JWT"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Iniciando sesión con: $TEST_EMAIL"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"password123\"
  }")

if echo "$LOGIN_RESPONSE" | grep -q "accessToken"; then
    echo -e "${GREEN}✅ Login exitoso - JWT obtenido${NC}"
    JWT=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('accessToken', ''))")
    echo "$LOGIN_RESPONSE" | python3 -m json.tool | head -15
    ((PASSED++))
    echo ""
    echo "JWT Token: ${JWT:0:50}..."
else
    echo -e "${RED}❌ Error en login${NC}"
    echo "$LOGIN_RESPONSE"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 5: CATALOG SERVICE - CREAR ESPACIO"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ ! -z "$USER_ID" ]; then
    echo "Creando espacio con USER_ID: $USER_ID"
    SPACE_RESPONSE=$(curl -s -X POST http://localhost:8085/api/catalog/spaces \
      -H "Content-Type: application/json" \
      -d "{
        \"ownerId\": \"$USER_ID\",
        \"title\": \"Terraza Test E2E\",
        \"description\": \"Espacio de prueba automatizada\",
        \"address\": \"Calle Test 123, Madrid\",
        \"lat\": 40.4168,
        \"lon\": -3.7038,
        \"capacity\": 10,
        \"areaSqm\": 50.0,
        \"basePriceCents\": 8500,
        \"amenities\": [\"wifi\", \"music_system\", \"parking\"],
        \"rules\": {\"no_smoking\": true, \"no_pets\": false}
      }")

    if echo "$SPACE_RESPONSE" | grep -q "id"; then
        echo -e "${GREEN}✅ Espacio creado exitosamente${NC}"
        SPACE_ID=$(echo "$SPACE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', ''))")
        echo "$SPACE_RESPONSE" | python3 -m json.tool | head -20
        ((PASSED++))
        echo ""
        echo "SPACE_ID: $SPACE_ID"
    else
        echo -e "${RED}❌ Error al crear espacio${NC}"
        echo "$SPACE_RESPONSE"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - No hay USER_ID disponible${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 6: CATALOG SERVICE - LISTAR ESPACIOS DEL HOST"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ ! -z "$USER_ID" ]; then
    echo "Consultando espacios del host: $USER_ID"
    SPACES_LIST=$(curl -s "http://localhost:8085/api/catalog/spaces?hostId=$USER_ID")

    if echo "$SPACES_LIST" | grep -q "\["; then
        echo -e "${GREEN}✅ Listado de espacios obtenido${NC}"
        echo "$SPACES_LIST" | python3 -m json.tool | head -30
        ((PASSED++))
    else
        echo -e "${RED}❌ Error al listar espacios${NC}"
        echo "$SPACES_LIST"
        ((FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - No hay USER_ID disponible${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 7: BOOKING SERVICE - CREAR RESERVA"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ ! -z "$SPACE_ID" ] && [ ! -z "$USER_ID" ]; then
    # Crear otro usuario como guest
    GUEST_EMAIL="guest${TIMESTAMP}@balconazo.com"
    GUEST_REGISTER=$(curl -s -X POST http://localhost:8084/api/auth/register \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$GUEST_EMAIL\",
        \"password\": \"password123\",
        \"role\": \"GUEST\"
      }")

    GUEST_ID=$(echo "$GUEST_REGISTER" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', ''))" 2>/dev/null)

    if [ ! -z "$GUEST_ID" ]; then
        echo "Guest registrado: $GUEST_ID"
        echo "Creando booking..."

        BOOKING_RESPONSE=$(curl -s -X POST http://localhost:8082/api/booking/bookings \
          -H "Content-Type: application/json" \
          -d "{
            \"spaceId\": \"$SPACE_ID\",
            \"guestId\": \"$GUEST_ID\",
            \"startTs\": \"2025-12-31T18:00:00\",
            \"endTs\": \"2025-12-31T23:00:00\",
            \"numGuests\": 5
          }")

        if echo "$BOOKING_RESPONSE" | grep -q "id"; then
            echo -e "${GREEN}✅ Booking creado exitosamente${NC}"
            BOOKING_ID=$(echo "$BOOKING_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id', ''))")
            echo "$BOOKING_RESPONSE" | python3 -m json.tool | head -20
            ((PASSED++))
            echo ""
            echo "BOOKING_ID: $BOOKING_ID"
        else
            echo -e "${RED}❌ Error al crear booking${NC}"
            echo "$BOOKING_RESPONSE"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠️  SKIPPED - No se pudo crear guest${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED - No hay SPACE_ID o USER_ID disponible${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 8: SEARCH SERVICE - BÚSQUEDA GEOESPACIAL"
echo "═══════════════════════════════════════════════════════"
echo ""

# Base URL para Search Service
SEARCH_BASE=${SEARCH_BASE:-http://localhost:8083/api/search}

echo "Buscando espacios cerca de Madrid (lat: 40.4168, lon: -3.7038, radio: 10km)"
SEARCH_RESPONSE=$(curl -s "$SEARCH_BASE/spaces?lat=40.4168&lon=-3.7038&radiusKm=10")

if echo "$SEARCH_RESPONSE" | grep -q "\["; then
    echo -e "${GREEN}✅ Búsqueda ejecutada exitosamente${NC}"
    echo "$SEARCH_RESPONSE" | python3 -m json.tool | head -40
    ((PASSED++))
else
    echo -e "${RED}❌ Error en búsqueda${NC}"
    echo "$SEARCH_RESPONSE"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 9: VERIFICAR EVENTOS EN KAFKA"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "Verificando tópicos de Kafka..."
TOPICS=$(docker exec balconazo-kafka kafka-topics --list --bootstrap-server localhost:9092 2>/dev/null)

if echo "$TOPICS" | grep -q "space.events.v1"; then
    echo -e "${GREEN}✅ Tópico space.events.v1 existe${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Tópico space.events.v1 no encontrado${NC}"
    ((FAILED++))
fi

if echo "$TOPICS" | grep -q "booking.events.v1"; then
    echo -e "${GREEN}✅ Tópico booking.events.v1 existe${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Tópico booking.events.v1 no encontrado${NC}"
    ((FAILED++))
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "TEST 10: VERIFICAR DATOS EN BASES DE DATOS"
echo "═══════════════════════════════════════════════════════"
echo ""

# PostgreSQL Catalog
echo "Verificando datos en catalog_db..."
CATALOG_COUNT=$(docker exec balconazo-pg-catalog psql -U postgres -d catalog_db -t -c "SELECT COUNT(*) FROM catalog.spaces;" 2>/dev/null | tr -d ' ')

if [ ! -z "$CATALOG_COUNT" ] && [ "$CATALOG_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Hay $CATALOG_COUNT espacios en catalog_db${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  No hay espacios en catalog_db (puede ser normal)${NC}"
fi

# MySQL Auth
echo "Verificando datos en auth_db..."
AUTH_COUNT=$(docker exec balconazo-mysql-auth mysql -u root -proot -D auth_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null)

if [ ! -z "$AUTH_COUNT" ] && [ "$AUTH_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ Hay $AUTH_COUNT usuarios en auth_db${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠️  No hay usuarios en auth_db${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "RESUMEN DE TESTS"
echo "═══════════════════════════════════════════════════════"
echo ""

TOTAL=$((PASSED + FAILED))
PERCENTAGE=$((PASSED * 100 / TOTAL))

echo "Total de tests ejecutados: $TOTAL"
echo -e "${GREEN}Tests pasados: $PASSED${NC}"
echo -e "${RED}Tests fallidos: $FAILED${NC}"
echo "Porcentaje de éxito: $PERCENTAGE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON EXITOSAMENTE!${NC}"
    echo -e "${GREEN}✅ El sistema está 100% funcional${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Algunos tests fallaron. Revisa los logs.${NC}"
    exit 1
fi

