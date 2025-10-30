#!/usr/bin/env bash
#
# stop-all.sh - Detiene todos los servicios de BalconazoApp
#
# Descripción:
#   Detiene todos los microservicios, Eureka y la infraestructura Docker
#
# Uso:
#   ./stop-all.sh [opciones]
#
# Opciones:
#   -h, --help          Muestra esta ayuda
#   -k, --keep-infra    Mantiene la infraestructura Docker corriendo
#   -f, --force         Forzar cierre (kill -9)
#

set -euo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

KEEP_INFRA=false
FORCE=false

log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

show_help() {
    sed -n '/^#/,/^$/s/^# \?//p' "$0"
    exit 0
}

stop_service() {
    local name=$1
    local port=$2
    local signal=${3:-TERM}

    if lsof -ti:"$port" >/dev/null 2>&1; then
        log_info "Deteniendo $name (puerto $port)..."
        if [ "$FORCE" = true ]; then
            lsof -ti:"$port" | xargs kill -9 2>/dev/null || true
        else
            lsof -ti:"$port" | xargs kill -"$signal" 2>/dev/null || true
        fi
        sleep 2
        if ! lsof -ti:"$port" >/dev/null 2>&1; then
            log_success "$name detenido"
        else
            log_warning "$name aún en ejecución"
        fi
    else
        log_info "$name no está en ejecución"
    fi
}

# Parsear argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -k|--keep-infra)
            KEEP_INFRA=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo "Opción desconocida: $1"
            show_help
            ;;
    esac
done

echo ""
echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
echo -e "${RED}║    🛑 DETENIENDO SISTEMA BALCONAZO        ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
echo ""

# Detener servicios
stop_service "Search Service" 8083
stop_service "Booking Service" 8082
stop_service "Catalog Service" 8085
stop_service "Auth Service" 8084
stop_service "API Gateway" 8080
stop_service "Eureka Server" 8761

# Detener infraestructura Docker
if [ "$KEEP_INFRA" = false ]; then
    log_info "Deteniendo infraestructura Docker..."
    docker-compose down 2>/dev/null || log_warning "Docker Compose no encontrado o ya detenido"
    log_success "Infraestructura detenida"
else
    log_info "Manteniendo infraestructura Docker (--keep-infra)"
fi

# Limpiar archivos PID
rm -f /tmp/*-pid.txt 2>/dev/null

echo ""
log_success "Sistema detenido correctamente"
echo ""


echo "lsof -ti:8761 | xargs kill -15 si eureka server no para"
