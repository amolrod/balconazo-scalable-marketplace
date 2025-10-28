#!/bin/bash

# ============================================
# SCRIPT: Iniciar Booking Service
# ============================================

echo "🚀 INICIANDO BOOKING SERVICE"
echo "============================="
echo ""

# 1. Verificar infraestructura
echo "📋 Verificando infraestructura..."

# PostgreSQL Booking
if ! docker ps | grep -q "balconazo-pg-booking"; then
    echo "   ⚠️  PostgreSQL Booking no está corriendo. Iniciándolo..."
    docker start balconazo-pg-booking 2>/dev/null || \
    docker run -d --name balconazo-pg-booking \
      -p 5434:5432 \
      -e POSTGRES_HOST_AUTH_METHOD=trust \
      -e POSTGRES_DB=booking_db \
      -e POSTGRES_USER=postgres \
      postgres:16-alpine
    sleep 3
    docker exec balconazo-pg-booking psql -U postgres -d booking_db \
      -c "CREATE SCHEMA IF NOT EXISTS booking;" 2>/dev/null
fi
echo "   ✅ PostgreSQL Booking OK (puerto 5434)"

# Kafka
if ! docker ps | grep -q "balconazo-kafka"; then
    echo "   ❌ ERROR: Kafka no está corriendo"
    echo "   Inicia Kafka primero: docker start balconazo-kafka"
    exit 1
fi
echo "   ✅ Kafka OK (puerto 9092)"

echo ""

# 2. Limpiar puerto
echo "🧹 Liberando puerto 8082..."
lsof -ti:8082 | xargs kill -9 2>/dev/null
echo "   ✅ Puerto 8082 libre"

echo ""

# 3. Iniciar servicio
echo "🚀 Iniciando Booking Service..."
echo ""
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
mvn spring-boot:run

