#!/bin/bash
# Script de backup de datos de srv-img ANTES de reconstruir la imagen
# Uso: ./scripts/backup-srv-img-before-rebuild.sh
# Esto asegura que nunca pierdes los datos si algo sale mal

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups/srv-img"
DB_FILE="/var/lib/docker/volumes/cb-totem_srv_img_data/_data/catalogos.db"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando backup de datos de srv-img..."
echo "⏰ Timestamp: $TIMESTAMP"

# Verificar que el volumen existe
if [ ! -f "$DB_FILE" ]; then
    echo "⚠️  No se encontró la base de datos en el volumen"
    echo "   Ruta esperada: $DB_FILE"
    exit 0
fi

# Hacer backup de la base de datos
BACKUP_PATH="$BACKUP_DIR/catalogos_${TIMESTAMP}.db.backup"
sudo cp "$DB_FILE" "$BACKUP_PATH"
sudo chown $(id -u):$(id -g) "$BACKUP_PATH"

echo "✅ Backup guardado en: $BACKUP_PATH"
echo "📊 Tamaño: $(du -h "$BACKUP_PATH" | cut -f1)"

# Crear archivo de reference para saber cuál es el más reciente
echo "$BACKUP_PATH" > "$BACKUP_DIR/LATEST"
echo "🔗 Referencia actualizada: $(cat $BACKUP_DIR/LATEST)"

echo ""
echo "✓ Backup completado exitosamente"
echo "  Ahora es seguro reconstruir la imagen con:"
echo "  docker compose build --no-cache srv-img"
echo "  docker compose up -d srv-img"
