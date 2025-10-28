#!/bin/bash

echo "🔄 REINICIANDO BOOKING SERVICE"
echo "=============================="
echo ""

# Matar proceso en puerto 8082
echo "1️⃣ Deteniendo servicio actual..."
PID=$(lsof -ti:8082)
if [ ! -z "$PID" ]; then
    kill -9 $PID 2>/dev/null
    echo "   ✅ Proceso $PID terminado"
    sleep 2
else
    echo "   ℹ️  No hay proceso corriendo en puerto 8082"
fi

# Reiniciar
echo ""
echo "2️⃣ Iniciando Booking Service..."
echo ""
cd /Users/angel/Desktop/BalconazoApp/booking_microservice

# Opción 1: Foreground (verás los logs)
mvn spring-boot:run

# Opción 2: Background (descomenta la siguiente línea y comenta la anterior)
# nohup mvn spring-boot:run > /tmp/booking-service.log 2>&1 &
# echo "✅ Servicio iniciado en background"
# echo "📝 Ver logs: tail -f /tmp/booking-service.log"

