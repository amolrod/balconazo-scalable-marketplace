#!/usr/bin/env bash
#
# test-jwt-completo.sh - Prueba completa del sistema JWT
#

set -euo pipefail

echo "🧪 TEST COMPLETO JWT - AUTH SERVICE"
echo "===================================="
echo ""

# 1. Reiniciar Auth Service
echo "1️⃣ Reiniciando Auth Service..."
lsof -ti:8084 | xargs kill -9 2>/dev/null || true
sleep 2

cd /Users/angel/Desktop/BalconazoApp/auth-service
nohup java -jar target/auth_service-0.0.1-SNAPSHOT.jar > /tmp/auth-jwt-test.log 2>&1 &
AUTH_PID=$!
echo "✅ Auth Service iniciado (PID: $AUTH_PID)"
echo "⏳ Esperando 30 segundos a que inicie..."
sleep 30

# 2. Verificar que está UP
echo ""
echo "2️⃣ Verificando health check..."
if curl -s http://localhost:8084/actuator/health | grep -q "UP"; then
    echo "✅ Auth Service UP"
else
    echo "❌ Auth Service DOWN"
    echo "Ver logs: tail -f /tmp/auth-jwt-test.log"
    exit 1
fi

# 3. Login y obtener token
echo ""
echo "3️⃣ Login y obtener token..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"host1@balconazo.com","password":"password123"}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ No se obtuvo token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Token obtenido: ${TOKEN:0:50}..."

# 4. Test /api/auth/me SIN token (debe dar 401)
echo ""
echo "4️⃣ Test /api/auth/me SIN token (esperado: 401)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/auth/me)

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ PASS - 401 Unauthorized (correcto)"
else
    echo "❌ FAIL - HTTP $HTTP_CODE (esperado: 401)"
fi

# 5. Test /api/auth/me CON token (debe dar 200)
echo ""
echo "5️⃣ Test /api/auth/me CON token (esperado: 200)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/auth/me)
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS - 200 OK (correcto)"
    EMAIL=$(echo "$BODY" | grep -o '"email":"[^"]*"' | cut -d'"' -f4)
    ROLE=$(echo "$BODY" | grep -o '"role":"[^"]*"' | cut -d'"' -f4)
    [ -n "$EMAIL" ] && echo "   Usuario: $EMAIL"
    [ -n "$ROLE" ] && echo "   Role: $ROLE"
else
    echo "❌ FAIL - HTTP $HTTP_CODE (esperado: 200)"
    echo "   Response: $BODY"
fi

# 6. Test /actuator/health (público, debe dar 200)
echo ""
echo "6️⃣ Test /actuator/health (esperado: 200)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS - 200 OK (correcto)"
else
    echo "❌ FAIL - HTTP $HTTP_CODE (esperado: 200)"
fi

# 7. Test /api/auth/login (público, debe dar 200)
echo ""
echo "7️⃣ Test /api/auth/login (esperado: 200)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"host1@balconazo.com","password":"password123"}')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS - 200 OK (correcto)"
else
    echo "❌ FAIL - HTTP $HTTP_CODE (esperado: 200)"
fi

# 8. Test login con password incorrecta (debe dar 401)
echo ""
echo "8️⃣ Test login con password incorrecta (esperado: 401)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"host1@balconazo.com","password":"wrong"}')

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ PASS - 401 Unauthorized (correcto)"
else
    echo "❌ FAIL - HTTP $HTTP_CODE (esperado: 401)"
fi

echo ""
echo "===================================="
echo "🎉 Tests completados"
echo ""
echo "📋 Para ver logs:"
echo "   tail -f /tmp/auth-jwt-test.log"
echo ""
echo "💡 Para detener Auth Service:"
echo "   lsof -ti:8084 | xargs kill -9"
echo ""

