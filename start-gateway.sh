#!/bin/bash

echo "🚀 INICIANDO API GATEWAY - BALCONAZO"
echo "====================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Puerto del API Gateway
PORT=8080

# Función para verificar si el puerto está ocupado
check_port() {
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${YELLOW}⚠️  Puerto $PORT ya está en uso. Deteniendo proceso...${NC}"
        kill -9 $(lsof -ti:$PORT) 2>/dev/null
        sleep 2
        echo -e "${GREEN}✅ Puerto $PORT liberado${NC}"
    fi
}

# Verificar puerto
check_port

# Verificar que Redis esté corriendo
echo "🔍 Verificando Redis..."
if ! redis-cli ping > /dev/null 2>&1; then
    echo -e "${RED}❌ Redis no está corriendo. Iniciando contenedor...${NC}"
    docker start balconazo-redis 2>/dev/null || docker-compose up -d redis
    sleep 3
fi
echo -e "${GREEN}✅ Redis está corriendo${NC}"
echo ""

# Verificar que Eureka esté corriendo
echo "🔍 Verificando Eureka Server..."
if ! curl -s http://localhost:8761/actuator/health > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Eureka Server no está corriendo. Inicia Eureka primero con:${NC}"
    echo -e "${YELLOW}   ./start-eureka.sh${NC}"
    echo ""
    read -p "¿Deseas continuar sin Eureka? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ Eureka Server está corriendo${NC}"
fi
echo ""

# Compilar el proyecto
echo "🔨 Compilando API Gateway..."
cd /Users/angel/Desktop/BalconazoApp/api-gateway

mvn clean package -DskipTests

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al compilar API Gateway${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Compilación exitosa${NC}"
echo ""

# Iniciar el servicio
echo "🚀 Iniciando API Gateway en puerto $PORT..."
echo -e "${YELLOW}📋 Logs se guardarán en: logs/api-gateway.log${NC}"
echo ""

mkdir -p logs

# Iniciar con logs en archivo y consola
java -jar target/api-gateway-1.0.0.jar \
    --spring.profiles.active=dev \
    2>&1 | tee logs/api-gateway.log

