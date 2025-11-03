#!/usr/bin/env bash
set -euo pipefail

echo "🔄 Reiniciando Catalog Service con imágenes habilitadas..."

# Parar servicio actual
lsof -ti:8085 | xargs kill -9 2>/dev/null || true
sleep 2

# Iniciar servicio actualizado
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
nohup java -jar target/catalog_microservice-0.0.1-SNAPSHOT.jar > /tmp/catalog-service.log 2>&1 &
echo "✅ Catalog Service iniciado - PID: $!"

# Esperar a que arranque
echo "⏳ Esperando 15 segundos..."
sleep 15

# Verificar que está UP
echo "🔍 Verificando health..."
curl -s http://localhost:8085/actuator/health | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"✅ Status: {d.get('status')}\")" || echo "❌ Health check falló"

echo ""
echo "✅ Todo listo!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Frontend: cd balconazo-frontend && ng serve"
echo "2. Login: host1@balconazo.com / password123"
echo "3. Dashboard → Mis Espacios → Editar → Subir imágenes"
echo "4. Ver espacio → Las imágenes se mostrarán"

