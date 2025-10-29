#!/bin/bash

echo "🚀 INICIANDO SISTEMA COMPLETO BALCONAZO"
echo "========================================"
echo ""

# Verificar infraestructura Docker
echo "🔍 Verificando infraestructura Docker..."
REQUIRED_CONTAINERS=("balconazo-pg-catalog" "balconazo-pg-booking" "balconazo-pg-search" "balconazo-kafka" "balconazo-redis")
MISSING=0

for container in "${REQUIRED_CONTAINERS[@]}"; do
    if ! docker ps | grep -q $container; then
        echo "⚠️  $container no está corriendo"
        MISSING=1
    else
        echo "✅ $container OK"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ Falta infraestructura. Inicia los servicios Docker primero."
    exit 1
fi

echo ""
echo "1️⃣ Iniciando Eureka Server (puerto 8761)..."
cd /Users/angel/Desktop/BalconazoApp/eureka-server
lsof -ti:8761 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/eureka-server.log 2>&1 &
echo $! > /tmp/eureka-pid.txt
echo "   PID: $(cat /tmp/eureka-pid.txt)"
echo "   Logs: tail -f /tmp/eureka-server.log"

sleep 25

echo ""
echo "2️⃣ Iniciando MySQL Auth (puerto 3307)..."
chmod +x /Users/angel/Desktop/BalconazoApp/start-mysql-auth.sh
/Users/angel/Desktop/BalconazoApp/start-mysql-auth.sh

echo ""
echo "3️⃣ Iniciando Auth Service (puerto 8084)..."
cd /Users/angel/Desktop/BalconazoApp/auth-service
lsof -ti:8084 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/auth-service.log 2>&1 &
echo $! > /tmp/auth-pid.txt
echo "   PID: $(cat /tmp/auth-pid.txt)"
echo "   Logs: tail -f /tmp/auth-service.log"

sleep 30

echo ""
echo "4️⃣ Iniciando Catalog Service (puerto 8085)..."
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
lsof -ti:8085 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/catalog-service.log 2>&1 &
echo $! > /tmp/catalog-pid.txt
echo "   PID: $(cat /tmp/catalog-pid.txt)"

sleep 20

echo ""
echo "5️⃣ Iniciando Booking Service (puerto 8082)..."
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
lsof -ti:8082 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/booking-service.log 2>&1 &
echo $! > /tmp/booking-pid.txt
echo "   PID: $(cat /tmp/booking-pid.txt)"

sleep 20

echo ""
echo "6️⃣ Iniciando Search Service (puerto 8083)..."
cd /Users/angel/Desktop/BalconazoApp/search_microservice
lsof -ti:8083 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/search-service.log 2>&1 &
echo $! > /tmp/search-pid.txt
echo "   PID: $(cat /tmp/search-pid.txt)"

sleep 20

echo ""
echo "7️⃣ Iniciando API Gateway (puerto 8080)..."
cd /Users/angel/Desktop/BalconazoApp/api-gateway
lsof -ti:8080 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/api-gateway.log 2>&1 &
echo $! > /tmp/gateway-pid.txt
echo "   PID: $(cat /tmp/gateway-pid.txt)"
echo "   Logs: tail -f /tmp/api-gateway.log"

echo ""
echo "⏳ Esperando 30 segundos para que todos los servicios inicien..."
sleep 30

echo ""
echo "✅ SISTEMA COMPLETO INICIADO"
echo "============================="
echo ""
echo "🌐 URLs:"
echo "   API Gateway:       http://localhost:8080"
echo "   Eureka Dashboard:  http://localhost:8761"
echo "   Auth Service:      http://localhost:8084/api/auth"
echo "   Catalog Service:   http://localhost:8085/api/catalog"
echo "   Booking Service:   http://localhost:8082/api/bookings"
echo "   Search Service:    http://localhost:8083/api/search"
echo ""
echo "🔍 Health Checks:"
curl -s http://localhost:8080/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ API Gateway UP" || echo "⚠️  API Gateway DOWN"
curl -s http://localhost:8761/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Eureka UP" || echo "⚠️  Eureka DOWN"
curl -s http://localhost:8084/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Auth UP" || echo "⚠️  Auth DOWN"
curl -s http://localhost:8085/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Catalog UP" || echo "⚠️  Catalog DOWN"
curl -s http://localhost:8082/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Booking UP" || echo "⚠️  Booking DOWN"
curl -s http://localhost:8083/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Search UP" || echo "⚠️  Search DOWN"

echo ""
echo "📝 Ver logs:"
echo "   tail -f /tmp/api-gateway.log"
echo "   tail -f /tmp/eureka-server.log"
echo "   tail -f /tmp/auth-service.log"
echo "   tail -f /tmp/catalog-service.log"
echo "   tail -f /tmp/booking-service.log"
echo "   tail -f /tmp/search-service.log"
echo ""
echo "🔍 Ver errores en los logs:"
echo "   grep -i error /tmp/api-gateway.log | tail -20"
echo "   grep -i error /tmp/auth-service.log | tail -20"
echo "   grep -i error /tmp/catalog-service.log | tail -20"
echo ""
echo "🛑 Para detener todo:"
echo "   kill \$(cat /tmp/gateway-pid.txt /tmp/eureka-pid.txt /tmp/auth-pid.txt /tmp/catalog-pid.txt /tmp/booking-pid.txt /tmp/search-pid.txt 2>/dev/null)"
echo ""

# Verificación adicional de logs para detectar errores
echo "🔎 Verificación rápida de errores en logs..."
echo ""

# Función para verificar errores reales (ignorando warnings conocidos)
check_real_errors() {
    local log_file=$1
    local service_name=$2

    if [ -f "$log_file" ]; then
        # Contar solo errores críticos, ignorando:
        # - DEBUG messages
        # - Campos SQL como 'last_error'
        # - Warnings de Netty DNS en macOS
        # - Configuración de Spring Security (no son errores)
        local error_count=$(grep -i "error\|exception" "$log_file" 2>/dev/null | \
                           grep -v "DEBUG\|last_error\|MacOSDnsServerAddressStreamProvider\|DisableEncodeUrlFilter\|Will secure any request" | \
                           wc -l | tr -d ' ')

        if [ -n "$error_count" ] && [ "$error_count" -gt 0 ]; then
            echo "⚠️  $service_name tiene $error_count errores críticos:"
            grep -i "error\|exception" "$log_file" | \
                grep -v "DEBUG\|last_error\|MacOSDnsServerAddressStreamProvider\|DisableEncodeUrlFilter\|Will secure any request" | \
                tail -3 | sed 's/^/   /'
            echo ""
        fi
    fi
}

check_real_errors "/tmp/api-gateway.log" "API Gateway"
check_real_errors "/tmp/auth-service.log" "Auth Service"
check_real_errors "/tmp/catalog-service.log" "Catalog Service"
check_real_errors "/tmp/booking-service.log" "Booking Service"
check_real_errors "/tmp/search-service.log" "Search Service"

echo "✅ Verificación de logs completada"
echo ""
echo "💡 Tip: Si algún servicio está DOWN, revisa sus logs con:"
echo "   tail -f /tmp/[nombre-servicio].log"


