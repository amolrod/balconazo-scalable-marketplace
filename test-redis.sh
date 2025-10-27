#!/bin/bash

echo "🚀 Iniciando Catalog Service con Redis..."
echo "==========================================="
echo ""

cd /Users/angel/Desktop/BalconazoApp/catalog_microservice

# Iniciar en background y guardar logs
mvn spring-boot:run > /tmp/catalog-redis-test.log 2>&1 &
SPRING_PID=$!

echo "📝 Proceso iniciado con PID: $SPRING_PID"
echo "📄 Logs en: /tmp/catalog-redis-test.log"
echo ""
echo "⏳ Esperando 25 segundos para que arranque..."
sleep 25

echo ""
echo "🔍 Buscando mensajes de Redis en los logs..."
echo "=============================================="
grep -i "redis" /tmp/catalog-redis-test.log | tail -10

echo ""
echo "🔍 Verificando si el servicio arrancó..."
echo "========================================"
grep "Started CatalogMicroserviceApplication" /tmp/catalog-redis-test.log

echo ""
echo "🏥 Health Check..."
echo "=================="
curl -s http://localhost:8085/actuator/health | python3 -m json.tool

echo ""
echo "✅ Proceso completado"

