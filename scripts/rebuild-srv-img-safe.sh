#!/bin/bash

################################################################################
# Script de Reconstrucción Segura de srv-img
# Uso: ./scripts/rebuild-srv-img-safe.sh
#
# Este script implementa la estrategia de protección completa:
# 1. Verifica estado actual del contenedor
# 2. Hace backup de la BD desde el volumen Docker
# 3. Detiene el contenedor srv-img
# 4. Reconstruye la imagen sin caché
# 5. Reinicia el contenedor
# 6. Verifica que la BD está intacta
#
# La BD se preserva automáticamente en el volumen persistente srv_img_data
################################################################################

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     SCRIPT DE RECONSTRUCCIÓN SEGURA: srv-img                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

# Funciones auxiliares
print_step() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yaml" ]; then
    print_error "docker-compose.yaml no encontrado"
    echo "Por favor, ejecuta este script desde la raíz del proyecto"
    exit 1
fi

# Variables
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups/srv-img"
CONTAINER_NAME="srv_img"
VOLUME_NAME="cb-totem_srv_img_data"

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

print_step "Paso 1: Verificando estado del contenedor..."
if docker compose ps $CONTAINER_NAME | grep -q "Up"; then
    print_success "Contenedor $CONTAINER_NAME está corriendo"
    CONTAINER_WAS_RUNNING=true
else
    print_warning "Contenedor $CONTAINER_NAME no está corriendo"
    CONTAINER_WAS_RUNNING=false
fi

# Obtener ruta del volumen Docker
print_step "Paso 2: Obteniendo información del volumen Docker..."
VOLUME_PATH=$(docker volume inspect "$VOLUME_NAME" --format='{{.Mountpoint}}' 2>/dev/null || echo "")

if [ -z "$VOLUME_PATH" ]; then
    print_warning "No se pudo obtener la ruta del volumen $VOLUME_NAME"
    print_warning "El volumen será creado automáticamente en el próximo start"
else
    print_success "Ruta del volumen: $VOLUME_PATH"
    
    # Hacer backup si la BD existe
    if [ -f "$VOLUME_PATH/catalogos.db" ]; then
        print_step "Paso 3: Creando backup de la base de datos..."
        BACKUP_PATH="$BACKUP_DIR/catalogos_${TIMESTAMP}.db"
        
        sudo cp "$VOLUME_PATH/catalogos.db" "$BACKUP_PATH"
        sudo chown $(id -u):$(id -g) "$BACKUP_PATH"
        
        BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
        print_success "Backup creado: $(basename $BACKUP_PATH) ($BACKUP_SIZE)"
        
        # Guardar referencia del último backup
        echo "$BACKUP_PATH" > "$BACKUP_DIR/LATEST"
        
        # Guardar información del backup
        DB_SIZE_BEFORE=$(du -h "$VOLUME_PATH/catalogos.db" | cut -f1)
        echo "Tamaño antes: $DB_SIZE_BEFORE" >> "$BACKUP_DIR/LATEST_INFO.txt"
        echo "Timestamp: $TIMESTAMP" >> "$BACKUP_DIR/LATEST_INFO.txt"
        
    else
        print_warning "No existe base de datos en el volumen (primer inicio)"
    fi
fi

# Detener contenedor
if [ "$CONTAINER_WAS_RUNNING" = true ]; then
    print_step "Paso 4: Deteniendo contenedor $CONTAINER_NAME..."
    docker compose stop $CONTAINER_NAME
    print_success "Contenedor detenido"
fi

# Reconstruir imagen
print_step "Paso 5: Reconstruyendo imagen Docker (sin caché)..."
echo "Esto puede tomar algunos minutos la primera vez..."
if docker compose build --no-cache $CONTAINER_NAME; then
    print_success "Imagen reconstruida exitosamente"
else
    print_error "Error al reconstruir la imagen"
    exit 1
fi

# Iniciar contenedor
print_step "Paso 6: Iniciando contenedor..."
docker compose up -d $CONTAINER_NAME
print_success "Contenedor iniciado"

# Esperar a que el contenedor esté listo
print_step "Paso 7: Esperando a que el contenedor esté listo..."
sleep 3
for i in {1..30}; do
    if docker compose ps $CONTAINER_NAME | grep -q "healthy"; then
        print_success "Contenedor está healthy"
        break
    elif docker compose ps $CONTAINER_NAME | grep -q "Up"; then
        echo -n "."
        sleep 1
    else
        print_error "El contenedor no está respondiendo"
        exit 1
    fi
done

# Verificar que la BD está intacta
print_step "Paso 8: Verificando integridad de la base de datos..."
sleep 2

if [ ! -z "$VOLUME_PATH" ] && [ -f "$VOLUME_PATH/catalogos.db" ]; then
    DB_SIZE_AFTER=$(du -h "$VOLUME_PATH/catalogos.db" | cut -f1)
    print_success "Base de datos está presente en el volumen"
    print_success "Tamaño: $DB_SIZE_AFTER"
    
    # Verificar que el archivo es válido
    if sqlite3 "$VOLUME_PATH/catalogos.db" ".tables" &>/dev/null; then
        print_success "Base de datos es válida (verificación SQLite OK)"
    else
        print_warning "No se pudo verificar la integridad de la BD"
    fi
else
    print_warning "Base de datos no existe aún (primera ejecución)"
fi

# Verificar acceso a la API
print_step "Paso 9: Verificando acceso a la API..."
if curl -s http://localhost:8000/ &>/dev/null; then
    print_success "API respondiendo correctamente"
else
    print_warning "API aún no está disponible (espera un momento)"
fi

# Resumen final
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✓ RECONSTRUCCIÓN COMPLETADA EXITOSAMENTE                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BLUE}📊 Resumen:${NC}"
echo "  • Contenedor: $CONTAINER_NAME"
echo "  • Imagen: cb-totem-srv-img"
echo "  • Volumen: $VOLUME_NAME"
echo "  • Timestamp: $TIMESTAMP"

if [ -f "$BACKUP_DIR/LATEST" ]; then
    echo -e "\n${BLUE}💾 Backup guardado:${NC}"
    echo "  $(cat $BACKUP_DIR/LATEST)"
fi

echo -e "\n${BLUE}📍 Comandos útiles:${NC}"
echo "  • Ver logs: docker compose logs srv-img -f"
echo "  • Ver estado: docker compose ps srv-img"
echo "  • Restaurar BD: python srv-img-totem/scripts/sqlite/restore_database.py"
echo "  • Ver API: curl http://localhost:8000/"

echo ""
print_success "El servicio está listo para usar"
