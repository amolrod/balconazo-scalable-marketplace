#!/bin/bash

echo "🚀 INICIANDO SISTEMA COMPLETO BALCONAZO CON API GATEWAY"
echo "======================================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para esperar que un servicio esté listo
wait_for_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1

    echo -n "⏳ Esperando a que $service_name esté listo"

    while [ $attempt -le $max_attempts ]; do
        if curl -s $url > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}✅ $service_name está listo${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo ""
    echo -e "${RED}❌ Timeout esperando a $service_name${NC}"
    return 1
}

# Paso 1: Iniciar infraestructura
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 1: INFRAESTRUCTURA${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

echo "🐳 Iniciando contenedores Docker..."
cd /Users/angel/Desktop/BalconazoApp

docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Docker Compose no encontrado, usando docker start...${NC}"
    docker start balconazo-zookeeper balconazo-kafka balconazo-redis \
                 balconazo-pg-catalog balconazo-pg-booking balconazo-pg-search 2>/dev/null
}

echo ""
echo "⏳ Esperando a que la infraestructura esté lista..."
sleep 15

# Verificar infraestructura
echo ""
echo "🔍 Verificando infraestructura..."

if redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Redis está corriendo${NC}"
else
    echo -e "${RED}❌ Redis no está corriendo${NC}"
fi

if curl -s http://localhost:9092 > /dev/null 2>&1 || nc -z localhost 9092 2>/dev/null; then
    echo -e "${GREEN}✅ Kafka está corriendo${NC}"
else
    echo -e "${YELLOW}⚠️  Kafka no responde en puerto 9092${NC}"
fi

echo ""

# Paso 2: Iniciar Eureka Server
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 2: EUREKA SERVER${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Verificar si Eureka ya está corriendo
if curl -s http://localhost:8761/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Eureka Server ya está corriendo${NC}"
else
    echo "🚀 Iniciando Eureka Server..."
    cd /Users/angel/Desktop/BalconazoApp/eureka-server

    # Compilar si no existe el JAR
    if [ ! -f "target/eureka-server-1.0.0.jar" ]; then
        echo "🔨 Compilando Eureka Server..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    # Iniciar en background
    nohup java -jar target/eureka-server-1.0.0.jar \
        > ../logs/eureka-server.log 2>&1 &
    echo $! > ../logs/eureka.pid

    wait_for_service "Eureka Server" "http://localhost:8761/actuator/health"
fi

echo ""

# Paso 3: Iniciar Auth Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 3: AUTH SERVICE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if curl -s http://localhost:8084/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Auth Service ya está corriendo${NC}"
else
    echo "🚀 Iniciando Auth Service..."
    cd /Users/angel/Desktop/BalconazoApp/auth-service

    if [ ! -f "target/auth-service-1.0.0.jar" ]; then
        echo "🔨 Compilando Auth Service..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    nohup java -jar target/auth-service-1.0.0.jar \
        > ../logs/auth-service.log 2>&1 &
    echo $! > ../logs/auth.pid

    wait_for_service "Auth Service" "http://localhost:8084/actuator/health"
fi

echo ""

# Paso 4: Iniciar Catalog Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 4: CATALOG SERVICE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if curl -s http://localhost:8085/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Catalog Service ya está corriendo${NC}"
else
    echo "🚀 Iniciando Catalog Service..."
    cd /Users/angel/Desktop/BalconazoApp/catalog_microservice

    if [ ! -f "target/catalog_microservice-0.0.1-SNAPSHOT.jar" ]; then
        echo "🔨 Compilando Catalog Service..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    nohup java -jar target/catalog_microservice-0.0.1-SNAPSHOT.jar \
        > ../logs/catalog-service.log 2>&1 &
    echo $! > ../logs/catalog.pid

    wait_for_service "Catalog Service" "http://localhost:8085/actuator/health"
fi

echo ""

# Paso 5: Iniciar Booking Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 5: BOOKING SERVICE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if curl -s http://localhost:8082/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Booking Service ya está corriendo${NC}"
else
    echo "🚀 Iniciando Booking Service..."
    cd /Users/angel/Desktop/BalconazoApp/booking_microservice

    if [ ! -f "target/booking_microservice-0.0.1-SNAPSHOT.jar" ]; then
        echo "🔨 Compilando Booking Service..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    nohup java -jar target/booking_microservice-0.0.1-SNAPSHOT.jar \
        > ../logs/booking-service.log 2>&1 &
    echo $! > ../logs/booking.pid

    wait_for_service "Booking Service" "http://localhost:8082/actuator/health"
fi

echo ""

# Paso 6: Iniciar Search Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 6: SEARCH SERVICE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if curl -s http://localhost:8083/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Search Service ya está corriendo${NC}"
else
    echo "🚀 Iniciando Search Service..."
    cd /Users/angel/Desktop/BalconazoApp/search_microservice

    if [ ! -f "target/search_microservice-0.0.1-SNAPSHOT.jar" ]; then
        echo "🔨 Compilando Search Service..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    nohup java -jar target/search_microservice-0.0.1-SNAPSHOT.jar \
        > ../logs/search-service.log 2>&1 &
    echo $! > ../logs/search.pid

    wait_for_service "Search Service" "http://localhost:8083/actuator/health"
fi

echo ""

# Paso 7: Iniciar API Gateway
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}PASO 7: API GATEWAY 🌐${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API Gateway ya está corriendo${NC}"
else
    # Verificar que el puerto 8080 esté libre
    if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Puerto 8080 ocupado. Liberando...${NC}"
        kill -9 $(lsof -ti:8080) 2>/dev/null
        sleep 2
    fi

    echo "🚀 Iniciando API Gateway..."
    cd /Users/angel/Desktop/BalconazoApp/api-gateway

    if [ ! -f "target/api-gateway-1.0.0.jar" ]; then
        echo "🔨 Compilando API Gateway..."
        mvn clean package -DskipTests > /dev/null 2>&1
    fi

    nohup java -jar target/api-gateway-1.0.0.jar \
        > ../logs/api-gateway.log 2>&1 &
    echo $! > ../logs/gateway.pid

    wait_for_service "API Gateway" "http://localhost:8080/actuator/health"
fi

echo ""

# Resumen final
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SISTEMA COMPLETO INICIADO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📊 RESUMEN DE SERVICIOS:${NC}"
echo ""
echo "┌────────────────────────────────────────────┐"
echo "│  INFRAESTRUCTURA                           │"
echo "├────────────────────────────────────────────┤"
echo "│  🔹 Zookeeper      : localhost:2181        │"
echo "│  🔹 Kafka          : localhost:9092        │"
echo "│  🔹 Redis          : localhost:6379        │"
echo "│  🔹 PostgreSQL Cat : localhost:5433        │"
echo "│  🔹 PostgreSQL Boo : localhost:5434        │"
echo "│  🔹 PostgreSQL Sea : localhost:5435        │"
echo "│  🔹 MySQL Auth     : localhost:3307        │"
echo "└────────────────────────────────────────────┘"
echo ""
echo "┌────────────────────────────────────────────┐"
echo "│  MICROSERVICIOS                            │"
echo "├────────────────────────────────────────────┤"
echo "│  🌐 API Gateway    : http://localhost:8080 │"
echo "│  🔐 Auth Service   : http://localhost:8084 │"
echo "│  📦 Catalog Service: http://localhost:8085 │"
echo "│  🎫 Booking Service: http://localhost:8082 │"
echo "│  🔍 Search Service : http://localhost:8083 │"
echo "│  🎯 Eureka Server  : http://localhost:8761 │"
echo "└────────────────────────────────────────────┘"
echo ""

echo -e "${BLUE}🧪 PRUEBA RÁPIDA:${NC}"
echo ""
echo "# Health check del API Gateway:"
echo "curl http://localhost:8080/actuator/health"
echo ""
echo "# Ver servicios registrados en Eureka:"
echo "open http://localhost:8761"
echo ""
echo "# Login a través del API Gateway:"
echo 'curl -X POST http://localhost:8080/api/auth/login \\'
echo '  -H "Content-Type: application/json" \\'
echo '  -d '"'"'{"email":"test@example.com","password":"password123"}'"'"
echo ""

echo -e "${YELLOW}📁 Logs disponibles en: logs/${NC}"
echo "  - logs/eureka-server.log"
echo "  - logs/auth-service.log"
echo "  - logs/catalog-service.log"
echo "  - logs/booking-service.log"
echo "  - logs/search-service.log"
echo "  - logs/api-gateway.log"
echo ""

echo -e "${GREEN}✨ Sistema listo para usar!${NC}"

