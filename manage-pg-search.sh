#!/usr/bin/env bash
#
# Gestionar contenedor balconazo-pg-search
# Este contenedor se crea manualmente para mantener el nombre exacto sin prefijos
#

set -euo pipefail

CONTAINER_NAME="balconazo-pg-search"
IMAGE="kartoza/postgis:16-3.4"
VOLUME_NAME="balconazo-pg-search-data"
NETWORK="balconazo-network"
PORT="5435:5432"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

function print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function print_error() {
    echo -e "${RED}❌ $1${NC}"
}

function check_status() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Contenedor ${CONTAINER_NAME} está corriendo"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "${CONTAINER_NAME}"
        return 0
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_warning "Contenedor ${CONTAINER_NAME} existe pero está parado"
        return 1
    else
        print_warning "Contenedor ${CONTAINER_NAME} no existe"
        return 2
    fi
}

function start_container() {
    print_info "Iniciando ${CONTAINER_NAME}..."

    # Verificar si ya existe
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "El contenedor ya está corriendo"
        return 0
    fi

    # Si existe pero está parado, iniciarlo
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker start ${CONTAINER_NAME}
        print_info "Contenedor iniciado"
        return 0
    fi

    # Crear contenedor nuevo
    print_info "Creando contenedor ${CONTAINER_NAME}..."

    # Asegurar que existe la red
    docker network inspect ${NETWORK} &>/dev/null || docker network create ${NETWORK}

    # Asegurar que existe el volumen
    docker volume inspect ${VOLUME_NAME} &>/dev/null || docker volume create ${VOLUME_NAME}

    # Crear contenedor
    docker run -d \
        --name ${CONTAINER_NAME} \
        --network ${NETWORK} \
        -p ${PORT} \
        -e POSTGRES_DB=search_db \
        -e POSTGRES_USER=postgres \
        -e POSTGRES_PASSWORD=postgres \
        -e ALLOW_IP_RANGE=0.0.0.0/0 \
        -v ${VOLUME_NAME}:/var/lib/postgresql/data \
        -v "$(pwd)/ddl/search.sql:/docker-entrypoint-initdb.d/01-schema.sql" \
        ${IMAGE}

    print_info "Esperando a que PostgreSQL esté listo..."
    sleep 10

    docker exec ${CONTAINER_NAME} pg_isready -U postgres && print_info "✅ PostgreSQL listo"
}

function stop_container() {
    print_info "Parando ${CONTAINER_NAME}..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    print_info "Contenedor parado"
}

function restart_container() {
    print_info "Reiniciando ${CONTAINER_NAME}..."
    docker restart ${CONTAINER_NAME}
    print_info "Contenedor reiniciado"
}

function remove_container() {
    print_warning "Eliminando ${CONTAINER_NAME}..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
    print_info "Contenedor eliminado"
}

function logs_container() {
    docker logs -f ${CONTAINER_NAME}
}

function exec_psql() {
    docker exec -it ${CONTAINER_NAME} psql -U postgres -d search_db
}

function show_help() {
    cat << EOF
Uso: $0 [COMANDO]

Comandos:
    status      Ver estado del contenedor
    start       Iniciar o crear el contenedor
    stop        Parar el contenedor
    restart     Reiniciar el contenedor
    remove      Eliminar el contenedor (no el volumen)
    logs        Ver logs en tiempo real
    psql        Conectar a PostgreSQL
    help        Mostrar esta ayuda

Ejemplos:
    $0 start      # Crear e iniciar el contenedor
    $0 status     # Ver si está corriendo
    $0 logs       # Ver logs
    $0 psql       # Conectar a la BD

EOF
}

# Main
case "${1:-}" in
    status)
        check_status
        ;;
    start)
        start_container
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        ;;
    remove)
        remove_container
        ;;
    logs)
        logs_container
        ;;
    psql)
        exec_psql
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Comando desconocido: ${1:-}"
        echo ""
        show_help
        exit 1
        ;;
esac

