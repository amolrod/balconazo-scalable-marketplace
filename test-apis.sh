#!/bin/bash

# Script de pruebas para APIs de Balconazo
# Uso: ./test-apis.sh

set -e

echo "🧪 Iniciando pruebas de APIs..."
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
API_BASE="http://localhost:8080/api"
JWT_TOKEN=""

# Función para mostrar resultados
check_response() {
    local response=$1
    local expected=$2
    local description=$3

    if echo "$response" | grep -q "HTTP/.*$expected"; then
        echo -e "${GREEN}✅ PASS${NC}: $description"
    else
        echo -e "${RED}❌ FAIL${NC}: $description"
        echo "Response: $response"
    fi
    echo ""
}

# TEST 1: Health Check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 TEST 1: Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Checking Gateway health..."
RESPONSE=$(curl -si http://localhost:8080/actuator/health 2>/dev/null || echo "Connection refused")
check_response "$RESPONSE" "200" "Gateway health"

echo "Checking Auth service..."
RESPONSE=$(curl -si http://localhost:8084/actuator/health 2>/dev/null || echo "Connection refused")
check_response "$RESPONSE" "200" "Auth service health"

echo "Checking Catalog service..."
RESPONSE=$(curl -si http://localhost:8085/actuator/health 2>/dev/null || echo "Connection refused")
check_response "$RESPONSE" "200" "Catalog service health"

# TEST 2: Login para obtener JWT
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 TEST 2: Login (obtener JWT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -si "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "password123"
  }' 2>/dev/null)

check_response "$RESPONSE" "200" "Login exitoso"

# Extraer token (si existe)
JWT_TOKEN=$(echo "$RESPONSE" | grep -o '"accessToken":"[^"]*' | sed 's/"accessToken":"//')

if [ -n "$JWT_TOKEN" ]; then
    echo -e "${GREEN}Token obtenido:${NC} ${JWT_TOKEN:0:50}..."
else
    echo -e "${YELLOW}⚠️  No se pudo obtener token. Pruebas con autenticación fallarán.${NC}"
fi
echo ""

# TEST 3: Get Profile (/api/auth/me)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 TEST 3: Get User Profile"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$JWT_TOKEN" ]; then
    RESPONSE=$(curl -si "$API_BASE/auth/me" \
      -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null)
    check_response "$RESPONSE" "200" "Get profile con token"
else
    echo -e "${YELLOW}⏭️  Saltando (sin token)${NC}"
    echo ""
fi

# TEST 4: Get Spaces List
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏠 TEST 4: Get Spaces List"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE=$(curl -si "$API_BASE/catalog/spaces" 2>/dev/null)
check_response "$RESPONSE" "200" "Get spaces (sin auth)"

# TEST 5: Get Space by ID (usar un ID real si existe)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 TEST 5: Get Space by ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Intentar obtener primer espacio de la lista
FIRST_SPACE_ID=$(curl -s "$API_BASE/catalog/spaces" 2>/dev/null | grep -o '"id":"[^"]*' | head -1 | sed 's/"id":"//')

if [ -n "$FIRST_SPACE_ID" ]; then
    echo "ID encontrado: $FIRST_SPACE_ID"
    RESPONSE=$(curl -si "$API_BASE/catalog/spaces/$FIRST_SPACE_ID" 2>/dev/null)
    check_response "$RESPONSE" "200" "Get space by ID"
else
    echo -e "${YELLOW}⏭️  No hay espacios en la base de datos${NC}"
    echo ""
fi

# TEST 6: Create Space (requiere autenticación)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "➕ TEST 6: Create Space"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$JWT_TOKEN" ]; then
    # Obtener userId del endpoint /api/auth/me
    USER_RESPONSE=$(curl -s "$API_BASE/auth/me" \
      -H "Authorization: Bearer $JWT_TOKEN" 2>/dev/null)

    USER_ID=$(echo "$USER_RESPONSE" | grep -o '"userId":"[^"]*' | sed 's/"userId":"//' || echo "")

    if [ -z "$USER_ID" ]; then
        # Intentar extraer 'id' en lugar de 'userId'
        USER_ID=$(echo "$USER_RESPONSE" | grep -o '"id":"[^"]*' | sed 's/"id":"//' || echo "")
    fi

    if [ -z "$USER_ID" ]; then
        echo -e "${YELLOW}⚠️  No se pudo obtener userId del perfil. Usando valor por defecto.${NC}"
        USER_ID="550e8400-e29b-41d4-a716-446655440000"
    else
        echo "userId obtenido del perfil: $USER_ID"
    fi

    RESPONSE=$(curl -si "$API_BASE/catalog/spaces" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $JWT_TOKEN" \
      -d "{
        \"ownerId\": \"$USER_ID\",
        \"title\": \"Test Space - $(date +%s)\",
        \"description\": \"Espacio de prueba creado automáticamente\",
        \"address\": \"Calle Test 123, Madrid\",
        \"lat\": 40.4168,
        \"lon\": -3.7038,
        \"capacity\": 10,
        \"basePriceCents\": 2500,
        \"amenities\": [\"wifi\", \"parking\"],
        \"rules\": {}
      }" 2>/dev/null)

    check_response "$RESPONSE" "20" "Create space (esperando 200 o 201)"

    # Mostrar body si falló
    if echo "$RESPONSE" | grep -q "HTTP/.*[45][0-9][0-9]"; then
        echo -e "${RED}Error detectado - Body de respuesta:${NC}"
        echo "$RESPONSE" | tail -5
        echo ""
    fi
else
    echo -e "${YELLOW}⏭️  Saltando (sin token)${NC}"
    echo ""
fi

# RESUMEN
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN DE PRUEBAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Si alguna prueba falló, verifica:"
echo "  1. Que todos los servicios estén corriendo"
echo "  2. Que las rutas en el gateway estén correctas"
echo "  3. Que exista un usuario de prueba en la BD"
echo "  4. Los logs de los microservicios"
echo ""
echo "Servicios esperados:"
echo "  - Gateway:  http://localhost:8080"
echo "  - Auth:     http://localhost:8084"
echo "  - Catalog:  http://localhost:8085"
echo ""

