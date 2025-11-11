#!/bin/bash

################################################################################
# Script para inicializar repositorios externos
# Clona vcc-totem y srv-img-totem si no existen
# Uso: ./scripts/init-repos.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        Inicializando Repositorios Externos                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para verificar si directorio tiene archivos (no vacío)
is_directory_empty() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        return 0  # No existe = vacío
    fi
    
    # Contar archivos (excluyendo . y ..)
    local count=$(find "$dir" -mindepth 1 -maxdepth 1 | wc -l)
    if [ "$count" -eq 0 ]; then
        return 0  # Vacío
    else
        return 1  # No vacío
    fi
}

# Función para clonar repo
clone_repo() {
    local repo_name="$1"
    local repo_url="$2"
    local target_dir="$PROJECT_ROOT/$repo_name"
    
    echo -e "${YELLOW}→${NC} Procesando: $repo_name"
    
    if is_directory_empty "$target_dir"; then
        echo "  📥 Clonando desde: $repo_url"
        
        # Eliminar directorio si existe pero está vacío
        if [ -d "$target_dir" ]; then
            rm -rf "$target_dir"
        fi
        
        # Clonar repo
        if git clone "$repo_url" "$target_dir" 2>&1 | grep -q "Cloning"; then
            echo -e "  ${GREEN}✓${NC} Clonado exitosamente"
            
            # Mostrar información del repo
            cd "$target_dir"
            local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            echo "  Branch: $branch"
            echo "  Commit: $commit"
            
            # Volver al directorio raíz
            cd "$PROJECT_ROOT"
        else
            echo -e "  ${RED}✗${NC} Error al clonar"
            return 1
        fi
    else
        echo -e "  ${GREEN}✓${NC} Ya existe y tiene contenido"
        
        # Mostrar información del repo existente
        cd "$target_dir"
        if [ -d ".git" ]; then
            local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
            local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            echo "  Branch: $branch"
            echo "  Commit: $commit"
        fi
        cd "$PROJECT_ROOT"
    fi
    
    echo ""
}

# Configuración de repositorios
declare -A REPOS=(
    ["vcc-totem"]="https://github.com/diego-moscaiza/vcc-totem.git"
    ["srv-img-totem"]="https://github.com/diego-moscaiza/srv-img-totem.git"
)

# Clonar cada repositorio
repos_cloned=0
repos_skipped=0
repos_failed=0

for repo_name in "${!REPOS[@]}"; do
    repo_url="${REPOS[$repo_name]}"
    
    if clone_repo "$repo_name" "$repo_url"; then
        if is_directory_empty "$PROJECT_ROOT/$repo_name"; then
            ((repos_skipped++))
        else
            ((repos_cloned++))
        fi
    else
        ((repos_failed++))
    fi
done

# Resumen
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "📊 Resumen:"
echo "  ✓ Repositorios clonados: $repos_cloned"
echo "  ℹ️  Ya existían: $repos_skipped"
if [ $repos_failed -gt 0 ]; then
    echo -e "  ${RED}✗ Fallidos: $repos_failed${NC}"
fi

echo ""

if [ $repos_failed -eq 0 ]; then
    echo -e "${GREEN}✅ Inicialización completada exitosamente${NC}"
    echo ""
    echo "📝 Próximos pasos:"
    echo "  1. Revisa la configuración en vcc-totem/.env"
    echo "  2. Revisa la configuración en srv-img-totem/.env"
    echo "  3. Ejecuta: docker-compose up -d"
else
    echo -e "${RED}⚠️  Algunos repositorios fallaron al clonar${NC}"
    echo ""
    echo "Verifica tu conexión a internet y permisos de acceso."
fi

echo ""
