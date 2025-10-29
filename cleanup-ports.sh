#!/usr/bin/env bash
#
# cleanup-ports.sh - Limpia todos los puertos antes de iniciar servicios
#

set -euo pipefail

echo "🧹 Limpiando todos los puertos de microservicios..."
echo ""

PORTS=(8080 8082 8083 8084 8085 8761)
CLEANED=0

for port in "${PORTS[@]}"; do
    if lsof -ti:"$port" >/dev/null 2>&1; then
        echo "🔴 Puerto $port ocupado - Limpiando..."
        lsof -ti:"$port" | xargs kill -9 2>/dev/null || true
        CLEANED=$((CLEANED + 1))
        echo "✅ Puerto $port liberado"
    else
        echo "✅ Puerto $port libre"
    fi
done

echo ""
if [ $CLEANED -gt 0 ]; then
    echo "🎉 $CLEANED puerto(s) limpiados"
else
    echo "✨ Todos los puertos ya estaban libres"
fi

echo ""
echo "📊 Estado de puertos:"
for port in "${PORTS[@]}"; do
    if lsof -ti:"$port" >/dev/null 2>&1; then
        echo "  ❌ Puerto $port: OCUPADO"
    else
        echo "  ✅ Puerto $port: LIBRE"
    fi
done

echo ""
echo "✅ Limpieza completada. Ahora puedes iniciar los servicios."

