#!/bin/bash

echo "⏳ Esperando 90 segundos para que los servicios terminen de iniciar..."
echo ""
sleep 90

echo "🎯 VERIFICACIÓN COMPLETA DEL SISTEMA BALCONAZO"
echo "=============================================="
echo ""

# Verificar cada servicio
echo "🔍 Verificando servicios:"
echo ""

check_service() {
    local port=$1
    local name=$2

    if curl -s http://localhost:$port/actuator/health > /dev/null 2>&1; then
        echo "✅ $name Service (puerto $port) - UP"
        return 0
    else
        echo "❌ $name Service (puerto $port) - DOWN"
        return 1
    fi
}

check_service 8761 "Eureka "
check_service 8084 "Auth   "
check_service 8085 "Catalog"
check_service 8082 "Booking"
check_service 8083 "Search "

echo ""
echo "🌐 URLs del sistema:"
echo "   Eureka Dashboard: http://localhost:8761"
echo "   Auth Service:     http://localhost:8084/api/auth"
echo "   Catalog Service:  http://localhost:8085/api/catalog"
echo "   Booking Service:  http://localhost:8082/api/bookings"
echo "   Search Service:   http://localhost:8083/api/search"
echo ""

# Verificar Eureka
echo "📊 Servicios registrados en Eureka:"
curl -s http://localhost:8761/eureka/apps | grep -o '<app>[^<]*</app>' | sed 's/<app>//g' | sed 's/<\/app>//g' | while read app; do
    if [ ! -z "$app" ]; then
        echo "   - $app"
    fi
done

echo ""
echo "🧪 Para probar el sistema:"
echo "   1. Registrar usuario:"
echo "      curl -X POST http://localhost:8084/api/auth/register \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '{\"email\":\"test@balconazo.com\",\"password\":\"password123\",\"role\":\"HOST\"}'"
echo ""
echo "   2. Login:"
echo "      curl -X POST http://localhost:8084/api/auth/login \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '{\"email\":\"test@balconazo.com\",\"password\":\"password123\"}'"
echo ""
echo "✅ Verificación completada"

