#!/bin/bash

###############################################################################
# CHECK-SERVICES.SH - Comprobación exhaustiva de todos los microservicios
###############################################################################
# Verifica:
# - Contenedores Docker (PostgreSQL)
# - Procesos Java (microservicios)
# - Health endpoints (/actuator/health)
# - Registro en Eureka
# - Conectividad entre servicios
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Función para imprimir encabezados
print_header() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Función para checks
check() {
    local name=$1
    local result=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$result" = "true" ]; then
        echo -e "  ${GREEN}✅${NC} $name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "  ${RED}❌${NC} $name"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

###############################################################################
# 1. VERIFICAR CONTENEDORES DOCKER
###############################################################################
print_header "1️⃣  CONTENEDORES DOCKER (PostgreSQL)"

check_docker_container() {
    local container_name=$1
    local port=$2
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        local status=$(docker inspect -f '{{.State.Status}}' ${container_name} 2>/dev/null || echo "unknown")
        if [ "$status" = "running" ]; then
            check "$container_name (puerto $port)" "true"
            return 0
        else
            check "$container_name (puerto $port) - Estado: $status" "false"
            return 1
        fi
    else
        check "$container_name (puerto $port) - NO EXISTE" "false"
        return 1
    fi
}

check_docker_container "pg-auth" "5433"
check_docker_container "pg-catalog" "5432"
check_docker_container "pg-booking" "5434"
check_docker_container "pg-search" "5435"

echo ""

###############################################################################
# 2. VERIFICAR PROCESOS JAVA
###############################################################################
print_header "2️⃣  PROCESOS JAVA (Microservicios)"

check_java_process() {
    local service_name=$1
    local jar_pattern=$2
    
    if jps -l | grep -q "$jar_pattern"; then
        local pid=$(jps -l | grep "$jar_pattern" | awk '{print $1}')
        check "$service_name (PID: $pid)" "true"
        return 0
    else
        check "$service_name - NO EJECUTÁNDOSE" "false"
        return 1
    fi
}

check_java_process "Eureka Server" "eureka-server"
check_java_process "API Gateway" "api-gateway"
check_java_process "Auth Service" "auth-service"
check_java_process "Catalog Service" "catalog_microservice"
check_java_process "Booking Service" "booking_microservice"
check_java_process "Search Service" "search_microservice"

echo ""

###############################################################################
# 3. VERIFICAR HEALTH ENDPOINTS
###############################################################################
print_header "3️⃣  HEALTH ENDPOINTS (/actuator/health)"

check_health() {
    local port=$1
    local name=$2
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        if curl -s -f -m 5 http://localhost:$port/actuator/health > /dev/null 2>&1; then
            local status=$(curl -s http://localhost:$port/actuator/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            if [ "$status" = "UP" ]; then
                check "$name Service (puerto $port) - Status: UP" "true"
                return 0
            else
                check "$name Service (puerto $port) - Status: $status" "false"
                return 1
            fi
        fi
        retry=$((retry + 1))
        sleep 1
    done
    
    check "$name Service (puerto $port) - NO RESPONDE" "false"
    return 1
}

check_health 8761 "Eureka"
check_health 8080 "API Gateway"
check_health 8084 "Auth"
check_health 8085 "Catalog"
check_health 8082 "Booking"
check_health 8083 "Search"

echo ""

###############################################################################
# 4. VERIFICAR REGISTRO EN EUREKA
###############################################################################
print_header "4️⃣  REGISTRO EN EUREKA"

check_eureka_registration() {
    local service_name=$1
    
    if curl -s http://localhost:8761/eureka/apps 2>/dev/null | grep -q "<name>${service_name}</name>"; then
        local instances=$(curl -s http://localhost:8761/eureka/apps/${service_name} 2>/dev/null | grep -c "<status>UP</status>" || echo "0")
        if [ "$instances" -gt 0 ]; then
            check "$service_name registrado ($instances instancia(s) UP)" "true"
            return 0
        else
            check "$service_name registrado pero DOWN" "false"
            return 1
        fi
    else
        check "$service_name - NO REGISTRADO" "false"
        return 1
    fi
}

# Esperar un poco para que los servicios se registren
if curl -s -f http://localhost:8761/eureka/apps > /dev/null 2>&1; then
    check_eureka_registration "API-GATEWAY"
    check_eureka_registration "AUTH-SERVICE"
    check_eureka_registration "CATALOG-SERVICE"
    check_eureka_registration "BOOKING-SERVICE"
    check_eureka_registration "SEARCH-SERVICE"
else
    echo -e "  ${YELLOW}⚠️${NC}  Eureka no disponible, saltando verificación de registro"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 5))
fi

echo ""

###############################################################################
# 5. VERIFICAR CONECTIVIDAD API GATEWAY
###############################################################################
print_header "5️⃣  CONECTIVIDAD API GATEWAY"

check_gateway_route() {
    local route=$1
    local description=$2
    
    # Solo verificar que el endpoint responde (puede ser 401 si requiere auth)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080${route} 2>/dev/null || echo "000")
    
    # Códigos aceptables: 200 (OK), 401 (Unauthorized - normal), 404 (Not Found pero servicio responde)
    if [ "$http_code" = "200" ] || [ "$http_code" = "401" ] || [ "$http_code" = "404" ]; then
        check "$description (HTTP $http_code)" "true"
        return 0
    else
        check "$description (HTTP $http_code) - NO ACCESIBLE" "false"
        return 1
    fi
}

check_gateway_route "/api/auth/health" "Ruta /api/auth"
check_gateway_route "/api/spaces" "Ruta /api/spaces"
check_gateway_route "/api/bookings" "Ruta /api/bookings"
check_gateway_route "/api/search" "Ruta /api/search"

echo ""

###############################################################################
# 6. VERIFICAR PUERTOS EN USO
###############################################################################
print_header "6️⃣  PUERTOS EN USO"

check_port() {
    local port=$1
    local description=$2
    
    if lsof -i:$port > /dev/null 2>&1; then
        check "Puerto $port ($description)" "true"
        return 0
    else
        check "Puerto $port ($description) - NO EN USO" "false"
        return 1
    fi
}

check_port 5433 "PostgreSQL Auth"
check_port 5432 "PostgreSQL Catalog"
check_port 5434 "PostgreSQL Booking"
check_port 5435 "PostgreSQL Search"
check_port 8761 "Eureka Server"
check_port 8080 "API Gateway"
check_port 8084 "Auth Service"
check_port 8085 "Catalog Service"
check_port 8082 "Booking Service"
check_port 8083 "Search Service"

echo ""

###############################################################################
# 7. RESUMEN FINAL
###############################################################################
print_header "📊 RESUMEN DE VERIFICACIÓN"

echo "  Tests ejecutados:  $TOTAL_CHECKS"
echo -e "  ${GREEN}Tests exitosos:    $PASSED_CHECKS${NC}"
echo -e "  ${RED}Tests fallidos:    $FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ TODOS LOS CHECKS PASARON CORRECTAMENTE${NC}"
    echo ""
    echo "🎉 El sistema está completamente operativo"
    echo ""
    echo "📍 URLs importantes:"
    echo "   • Eureka Dashboard:  http://localhost:8761"
    echo "   • API Gateway:       http://localhost:8080"
    echo "   • Auth Service:      http://localhost:8084/api/auth"
    echo "   • Catalog Service:   http://localhost:8085/api/catalog"
    echo "   • Booking Service:   http://localhost:8082/api/bookings"
    echo "   • Search Service:    http://localhost:8083/api/search"
    echo ""
    exit 0
else
    PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")
    echo ""
    echo -e "${YELLOW}⚠️  ALGUNOS CHECKS FALLARON (${PERCENTAGE}% éxito)${NC}"
    echo ""
    echo "🔧 Acciones recomendadas:"
    
    if [ $FAILED_CHECKS -le 5 ]; then
        echo "   1. Revisa los logs de los servicios fallidos:"
        echo "      tail -100 /tmp/auth-service.log"
        echo "      tail -100 /tmp/catalog-service.log"
        echo ""
        echo "   2. Reinicia los servicios problemáticos:"
        echo "      ./scripts/stop-all.sh"
        echo "      ./scripts/start-all-with-eureka.sh"
    else
        echo "   1. Reinicia todo el sistema:"
        echo "      ./scripts/stop-all.sh"
        echo "      docker-compose down"
        echo "      ./scripts/deploy-all.sh"
        echo ""
        echo "   2. Verifica que Docker esté corriendo"
        echo "   3. Verifica que no haya conflictos de puertos"
    fi
    
    echo ""
    exit 1
fi
