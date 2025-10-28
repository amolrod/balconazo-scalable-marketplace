#!/bin/bash

# ============================================
# SCRIPT MAESTRO: Iniciar Sistema Completo
# ============================================

echo "🚀 INICIANDO SISTEMA BALCONAZO COMPLETO"
echo "========================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. VERIFICAR DOCKER
echo "📦 Paso 1: Verificando Docker..."
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está corriendo${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker OK${NC}"
echo ""

# 2. INICIAR INFRAESTRUCTURA
echo "🏗️ Paso 2: Iniciando infraestructura..."

# PostgreSQL Catalog
docker ps | grep -q balconazo-pg-catalog || docker start balconazo-pg-catalog 2>/dev/null
echo "  ✅ PostgreSQL Catalog (puerto 5433)"

# PostgreSQL Booking
docker ps | grep -q balconazo-pg-booking || docker start balconazo-pg-booking 2>/dev/null
echo "  ✅ PostgreSQL Booking (puerto 5434)"

# PostgreSQL Search
if ! docker ps | grep -q balconazo-pg-search; then
    docker start balconazo-pg-search 2>/dev/null || \
    docker run -d --name balconazo-pg-search \
      -p 5435:5432 \
      -e POSTGRES_HOST_AUTH_METHOD=trust \
      -e POSTGRES_DB=search_db \
      -e POSTGRES_USER=postgres \
      postgis/postgis:16-3.4-alpine > /dev/null
    sleep 3
    docker exec balconazo-pg-search psql -U postgres -d search_db \
      -c "CREATE SCHEMA IF NOT EXISTS search; CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null
fi
echo "  ✅ PostgreSQL Search (puerto 5435)"

# Zookeeper
docker ps | grep -q balconazo-zookeeper || docker start balconazo-zookeeper 2>/dev/null
echo "  ✅ Zookeeper (puerto 2181)"

# Kafka
docker ps | grep -q balconazo-kafka || docker start balconazo-kafka 2>/dev/null
echo "  ✅ Kafka (puerto 9092)"

# Redis
docker ps | grep -q balconazo-redis || docker start balconazo-redis 2>/dev/null
echo "  ✅ Redis (puerto 6379)"

echo ""
echo "⏳ Esperando 10 segundos para que la infraestructura esté lista..."
sleep 10

# 3. LIMPIAR PUERTOS
echo ""
echo "🧹 Paso 3: Liberando puertos..."
lsof -ti:8085 | xargs kill -9 2>/dev/null
lsof -ti:8082 | xargs kill -9 2>/dev/null
lsof -ti:8083 | xargs kill -9 2>/dev/null
echo -e "${GREEN}✅ Puertos 8085, 8082, 8083 libres${NC}"
echo ""

# 4. COMPILAR SERVICIOS
echo "🔨 Paso 4: Compilando servicios..."
cd /Users/angel/Desktop/BalconazoApp

echo "  - Catalog Service..."
cd catalog_microservice && mvn clean install -DskipTests -q
cd ..

echo "  - Booking Service..."
cd booking_microservice && mvn clean install -DskipTests -q
cd ..

echo "  - Search Service..."
cd search_microservice && mvn clean install -DskipTests -q
cd ..

echo -e "${GREEN}✅ Todos los servicios compilados${NC}"
echo ""

# 5. INICIAR SERVICIOS
echo "🚀 Paso 5: Iniciando microservicios..."
echo ""

# Catalog Service
echo "  📍 Iniciando Catalog Service (puerto 8085)..."
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run > /tmp/catalog-service.log 2>&1 &
CATALOG_PID=$!
echo "     PID: $CATALOG_PID"
sleep 5

# Booking Service
echo "  📍 Iniciando Booking Service (puerto 8082)..."
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
mvn spring-boot:run > /tmp/booking-service.log 2>&1 &
BOOKING_PID=$!
echo "     PID: $BOOKING_PID"
sleep 5

# Search Service
echo "  📍 Iniciando Search Service (puerto 8083)..."
cd /Users/angel/Desktop/BalconazoApp/search_microservice
mvn spring-boot:run > /tmp/search-service.log 2>&1 &
SEARCH_PID=$!
echo "     PID: $SEARCH_PID"
sleep 5

echo ""
echo "⏳ Esperando 30 segundos para que los servicios inicien..."
sleep 30

# 6. VERIFICAR HEALTH CHECKS
echo ""
echo "🏥 Paso 6: Verificando health checks..."
echo ""

# Catalog
CATALOG_STATUS=$(curl -s http://localhost:8085/actuator/health 2>/dev/null | grep -o '"status":"UP"' || echo "DOWN")
if [[ $CATALOG_STATUS == *"UP"* ]]; then
    echo -e "  ${GREEN}✅ Catalog Service: UP${NC}"
else
    echo -e "  ${RED}❌ Catalog Service: DOWN${NC}"
    echo "     Ver logs: tail -f /tmp/catalog-service.log"
fi

# Booking
BOOKING_STATUS=$(curl -s http://localhost:8082/actuator/health 2>/dev/null | grep -o '"status":"UP"' || echo "DOWN")
if [[ $BOOKING_STATUS == *"UP"* ]]; then
    echo -e "  ${GREEN}✅ Booking Service: UP${NC}"
else
    echo -e "  ${RED}❌ Booking Service: DOWN${NC}"
    echo "     Ver logs: tail -f /tmp/booking-service.log"
fi

# Search
SEARCH_STATUS=$(curl -s http://localhost:8083/actuator/health 2>/dev/null | grep -o '"status":"UP"' || echo "DOWN")
if [[ $SEARCH_STATUS == *"UP"* ]]; then
    echo -e "  ${GREEN}✅ Search Service: UP${NC}"
else
    echo -e "  ${YELLOW}⚠️ Search Service: DOWN (normal si no hay datos aún)${NC}"
    echo "     Ver logs: tail -f /tmp/search-service.log"
fi

echo ""
echo "=========================================="
echo "🎉 SISTEMA INICIADO"
echo "=========================================="
echo ""
echo "📊 Endpoints disponibles:"
echo "  - Catalog:  http://localhost:8085/actuator/health"
echo "  - Booking:  http://localhost:8082/actuator/health"
echo "  - Search:   http://localhost:8083/actuator/health"
echo ""
echo "📝 Logs:"
echo "  - Catalog:  tail -f /tmp/catalog-service.log"
echo "  - Booking:  tail -f /tmp/booking-service.log"
echo "  - Search:   tail -f /tmp/search-service.log"
echo ""
echo "🧪 Ejecutar pruebas E2E:"
echo "  ./test-e2e.sh"
echo ""

