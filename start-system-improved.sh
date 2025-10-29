#!/usr/bin/env bash
#
# start-system-improved.sh - Inicia el sistema completo de BalconazoApp
#
# Descripción:
#   Script maestro que inicia todos los microservicios en el orden correcto:
#   1. Infraestructura (DBs, Kafka, Redis)
#   2. Eureka Server (Service Discovery)
#   3. API Gateway
#   4. Microservicios (Auth, Catalog, Booking, Search)
#
# Uso:
#   ./start-system-improved.sh [opciones]
#
# Opciones:
#   -h, --help     Muestra esta ayuda
#   -v, --verbose  Modo verbose
#   -s, --skip-infra  Salta la inicialización de infraestructura
#
# Ejemplo:
#   ./start-system-improved.sh
#   ./start-system-improved.sh --skip-infra
#

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuración
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/tmp"
readonly WAIT_TIME=20
SKIP_INFRA=false
VERBOSE=false

# Funciones auxiliares
log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

show_help() {
    sed -n '/^#/,/^$/s/^# \?//p' "$0"
    exit 0
}

check_port() {
    local port=$1
    nc -z localhost "$port" 2>/dev/null
}

wait_for_service() {
    local name=$1
    local port=$2
    local max_attempts=30
    local attempt=0

    log_info "Esperando a que $name esté disponible en puerto $port..."

    while ! check_port "$port"; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            log_error "$name no respondió después de $max_attempts intentos"
            return 1
        fi
        sleep 2
        echo -n "."
    done
    echo ""
    log_success "$name está disponible"
}

check_service_health() {
    local name=$1
    local port=$2
    local response

    response=$(curl -s "http://localhost:$port/actuator/health" 2>/dev/null || echo "")
    if echo "$response" | jq -e '.status == "UP"' >/dev/null 2>&1; then
        log_success "$name: UP"
        return 0
    else
        log_warning "$name: DOWN o sin respuesta"
        return 1
    fi
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--skip-infra)
            SKIP_INFRA=true
            shift
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            ;;
    esac
done

# Verificar prerequisitos
if ! command -v java &> /dev/null; then
    log_error "Java no está instalado. Por favor instala Java 21+"
    exit 1
fi

if ! command -v mvn &> /dev/null; then
    log_error "Maven no está instalado"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado"
    exit 1
fi

# Banner
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 INICIANDO SISTEMA BALCONAZO        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo ""

# 1. Infraestructura
if [ "$SKIP_INFRA" = false ]; then
    log_info "PASO 1/5: Iniciando infraestructura (DBs, Kafka, Redis)..."
    if [ -f "$SCRIPT_DIR/start-infrastructure.sh" ]; then
        bash "$SCRIPT_DIR/start-infrastructure.sh"
    else
        log_warning "start-infrastructure.sh no encontrado, saltando..."
    fi
    sleep 10
else
    log_info "PASO 1/5: Saltando infraestructura (--skip-infra)"
fi

# 2. Eureka Server
log_info "PASO 2/5: Iniciando Eureka Server..."
if [ -f "$SCRIPT_DIR/start-eureka.sh" ]; then
    bash "$SCRIPT_DIR/start-eureka.sh"
    wait_for_service "Eureka Server" 8761
else
    log_error "start-eureka.sh no encontrado"
    exit 1
fi

# 3. API Gateway
log_info "PASO 3/5: Iniciando API Gateway..."
if [ -f "$SCRIPT_DIR/start-gateway.sh" ]; then
    bash "$SCRIPT_DIR/start-gateway.sh"
    wait_for_service "API Gateway" 8080
else
    log_warning "start-gateway.sh no encontrado, saltando..."
fi

# 4. Auth Service
log_info "PASO 4/5: Iniciando Auth Service..."
cd "$SCRIPT_DIR/auth-service" || exit 1
nohup java -jar target/auth-service-1.0.0.jar > "$LOG_DIR/auth-service.log" 2>&1 &
echo $! > "$LOG_DIR/auth-pid.txt"
wait_for_service "Auth Service" 8084

# 5. Catalog Service
log_info "Iniciando Catalog Service..."
cd "$SCRIPT_DIR/catalog_microservice" || exit 1
nohup java -jar target/catalog_microservice-0.0.1-SNAPSHOT.jar > "$LOG_DIR/catalog-service.log" 2>&1 &
echo $! > "$LOG_DIR/catalog-pid.txt"
wait_for_service "Catalog Service" 8085

# 6. Booking Service
log_info "Iniciando Booking Service..."
cd "$SCRIPT_DIR/booking_microservice" || exit 1
nohup java -jar target/booking_microservice-0.0.1-SNAPSHOT.jar > "$LOG_DIR/booking-service.log" 2>&1 &
echo $! > "$LOG_DIR/booking-pid.txt"
wait_for_service "Booking Service" 8082

# 7. Search Service
log_info "Iniciando Search Service..."
cd "$SCRIPT_DIR/search_microservice" || exit 1
nohup java -jar target/search_microservice-0.0.1-SNAPSHOT.jar > "$LOG_DIR/search-service.log" 2>&1 &
echo $! > "$LOG_DIR/search-pid.txt"
wait_for_service "Search Service" 8083

# Esperar un poco para que se registren en Eureka
log_info "PASO 5/5: Esperando registro en Eureka..."
sleep 15

# Verificación final
echo ""
log_info "Verificando estado de los servicios..."
echo ""

check_service_health "API Gateway" 8080
check_service_health "Eureka Server" 8761
check_service_health "Auth Service" 8084
check_service_health "Catalog Service" 8085
check_service_health "Booking Service" 8082
check_service_health "Search Service" 8083

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ SISTEMA INICIADO CORRECTAMENTE       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

log_info "URLs útiles:"
echo "  • API Gateway:     http://localhost:8080"
echo "  • Eureka Dashboard: http://localhost:8761"
echo "  • Auth Service:     http://localhost:8084"
echo "  • Catalog Service:  http://localhost:8085"
echo "  • Booking Service:  http://localhost:8082"
echo "  • Search Service:   http://localhost:8083"
echo ""

log_info "Logs disponibles en: $LOG_DIR/*.log"
echo ""

log_info "Para ejecutar tests: ./test-e2e-completo.sh"
log_info "Para detener el sistema: ./stop-all.sh"
echo ""

