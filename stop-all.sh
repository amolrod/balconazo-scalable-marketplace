#!/bin/bash

echo "🛑 Deteniendo Sistema Balconazo..."
echo ""

# Función para detener un servicio por puerto
stop_service() {
    local port=$1
    local name=$2

    if lsof -ti:$port > /dev/null 2>&1; then
        lsof -ti:$port | xargs kill -9 2>/dev/null
        echo "✅ $name detenido (puerto $port)"
    else
        echo "⚪ $name no estaba corriendo (puerto $port)"
    fi
}

# Detener microservicios
stop_service 8761 "Eureka Server"
stop_service 8084 "Auth Service"
stop_service 8085 "Catalog Service"
stop_service 8082 "Booking Service"
stop_service 8083 "Search Service"

echo ""
echo "🗑️  Limpiando archivos de PID..."
rm -f /tmp/eureka-pid.txt
rm -f /tmp/auth-pid.txt
rm -f /tmp/catalog-pid.txt
rm -f /tmp/booking-pid.txt
rm -f /tmp/search-pid.txt

echo ""
echo "✅ Sistema detenido completamente"
echo ""
echo "📝 Los logs siguen disponibles en:"
echo "   /tmp/eureka-server.log"
echo "   /tmp/auth-service.log"
echo "   /tmp/catalog-service.log"
echo "   /tmp/booking-service.log"
echo "   /tmp/search-service.log"
echo ""
echo "🐳 Infraestructura Docker (PostgreSQL, MySQL, Kafka, Redis) sigue corriendo"
echo "   Para detenerla: docker stop \$(docker ps -q --filter 'name=balconazo')"

