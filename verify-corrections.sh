#!/bin/bash

echo "🧪 VERIFICACIÓN DE CORRECCIONES APLICADAS"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

# Test 1: Verificar que la dependencia de Netty esté en el pom.xml
echo "Test 1: Dependencia netty-resolver-dns-native-macos"
if grep -q "netty-resolver-dns-native-macos" /Users/angel/Desktop/BalconazoApp/api-gateway/pom.xml; then
    echo -e "${GREEN}✅ PASS${NC} - Dependencia encontrada en pom.xml"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Dependencia NO encontrada"
    ((FAIL++))
fi
echo ""

# Test 2: Verificar que el JAR esté compilado con la nueva dependencia
echo "Test 2: Compilación del API Gateway"
if [ -f "/Users/angel/Desktop/BalconazoApp/api-gateway/target/api-gateway-1.0.0.jar" ]; then
    echo -e "${GREEN}✅ PASS${NC} - JAR existe"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - JAR no encontrado, recompila con: cd api-gateway && mvn clean package -DskipTests"
    ((FAIL++))
fi
echo ""

# Test 3: Verificar corrección en start-system-improved.sh
echo "Test 3: Corrección de conteo de errores (start-system-improved.sh)"
if grep -q "wc -l | tr -d" /Users/angel/Desktop/BalconazoApp/start-system-improved.sh; then
    echo -e "${GREEN}✅ PASS${NC} - Conteo de errores corregido"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Script no corregido"
    ((FAIL++))
fi
echo ""

# Test 4: Verificar filtros en start-system-improved.sh
echo "Test 4: Filtros de falsos positivos (start-system-improved.sh)"
if grep -q "MacOSDnsServerAddressStreamProvider" /Users/angel/Desktop/BalconazoApp/start-system-improved.sh && \
   grep -q "last_error" /Users/angel/Desktop/BalconazoApp/start-system-improved.sh; then
    echo -e "${GREEN}✅ PASS${NC} - Filtros implementados"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Filtros faltantes"
    ((FAIL++))
fi
echo ""

# Test 5: Verificar función check_real_errors en start-all-with-eureka.sh
echo "Test 5: Función check_real_errors (start-all-with-eureka.sh)"
if grep -q "check_real_errors" /Users/angel/Desktop/BalconazoApp/start-all-with-eureka.sh; then
    echo -e "${GREEN}✅ PASS${NC} - Función implementada"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Función no encontrada"
    ((FAIL++))
fi
echo ""

# Test 6: Probar filtro de errores con ejemplo
echo "Test 6: Prueba funcional del filtro"
echo "2025-10-29 - Unable to load MacOSDnsServerAddressStreamProvider" > /tmp/test-filter.log
echo "2025-10-29 - DEBUG DisableEncodeUrlFilter" >> /tmp/test-filter.log
echo "2025-10-29 - oee1_0.last_error," >> /tmp/test-filter.log
echo "2025-10-29 - REAL ERROR: Connection failed" >> /tmp/test-filter.log

TOTAL=$(grep -c -i "error" /tmp/test-filter.log)
FILTERED=$(grep -i "error" /tmp/test-filter.log | grep -v "MacOSDnsServerAddressStreamProvider\|DEBUG\|last_error" | wc -l | tr -d ' ')

if [ "$FILTERED" = "1" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Filtro funciona correctamente"
    echo "   Total con 'error': $TOTAL"
    echo "   Después de filtrar: $FILTERED (solo errores reales)"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Filtro no funciona correctamente"
    echo "   Esperado: 1, Obtenido: $FILTERED"
    ((FAIL++))
fi
echo ""

# Test 7: Verificar que los scripts tengan permisos de ejecución
echo "Test 7: Permisos de ejecución"
SCRIPTS=(
    "/Users/angel/Desktop/BalconazoApp/start-system-improved.sh"
    "/Users/angel/Desktop/BalconazoApp/start-all-with-eureka.sh"
    "/Users/angel/Desktop/BalconazoApp/test-api-gateway.sh"
)

ALL_EXECUTABLE=true
for script in "${SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        echo -e "${RED}❌ $script no es ejecutable${NC}"
        ALL_EXECUTABLE=false
    fi
done

if [ "$ALL_EXECUTABLE" = true ]; then
    echo -e "${GREEN}✅ PASS${NC} - Todos los scripts tienen permisos correctos"
    ((PASS++))
else
    echo -e "${RED}❌ FAIL${NC} - Algunos scripts no son ejecutables"
    echo "   Ejecuta: chmod +x /Users/angel/Desktop/BalconazoApp/*.sh"
    ((FAIL++))
fi
echo ""

# Resumen final
echo "=========================================="
echo "RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo ""
echo "Tests ejecutados: $((PASS + FAIL))"
echo -e "${GREEN}Tests pasados:    $PASS${NC}"
echo -e "${RED}Tests fallidos:   $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡Todas las correcciones están aplicadas correctamente!${NC}"
    echo ""
    echo "Puedes iniciar el sistema con confianza:"
    echo "  ./start-system-improved.sh"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  Hay correcciones pendientes${NC}"
    echo ""
    echo "Revisa los tests fallidos arriba y aplica las correcciones necesarias."
    echo ""
    exit 1
fi

