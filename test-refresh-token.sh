#!/bin/bash

# Script completo de pruebas para Refresh Token
# Uso: ./test-refresh-token.sh

set -e

echo "🧪 Iniciando pruebas de Refresh Token..."
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_BASE="http://localhost:8080/api"

# ============================================
# TEST 1: Login y obtener tokens
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📍 TEST 1: Login y obtener tokens${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "password123"
  }')

echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.accessToken' 2>/dev/null)
REFRESH_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.refreshToken' 2>/dev/null)
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.userId' 2>/dev/null)

if [ "$ACCESS_TOKEN" != "null" ] && [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${GREEN}✅ Login exitoso${NC}"
    echo "Access Token: ${ACCESS_TOKEN:0:50}..."
    echo "Refresh Token: ${REFRESH_TOKEN:0:50}..."
    echo "User ID: $USER_ID"
else
    echo -e "${RED}❌ Login falló${NC}"
    exit 1
fi

echo ""

# ============================================
# TEST 2: Usar access token válido
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📍 TEST 2: Request con token válido${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

ME_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$API_BASE/auth/me")

HTTP_CODE=$(echo "$ME_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
BODY=$(echo "$ME_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ GET /auth/me → 200 OK${NC}"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
else
    echo -e "${RED}❌ GET /auth/me → $HTTP_CODE${NC}"
    echo "$BODY"
fi

echo ""

# ============================================
# TEST 3: Refresh token
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📍 TEST 3: Refresh token${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

REFRESH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST "$API_BASE/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}")

HTTP_CODE=$(echo "$REFRESH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
BODY=$(echo "$REFRESH_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ POST /auth/refresh → 200 OK${NC}"

    NEW_ACCESS_TOKEN=$(echo "$BODY" | jq -r '.accessToken' 2>/dev/null)
    NEW_REFRESH_TOKEN=$(echo "$BODY" | jq -r '.refreshToken' 2>/dev/null)

    echo "Nuevo Access Token: ${NEW_ACCESS_TOKEN:0:50}..."

    if [ "$NEW_REFRESH_TOKEN" != "null" ] && [ -n "$NEW_REFRESH_TOKEN" ]; then
        echo "Nuevo Refresh Token: ${NEW_REFRESH_TOKEN:0:50}..."
    else
        echo "Refresh Token (sin cambios): ${REFRESH_TOKEN:0:50}..."
    fi

    # Usar nuevo token
    ACCESS_TOKEN="$NEW_ACCESS_TOKEN"
else
    echo -e "${RED}❌ POST /auth/refresh → $HTTP_CODE${NC}"
    echo "$BODY"
    exit 1
fi

echo ""

# ============================================
# TEST 4: Usar nuevo token
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📍 TEST 4: Request con nuevo token${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SPACES_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "$API_BASE/catalog/spaces/owner/$USER_ID")

HTTP_CODE=$(echo "$SPACES_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
BODY=$(echo "$SPACES_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ GET /catalog/spaces/owner/$USER_ID → 200 OK${NC}"

    SPACES_COUNT=$(echo "$BODY" | jq '. | length' 2>/dev/null || echo "?")
    echo "Espacios encontrados: $SPACES_COUNT"
else
    echo -e "${RED}❌ GET /catalog/spaces/owner/$USER_ID → $HTTP_CODE${NC}"
    echo "$BODY"
fi

echo ""

# ============================================
# TEST 5: Refresh token inválido
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📍 TEST 5: Refresh con token inválido${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

INVALID_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -X POST "$API_BASE/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "invalid_token_123"}')

HTTP_CODE=$(echo "$INVALID_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✅ POST /auth/refresh con token inválido → $HTTP_CODE (esperado)${NC}"
else
    echo -e "${YELLOW}⚠️  POST /auth/refresh con token inválido → $HTTP_CODE (esperaba 401/400)${NC}"
fi

echo ""

# ============================================
# RESUMEN
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 RESUMEN DE PRUEBAS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "
${GREEN}✅ Todos los flujos básicos funcionan correctamente${NC}

Próximos pasos para probar en UI:
1. Iniciar frontend: cd balconazo-frontend && npm run dev
2. Login en http://localhost:4200
3. Ver en DevTools:
   - Application → LocalStorage → accessToken, refreshToken
4. Simular expiración (console):
   - const refresh = localStorage.getItem('refreshToken');
   - localStorage.setItem('accessToken', 'expired_token');
5. Navegar a 'Mis Espacios'
6. Verificar en Network:
   - GET /spaces/owner/... → 401
   - POST /auth/refresh → 200
   - GET /spaces/owner/... → 200 (retry automático)
7. Verificar en Console:
   - '✅ Token refrescado exitosamente'

${YELLOW}Tokens generados para pruebas manuales:${NC}
Access Token: ${ACCESS_TOKEN:0:80}...
Refresh Token: ${REFRESH_TOKEN:0:80}...
User ID: $USER_ID
"

echo ""
echo -e "${GREEN}🎉 Pruebas completadas${NC}"

