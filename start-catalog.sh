#!/bin/bash

# ============================================
# SCRIPT: Iniciar Catalog Service
# ============================================

echo "🚀 INICIANDO CATALOG SERVICE"
echo "============================"
echo ""

# 1. Verificar infraestructura
echo "📋 Verificando infraestructura..."

# PostgreSQL Catalog
if ! docker ps | grep -q "balconazo-pg-catalog"; then
    echo "   ⚠️  PostgreSQL Catalog no está corriendo. Iniciándolo..."
    docker start balconazo-pg-catalog 2>/dev/null || \
    docker run -d --name balconazo-pg-catalog \
      -p 5433:5432 \
      -e POSTGRES_HOST_AUTH_METHOD=trust \
      -e POSTGRES_DB=catalog_db \
      -e POSTGRES_USER=postgres \
      postgres:16-alpine
    sleep 3
    docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
      -c "CREATE SCHEMA IF NOT EXISTS catalog;" 2>/dev/null
fi
echo "   ✅ PostgreSQL Catalog OK (puerto 5433)"

# Kafka
if ! docker ps | grep -q "balconazo-kafka"; then
    echo "   ❌ ERROR: Kafka no está corriendo"
    echo "   Inicia Kafka primero: docker start balconazo-kafka"
    exit 1
fi
echo "   ✅ Kafka OK (puerto 9092)"

echo ""

# 2. Limpiar puerto
echo "🧹 Liberando puerto 8085..."
lsof -ti:8085 | xargs kill -9 2>/dev/null
echo "   ✅ Puerto 8085 libre"

echo ""

# 3. Iniciar servicio
echo "🚀 Iniciando Catalog Service..."
echo ""
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn spring-boot:run

