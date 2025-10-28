#!/bin/bash

# ============================================
# SCRIPT: Iniciar TODA la infraestructura
# ============================================

echo "🚀 INICIANDO INFRAESTRUCTURA BALCONAZO"
echo "======================================="
echo ""

# 1. PostgreSQL Catalog
echo "📦 1. PostgreSQL Catalog (puerto 5433)..."
docker start balconazo-pg-catalog 2>/dev/null || \
docker run -d --name balconazo-pg-catalog \
  -p 5433:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=catalog_db \
  -e POSTGRES_USER=postgres \
  postgres:16-alpine

sleep 2
docker exec balconazo-pg-catalog psql -U postgres -d catalog_db \
  -c "CREATE SCHEMA IF NOT EXISTS catalog;" 2>/dev/null
echo "   ✅ PostgreSQL Catalog listo"

# 2. PostgreSQL Booking
echo ""
echo "📦 2. PostgreSQL Booking (puerto 5434)..."
docker start balconazo-pg-booking 2>/dev/null || \
docker run -d --name balconazo-pg-booking \
  -p 5434:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=trust \
  -e POSTGRES_DB=booking_db \
  -e POSTGRES_USER=postgres \
  postgres:16-alpine

sleep 2
docker exec balconazo-pg-booking psql -U postgres -d booking_db \
  -c "CREATE SCHEMA IF NOT EXISTS booking;" 2>/dev/null
echo "   ✅ PostgreSQL Booking listo"

# 3. Zookeeper
echo ""
echo "📦 3. Zookeeper (puerto 2181)..."
docker start balconazo-zookeeper 2>/dev/null || \
docker run -d --name balconazo-zookeeper \
  -p 2181:2181 \
  -e ZOOKEEPER_CLIENT_PORT=2181 \
  -e ZOOKEEPER_TICK_TIME=2000 \
  confluentinc/cp-zookeeper:7.5.0
echo "   ✅ Zookeeper listo"

# 4. Kafka
echo ""
echo "📦 4. Kafka (puerto 9092)..."
docker start balconazo-kafka 2>/dev/null || \
docker run -d --name balconazo-kafka \
  -p 9092:9092 \
  --link balconazo-zookeeper:zookeeper \
  -e KAFKA_BROKER_ID=1 \
  -e KAFKA_ZOOKEEPER_CONNECT=balconazo-zookeeper:2181 \
  -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://localhost:9092 \
  -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
  confluentinc/cp-kafka:7.5.0

echo "   ⏳ Esperando a que Kafka esté listo (15 segundos)..."
sleep 15
echo "   ✅ Kafka listo"

# 5. Redis
echo ""
echo "📦 5. Redis (puerto 6379)..."
docker start balconazo-redis 2>/dev/null || \
docker run -d --name balconazo-redis \
  -p 6379:6379 \
  redis:7-alpine
echo "   ✅ Redis listo"

# Resumen
echo ""
echo "✅ INFRAESTRUCTURA COMPLETA"
echo ""
echo "📊 Contenedores activos:"
docker ps --filter "name=balconazo" --format "   ✅ {{.Names}} - {{.Ports}}"

echo ""
echo "🎯 Siguiente paso:"
echo "   - Inicia Catalog Service:  ./start-catalog.sh"
echo "   - Inicia Booking Service:  ./start-booking.sh"

