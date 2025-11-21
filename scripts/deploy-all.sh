#!/bin/bash

###############################################################################
# DEPLOY-ALL.SH - Despliegue completo del sistema BalconazoApp
###############################################################################
# Este script realiza el despliegue completo del sistema en un solo comando:
# 1. Detiene servicios existentes
# 2. Limpia logs antiguos
# 3. Inicia infraestructura Docker
# 4. Compila todos los microservicios
# 5. Inicia todos los servicios en orden
# 6. Verifica el estado del sistema
###############################################################################

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para imprimir pasos
print_step() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  🚀 PASO $1: $2${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Función para mensajes de éxito
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mensajes de error
print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

# Función para mensajes de advertencia
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encuentra docker-compose.yml. Ejecuta este script desde la raíz del proyecto."
    exit 1
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║      🏢 BALCONAZO APP - DESPLIEGUE COMPLETO 🚀            ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Este script realizará el despliegue completo del sistema.${NC}"
echo -e "${CYAN}Tiempo estimado: 5-7 minutos${NC}"
echo ""

# Preguntar confirmación
read -p "¿Desea continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Despliegue cancelado."
    exit 0
fi

###############################################################################
# PASO 1: DETENER SERVICIOS EXISTENTES
###############################################################################
print_step "1" "Deteniendo servicios existentes"

if ./scripts/stop-all.sh; then
    print_success "Servicios Java detenidos"
else
    print_warning "No había servicios Java ejecutándose"
fi

# Detener contenedores Docker si existen
if docker ps -q --filter "name=pg-" | grep -q .; then
    echo "Deteniendo contenedores Docker..."
    docker-compose down
    print_success "Contenedores Docker detenidos"
else
    print_warning "No había contenedores Docker ejecutándose"
fi

###############################################################################
# PASO 2: LIMPIAR LOGS ANTIGUOS
###############################################################################
print_step "2" "Limpiando logs antiguos"

if rm -f /tmp/*.log 2>/dev/null; then
    print_success "Logs limpiados"
else
    print_warning "No había logs para limpiar"
fi

###############################################################################
# PASO 3: INICIAR INFRAESTRUCTURA DOCKER
###############################################################################
print_step "3" "Iniciando infraestructura Docker (PostgreSQL)"

if ./scripts/start-infrastructure.sh; then
    print_success "Contenedores PostgreSQL iniciados correctamente"
else
    print_error "Fallo al iniciar infraestructura Docker"
    echo "Verifica que Docker Desktop esté corriendo"
    exit 1
fi

# Esperar a que las BD estén listas
echo "Esperando a que las bases de datos estén listas..."
sleep 10

###############################################################################
# PASO 4: COMPILAR TODOS LOS MICROSERVICIOS
###############################################################################
print_step "4" "Compilando microservicios (Maven)"

echo "Esto puede tomar 2-3 minutos..."
if ./scripts/recompile-all.sh; then
    print_success "Todos los microservicios compilados exitosamente"
else
    print_error "Fallo en la compilación"
    echo "Revisa los errores de Maven arriba"
    exit 1
fi

###############################################################################
# PASO 5: INICIAR MICROSERVICIOS
###############################################################################
print_step "5" "Iniciando microservicios"

if ./scripts/start-all-with-eureka.sh; then
    print_success "Todos los microservicios iniciados"
else
    print_error "Fallo al iniciar microservicios"
    exit 1
fi

###############################################################################
# PASO 6: ESPERAR INICIALIZACIÓN COMPLETA
###############################################################################
print_step "6" "Esperando inicialización completa del sistema"

echo "Esperando a que todos los servicios estén listos..."
echo "Esto puede tomar hasta 90 segundos..."
echo ""

# Mostrar progreso
for i in {1..18}; do
    echo -n "▓"
    sleep 5
done
echo " 100%"
echo ""

print_success "Tiempo de espera completado"

###############################################################################
# PASO 7: VERIFICAR ESTADO DEL SISTEMA
###############################################################################
print_step "7" "Verificando estado del sistema"

if ./scripts/check-services.sh; then
    echo ""
    print_success "DESPLIEGUE COMPLETADO EXITOSAMENTE"
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║     🎉 SISTEMA COMPLETAMENTE OPERATIVO 🎉                 ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo "📍 URLs del sistema:"
    echo ""
    echo "   🌐 Eureka Dashboard:   http://localhost:8761"
    echo "   🚪 API Gateway:        http://localhost:8080"
    echo "   🔐 Auth Service:       http://localhost:8084/api/auth"
    echo "   🏠 Catalog Service:    http://localhost:8085/api/catalog"
    echo "   📅 Booking Service:    http://localhost:8082/api/bookings"
    echo "   🔍 Search Service:     http://localhost:8083/api/search"
    echo ""
    
    echo "🧪 Ejecutar tests end-to-end:"
    echo "   ./scripts/test-roles-usuarios-completo.sh"
    echo ""
    
    echo "📚 Ver documentación completa:"
    echo "   docs/INDEX.md"
    echo ""
    
    exit 0
else
    echo ""
    print_error "ALGUNOS SERVICIOS NO ESTÁN FUNCIONANDO CORRECTAMENTE"
    echo ""
    echo "🔧 Acciones recomendadas:"
    echo ""
    echo "   1. Revisa los logs de los servicios:"
    echo "      tail -100 /tmp/eureka-server.log"
    echo "      tail -100 /tmp/auth-service.log"
    echo "      tail -100 /tmp/catalog-service.log"
    echo ""
    echo "   2. Verifica que Docker esté corriendo:"
    echo "      docker ps"
    echo ""
    echo "   3. Verifica que no haya conflictos de puertos:"
    echo "      lsof -i:8080"
    echo "      lsof -i:8084"
    echo ""
    echo "   4. Intenta reiniciar el despliegue:"
    echo "      ./scripts/deploy-all.sh"
    echo ""
    
    exit 1
fi
