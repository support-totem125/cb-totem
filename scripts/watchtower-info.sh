#!/bin/bash

# ============================================================================
# Watchtower - Sistema de Auto-Actualización de Contenedores
# ============================================================================
# 
# Watchtower está configurado y corriendo en tu stack Docker Compose
# Auto-actualiza todos los servicios marcados con labels cada 60 segundos
#
# ============================================================================

# Ver logs en tiempo real:
docker compose logs watchtower -f

# Ver logs históricos:
docker compose logs watchtower --tail=50

# Ver información de Watchtower:
docker compose ps watchtower

# ============================================================================
# ¿Qué hace Watchtower?
# ============================================================================
# 
# 1. Cada 60 segundos verifica si hay nuevas versiones de imágenes
# 2. Descarga automáticamente nuevas versiones (`:latest` o tags específicos)
# 3. Para el contenedor anterior GRACEFULLY (espera 30 segundos para shutdown)
# 4. Inicia un nuevo contenedor con la imagen actualizada
# 5. Limpia imágenes antiguas para ahorrar espacio
# 
# TODO ESTO SIN DOWNTIME MANUAL - Sin necesidad de `docker compose down`

# ============================================================================
# Servicios monitoreados con AUTO-UPDATE habilitado:
# ============================================================================
# 
# ✅ evolution-api:latest
# ✅ chatwoot/chatwoot:latest (web + sidekiq)
# ✅ n8nio/n8n:latest
# ✅ dpage/pgadmin4:latest
#
# ❌ NO se actualizan automáticamente (sin label):
# ❌ PostgreSQL (pgvector/pgvector:pg15) - versión fija
# ❌ Redis (redis:7-alpine) - versión fija
#
# Razón: Servicios con estado (BD, cache) necesitan actualización manual

# ============================================================================
# Variables de configuración en docker-compose.yaml:
# ============================================================================
#
# WATCHTOWER_POLL_INTERVAL=60
#   → Verificar cambios cada 60 segundos (1 minuto)
#
# WATCHTOWER_CLEANUP=true
#   → Limpiar imágenes antiguas después de actualizar
#
# WATCHTOWER_LABEL_ENABLE=true
#   → Solo actualizar servicios con label "com.centurylinklabs.watchtower.enable=true"
#
# WATCHTOWER_STOP_TIMEOUT=30s
#   → Esperar 30 segundos para graceful shutdown antes de forzar kill
#

# ============================================================================
# Cómo agregar auto-update a un nuevo servicio:
# ============================================================================
#
# Agregar label al servicio en docker-compose.yaml:
#
#   mi-servicio:
#     image: mi-imagen:latest
#     container_name: mi-servicio
#     restart: always
#     labels:
#       - "com.centurylinklabs.watchtower.enable=true"  # ← Agregar esto
#     # ... resto de configuración
#

# ============================================================================
# Cómo DESHABILITAR auto-update para un servicio:
# ============================================================================
#
# Cambiar `:latest` a versión fija:
#
#   evolution-api:
#     image: atendai/evolution-api:v2.2.3  # ← Versión fija
#
# O remover el label:
#     # labels:
#     #   - "com.centurylinklabs.watchtower.enable=true"
#

# ============================================================================
# Ventajas:
# ============================================================================
# ✅ Zero-downtime updates (sin interrupsión de servicio)
# ✅ Automático - no requiere acción manual
# ✅ Limpieza de imágenes antiguas (ahorra espacio)
# ✅ Graceful shutdown (30 segundos para cerrar cleanly)
# ✅ Control granular por servicio (usando labels)
# ✅ Logs completos de cada actualización
# ✅ No requiere terminal abierta (corre como servicio Docker)

# ============================================================================
# Monitoreo:
# ============================================================================
#
# Ver actualizaciones en tiempo real:
#   docker compose logs watchtower -f
#
# Ver solo actualizaciones recientes:
#   docker compose logs watchtower --tail=50 | grep "Pulling new image"
#
# Verificar servicios monitoreados:
#   docker compose ps
#   docker compose ls
#

# ============================================================================
# Notas importantes:
# ============================================================================
#
# 1. Watchtower necesita acceso a /var/run/docker.sock
#    → Por eso está mapeado en volumes
#
# 2. Las imágenes deben estar en registros accesibles (DockerHub, GitHub, etc)
#    → Watchtower las descarga automáticamente
#
# 3. Si necesitas controlar CUÁNDO actualizar:
#    → Cambia a versión fija (v2.2.3) en lugar de :latest
#    → Luego actualiza manualmente cuando lo necesites
#
# 4. Para producción con múltiples servidores:
#    → Considera usar Docker Swarm o Kubernetes
#    → Watchtower es mejor para desarrollo/testing
#

echo "✅ Watchtower está corriendo y monitoreando servicios"
echo "🔄 Próxima verificación de actualizaciones: ~60 segundos"
echo "📊 Ver logs: docker compose logs watchtower -f"
