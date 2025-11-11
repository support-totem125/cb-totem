#!/bin/bash

################################################################################
# Script para verificar rápidamente si hay actualizaciones disponibles
# Uso: ./scripts/check-updates.sh
# Muestra estado de todos los repos
################################################################################

MAIN_REPO="/home/admin/Documents/chat-bot-totem"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         🔍 Verificando Actualizaciones Disponibles         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

declare -a repos=(
    "."
    "vcc-totem"
    "srv-img-totem"
)

total_updates=0
repos_processed=0

for repo in "${repos[@]}"; do
    repo_path="$MAIN_REPO/$repo"
    
    if [ ! -d "$repo_path/.git" ]; then
        echo -e "${RED}❌${NC} No es repositorio: $repo"
        continue
    fi
    
    cd "$repo_path"
    ((repos_processed++))
    
    # Obtener nombre para mostrar
    if [ "$repo" == "." ]; then
        repo_name="🤖 Chat-Bot Totem (Main)"
    elif [ "$repo" == "vcc-totem" ]; then
        repo_name="🟣 VCC-Totem"
    else
        repo_name="🖼️  SRV-IMG-Totem"
    fi
    
    echo -e "${YELLOW}→${NC} $repo_name"
    
    # Hacer fetch
    echo "  Fetching... " | tr -d '\n'
    if git fetch --all --quiet 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        continue
    fi
    
    # Obtener información
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo "  Branch: $BRANCH"
    
    # Verificar cambios
    if git rev-parse --verify @{u} >/dev/null 2>&1; then
        AHEAD=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        BEHIND=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        
        if [ "$AHEAD" -gt 0 ]; then
            echo -e "  ${RED}📥 $AHEAD cambios disponibles para descargar${NC}"
            ((total_updates++))
        elif [ "$BEHIND" -gt 0 ]; then
            echo -e "  ${YELLOW}📤 $BEHIND cambios locales para subir${NC}"
        else
            echo -e "  ${GREEN}✓ Todo actualizado${NC}"
        fi
    else
        echo -e "  ${YELLOW}ℹ️  Sin tracking branch configurado${NC}"
    fi
    
    echo ""
done

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

if [ $total_updates -gt 0 ]; then
    echo -e "${RED}⚠️  Hay $total_updates repositorio(s) con actualizaciones disponibles${NC}"
    echo ""
    echo "Ejecuta para actualizar:"
    echo "  • bash scripts/update-vcc-totem.sh"
    echo "  • bash scripts/update-srv-img-totem.sh"
else
    echo -e "${GREEN}✅ Todo está actualizado${NC}"
fi

echo ""
