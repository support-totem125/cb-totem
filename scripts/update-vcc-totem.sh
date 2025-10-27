#!/bin/bash
# Script para actualizar el repo vcc-totem
# Uso: bash /home/admin/Documents/chat-bot-totem/scripts/update-vcc-totem.sh

REPO_PATH="/home/admin/Documents/chat-bot-totem/vcc-totem"
LOG_FILE="/home/admin/Documents/chat-bot-totem/logs/vcc-totem-updates.log"

# Crear directorio de logs si no existe
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando actualización del repo vcc-totem..." >> "$LOG_FILE"

# Navegar al repo
cd "$REPO_PATH" || exit 1

# Obtener hash del commit actual
BEFORE=$(git rev-parse HEAD)

# Hacer pull
git fetch origin >> "$LOG_FILE" 2>&1
git pull origin main >> "$LOG_FILE" 2>&1

# Obtener hash después
AFTER=$(git rev-parse HEAD)

# Comparar
if [ "$BEFORE" != "$AFTER" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Actualización detectada: $BEFORE → $AFTER" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cambios en el repo. Revisar:" >> "$LOG_FILE"
    git log --oneline $BEFORE..$AFTER >> "$LOG_FILE" 2>&1
    
    # Opcional: reiniciar servicios
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Instalando dependencias actualizadas..." >> "$LOG_FILE"
    pip install -r requirements.txt -q >> "$LOG_FILE" 2>&1
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Actualización completada" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️ No hay cambios nuevos" >> "$LOG_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ---" >> "$LOG_FILE"
