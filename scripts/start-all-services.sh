#!/usr/bin/env bash
#
# start-all-services.sh - Inicia todos los microservicios
#

set -euo pipefail

echo "🚀 Iniciando todos los microservicios..."
echo ""

# 1. Eureka Server
echo "1️⃣ Iniciando Eureka Server..."
cd /Users/angel/Desktop/BalconazoApp/eureka-server
java -jar target/eureka-server-1.0.0.jar > /tmp/eureka-server.log 2>&1 &
echo $! > /tmp/eureka-server-pid.txt
echo "✅ Eureka Server iniciado (PID: $(cat /tmp/eureka-server-pid.txt))"
sleep 25

# 2. API Gateway
echo ""
echo "2️⃣ Iniciando API Gateway..."
cd /Users/angel/Desktop/BalconazoApp/api-gateway
java -jar target/api-gateway-1.0.0.jar > /tmp/api-gateway.log 2>&1 &
echo $! > /tmp/api-gateway-pid.txt
echo "✅ API Gateway iniciado (PID: $(cat /tmp/api-gateway-pid.txt))"
sleep 25

# 3. Auth Service
echo ""
echo "3️⃣ Iniciando Auth Service..."
cd /Users/angel/Desktop/BalconazoApp/auth-service
java -jar target/auth_service-0.0.1-SNAPSHOT.jar > /tmp/auth-service.log 2>&1 &
echo $! > /tmp/auth-service-pid.txt
echo "✅ Auth Service iniciado (PID: $(cat /tmp/auth-service-pid.txt))"
sleep 20

# 4. Catalog Service
echo ""
echo "4️⃣ Compilando y iniciando Catalog Service..."
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
echo "   🔨 Compilando con Maven (MapStruct)..."
mvn clean package -DskipTests -q > /tmp/catalog-compile.log 2>&1
if [ $? -eq 0 ]; then
  echo "   ✅ Compilación exitosa"
  java -jar target/catalog_microservice-0.0.1-SNAPSHOT.jar > /tmp/catalog-service.log 2>&1 &
  echo $! > /tmp/catalog-service-pid.txt
  echo "   ✅ Catalog Service iniciado (PID: $(cat /tmp/catalog-service-pid.txt))"
else
  echo "   ❌ Error en compilación. Ver /tmp/catalog-compile.log"
  exit 1
fi
sleep 25

# 5. Booking Service
echo ""
echo "5️⃣ Iniciando Booking Service..."
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
java -jar target/booking_microservice-0.0.1-SNAPSHOT.jar > /tmp/booking-service.log 2>&1 &
echo $! > /tmp/booking-service-pid.txt
echo "✅ Booking Service iniciado (PID: $(cat /tmp/booking-service-pid.txt))"
sleep 20

# 6. Search Service
echo ""
echo "6️⃣ Iniciando Search Service..."
cd /Users/angel/Desktop/BalconazoApp/search_microservice
java -jar target/search_microservice-0.0.1-SNAPSHOT.jar > /tmp/search-service.log 2>&1 &
echo $! > /tmp/search-service-pid.txt
echo "✅ Search Service iniciado (PID: $(cat /tmp/search-service-pid.txt))"

echo ""
echo "⏳ Esperando 20 segundos para que se registren en Eureka..."
sleep 20

echo ""
echo "🔍 Verificando estado de los servicios..."
echo ""

curl -s http://localhost:8761/actuator/health | jq -r '.status' > /dev/null && echo "✅ Eureka Server: UP" || echo "❌ Eureka Server: DOWN"
curl -s http://localhost:8080/actuator/health | jq -r '.status' > /dev/null && echo "✅ API Gateway: UP" || echo "❌ API Gateway: DOWN"
curl -s http://localhost:8084/actuator/health | jq -r '.status' > /dev/null && echo "✅ Auth Service: UP" || echo "❌ Auth Service: DOWN"
curl -s http://localhost:8085/actuator/health | jq -r '.status' > /dev/null && echo "✅ Catalog Service: UP" || echo "❌ Catalog Service: DOWN"
curl -s http://localhost:8082/actuator/health | jq -r '.status' > /dev/null && echo "✅ Booking Service: UP" || echo "❌ Booking Service: DOWN"
curl -s http://localhost:8083/actuator/health | jq -r '.status' > /dev/null && echo "✅ Search Service: UP" || echo "❌ Search Service: DOWN"

echo ""
echo "🎉 Todos los servicios iniciados!"
echo ""
echo "📋 Servicios disponibles:"
echo "  • Eureka Dashboard: http://localhost:8761"
echo "  • API Gateway:      http://localhost:8080"
echo "  • Auth Service:     http://localhost:8084"
echo "  • Catalog Service:  http://localhost:8085"
echo "  • Booking Service:  http://localhost:8082"
echo "  • Search Service:   http://localhost:8083"
echo ""
echo "📝 Ver logs:"
echo "  tail -f /tmp/eureka-server.log"
echo "  tail -f /tmp/api-gateway.log"
echo "  tail -f /tmp/auth-service.log"
echo "  tail -f /tmp/catalog-service.log"
echo "  tail -f /tmp/booking-service.log"
echo "  tail -f /tmp/search-service.log"
echo ""

