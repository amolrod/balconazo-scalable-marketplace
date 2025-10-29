#!/bin/bash

echo "🚀 INICIANDO SISTEMA COMPLETO BALCONAZO (Mejorado)"
echo "==================================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para esperar que un servicio esté listo
wait_for_service() {
    local service_name=$1
    local url=$2
    local log_file=$3
    local max_attempts=60
    local attempt=1

    echo -n "⏳ Esperando a que $service_name esté listo"

    while [ $attempt -le $max_attempts ]; do
        if curl -s $url > /dev/null 2>&1; then
            echo ""
            echo -e "${GREEN}✅ $service_name está listo${NC}"
            return 0
        fi

        # Verificar errores críticos en el log
        if [ -f "$log_file" ]; then
            if grep -q "APPLICATION FAILED TO START\|Error starting ApplicationContext\|Port .* was already in use" "$log_file" 2>/dev/null; then
                echo ""
                echo -e "${RED}❌ $service_name falló al iniciar. Últimas líneas del log:${NC}"
                tail -10 "$log_file"
                return 1
            fi
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo ""
    echo -e "${RED}❌ Timeout esperando a $service_name${NC}"
    echo -e "${YELLOW}📋 Revisando últimas líneas del log:${NC}"
    tail -20 "$log_file"
    return 1
}

# Verificar infraestructura Docker
echo "🔍 Verificando infraestructura Docker..."
REQUIRED_CONTAINERS=("balconazo-pg-catalog" "balconazo-pg-booking" "balconazo-pg-search" "balconazo-kafka" "balconazo-redis")
MISSING=0

for container in "${REQUIRED_CONTAINERS[@]}"; do
    if ! docker ps | grep -q $container; then
        echo -e "${YELLOW}⚠️  $container no está corriendo${NC}"
        MISSING=1
    else
        echo -e "${GREEN}✅ $container OK${NC}"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ Falta infraestructura. Iniciando contenedores Docker...${NC}"
    cd /Users/angel/Desktop/BalconazoApp
    docker-compose up -d zookeeper kafka redis pg-catalog pg-booking pg-search 2>/dev/null
    echo "⏳ Esperando 15 segundos a que la infraestructura esté lista..."
    sleep 15
fi

echo ""

# 1. Eureka Server
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}1️⃣ Iniciando Eureka Server (puerto 8761)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/eureka-server
lsof -ti:8761 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/eureka-server.log 2>&1 &
echo $! > /tmp/eureka-pid.txt
echo "   PID: $(cat /tmp/eureka-pid.txt)"

wait_for_service "Eureka Server" "http://localhost:8761/actuator/health" "/tmp/eureka-server.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}Abortando inicio del sistema${NC}"
    exit 1
fi

echo ""

# 2. MySQL Auth
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}2️⃣ Iniciando MySQL Auth (puerto 3307)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
if ! docker ps | grep -q balconazo-mysql-auth; then
    chmod +x /Users/angel/Desktop/BalconazoApp/start-mysql-auth.sh
    /Users/angel/Desktop/BalconazoApp/start-mysql-auth.sh
    sleep 5
else
    echo -e "${GREEN}✅ MySQL Auth ya está corriendo${NC}"
fi

echo ""

# 3. Auth Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}3️⃣ Iniciando Auth Service (puerto 8084)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/auth-service
lsof -ti:8084 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/auth-service.log 2>&1 &
echo $! > /tmp/auth-pid.txt
echo "   PID: $(cat /tmp/auth-pid.txt)"

wait_for_service "Auth Service" "http://localhost:8084/actuator/health" "/tmp/auth-service.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}Abortando inicio del sistema${NC}"
    exit 1
fi

echo ""

# 4. Catalog Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}4️⃣ Iniciando Catalog Service (puerto 8085)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
lsof -ti:8085 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/catalog-service.log 2>&1 &
echo $! > /tmp/catalog-pid.txt
echo "   PID: $(cat /tmp/catalog-pid.txt)"

wait_for_service "Catalog Service" "http://localhost:8085/actuator/health" "/tmp/catalog-service.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}Abortando inicio del sistema${NC}"
    exit 1
fi

echo ""

# 5. Booking Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}5️⃣ Iniciando Booking Service (puerto 8082)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
lsof -ti:8082 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/booking-service.log 2>&1 &
echo $! > /tmp/booking-pid.txt
echo "   PID: $(cat /tmp/booking-pid.txt)"

wait_for_service "Booking Service" "http://localhost:8082/actuator/health" "/tmp/booking-service.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}Abortando inicio del sistema${NC}"
    exit 1
fi

echo ""

# 6. Search Service
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}6️⃣ Iniciando Search Service (puerto 8083)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/search_microservice
lsof -ti:8083 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/search-service.log 2>&1 &
echo $! > /tmp/search-pid.txt
echo "   PID: $(cat /tmp/search-pid.txt)"

wait_for_service "Search Service" "http://localhost:8083/actuator/health" "/tmp/search-service.log"
if [ $? -ne 0 ]; then
    echo -e "${RED}Abortando inicio del sistema${NC}"
    exit 1
fi

echo ""

# 7. API Gateway
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}7️⃣ Iniciando API Gateway (puerto 8080)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
cd /Users/angel/Desktop/BalconazoApp/api-gateway
lsof -ti:8080 | xargs kill -9 2>/dev/null
mvn spring-boot:run > /tmp/api-gateway.log 2>&1 &
echo $! > /tmp/gateway-pid.txt
echo "   PID: $(cat /tmp/gateway-pid.txt)"

wait_for_service "API Gateway" "http://localhost:8080/actuator/health" "/tmp/api-gateway.log"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  API Gateway falló, pero continuando...${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SISTEMA COMPLETO INICIADO${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}🌐 URLs:${NC}"
echo "   API Gateway:       http://localhost:8080"
echo "   Eureka Dashboard:  http://localhost:8761"
echo "   Auth Service:      http://localhost:8084/api/auth"
echo "   Catalog Service:   http://localhost:8085/api/catalog"
echo "   Booking Service:   http://localhost:8082/api/bookings"
echo "   Search Service:    http://localhost:8083/api/search"
echo ""

echo -e "${BLUE}🔍 Health Checks Finales:${NC}"
curl -s http://localhost:8080/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ API Gateway UP${NC}" || echo -e "   ${RED}❌ API Gateway DOWN${NC}"
curl -s http://localhost:8761/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ Eureka UP${NC}" || echo -e "   ${RED}❌ Eureka DOWN${NC}"
curl -s http://localhost:8084/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ Auth UP${NC}" || echo -e "   ${RED}❌ Auth DOWN${NC}"
curl -s http://localhost:8085/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ Catalog UP${NC}" || echo -e "   ${RED}❌ Catalog DOWN${NC}"
curl -s http://localhost:8082/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ Booking UP${NC}" || echo -e "   ${RED}❌ Booking DOWN${NC}"
curl -s http://localhost:8083/actuator/health > /dev/null 2>&1 && echo -e "   ${GREEN}✅ Search UP${NC}" || echo -e "   ${RED}❌ Search DOWN${NC}"

echo ""
echo -e "${BLUE}📝 Ver logs:${NC}"
echo "   tail -f /tmp/api-gateway.log"
echo "   tail -f /tmp/eureka-server.log"
echo "   tail -f /tmp/auth-service.log"
echo "   tail -f /tmp/catalog-service.log"
echo "   tail -f /tmp/booking-service.log"
echo "   tail -f /tmp/search-service.log"
echo ""

echo -e "${BLUE}🔍 Verificar errores en logs:${NC}"
echo "   grep -i error /tmp/api-gateway.log | tail -20"
echo "   grep -i error /tmp/auth-service.log | tail -20"
echo ""

echo -e "${BLUE}🛑 Para detener todo:${NC}"
echo "   kill \$(cat /tmp/gateway-pid.txt /tmp/eureka-pid.txt /tmp/auth-pid.txt /tmp/catalog-pid.txt /tmp/booking-pid.txt /tmp/search-pid.txt 2>/dev/null)"
echo ""

# Verificación final de errores en logs
echo -e "${YELLOW}🔎 Verificación de errores en logs...${NC}"
echo ""

ERROR_FOUND=0

for service in api-gateway auth-service catalog-service booking-service search-service; do
    LOG_FILE="/tmp/${service}.log"
    if [ -f "$LOG_FILE" ]; then
        # Filtrar solo errores reales (excluir DEBUG, campos SQL como last_error, etc)
        ERROR_COUNT=$(grep -i "error\|exception" "$LOG_FILE" 2>/dev/null | \
                      grep -v "DEBUG\|last_error\|MacOSDnsServerAddressStreamProvider\|DisableEncodeUrlFilter" | \
                      wc -l | tr -d ' ')

        if [ -n "$ERROR_COUNT" ] && [ "$ERROR_COUNT" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  $service tiene $ERROR_COUNT errores críticos en el log${NC}"
            echo "   Últimos errores:"
            grep -i "error\|exception" "$LOG_FILE" | \
                grep -v "DEBUG\|last_error\|MacOSDnsServerAddressStreamProvider\|DisableEncodeUrlFilter" | \
                tail -2 | sed 's/^/   /'
            echo ""
            ERROR_FOUND=1
        fi
    fi
done

if [ $ERROR_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ No se encontraron errores críticos en los logs${NC}"
else
    echo -e "${YELLOW}💡 Tip: Revisa los logs completos para más detalles${NC}"
fi

echo ""
echo -e "${GREEN}🎉 ¡Sistema listo para usar!${NC}"

