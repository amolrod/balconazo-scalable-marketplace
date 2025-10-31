#!/usr/bin/env bash

echo "🎨 Iniciando Frontend Angular BalconazoApp..."
echo ""

cd /Users/angel/Desktop/BalconazoApp/balconazo-frontend

echo "📍 Directorio: $(pwd)"
echo ""

# Verificar que node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm install
fi

echo "🚀 Iniciando ng serve..."
echo ""
echo "🌐 Frontend estará disponible en: http://localhost:4200"
echo ""
echo "💡 Credenciales de prueba:"
echo "   Email: host1@balconazo.com"
echo "   Password: password123"
echo ""
echo "🛑 Para detener: Ctrl+C"
echo ""

ng serve --open

