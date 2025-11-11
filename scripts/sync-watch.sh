#!/bin/bash

################################################################################
# Script para monitorear cambios en repositorios
# Se ejecuta periódicamente y notifica si hay actualizaciones disponibles
# Uso: ./scripts/monitor-repos.sh
# Para ejecución automática, agregarlo a crontab:
# */5 * * * * /path/to/chat-bot-totem/scripts/monitor-repos.sh
################################################################################

set -e

# Obtener ruta del proyecto de forma dinámica
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
STATUS_FILE="/tmp/chat-bot-totem-status.txt"
NOTIFICATION_FILE="/tmp/chat-bot-totem-notification.flag"

# Repositorios a monitorear
declare -a repos=(
    "."
    "vcc-totem"
    "srv-img-totem"
)

# Hacer fetch de todos
for repo in "${repos[@]}"; do
    repo_path="$MAIN_REPO/$repo"
    
    if [ ! -d "$repo_path/.git" ]; then
        continue
    fi
    
    cd "$repo_path"
    git fetch --all 2>/dev/null || true
done

# Crear status
{
    echo "Actualizado: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    for repo in "${repos[@]}"; do
        repo_path="$MAIN_REPO/$repo"
        
        if [ ! -d "$repo_path/.git" ]; then
            continue
        fi
        
        cd "$repo_path"
        
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        
        if git rev-parse --verify @{u} >/dev/null 2>&1; then
            AHEAD=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
            BEHIND=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            
            if [ "$AHEAD" -gt 0 ]; then
                echo "📥 $repo: $AHEAD cambios para descargar ($BRANCH)"
            elif [ "$BEHIND" -gt 0 ]; then
                echo "📤 $repo: $BEHIND cambios para subir ($BRANCH)"
            else
                echo "✓ $repo: actualizado ($BRANCH)"
            fi
        fi
    done
} > "$STATUS_FILE"

# Si hay cambios, crear flag para notificación
if grep -q "^📥" "$STATUS_FILE"; then
    touch "$NOTIFICATION_FILE"
fi
