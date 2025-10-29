#!/usr/bin/env bash
# diagnostico-403-completo.sh - Diagnóstico completo del 403 en Auth Service

set -Eeuo pipefail

HEAD="/usr/bin/head"   # evita el 'head' raro del PATH
GREP="/usr/bin/grep"   # por si hay alias raros

echo "🔍 DIAGNÓSTICO COMPLETO DEL ERROR 403"
echo "======================================"
echo ""

# 0) utilidades
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Falta comando: $1"; exit 1; }; }
need curl
need lsof
need sed
need awk
# jq es opcional; si no está, usamos grep/sed
HAS_JQ=1; command -v jq >/dev/null 2>&1 || HAS_JQ=0

# 1) Verificar si Auth Service está corriendo
echo "1️⃣ Verificando si Auth Service está corriendo..."
if lsof -i:8084 >/dev/null 2>&1; then
  PID=$(lsof -ti:8084 | /usr/bin/head -n 1)
  echo "✅ Auth Service está corriendo en puerto 8084 (PID: $PID)"
else
  echo "❌ Auth Service NO está corriendo en :8084"
  echo "   Inícialo y vuelve a ejecutar este script:"
  echo "   cd /Users/angel/Desktop/BalconazoApp/auth-service && java -jar target/auth_service-0.0.1-SNAPSHOT.jar"
  exit 1
fi
echo ""

# 2) Health
echo "2️⃣ Verificando health check..."
HEALTH="$(curl -s http://localhost:8084/actuator/health || true)"
if echo "$HEALTH" | $GREP -q '"status":"UP"'; then
  echo "✅ Auth Service está UP"
else
  echo "❌ Auth Service NO está UP. Respuesta:"
  echo "$HEALTH"
  exit 1
fi
echo ""

# 3) Mappings
echo "3️⃣ Verificando endpoints registrados (actuator /mappings)..."
MAPPINGS="$(curl -s http://localhost:8084/actuator/mappings || true)"
if [ -z "$MAPPINGS" ]; then
  echo "❌ No se pudo obtener /actuator/mappings."
  echo "   Asegúrate de exponer 'mappings' en actuator."
  exit 1
fi

PATH_CORRECTO=""
if [ "$HAS_JQ" -eq 1 ]; then
  # Intento con jq (estructuras típicas de Spring Boot 3)
  PATH_CORRECTO="$(echo "$MAPPINGS" \
    | jq -r '.. | objects | select(.details.requestMappingConditions.pathPatterns? or .handler) | .details.requestMappingConditions.pathPatterns? // empty' \
    | $GREP -E '^/api/auth/login$|^/auth/login$' \
    | /usr/bin/head -n 1 || true)"
fi

# Fallback sin jq
if [ -z "${PATH_CORRECTO:-}" ]; then
  if echo "$MAPPINGS" | $GREP -q '/api/auth/login'; then
    PATH_CORRECTO="/api/auth/login"
  elif echo "$MAPPINGS" | $GREP -q '/auth/login'; then
    PATH_CORRECTO="/auth/login"
  fi
fi

if [ -z "${PATH_CORRECTO:-}" ]; then
  echo "❌ NO ENCONTRADO: Ningún endpoint /auth/login registrado en mappings."
  echo "   Ejemplos de endpoints detectados (primeros 20):"
  echo "$MAPPINGS" | $GREP -oE '"/[a-zA-Z0-9_/\-\.\{\}]*"' | sort -u | /usr/bin/head -n 20
  echo ""
  echo "💡 Si esperabas /api/auth/login, puede que tu controller esté en /auth/login o que no se esté escaneando."
  exit 1
fi

echo "✅ Endpoint detectado: POST $PATH_CORRECTO"
echo ""

# 4) Probar endpoint detectado
echo "4️⃣ Probando login en: $PATH_CORRECTO"
RESP="$(curl -s -w '\nHTTP_CODE:%{http_code}' -X POST "http://localhost:8084$PATH_CORRECTO" \
  -H 'Content-Type: application/json' \
  -d '{"email":"host1@balconazo.com","password":"password123"}' || true)"

HTTP_CODE="$(echo "$RESP" | $GREP 'HTTP_CODE:' | sed 's/.*HTTP_CODE://')"
BODY="$(echo "$RESP" | sed '/HTTP_CODE:/d')"

echo "HTTP Status: $HTTP_CODE"
echo ""

case "${HTTP_CODE:-}" in
  200)
    echo "✅ ¡LOGIN OK! Token (inicio):"
    echo "$BODY" | /usr/bin/head -n 20
    exit 0
    ;;
  401)
    echo "⚠️  401 Unauthorized — credenciales o seed de usuarios."
    echo "$BODY"
    exit 1
    ;;
  403)
    echo "❌ 403 Forbidden — Security bloquea."
    echo "   Causas típicas:"
    echo "   - CSRF no desactivado"
    echo "   - Falta permitAll() para $PATH_CORRECTO"
    echo "   - Filtro JWT aplica en login"
    echo "   - Estás llamando al path correcto pero el controller falla antes y cae en /error"
    echo ""
    echo "Sugerencia extra: permitir /error en Security para ver 404 si la ruta no existe:"
    echo '  .requestMatchers("/actuator/**", "/error").permitAll()'
    echo ""
    exit 1
    ;;
  404)
    echo "❌ 404 Not Found — el path no existe."
    if [ "$PATH_CORRECTO" = "/api/auth/login" ]; then
      echo "💡 Prueba sin /api: curl -X POST http://localhost:8084/auth/login ..."
    else
      echo "💡 Prueba con /api: curl -X POST http://localhost:8084/api/auth/login ..."
    fi
    exit 1
    ;;
  *)
    echo "⚠️  HTTP ${HTTP_CODE:-<vacío>} inesperado. Respuesta:"
    echo "$BODY" | /usr/bin/head -n 40
    exit 1
    ;;
esac
