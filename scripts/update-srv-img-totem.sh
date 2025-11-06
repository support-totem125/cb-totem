#!/bin/bash

################################################################################
# Script para actualizar srv-img-totem desde GitHub
# Trae cambios del repositorio remoto y redeploya el servicio
# Uso: ./scripts/update-srv-img-totem.sh
################################################################################

set -e

REPO_PATH="/home/admin/Documents/chat-bot-totem/srv-img-totem"
LOG_FILE="/home/admin/Documents/chat-bot-totem/srv-img-totem-updates.log"
GITHUB_REPO="https://github.com/support-totem125/srv-img-totem.git"

# Crear directorio de logs si no existe
mkdir -p logs

# Función para logging con timestamp
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Verificar que el repositorio existe
if [ ! -d "$REPO_PATH" ]; then
    log_message "❌ Error: No se encontró el directorio $REPO_PATH"
    log_message "Clonando repositorio desde $GITHUB_REPO..."
    git clone "$GITHUB_REPO" "$REPO_PATH"
    log_message "✅ Repositorio clonado exitosamente"
fi

cd "$REPO_PATH"

log_message "🔄 Iniciando actualización de srv-img-totem..."
log_message "📍 Ruta: $(pwd)"

# Obtener branch actual
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log_message "📌 Branch actual: $CURRENT_BRANCH"

# Hacer fetch de todos los remotos
log_message "📥 Realizando git fetch --all..."
git fetch --all 2>&1 | tee -a "$LOG_FILE"

# Si existe 'upstream', preferir ese remoto; si no, usar 'origin'
if git remote | grep -q upstream; then
    REMOTE="upstream"
    log_message "🔗 Usando remoto 'upstream'"
else
    REMOTE="origin"
    log_message "🔗 Usando remoto 'origin'"
fi

# Pull desde el remoto
log_message "📥 Haciendo pull desde $REMOTE/$CURRENT_BRANCH..."
if git pull "$REMOTE" "$CURRENT_BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
    log_message "✅ Pull completado exitosamente"
else
    log_message "⚠️  Pull completado con advertencias o cambios locales"
fi

# Mostrar cambios recientes
log_message "📝 Últimos 3 commits:"
git log --oneline -3 | while read line; do
    log_message "   $line"
done

cd ..

# Recargar el servicio con docker compose
log_message "🐳 Recargando servicio srv-img con docker compose..."
if docker compose up -d srv-img --pull always 2>&1 | tee -a "$LOG_FILE"; then
    log_message "✅ Servicio srv-img recargado exitosamente"
    
    # Esperar a que el servicio esté listo
    sleep 3
    
    # Verificar estado
    if docker compose ps srv-img | grep -q "Up"; then
        log_message "✅ Servicio srv-img está en estado 'Up'"
        log_message "✨ Actualización completada exitosamente"
    else
        log_message "⚠️  Verificar estado del servicio: docker compose ps srv-img"
    fi
else
    log_message "❌ Error al recargar servicio srv-img"
    log_message "Revisa los logs: docker compose logs srv-img"
    exit 1
fi

log_message "📊 Resumen de cambios aplicados:"
log_message "   - Repositorio: $GITHUB_REPO"
log_message "   - Remoto: $REMOTE"
log_message "   - Branch: $CURRENT_BRANCH"
log_message "   - Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

