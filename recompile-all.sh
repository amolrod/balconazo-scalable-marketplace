#!/bin/bash

echo "🔨 Recompilando microservicios con Eureka Client..."
echo ""

# Catalog Service
echo "1️⃣ Compilando Catalog Service..."
cd /Users/angel/Desktop/BalconazoApp/catalog_microservice
mvn clean install -DskipTests
if [ $? -eq 0 ]; then
    echo "✅ Catalog Service compilado"
else
    echo "❌ Error compilando Catalog Service"
    exit 1
fi

echo ""

# Booking Service
echo "2️⃣ Compilando Booking Service..."
cd /Users/angel/Desktop/BalconazoApp/booking_microservice
mvn clean install -DskipTests
if [ $? -eq 0 ]; then
    echo "✅ Booking Service compilado"
else
    echo "❌ Error compilando Booking Service"
    exit 1
fi

echo ""

# Search Service
echo "3️⃣ Compilando Search Service..."
cd /Users/angel/Desktop/BalconazoApp/search_microservice
mvn clean install -DskipTests
if [ $? -eq 0 ]; then
    echo "✅ Search Service compilado"
else
    echo "❌ Error compilando Search Service"
    exit 1
fi

echo ""
echo "✅ Todos los microservicios compilados exitosamente"
echo "📦 Ahora están listos para registrarse en Eureka"

