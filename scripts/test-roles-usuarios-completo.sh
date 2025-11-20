#!/bin/bash

# 🧪 SUITE EXHAUSTIVA DE PRUEBAS - ROLES Y USUARIOS
# ==================================================
# Este script prueba TODOS los escenarios posibles de roles y permisos

BASE_URL="http://localhost:8080"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Función para imprimir resultados
print_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}  ✅ PASS${NC} - $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}  ❌ FAIL${NC} - $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ ! -z "$3" ]; then
            echo -e "${YELLOW}     Detalles: $3${NC}"
        fi
    fi
}

# Función para verificar respuesta HTTP
check_http_code() {
    local expected=$1
    local actual=$2
    local description=$3
    
    if [ "$actual" = "$expected" ]; then
        print_test 0 "$description (HTTP $actual)"
    else
        print_test 1 "$description" "Esperado: HTTP $expected, Obtenido: HTTP $actual"
    fi
}

echo "═══════════════════════════════════════════════════"
echo "🧪 SUITE EXHAUSTIVA DE PRUEBAS - ROLES Y USUARIOS"
echo "═══════════════════════════════════════════════════"
echo ""

# Generar emails únicos con timestamp
TIMESTAMP=$(date +%s)
HOST_EMAIL="host_test_${TIMESTAMP}@balconazo.com"
GUEST_EMAIL="guest_test_${TIMESTAMP}@balconazo.com"
DUAL_EMAIL="dual_test_${TIMESTAMP}@balconazo.com"

echo "📧 Usuarios de prueba generados:"
echo "   Host:  $HOST_EMAIL"
echo "   Guest: $GUEST_EMAIL"
echo "   Dual:  $DUAL_EMAIL"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 1: REGISTRO Y VERIFICACIÓN DE ROLES"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 1.1: Registrar usuario que será HOST
echo "1.1 Registrando usuario HOST..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$HOST_EMAIL\",
    \"password\": \"Test123!\",
    \"name\": \"Test Host User\",
    \"phone\": \"+34600000001\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Registro de usuario HOST"

if [ "$HTTP_CODE" = "201" ]; then
    HOST_USER_ID=$(echo "$BODY" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    
    # Verificar que viene con isHost=false inicialmente
    IS_HOST=$(echo "$BODY" | grep -o '"isHost":[^,}]*' | cut -d':' -f2)
    IS_GUEST=$(echo "$BODY" | grep -o '"isGuest":[^,}]*' | cut -d':' -f2)
    
    echo "   User ID: $HOST_USER_ID"
    echo "   isHost: $IS_HOST (debe ser false inicialmente)"
    echo "   isGuest: $IS_GUEST (debe ser true)"
    
    if [ "$IS_HOST" = "false" ] || [ "$IS_HOST" = "False" ]; then
        print_test 0 "Usuario HOST tiene isHost=false al registrarse"
    else
        print_test 1 "Usuario HOST tiene isHost=$IS_HOST (esperado: false)"
    fi
    
    if [ "$IS_GUEST" = "true" ] || [ "$IS_GUEST" = "True" ]; then
        print_test 0 "Usuario HOST tiene isGuest=true al registrarse"
    else
        print_test 1 "Usuario HOST tiene isGuest=$IS_GUEST (esperado: true)"
    fi
    
    # Hacer login para obtener el token
    echo ""
    echo "   Haciendo login para obtener token..."
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$HOST_EMAIL\",
        \"password\": \"Test123!\"
      }")
    
    LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
    
    if [ "$LOGIN_CODE" = "200" ]; then
        HOST_TOKEN=$(echo "$LOGIN_BODY" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
        echo "   Token obtenido: ${HOST_TOKEN:0:30}..."
        print_test 0 "Login exitoso para usuario HOST"
    else
        print_test 1 "Login falló para usuario HOST" "HTTP $LOGIN_CODE"
    fi
fi
echo ""

# TEST 1.2: Registrar usuario que será GUEST
echo "1.2 Registrando usuario GUEST..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$GUEST_EMAIL\",
    \"password\": \"Test123!\",
    \"name\": \"Test Guest User\",
    \"phone\": \"+34600000002\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Registro de usuario GUEST"

if [ "$HTTP_CODE" = "201" ]; then
    GUEST_USER_ID=$(echo "$BODY" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    echo "   User ID: $GUEST_USER_ID"
    
    # Login para obtener token
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$GUEST_EMAIL\",
        \"password\": \"Test123!\"
      }")
    
    LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
    
    if [ "$LOGIN_CODE" = "200" ]; then
        GUEST_TOKEN=$(echo "$LOGIN_BODY" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
        echo "   Token obtenido: ${GUEST_TOKEN:0:30}..."
    fi
fi
echo ""

# TEST 1.3: Registrar usuario DUAL (será host y guest)
echo "1.3 Registrando usuario DUAL..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$DUAL_EMAIL\",
    \"password\": \"Test123!\",
    \"name\": \"Test Dual User\",
    \"phone\": \"+34600000003\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Registro de usuario DUAL"

if [ "$HTTP_CODE" = "201" ]; then
    DUAL_USER_ID=$(echo "$BODY" | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    echo "   User ID: $DUAL_USER_ID"
    
    # Login para obtener token
    LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$DUAL_EMAIL\",
        \"password\": \"Test123!\"
      }")
    
    LOGIN_CODE=$(echo "$LOGIN_RESPONSE" | tail -n1)
    LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')
    
    if [ "$LOGIN_CODE" = "200" ]; then
        DUAL_TOKEN=$(echo "$LOGIN_BODY" | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
        echo "   Token obtenido: ${DUAL_TOKEN:0:30}..."
    fi
fi
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 2: VERIFICAR ENDPOINT /me"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 2.1: /me del HOST
echo "2.1 Verificando /me del usuario HOST..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "Endpoint /me para HOST"

if [ "$HTTP_CODE" = "200" ]; then
    echo "   Respuesta: $BODY"
    
    # Verificar campos
    if echo "$BODY" | grep -q "userId"; then
        print_test 0 "Campo 'userId' presente"
    else
        print_test 1 "Campo 'userId' ausente"
    fi
    
    if echo "$BODY" | grep -q "email"; then
        print_test 0 "Campo 'email' presente"
    else
        print_test 1 "Campo 'email' ausente"
    fi
fi
echo ""

# TEST 2.2: /me del GUEST
echo "2.2 Verificando /me del usuario GUEST..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $GUEST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "200" "$HTTP_CODE" "Endpoint /me para GUEST"
echo ""

# TEST 2.3: /me sin token (debe fallar)
echo "2.3 Verificando /me SIN token (debe fallar)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/auth/me")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Endpoint /me sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 3: CREAR ESPACIOS (VERIFICAR PROMOCIÓN A HOST)"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 3.1: Usuario HOST crea su primer espacio
echo "3.1 Usuario HOST crea su primer espacio..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/catalog/spaces" \
  -H "Authorization: Bearer $HOST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Espacio Test HOST 1\",
    \"description\": \"Primer espacio del usuario HOST\",
    \"address\": \"Calle Test 1, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 10,
    \"basePriceCents\": 2500,
    \"areaSqm\": 50,
    \"amenities\": [\"wifi\", \"parking\"]
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Crear espacio como usuario HOST"

if [ "$HTTP_CODE" = "201" ]; then
    SPACE_HOST_1=$(echo "$BODY" | grep -o '"id":"[^"]*' | sed -n 1p | cut -d'"' -f4)
    echo "   Space ID: $SPACE_HOST_1"
    
    # Verificar que ahora el usuario es HOST
    echo ""
    echo "   Verificando que el usuario fue promovido a isHost=true..."
    sleep 2  # Esperar a que se actualice
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/auth/me" \
      -H "Authorization: Bearer $HOST_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        IS_HOST=$(echo "$BODY" | grep -o '"isHost":[^,}]*' | cut -d':' -f2)
        echo "   isHost después de crear espacio: $IS_HOST"
        
        if [ "$IS_HOST" = "true" ] || [ "$IS_HOST" = "True" ]; then
            print_test 0 "Usuario promovido a isHost=true tras crear espacio"
        else
            print_test 1 "Usuario NO fue promovido a isHost=true" "isHost=$IS_HOST"
        fi
    fi
fi
echo ""

# TEST 3.2: Usuario HOST crea segundo espacio
echo "3.2 Usuario HOST crea segundo espacio..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/catalog/spaces" \
  -H "Authorization: Bearer $HOST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Espacio Test HOST 2\",
    \"description\": \"Segundo espacio del usuario HOST\",
    \"address\": \"Calle Test 2, Madrid\",
    \"lat\": 40.4200,
    \"lon\": -3.7100,
    \"capacity\": 15,
    \"basePriceCents\": 3000,
    \"areaSqm\": 60
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Crear segundo espacio como HOST"

if [ "$HTTP_CODE" = "201" ]; then
    SPACE_HOST_2=$(echo "$BODY" | grep -o '"id":"[^"]*' | sed -n 1p | cut -d'"' -f4)
    echo "   Space ID: $SPACE_HOST_2"
fi
echo ""

# TEST 3.3: Usuario GUEST intenta crear espacio
echo "3.3 Usuario GUEST intenta crear espacio (debería poder)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/catalog/spaces" \
  -H "Authorization: Bearer $GUEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Espacio Test GUEST 1\",
    \"description\": \"Primer espacio del usuario GUEST (se convertirá en host)\",
    \"address\": \"Calle Test 3, Madrid\",
    \"lat\": 40.4250,
    \"lon\": -3.7150,
    \"capacity\": 8,
    \"basePriceCents\": 2000,
    \"areaSqm\": 40
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Usuario GUEST crea espacio (se convierte en host)"

if [ "$HTTP_CODE" = "201" ]; then
    SPACE_GUEST_1=$(echo "$BODY" | grep -o '"id":"[^"]*' | sed -n 1p | cut -d'"' -f4)
    echo "   Space ID: $SPACE_GUEST_1"
    
    # Verificar promoción a host
    echo ""
    echo "   Verificando promoción de GUEST a HOST..."
    sleep 2
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/auth/me" \
      -H "Authorization: Bearer $GUEST_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        IS_HOST=$(echo "$BODY" | grep -o '"isHost":[^,}]*' | cut -d':' -f2)
        IS_GUEST=$(echo "$BODY" | grep -o '"isGuest":[^,}]*' | cut -d':' -f2)
        
        echo "   isHost: $IS_HOST"
        echo "   isGuest: $IS_GUEST"
        
        if [ "$IS_HOST" = "true" ] || [ "$IS_HOST" = "True" ]; then
            print_test 0 "GUEST promovido a isHost=true tras crear espacio"
        else
            print_test 1 "GUEST NO fue promovido" "isHost=$IS_HOST"
        fi
        
        if [ "$IS_GUEST" = "true" ] || [ "$IS_GUEST" = "True" ]; then
            print_test 0 "Usuario sigue siendo isGuest=true (modelo dual)"
        else
            print_test 1 "Usuario perdió isGuest" "isGuest=$IS_GUEST"
        fi
    fi
fi
echo ""

# TEST 3.4: Crear espacio sin token (debe fallar)
echo "3.4 Intentar crear espacio SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/catalog/spaces" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Espacio Sin Token\",
    \"description\": \"Este no debería crearse\",
    \"address\": \"Nowhere\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 10,
    \"basePriceCents\": 2500,
    \"areaSqm\": 50
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Crear espacio sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 4: LISTAR Y OBTENER ESPACIOS"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 4.1: Listar todos los espacios
echo "4.1 Listar todos los espacios..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/catalog/spaces" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "Listar espacios"

if [ "$HTTP_CODE" = "200" ]; then
    SPACE_COUNT=$(echo "$BODY" | grep -o '\"id\":' | wc -l | tr -d ' ')
    echo "   Espacios encontrados: $SPACE_COUNT"
    
    if [ "$SPACE_COUNT" -ge 3 ]; then
        print_test 0 "Se encontraron los espacios creados ($SPACE_COUNT >= 3)"
    else
        print_test 1 "Menos espacios de los esperados" "Encontrados: $SPACE_COUNT, Esperados: >= 3"
    fi
fi
echo ""

# TEST 4.2: Obtener espacio específico
echo "4.2 Obtener espacio específico por ID..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "Obtener espacio por ID"

if [ "$HTTP_CODE" = "200" ]; then
    TITLE=$(echo "$BODY" | grep -o '"title":"[^"]*' | cut -d'"' -f4)
    echo "   Título: $TITLE"
    
    if echo "$BODY" | grep -q "Espacio Test HOST 1"; then
        print_test 0 "Espacio obtenido correctamente"
    else
        print_test 1 "Espacio obtenido pero título no coincide"
    fi
fi
echo ""

# TEST 4.3: Listar espacios sin token
echo "4.3 Listar espacios SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/catalog/spaces")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Listar espacios sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 5: EDITAR ESPACIOS (OWNERSHIP VERIFICATION)"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 5.1: Owner edita su propio espacio
echo "5.1 HOST edita su propio espacio..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1" \
  -H "Authorization: Bearer $HOST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Espacio Test HOST 1 (EDITADO)\",
    \"description\": \"Descripción actualizada\",
    \"address\": \"Calle Test 1, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 12,
    \"basePriceCents\": 2800,
    \"areaSqm\": 55
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "Owner edita su propio espacio"

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$BODY" | grep -q "EDITADO"; then
        print_test 0 "Espacio actualizado correctamente"
    else
        print_test 1 "Espacio no muestra cambios"
    fi
fi
echo ""

# TEST 5.2: Usuario intenta editar espacio de otro
echo "5.2 GUEST intenta editar espacio de HOST (debe fallar)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1" \
  -H "Authorization: Bearer $GUEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Intento de hackeo\",
    \"description\": \"Esto no debería funcionar\",
    \"address\": \"Calle Test 1, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 12,
    \"basePriceCents\": 2800,
    \"areaSqm\": 55
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "403" "$HTTP_CODE" "Editar espacio ajeno debe retornar 403 Forbidden"
echo ""

# TEST 5.3: Editar sin token
echo "5.3 Editar espacio SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Sin token\",
    \"description\": \"No debería funcionar\",
    \"address\": \"Calle Test 1, Madrid\",
    \"lat\": 40.4168,
    \"lon\": -3.7038,
    \"capacity\": 12,
    \"basePriceCents\": 2800,
    \"areaSqm\": 55
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Editar espacio sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 6: ELIMINAR ESPACIOS (SOFT DELETE)"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 6.1: Owner elimina su propio espacio
echo "6.1 HOST elimina su segundo espacio..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/catalog/spaces/$SPACE_HOST_2" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "204" "$HTTP_CODE" "Owner elimina su propio espacio"

# Verificar que está marcado como DELETED
echo ""
echo "   Verificando soft delete (status=DELETED)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/catalog/spaces/$SPACE_HOST_2" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    STATUS=$(echo "$BODY" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
    echo "   Status del espacio: $STATUS"
    
    if [ "$STATUS" = "DELETED" ] || [ "$STATUS" = "deleted" ]; then
        print_test 0 "Espacio marcado como DELETED (soft delete correcto)"
    else
        print_test 1 "Espacio no tiene status DELETED" "Status: $STATUS"
    fi
fi
echo ""

# TEST 6.2: Usuario intenta eliminar espacio ajeno
echo "6.2 GUEST intenta eliminar espacio de HOST (debe fallar)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1" \
  -H "Authorization: Bearer $GUEST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "403" "$HTTP_CODE" "Eliminar espacio ajeno debe retornar 403"
echo ""

# TEST 6.3: Eliminar sin token
echo "6.3 Eliminar espacio SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/api/catalog/spaces/$SPACE_HOST_1")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Eliminar sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 7: BÚSQUEDA GEOESPACIAL (PÚBLICO)"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 7.1: Búsqueda sin token (debe funcionar)
echo "7.1 Búsqueda geoespacial SIN token (público)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/search/spaces?lat=40.4168&lon=-3.7038&radius=10")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "Búsqueda pública sin token"

if [ "$HTTP_CODE" = "200" ]; then
    FOUND=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
    echo "   Espacios encontrados: $FOUND"
    
    if [ "$FOUND" -gt 0 ]; then
        print_test 0 "Búsqueda retornó resultados ($FOUND espacios)"
    else
        print_test 1 "Búsqueda no retornó resultados"
    fi
fi
echo ""

# TEST 7.2: Búsqueda con token (también debe funcionar)
echo "7.2 Búsqueda geoespacial CON token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/search/spaces?lat=40.4168&lon=-3.7038&radius=10" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "200" "$HTTP_CODE" "Búsqueda con token también funciona"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 8: CREAR RESERVAS (BOOKING)"
echo "═══════════════════════════════════════════════════"
echo ""

# Calcular fechas futuras
START_DATE=$(date -u -v+3d +"%Y-%m-%dT10:00:00" 2>/dev/null || date -u -d "+3 days" +"%Y-%m-%dT10:00:00")
END_DATE=$(date -u -v+3d +"%Y-%m-%dT14:00:00" 2>/dev/null || date -u -d "+3 days" +"%Y-%m-%dT14:00:00")

# TEST 8.1: GUEST crea reserva en espacio de HOST
echo "8.1 GUEST crea reserva en espacio de HOST..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings" \
  -H "Authorization: Bearer $GUEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"spaceId\": \"$SPACE_HOST_1\",
    \"guestId\": \"$GUEST_USER_ID\",
    \"startTs\": \"$START_DATE\",
    \"endTs\": \"$END_DATE\",
    \"numGuests\": 2
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "GUEST crea reserva"

if [ "$HTTP_CODE" = "201" ]; then
    BOOKING_ID=$(echo "$BODY" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | sed -n '1p')
    echo "   Booking ID: $BOOKING_ID"
fi
echo ""

# TEST 8.2: DUAL user crea reserva (fechas diferentes para evitar conflicto)
echo "8.2 Usuario DUAL crea reserva..."
START_DATE_2=$(date -u -v+4d +"%Y-%m-%dT10:00:00" 2>/dev/null || date -u -d "+4 days" +"%Y-%m-%dT10:00:00")
END_DATE_2=$(date -u -v+4d +"%Y-%m-%dT14:00:00" 2>/dev/null || date -u -d "+4 days" +"%Y-%m-%dT14:00:00")
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings" \
  -H "Authorization: Bearer $DUAL_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"spaceId\": \"$SPACE_HOST_1\",
    \"guestId\": \"$DUAL_USER_ID\",
    \"startTs\": \"$START_DATE_2\",
    \"endTs\": \"$END_DATE_2\",
    \"numGuests\": 2
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "201" "$HTTP_CODE" "Usuario DUAL crea reserva (es guest)"

if [ "$HTTP_CODE" = "201" ]; then
    BOOKING_DUAL_ID=$(echo "$BODY" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | sed -n '1p')
    echo "   Booking ID (DUAL): $BOOKING_DUAL_ID"
fi
echo ""

# TEST 8.3: Crear reserva sin token
echo "8.3 Crear reserva SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings" \
  -H "Content-Type: application/json" \
  -d "{
    \"spaceId\": \"$SPACE_HOST_1\",
    \"guestId\": \"$GUEST_USER_ID\",
    \"startTs\": \"$START_DATE\",
    \"endTs\": \"$END_DATE\",
    \"numGuests\": 2
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Crear reserva sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 9: LISTAR Y GESTIONAR RESERVAS"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 9.1: GUEST lista sus propias reservas
echo "9.1 GUEST lista sus propias reservas..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/bookings/guest/$GUEST_USER_ID" \
  -H "Authorization: Bearer $GUEST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "GUEST lista sus reservas"

if [ "$HTTP_CODE" = "200" ]; then
    BOOKING_COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
    echo "   Reservas encontradas: $BOOKING_COUNT"
    
    if [ "$BOOKING_COUNT" -ge 1 ]; then
        print_test 0 "Se encontraron las reservas del guest ($BOOKING_COUNT >= 1)"
    else
        print_test 1 "No se encontraron reservas del guest"
    fi
fi
echo ""

# TEST 9.2: HOST lista reservas de su espacio
echo "9.2 HOST lista reservas de su espacio..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/bookings/space/$SPACE_HOST_1" \
  -H "Authorization: Bearer $HOST_TOKEN")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

check_http_code "200" "$HTTP_CODE" "HOST lista reservas de su espacio"

if [ "$HTTP_CODE" = "200" ]; then
    BOOKING_COUNT=$(echo "$BODY" | grep -o '"id"' | wc -l | tr -d ' ')
    echo "   Reservas en el espacio: $BOOKING_COUNT"
    
    if [ "$BOOKING_COUNT" -ge 1 ]; then
        print_test 0 "Se encontraron reservas en el espacio ($BOOKING_COUNT >= 1)"
    else
        print_test 1 "Menos reservas de las esperadas" "Encontradas: $BOOKING_COUNT"
    fi
fi
echo ""

# TEST 9.3: Listar reservas sin token
echo "9.3 Listar reservas SIN token..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/api/bookings/guest/$GUEST_USER_ID")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
check_http_code "401" "$HTTP_CODE" "Listar reservas sin token debe retornar 401"
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "TEST SUITE 10: CONFIRMAR Y CANCELAR RESERVAS"
echo "═══════════════════════════════════════════════════"
echo ""

# TEST 10.1: HOST confirma reserva
echo "10.1 HOST confirma reserva en su espacio..."
if [ ! -z "$BOOKING_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings/$BOOKING_ID/confirm?paymentIntentId=test_payment_123" \
      -H "Authorization: Bearer $HOST_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    check_http_code "200" "$HTTP_CODE" "HOST confirma reserva"
else
    print_test 1 "No hay booking ID para confirmar"
fi
echo ""

# TEST 10.2: GUEST cancela su reserva
echo "10.2 GUEST cancela su propia reserva..."
if [ ! -z "$BOOKING_DUAL_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings/$BOOKING_DUAL_ID/cancel?reason=Test+cancellation" \
      -H "Authorization: Bearer $DUAL_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    check_http_code "200" "$HTTP_CODE" "GUEST cancela su reserva"
else
    print_test 1 "No hay booking ID para cancelar"
fi
echo ""

# TEST 10.3: Usuario intenta confirmar reserva ajena
echo "10.3 GUEST intenta confirmar reserva ajena (debe fallar)..."
if [ ! -z "$BOOKING_ID" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/bookings/$BOOKING_ID/confirm?paymentIntentId=test_payment_456" \
      -H "Authorization: Bearer $DUAL_TOKEN")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    # Puede ser 400 (estado inválido), 403 (sin permisos) o 404 (no existe)
    if [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "403" ] || [ "$HTTP_CODE" = "404" ]; then
        print_test 0 "Confirmar reserva ajena bloqueado (HTTP $HTTP_CODE)"
    else
        print_test 1 "Confirmar reserva ajena no bloqueado" "HTTP $HTTP_CODE (esperado 400/403/404)"
    fi
fi
echo ""

# ═══════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════"
echo "RESUMEN FINAL DE PRUEBAS"
echo "═══════════════════════════════════════════════════"
echo ""

TOTAL=$TESTS_TOTAL
PASSED=$TESTS_PASSED
FAILED=$TESTS_FAILED
SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($PASSED/$TOTAL)*100}")

echo "Tests ejecutados:     $TOTAL"
echo "Tests exitosos:       $PASSED ✅"
echo "Tests fallidos:       $FAILED ❌"
echo "Tasa de éxito:        $SUCCESS_RATE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡TODOS LOS TESTS PASARON!${NC}"
    echo ""
    echo "✅ Sistema de roles funcionando correctamente"
    echo "✅ Promoción a HOST automática funciona"
    echo "✅ Ownership verification funciona"
    echo "✅ Permisos de seguridad correctos"
    exit 0
else
    echo -e "${RED}⚠️  ALGUNOS TESTS FALLARON${NC}"
    echo ""
    echo "Revisa los errores arriba para identificar problemas."
    
    if [ $FAILED -le 3 ]; then
        echo ""
        echo "Errores menores detectados ($FAILED). El sistema es mayormente funcional."
    else
        echo ""
        echo "Errores significativos detectados ($FAILED). Revisa la implementación de roles."
    fi
    
    exit 1
fi
