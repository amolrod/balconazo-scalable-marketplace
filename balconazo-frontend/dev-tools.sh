#!/bin/bash

# ============================================
# BALCONAZO FRONTEND - COMANDOS RÁPIDOS
# ============================================

echo "🚀 Balconazo Frontend - Comandos Rápidos"
echo "========================================"
echo ""

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar menú
show_menu() {
    echo -e "${BLUE}Selecciona una opción:${NC}"
    echo ""
    echo "  1) 🏗️  Build producción"
    echo "  2) 🚀 Start desarrollo"
    echo "  3) 🧪 Run tests"
    echo "  4) 📊 Test coverage"
    echo "  5) 💅 Format code (Prettier)"
    echo "  6) 🔍 Lighthouse audit"
    echo "  7) 📦 Ver tamaño de bundles"
    echo "  8) 🧹 Clean build"
    echo "  9) 📖 Ver documentación PRs"
    echo "  0) ❌ Salir"
    echo ""
}

# Función principal
main() {
    cd "$(dirname "$0")"

    while true; do
        show_menu
        read -p "Opción: " option
        echo ""

        case $option in
            1)
                echo -e "${YELLOW}🏗️  Building producción...${NC}"
                npm run build
                echo -e "${GREEN}✅ Build completado${NC}"
                ;;
            2)
                echo -e "${YELLOW}🚀 Iniciando servidor de desarrollo...${NC}"
                echo -e "${GREEN}🌐 http://localhost:4200${NC}"
                npm start
                ;;
            3)
                echo -e "${YELLOW}🧪 Ejecutando tests...${NC}"
                npm test
                ;;
            4)
                echo -e "${YELLOW}📊 Ejecutando tests con coverage...${NC}"
                npm run test:coverage
                ;;
            5)
                echo -e "${YELLOW}💅 Formateando código con Prettier...${NC}"
                npx prettier --write "src/**/*.{ts,html,scss}"
                echo -e "${GREEN}✅ Código formateado${NC}"
                ;;
            6)
                echo -e "${YELLOW}🔍 Ejecutando Lighthouse audit...${NC}"
                echo "⚠️  Asegúrate de que el servidor esté corriendo (npm start)"
                read -p "Continuar? (y/n): " confirm
                if [ "$confirm" = "y" ]; then
                    npx lighthouse http://localhost:4200 --view
                fi
                ;;
            7)
                echo -e "${YELLOW}📦 Analizando tamaño de bundles...${NC}"
                if [ -d "dist/balconazo-frontend" ]; then
                    du -sh dist/balconazo-frontend/*
                else
                    echo "⚠️  No hay build. Ejecuta 'npm run build' primero."
                fi
                ;;
            8)
                echo -e "${YELLOW}🧹 Limpiando build...${NC}"
                rm -rf dist/
                echo -e "${GREEN}✅ Build limpiado${NC}"
                ;;
            9)
                echo -e "${YELLOW}📖 Documentación de PRs:${NC}"
                echo ""
                echo "  • PR-1-DESIGN-SYSTEM.md - Documentación completa del PR #1"
                echo "  • PR-1-ENTREGA.md - Resumen de entrega"
                echo "  • ../ROADMAP-FRONTEND.md - Roadmap completo (8 PRs)"
                echo ""
                read -p "Abrir PR-1-ENTREGA.md? (y/n): " open_doc
                if [ "$open_doc" = "y" ]; then
                    cat PR-1-ENTREGA.md | less
                fi
                ;;
            0)
                echo -e "${GREEN}👋 ¡Hasta luego!${NC}"
                exit 0
                ;;
            *)
                echo -e "${YELLOW}⚠️  Opción inválida${NC}"
                ;;
        esac

        echo ""
        read -p "Presiona ENTER para continuar..."
        clear
    done
}

# Ejecutar
main

