#!/usr/bin/env bash
#
# start-frontend.sh - Iniciar servidor de desarrollo Angular
#

set -euo pipefail

echo "🚀 Iniciando servidor de desarrollo Angular..."
echo ""

cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend

# Matar proceso anterior si existe
lsof -ti:4200 | xargs kill -9 2>/dev/null || true

# Iniciar servidor
echo "📦 Iniciando ng serve..."
nohup ng serve > /tmp/angular-dev-server.log 2>&1 &
SERVER_PID=$!

echo "✅ Servidor iniciado con PID: $SERVER_PID"
echo ""
echo "⏳ Esperando a que el servidor esté listo..."

# Esperar hasta que el servidor responda
for i in {1..30}; do
    if curl -s http://localhost:4200 > /dev/null 2>&1; then
        echo ""
        echo "✅ Servidor listo!"
        echo ""
        echo "🌐 Frontend disponible en: http://localhost:4200"
        echo "📋 Logs en: /tmp/angular-dev-server.log"
        echo ""
        echo "💡 Para ver logs en tiempo real:"
        echo "   tail -f /tmp/angular-dev-server.log"
        echo ""
        echo "🛑 Para detener el servidor:"
        echo "   lsof -ti:4200 | xargs kill -9"
        echo ""
        exit 0
    fi
    sleep 2
    echo -n "."
done

echo ""
echo "⚠️  El servidor no respondió en 60 segundos"
echo "📋 Revisa los logs: tail -50 /tmp/angular-dev-server.log"
exit 1

