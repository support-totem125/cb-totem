#!/bin/bash

################################################################################
# Script para hacer fetch de todos los repositorios
# Ejecutar periódicamente (cron job) para detectar cambios remotos
# Uso: ./scripts/fetch-all-repos.sh
################################################################################

set -e

# Obtener ruta del proyecto de forma dinámica
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$MAIN_REPO/logs/fetch-all-repos.log"

# Crear directorio de logs si no existe
mkdir -p "$(dirname "$LOG_FILE")"

# Función para logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "🔄 Iniciando fetch de todos los repositorios..."

# Array de repositorios
declare -a repos=(
    "."
    "vcc-totem"
    "srv-img-totem"
)

total_repos=${#repos[@]}
updated=0
no_changes=0
errors=0

# Iterar sobre cada repositorio
for repo in "${repos[@]}"; do
    repo_path="$MAIN_REPO/$repo"
    
    if [ ! -d "$repo_path/.git" ]; then
        log_message "⚠️  No es un repositorio Git: $repo_path"
        ((errors++))
        continue
    fi
    
    cd "$repo_path"
    
    log_message "📍 Procesando: $repo"
    
    # Obtener branch actual
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    log_message "   Branch: $CURRENT_BRANCH"
    
    # Hacer fetch desde todos los remotos
    if git fetch --all 2>&1 | tee -a "$LOG_FILE"; then
        log_message "   ✅ Fetch completado"
        
        # Verificar si hay cambios disponibles
        if git rev-parse --verify @{u} >/dev/null 2>&1; then
            BEHIND=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            AHEAD=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
            
            if [ "$AHEAD" -gt 0 ]; then
                log_message "   📥 Cambios disponibles: $AHEAD commits para descargar"
                ((updated++))
            elif [ "$BEHIND" -gt 0 ]; then
                log_message "   📤 Cambios locales: $BEHIND commits para subir"
            else
                log_message "   ✓ Todo actualizado"
                ((no_changes++))
            fi
        else
            log_message "   ℹ️  No configurado tracking branch"
            ((no_changes++))
        fi
    else
        log_message "   ❌ Error en fetch"
        ((errors++))
    fi
    
    log_message "   ---"
done

# Resumen
log_message ""
log_message "📊 Resumen:"
log_message "   Total procesados: $total_repos"
log_message "   Con cambios disponibles: $updated"
log_message "   Sin cambios: $no_changes"
log_message "   Errores: $errors"

if [ $updated -gt 0 ]; then
    log_message ""
    log_message "✨ Hay actualizaciones disponibles. Ejecutar:"
    log_message "   - scripts/update-vcc-totem.sh"
    log_message "   - scripts/update-srv-img-totem.sh"
fi

log_message "✅ Fetch completado"
