#!/bin/bash

################################################################################
# Auto-Sync Script for Docker Compose Services
# Monitorea cambios en archivos y aplica updates sin down/up
# Uso: ./scripts/auto-sync.sh
################################################################################

set -e

COMPOSE_FILE="docker-compose.yaml"
ENV_FILE=".env"
WATCH_INTERVAL=1  # segundos
LOG_FILE="logs/auto-sync.log"

# Crear directorio de logs si no existe
mkdir -p logs

# Función para logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para calcular hash de archivo
get_file_hash() {
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

# Función para validar docker-compose.yaml
validate_compose() {
    if docker compose config > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para aplicar cambios sin down
apply_changes() {
    local service=$1
    log_message "📦 Actualizando servicio: $service"
    
    # Opción 1: Usar docker compose up (pull + update sin remover contenedor)
    docker compose up -d "$service" --pull always
    
    # Esperar a que el servicio esté listo
    sleep 3
    
    # Verificar estado
    if docker compose ps "$service" | grep -q "Up"; then
        log_message "✅ Servicio $service actualizado correctamente"
        return 0
    else
        log_message "❌ Error: Servicio $service no está en estado Up"
        return 1
    fi
}

# Función para recargar configuración sin reiniciar (aplica cambios de .env)
reload_env() {
    log_message "🔄 Detectado cambio en .env, recargando configuración..."
    
    # Validar .env
    if [ ! -f "$ENV_FILE" ]; then
        log_message "❌ Error: $ENV_FILE no encontrado"
        return 1
    fi
    
    # Aplicar cambios a todos los servicios
    docker compose up -d
    log_message "✅ Configuración recargada"
    return 0
}

# Inicializar hashes
log_message "🚀 Iniciando Auto-Sync Monitor"
log_message "📁 Monitoreando: $COMPOSE_FILE, $ENV_FILE"
log_message "⏱️  Intervalo de verificación: ${WATCH_INTERVAL}s"

compose_hash=$(get_file_hash "$COMPOSE_FILE")
env_hash=$(get_file_hash "$ENV_FILE")

echo "================================"
echo "Auto-Sync Monitor Iniciado"
echo "Presiona Ctrl+C para detener"
echo "================================"

# Loop de monitoreo
while true; do
    sleep "$WATCH_INTERVAL"
    
    # Verificar cambios en docker-compose.yaml
    new_compose_hash=$(get_file_hash "$COMPOSE_FILE")
    if [ "$compose_hash" != "$new_compose_hash" ]; then
        log_message "📝 Cambio detectado en $COMPOSE_FILE"
        
        if validate_compose; then
            # Obtener servicios que cambiaron
            docker compose up -d --no-deps
            log_message "✅ Cambios aplicados exitosamente"
            compose_hash="$new_compose_hash"
        else
            log_message "❌ Error: docker-compose.yaml inválido"
            compose_hash=$(get_file_hash "$COMPOSE_FILE")  # Revertir a hash actual
        fi
    fi
    
    # Verificar cambios en .env
    new_env_hash=$(get_file_hash "$ENV_FILE")
    if [ "$env_hash" != "$new_env_hash" ]; then
        log_message "📝 Cambio detectado en $ENV_FILE"
        reload_env
        env_hash="$new_env_hash"
    fi
done
