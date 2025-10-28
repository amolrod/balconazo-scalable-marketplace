#!/bin/bash

echo "🧪 PRUEBA RÁPIDA DEL SISTEMA BALCONAZO"
echo "======================================"
echo ""

# Función para verificar si un puerto está en uso
check_port() {
    local port=$1
    local service=$2
    if lsof -ti:$port > /dev/null 2>&1; then
        echo "✅ $service corriendo en puerto $port"
        return 0
    else
        echo "❌ $service NO corriendo en puerto $port"
        return 1
    fi
}

echo "1️⃣ Verificando infraestructura Docker..."
echo ""

# PostgreSQL
docker ps | grep balconazo-pg-catalog > /dev/null && echo "✅ PostgreSQL Catalog (5433)" || echo "❌ PostgreSQL Catalog NO corriendo"
docker ps | grep balconazo-pg-booking > /dev/null && echo "✅ PostgreSQL Booking (5434)" || echo "❌ PostgreSQL Booking NO corriendo"
docker ps | grep balconazo-pg-search > /dev/null && echo "✅ PostgreSQL Search (5435)" || echo "❌ PostgreSQL Search NO corriendo"
docker ps | grep balconazo-mysql-auth > /dev/null && echo "✅ MySQL Auth (3307)" || echo "⚠️  MySQL Auth NO corriendo (se creará automáticamente)"
docker ps | grep balconazo-kafka > /dev/null && echo "✅ Kafka (9092)" || echo "❌ Kafka NO corriendo"
docker ps | grep balconazo-redis > /dev/null && echo "✅ Redis (6379)" || echo "❌ Redis NO corriendo"

echo ""
echo "2️⃣ Verificando microservicios..."
echo ""

check_port 8761 "Eureka Server"
check_port 8084 "Auth Service"
check_port 8085 "Catalog Service"
check_port 8082 "Booking Service"
check_port 8083 "Search Service"

echo ""
echo "3️⃣ Health Checks (si están corriendo)..."
echo ""

# Eureka
if lsof -ti:8761 > /dev/null 2>&1; then
    curl -s http://localhost:8761/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Eureka UP" || echo "⚠️ Eureka responde pero no health"
fi

# Auth
if lsof -ti:8084 > /dev/null 2>&1; then
    curl -s http://localhost:8084/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Auth UP" || echo "⚠️ Auth responde pero no health"
fi

# Catalog
if lsof -ti:8085 > /dev/null 2>&1; then
    curl -s http://localhost:8085/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Catalog UP" || echo "⚠️ Catalog responde pero no health"
fi

# Booking
if lsof -ti:8082 > /dev/null 2>&1; then
    curl -s http://localhost:8082/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Booking UP" || echo "⚠️ Booking responde pero no health"
fi

# Search
if lsof -ti:8083 > /dev/null 2>&1; then
    curl -s http://localhost:8083/actuator/health | python3 -m json.tool 2>/dev/null && echo "✅ Search UP" || echo "⚠️ Search responde pero no health"
fi

echo ""
echo "🌐 URLs útiles:"
echo "   Eureka Dashboard: http://localhost:8761"
echo "   Auth API Docs:    http://localhost:8084/actuator/health"
echo "   Catalog API:      http://localhost:8085/actuator/health"
echo "   Booking API:      http://localhost:8082/actuator/health"
echo "   Search API:       http://localhost:8083/actuator/health"
echo ""
echo "📝 Para ver logs:"
echo "   tail -f /tmp/eureka-server.log"
echo "   tail -f /tmp/auth-service.log"
echo "   tail -f /tmp/catalog-service.log"
echo "   tail -f /tmp/booking-service.log"
echo "   tail -f /tmp/search-service.log"

