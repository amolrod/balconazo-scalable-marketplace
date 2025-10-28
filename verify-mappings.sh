#!/bin/bash

echo "🔍 VERIFICACIÓN DE MAPPINGS - TODOS LOS SERVICIOS"
echo "=================================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para verificar mappings
check_mappings() {
    local service_name=$1
    local port=$2
    local expected_paths=$3

    echo -e "${YELLOW}📋 $service_name (puerto $port)${NC}"
    echo "----------------------------------------"

    # Verificar si el servicio está UP
    if ! curl -s http://localhost:$port/actuator/health > /dev/null 2>&1; then
        echo "❌ Servicio no está disponible"
        echo ""
        return 1
    fi

    # Obtener mappings
    mappings=$(curl -s http://localhost:$port/actuator/mappings 2>/dev/null)

    if [ -z "$mappings" ]; then
        echo "⚠️  No se pudo obtener mappings (puede que /actuator/mappings no esté expuesto)"
        echo ""
        return 1
    fi

    # Buscar paths específicos
    echo "$mappings" | grep -Eo '"[^"]*(/api/[^"]*|/[a-z]+/[^"]*)"' | sort -u | grep -v actuator | head -20

    echo ""
}

echo "1️⃣ EUREKA SERVER"
check_mappings "Eureka Server" 8761 "/eureka"

echo "2️⃣ AUTH SERVICE"
check_mappings "Auth Service" 8084 "/api/auth"

echo "3️⃣ CATALOG SERVICE"
check_mappings "Catalog Service" 8085 "/api/catalog"

echo "4️⃣ BOOKING SERVICE"
check_mappings "Booking Service" 8082 "/api/booking"

echo "5️⃣ SEARCH SERVICE"
check_mappings "Search Service" 8083 "/api/search"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "RESUMEN DE ENDPOINTS PRINCIPALES"
echo "═══════════════════════════════════════════════════════"
echo ""

echo -e "${GREEN}Auth Service (8084):${NC}"
echo "  POST http://localhost:8084/api/auth/register"
echo "  POST http://localhost:8084/api/auth/login"
echo "  POST http://localhost:8084/api/auth/refresh"
echo ""

echo -e "${GREEN}Catalog Service (8085):${NC}"
echo "  GET/POST http://localhost:8085/api/catalog/spaces"
echo "  GET http://localhost:8085/api/catalog/spaces/{id}"
echo "  GET http://localhost:8085/api/catalog/users"
echo "  POST http://localhost:8085/api/catalog/availability"
echo ""

echo -e "${GREEN}Booking Service (8082):${NC}"
echo "  GET/POST http://localhost:8082/api/booking/bookings"
echo "  GET http://localhost:8082/api/booking/bookings/{id}"
echo "  POST http://localhost:8082/api/booking/bookings/{id}/confirm"
echo ""

echo -e "${GREEN}Search Service (8083):${NC}"
echo "  GET http://localhost:8083/api/search/spaces?lat=40.4168&lon=-3.7038&radiusKm=10"
echo "  GET http://localhost:8083/api/search/spaces/{id}"
echo ""

echo "✅ Verificación completada"

