# Watchtower - Auto-Update de Contenedores
# Watchtower monitorea cambios en imágenes Docker y actualiza contenedores automáticamente
# Sin necesidad de down/up - los contenedores se actualizan sin downtime

# Agregar esta sección al docker-compose.yaml para auto-updates:

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      # Verificar actualizaciones cada X segundos (60 = 1 minuto, 10 = 10 segundos)
      - WATCHTOWER_POLL_INTERVAL=60
      # Actualizar automáticamente sin preguntar
      - WATCHTOWER_RUN_ONCE=false
      # Limpiar imágenes antiguas
      - WATCHTOWER_CLEANUP=true
      # Actualizar solo contenedores con label específico (seguro)
      - WATCHTOWER_LABEL_ENABLE=true
      # Esperar 30 segundos antes de parar contenedor (graceful shutdown)
      - WATCHTOWER_STOP_TIMEOUT=30s
      # Mostrar logs detallados
      - WATCHTOWER_DEBUG=false
    command: 
      # Solo actualizar servicios con label "auto-update=true"
      - --cleanup
      - --remove-volumes
      - --poll-interval
      - "60"
    networks:
      - app_network
    # NO exponer puertos, es un servicio interno

# ============================================
# Para habilitar auto-update en un servicio:
# ============================================

# Agregar estos labels a cada servicio que quieras auto-actualizar:

  evolution-api:
    image: atendai/evolution-api:latest
    container_name: evolution_api
    restart: always
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    # ... resto de configuración

  chatwoot-web:
    image: chatwoot/chatwoot:latest
    container_name: chatwoot_web
    restart: always
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    # ... resto de configuración

# ============================================
# Ventajas de Watchtower:
# ============================================
# ✅ Auto-actualiza contenedores sin down/up
# ✅ Solo actualiza servicios marcados con label
# ✅ Limpia imágenes antiguas automáticamente
# ✅ Zero-downtime deployments
# ✅ Logs de cada actualización
# ✅ Control granular por servicio

# ============================================
# Alternativa: Docker Config File (sin Watchtower)
# ============================================
# En lugar de Watchtower, puedes usar docker-compose con health checks
# y un script simple que verifica cambios cada X tiempo
