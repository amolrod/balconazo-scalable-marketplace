#!/usr/bin/env bash
#
# recompile-all.sh - Recompila todos los microservicios
#

set -euo pipefail

echo "🔨 Recompilando TODOS los servicios..."
echo ""

# 1. Eureka Server
echo "1️⃣ Compilando Eureka Server..."
cd /Users/angel/Desktop/BalconazoApp/eureka-server
mvn clean package -DskipTests -q
echo "✅ Eureka Server compilado"
echo ""

# 2. API Gateway
echo "2️⃣ Compilando API Gateway..."
cd /Users/angel/Desktop/BalconazoApp/api-gateway
mvn clean package -DskipTests -q
echo "✅ API Gateway compilado"
echo ""

# 3. Auth Service
echo "3️⃣ Compilando Auth Service..."
cd /Users/angel/Desktop/BalconazoApp/auth-service
mvn clean package -DskipTests -q
echo "✅ Auth Service compilado"
echo ""

# 4. Catalog Service
echo "4️⃣ Compilando Catalog Service..."
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn clean package -DskipTests -q
echo "✅ Catalog Service compilado"
echo ""

# 5. Booking Service
echo "5️⃣ Compilando Booking Service..."
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
mvn clean package -DskipTests -q
echo "✅ Booking Service compilado"
echo ""

# 6. Search Service
echo "6️⃣ Compilando Search Service..."
cd /Users/angel/Desktop/BalconazoApp/search_microservice
mvn clean package -DskipTests -q
echo "✅ Search Service compilado"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Todos los servicios compilados exitosamente"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 JARs generados:"
echo "  • eureka-server/target/eureka-server-1.0.0.jar"
echo "  • api-gateway/target/api-gateway-1.0.0.jar"
echo "  • auth-service/target/auth_service-0.0.1-SNAPSHOT.jar"
echo "  • catalog_microservice/target/catalog_microservice-0.0.1-SNAPSHOT.jar"
echo "  • booking_microservice/target/booking_microservice-0.0.1-SNAPSHOT.jar"
echo "  • search_microservice/target/search_microservice-0.0.1-SNAPSHOT.jar"
echo ""
echo "🚀 Para iniciar todos los servicios:"
echo "   ./start-all-services.sh"
echo ""

