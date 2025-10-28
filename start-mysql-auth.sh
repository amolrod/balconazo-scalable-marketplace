#!/bin/bash

echo "🐬 Iniciando MySQL para Auth Service..."

# Detener y eliminar contenedor anterior si existe
docker stop balconazo-mysql-auth 2>/dev/null
docker rm balconazo-mysql-auth 2>/dev/null

# Iniciar MySQL
docker run -d --name balconazo-mysql-auth \
  -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=auth_db \
  mysql:8.0

echo "⏳ Esperando 30 segundos para que MySQL inicie..."
sleep 30

# Verificar que MySQL esté corriendo
if docker ps | grep -q balconazo-mysql-auth; then
    echo "✅ MySQL corriendo en puerto 3307"

    # Crear schema auth
    echo "📋 Creando schema auth..."
    docker exec balconazo-mysql-auth mysql -uroot -proot -e "CREATE SCHEMA IF NOT EXISTS auth; USE auth;"

    # Verificar conexión
    docker exec balconazo-mysql-auth mysql -uroot -proot auth_db -e "SHOW DATABASES;" | grep auth_db

    if [ $? -eq 0 ]; then
        echo "✅ Base de datos auth_db lista"
    else
        echo "⚠️  Base de datos no encontrada, pero MySQL está corriendo"
    fi
else
    echo "❌ Error: MySQL no está corriendo"
    exit 1
fi

echo ""
echo "🎯 MySQL Auth Service listo:"
echo "   Host: localhost"
echo "   Port: 3307"
echo "   Database: auth_db"
echo "   User: root"
echo "   Password: root"

