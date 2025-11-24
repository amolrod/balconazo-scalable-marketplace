#!/bin/bash

# Script para probar el sistema de reseñas
# Verifica que el campo hasReview esté funcionando correctamente

echo "🧪 PRUEBA DEL SISTEMA DE RESEÑAS"
echo "================================"
echo ""

# Variables
GUEST_ID="a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890"
GATEWAY_URL="http://localhost:8080"

echo "1️⃣ Obteniendo token de autenticación..."
TOKEN=$(curl -s -X POST "${GATEWAY_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "password123"
  }' | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Error: No se pudo obtener el token"
  exit 1
fi

echo "✅ Token obtenido: ${TOKEN:0:20}..."
echo ""

echo "2️⃣ Consultando reservas del usuario..."
BOOKINGS=$(curl -s -X GET "${GATEWAY_URL}/api/bookings/guest/${GUEST_ID}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json")

echo "📋 Reservas encontradas:"
echo "$BOOKINGS" | python3 -m json.tool 2>/dev/null || echo "$BOOKINGS"
echo ""

echo "3️⃣ Verificando campo hasReview en cada reserva..."
COMPLETED_COUNT=$(echo "$BOOKINGS" | grep -o '"status":"COMPLETED"' | wc -l | tr -d ' ')
HAS_REVIEW_TRUE=$(echo "$BOOKINGS" | grep -o '"hasReview":true' | wc -l | tr -d ' ')
HAS_REVIEW_FALSE=$(echo "$BOOKINGS" | grep -o '"hasReview":false' | wc -l | tr -d ' ')

echo "📊 Estadísticas:"
echo "   - Reservas completadas: $COMPLETED_COUNT"
echo "   - Con reseña (hasReview=true): $HAS_REVIEW_TRUE"
echo "   - Sin reseña (hasReview=false): $HAS_REVIEW_FALSE"
echo ""

if [ "$HAS_REVIEW_FALSE" -gt 0 ]; then
  echo "✅ SISTEMA OK: Hay reservas completadas sin reseña disponibles"
  echo "   El botón 'Dejar reseña' debería aparecer en el frontend"
else
  echo "⚠️  ADVERTENCIA: No hay reservas completadas sin reseña"
  echo "   Verifica que existan reservas con status='COMPLETED' y hasReview=false"
fi

echo ""
echo "4️⃣ Instrucciones para probar en el frontend:"
echo "   1. Accede a http://localhost:4200"
echo "   2. Inicia sesión con: test@test.com / password123"
echo "   3. Ve a 'Mis Reservas'"
echo "   4. Verifica que las reservas COMPLETED muestren el botón 'Dejar reseña'"
echo ""
