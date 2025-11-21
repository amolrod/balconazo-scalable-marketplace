#!/bin/bash

###############################################################################
# VERIFY-SYSTEM.SH - Verificación rápida del sistema
###############################################################################
# Verificación básica de salud de los servicios
# Para verificación exhaustiva usa: ./scripts/check-services.sh
###############################################################################

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🎯 VERIFICACIÓN RÁPIDA DEL SISTEMA BALCONAZO${NC}"
echo "=============================================="
echo ""

# Contador de servicios
TOTAL=6
UP=0
DOWN=0

# Verificar cada servicio
echo "🔍 Verificando servicios:"
echo ""

check_service() {
    local port=$1
    local name=$2

    if curl -s -f -m 3 http://localhost:$port/actuator/health > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅${NC} $name Service (puerto $port) - UP"
        UP=$((UP + 1))
        return 0
    else
        echo -e "  ${RED}❌${NC} $name Service (puerto $port) - DOWN"
        DOWN=$((DOWN + 1))
        return 1
    fi
}

check_service 8761 "Eureka "
check_service 8080 "Gateway"
check_service 8084 "Auth   "
check_service 8085 "Catalog"
check_service 8082 "Booking"
check_service 8083 "Search "

echo ""
echo "📊 Resultado: $UP/$TOTAL servicios UP"

if [ $DOWN -eq 0 ]; then
    echo -e "${GREEN}✅ Todos los servicios están funcionando${NC}"
else
    echo -e "${YELLOW}⚠️  $DOWN servicio(s) no disponible(s)${NC}"
    echo ""
    echo "💡 Para diagnóstico detallado ejecuta:"
    echo "   ./scripts/check-services.sh"
fi

echo ""
echo "🌐 URLs del sistema:"
echo "   • Eureka Dashboard: http://localhost:8761"
echo "   • API Gateway:      http://localhost:8080"
echo "   • Auth Service:     http://localhost:8084/api/auth"
echo "   • Catalog Service:  http://localhost:8085/api/catalog"
echo "   • Booking Service:  http://localhost:8082/api/bookings"
echo "   • Search Service:   http://localhost:8083/api/search"
echo ""

# Verificar Eureka solo si está UP
if curl -s -f http://localhost:8761/eureka/apps > /dev/null 2>&1; then
    echo "📊 Servicios registrados en Eureka:"
    curl -s http://localhost:8761/eureka/apps | grep -o '<app>[^<]*</app>' | sed 's/<app>//g' | sed 's/<\/app>//g' | while read app; do
        if [ ! -z "$app" ]; then
            echo "   • $app"
        fi
    done
    echo ""
fi

echo "🧪 Comandos útiles:"
echo "   • Tests completos:        ./scripts/test-roles-usuarios-completo.sh"
echo "   • Verificación detallada: ./scripts/check-services.sh"
echo "   • Ver logs:               tail -f /tmp/auth-service.log"
echo ""

if [ $DOWN -eq 0 ]; then
    echo -e "${GREEN}✅ Sistema operativo${NC}"
    exit 0
else
    echo -e "${RED}❌ Sistema con problemas${NC}"
    exit 1
fi"

