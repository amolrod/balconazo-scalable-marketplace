#!/bin/bash

echo "🚀 Iniciando Eureka Server..."

# Liberar puerto si está ocupado
lsof -ti:8761 | xargs kill -9 2>/dev/null && echo "✅ Puerto 8761 liberado"

# Ir al directorio
cd /Users/angel/Desktop/BalconazoApp/eureka-server

# Iniciar en background
mvn spring-boot:run > /tmp/eureka-server.log 2>&1 &
EUREKA_PID=$!
echo $EUREKA_PID > /tmp/eureka-pid.txt

echo "✅ Eureka Server iniciando en background (PID: $EUREKA_PID)"
echo "📝 Logs: tail -f /tmp/eureka-server.log"
echo "🌐 Dashboard: http://localhost:8761"
echo ""
echo "⏳ Esperando 25 segundos para que inicie..."
sleep 25

# Verificar si está corriendo
if curl -s http://localhost:8761/actuator/health > /dev/null 2>&1; then
    echo "✅ Eureka Server está UP"
    curl -s http://localhost:8761/actuator/health | python3 -m json.tool
else
    echo "⚠️ Eureka Server aún no responde, revisa los logs:"
    echo "   tail -f /tmp/eureka-server.log"
fi

