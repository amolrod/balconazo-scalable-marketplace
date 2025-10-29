#!/usr/bin/env bash
#
# comprobacionmicroservicios.sh - Verifica el estado de todos los microservicios
#

set -euo pipefail

echo "🔍 COMPROBACIÓN DE ESTADO DE MICROSERVICIOS"
echo "==========================================="
echo ""

# Función para verificar servicio
check_service() {
    local name=$1
    local url=$2
    local port=$3

    if curl -s --connect-timeout 3 "$url" | grep -q "UP"; then
        echo "✅ $name (Puerto $port): UP"
        return 0
    else
        echo "❌ $name (Puerto $port): DOWN"
        return 1
    fi
}

# Contadores
TOTAL=6
UP=0

echo "Verificando servicios..."
echo ""

# Eureka Server
if check_service "Eureka Server    " "http://localhost:8761/actuator/health" "8761"; then
    ((UP++))
fi

# API Gateway
if check_service "API Gateway      " "http://localhost:8080/actuator/health" "8080"; then
    ((UP++))
fi

# Auth Service
if check_service "Auth Service     " "http://localhost:8084/actuator/health" "8084"; then
    ((UP++))
fi

# Catalog Service
if check_service "Catalog Service  " "http://localhost:8085/actuator/health" "8085"; then
    ((UP++))
fi

# Booking Service
if check_service "Booking Service  " "http://localhost:8082/actuator/health" "8082"; then
    ((UP++))
fi

# Search Service
if check_service "Search Service   " "http://localhost:8083/actuator/health" "8083"; then
    ((UP++))
fi

echo ""
echo "==========================================="
echo "📊 RESUMEN: $UP/$TOTAL servicios funcionando"
echo ""

if [ $UP -eq $TOTAL ]; then
    echo "🎉 ¡Todos los servicios están UP!"
    echo ""
    echo "🌐 URLs disponibles:"
    echo "  • Eureka Dashboard: http://localhost:8761"
    echo "  • API Gateway:      http://localhost:8080"
    echo "  • Auth Service:     http://localhost:8084"
    echo "  • Catalog Service:  http://localhost:8085"
    echo "  • Booking Service:  http://localhost:8082"
    echo "  • Search Service:   http://localhost:8083"
    echo ""
    echo "✅ Sistema listo para usar"
    exit 0
else
    echo "⚠️  Algunos servicios no están funcionando"
    echo ""
    echo "💡 Para iniciar todos los servicios:"
    echo "   ./start-all-services.sh"
    echo ""
    echo "📝 Para ver logs de un servicio:"
    echo "   tail -f /tmp/[servicio].log"
    echo ""
    exit 1
fi

