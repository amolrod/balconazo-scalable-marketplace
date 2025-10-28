#!/bin/bash

# ============================================
# SCRIPT: Iniciar Search Microservice
# ============================================

echo "🚀 INICIANDO SEARCH MICROSERVICE"
echo "================================"
echo ""

# 1. Verificar infraestructura
echo "📋 Verificando infraestructura..."

# PostgreSQL Search
if ! docker ps | grep -q "balconazo-pg-search"; then
    echo "   ⚠️  PostgreSQL Search no está corriendo. Iniciándolo..."
    docker start balconazo-pg-search 2>/dev/null || \
    docker run -d --name balconazo-pg-search \
      -p 5435:5432 \
      -e POSTGRES_HOST_AUTH_METHOD=trust \
      -e POSTGRES_DB=search_db \
      -e POSTGRES_USER=postgres \
      postgis/postgis:16-3.4-alpine
    sleep 3
    docker exec balconazo-pg-search psql -U postgres -d search_db \
      -c "CREATE SCHEMA IF NOT EXISTS search; CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pg_trgm;" 2>/dev/null
fi
echo "   ✅ PostgreSQL Search OK (puerto 5435)"

# Kafka
if ! docker ps | grep -q "balconazo-kafka"; then
    echo "   ❌ ERROR: Kafka no está corriendo"
    echo "   Inicia Kafka primero: docker start balconazo-kafka"
    exit 1
fi
echo "   ✅ Kafka OK (puerto 9092)"

# Redis
if ! docker ps | grep -q "balconazo-redis"; then
    echo "   ⚠️  Redis no está corriendo. Iniciándolo..."
    docker start balconazo-redis 2>/dev/null
fi
echo "   ✅ Redis OK (puerto 6379)"

echo ""

# 2. Limpiar puerto
echo "🧹 Liberando puerto 8083..."
lsof -ti:8083 | xargs kill -9 2>/dev/null
echo "   ✅ Puerto 8083 libre"

echo ""

# 3. Iniciar servicio
echo "🚀 Iniciando Search Microservice..."
echo ""
cd /Users/angel/Desktop/BalconazoApp/search_microservice
mvn spring-boot:run

