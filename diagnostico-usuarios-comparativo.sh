#!/bin/bash

# Script de diagnóstico completo: Usuario Nuevo vs Host1
# Ejecuta pruebas paralelas para comparar comportamiento

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 DIAGNÓSTICO: Usuario Nuevo vs Host1${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

API_BASE="http://localhost:8080/api"

# ============================================
# TEST 1: Login Usuario Nuevo
# ============================================
echo -e "${YELLOW}📍 TEST 1: Login Usuario Nuevo (aamolinad4d5@gmail.com)${NC}"

NUEVO_LOGIN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "aamolinad4d5@gmail.com",
    "password": "Angel1234"
  }')

echo "$NUEVO_LOGIN" | jq '.'

NUEVO_ACCESS=$(echo "$NUEVO_LOGIN" | jq -r '.accessToken')
NUEVO_REFRESH=$(echo "$NUEVO_LOGIN" | jq -r '.refreshToken')
NUEVO_USER_ID=$(echo "$NUEVO_LOGIN" | jq -r '.userId')

echo -e "${GREEN}✅ Usuario Nuevo logueado${NC}"
echo "  Access Token: ${NUEVO_ACCESS:0:50}..."
echo "  Refresh Token: ${NUEVO_REFRESH:0:50}..."
echo "  User ID: $NUEVO_USER_ID"
echo ""

# ============================================
# TEST 2: Login Host1
# ============================================
echo -e "${YELLOW}📍 TEST 2: Login Host1 (host1@balconazo.com)${NC}"

HOST1_LOGIN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "host1@balconazo.com",
    "password": "password123"
  }')

echo "$HOST1_LOGIN" | jq '.'

HOST1_ACCESS=$(echo "$HOST1_LOGIN" | jq -r '.accessToken')
HOST1_REFRESH=$(echo "$HOST1_LOGIN" | jq -r '.refreshToken')
HOST1_USER_ID=$(echo "$HOST1_LOGIN" | jq -r '.userId')

echo -e "${GREEN}✅ Host1 logueado${NC}"
echo "  Access Token: ${HOST1_ACCESS:0:50}..."
echo "  Refresh Token: ${HOST1_REFRESH:0:50}..."
echo "  User ID: $HOST1_USER_ID"
echo ""

# ============================================
# TEST 3: GET /me con ambos usuarios
# ============================================
echo -e "${YELLOW}📍 TEST 3: Verificar /auth/me con ambos tokens${NC}"

echo "Usuario Nuevo:"
NUEVO_ME=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $NUEVO_ACCESS" \
  "$API_BASE/auth/me")

NUEVO_ME_CODE=$(echo "$NUEVO_ME" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
NUEVO_ME_BODY=$(echo "$NUEVO_ME" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$NUEVO_ME_CODE" = "200" ]; then
    echo -e "  ${GREEN}✅ GET /auth/me → 200 OK${NC}"
    echo "$NUEVO_ME_BODY" | jq '.'
else
    echo -e "  ${RED}❌ GET /auth/me → $NUEVO_ME_CODE${NC}"
    echo "$NUEVO_ME_BODY"
fi

echo ""
echo "Host1:"
HOST1_ME=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $HOST1_ACCESS" \
  "$API_BASE/auth/me")

HOST1_ME_CODE=$(echo "$HOST1_ME" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
HOST1_ME_BODY=$(echo "$HOST1_ME" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HOST1_ME_CODE" = "200" ]; then
    echo -e "  ${GREEN}✅ GET /auth/me → 200 OK${NC}"
    echo "$HOST1_ME_BODY" | jq '.'
else
    echo -e "  ${RED}❌ GET /auth/me → $HOST1_ME_CODE${NC}"
    echo "$HOST1_ME_BODY"
fi

echo ""

# ============================================
# TEST 4: GET /catalog/spaces/owner/{id}
# ============================================
echo -e "${YELLOW}📍 TEST 4: GET /catalog/spaces/owner/{id}${NC}"

echo "Usuario Nuevo ($NUEVO_USER_ID):"
NUEVO_SPACES=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $NUEVO_ACCESS" \
  "$API_BASE/catalog/spaces/owner/$NUEVO_USER_ID")

NUEVO_SPACES_CODE=$(echo "$NUEVO_SPACES" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
NUEVO_SPACES_BODY=$(echo "$NUEVO_SPACES" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$NUEVO_SPACES_CODE" = "200" ]; then
    SPACES_COUNT=$(echo "$NUEVO_SPACES_BODY" | jq '. | length')
    echo -e "  ${GREEN}✅ GET /catalog/spaces/owner/{id} → 200 OK${NC}"
    echo "  Espacios encontrados: $SPACES_COUNT"
elif [ "$NUEVO_SPACES_CODE" = "401" ]; then
    echo -e "  ${RED}❌ GET /catalog/spaces/owner/{id} → 401 UNAUTHORIZED${NC}"
    echo "  Body: $NUEVO_SPACES_BODY"
else
    echo -e "  ${YELLOW}⚠️  GET /catalog/spaces/owner/{id} → $NUEVO_SPACES_CODE${NC}"
    echo "  Body: $NUEVO_SPACES_BODY"
fi

echo ""
echo "Host1 ($HOST1_USER_ID):"
HOST1_SPACES=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  -H "Authorization: Bearer $HOST1_ACCESS" \
  "$API_BASE/catalog/spaces/owner/$HOST1_USER_ID")

HOST1_SPACES_CODE=$(echo "$HOST1_SPACES" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
HOST1_SPACES_BODY=$(echo "$HOST1_SPACES" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HOST1_SPACES_CODE" = "200" ]; then
    SPACES_COUNT=$(echo "$HOST1_SPACES_BODY" | jq '. | length')
    echo -e "  ${GREEN}✅ GET /catalog/spaces/owner/{id} → 200 OK${NC}"
    echo "  Espacios encontrados: $SPACES_COUNT"
else
    echo -e "  ${RED}❌ GET /catalog/spaces/owner/{id} → $HOST1_SPACES_CODE${NC}"
    echo "  Body: $HOST1_SPACES_BODY"
fi

echo ""

# ============================================
# TEST 5: Refresh Token - Usuario Nuevo
# ============================================
if [ "$NUEVO_SPACES_CODE" = "401" ]; then
    echo -e "${YELLOW}📍 TEST 5: Refresh Token del Usuario Nuevo${NC}"

    NUEVO_REFRESH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
      -X POST "$API_BASE/auth/refresh" \
      -H "Content-Type: application/json" \
      -d "{\"refreshToken\": \"$NUEVO_REFRESH\"}")

    NUEVO_REFRESH_CODE=$(echo "$NUEVO_REFRESH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)
    NUEVO_REFRESH_BODY=$(echo "$NUEVO_REFRESH_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

    if [ "$NUEVO_REFRESH_CODE" = "200" ]; then
        echo -e "  ${GREEN}✅ POST /auth/refresh → 200 OK${NC}"
        echo "$NUEVO_REFRESH_BODY" | jq '.'

        NUEVO_ACCESS_NEW=$(echo "$NUEVO_REFRESH_BODY" | jq -r '.accessToken')
        echo ""
        echo "  Reintentando GET /catalog/spaces/owner/{id} con nuevo token..."

        NUEVO_SPACES_RETRY=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
          -H "Authorization: Bearer $NUEVO_ACCESS_NEW" \
          "$API_BASE/catalog/spaces/owner/$NUEVO_USER_ID")

        NUEVO_SPACES_RETRY_CODE=$(echo "$NUEVO_SPACES_RETRY" | grep -o "HTTP_CODE:[0-9]*" | cut -d':' -f2)

        if [ "$NUEVO_SPACES_RETRY_CODE" = "200" ]; then
            echo -e "  ${GREEN}✅ Retry → 200 OK (REFRESH FUNCIONÓ)${NC}"
        else
            echo -e "  ${RED}❌ Retry → $NUEVO_SPACES_RETRY_CODE (REFRESH NO SOLUCIONÓ EL PROBLEMA)${NC}"
            echo "  Body: $(echo "$NUEVO_SPACES_RETRY" | sed 's/HTTP_CODE:[0-9]*$//')"
        fi
    else
        echo -e "  ${RED}❌ POST /auth/refresh → $NUEVO_REFRESH_CODE${NC}"
        echo "$NUEVO_REFRESH_BODY"
    fi

    echo ""
fi

# ============================================
# TEST 6: Decodificar JWT de ambos usuarios
# ============================================
echo -e "${YELLOW}📍 TEST 6: Comparar payloads de JWT${NC}"

echo "Usuario Nuevo JWT Payload:"
echo "$NUEVO_ACCESS" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.' || echo "Error decodificando"

echo ""
echo "Host1 JWT Payload:"
echo "$HOST1_ACCESS" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.' || echo "Error decodificando"

echo ""

# ============================================
# RESUMEN
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 RESUMEN DE DIFERENCIAS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo "| Endpoint | Usuario Nuevo | Host1 |"
echo "|----------|--------------|-------|"
echo "| POST /auth/login | ✅ $NUEVO_ME_CODE | ✅ $HOST1_ME_CODE |"
echo "| GET /auth/me | $([[ "$NUEVO_ME_CODE" = "200" ]] && echo "✅" || echo "❌") $NUEVO_ME_CODE | $([[ "$HOST1_ME_CODE" = "200" ]] && echo "✅" || echo "❌") $HOST1_ME_CODE |"
echo "| GET /catalog/spaces/owner/{id} | $([[ "$NUEVO_SPACES_CODE" = "200" ]] && echo "✅" || echo "❌") $NUEVO_SPACES_CODE | $([[ "$HOST1_SPACES_CODE" = "200" ]] && echo "✅" || echo "❌") $HOST1_SPACES_CODE |"

echo ""
echo -e "${GREEN}🎉 Diagnóstico completado${NC}"

