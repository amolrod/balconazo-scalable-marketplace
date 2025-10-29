#!/usr/bin/env bash

echo "Iniciando Auth Service..."
cd /Users/angel/Desktop/BalconazoApp/auth-service
java -jar target/auth_service-0.0.1-SNAPSHOT.jar &
AUTH_PID=$!
echo "Auth Service iniciado con PID: $AUTH_PID"
echo "Esperando 25 segundos..."
sleep 25
echo ""
echo "Probando health check..."
curl -s http://localhost:8084/actuator/health | head -20
echo ""
echo ""
echo "Probando login..."
curl -v -X POST http://localhost:8084/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"host1@balconazo.com","password":"password123"}' \
  2>&1 | grep -E "HTTP|403|200|{" | head -10

