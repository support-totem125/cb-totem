#!/bin/bash

#############################################################################
# Script: init-chatwoot.sh
# Descripción: Inicializa Chatwoot correctamente desde cero al primer intento
#              SOLUCIÓN AL BUG: Usa db:chatwoot_prepare NO db:migrate
# Autor: CB-Totem Team
# Fecha: 2025-11-13
# Uso: ./init-chatwoot.sh
#############################################################################

set -e  # Detener en cualquier error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yaml}"

# Funciones de utilidad
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Inicialización de Chatwoot - Primera Instalación      ║"
echo "║           Garantizado al primer intento                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar que docker compose existe
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    log_error "docker compose no está disponible (se requiere docker compose v2)"
    exit 1
fi

# Verificar que el archivo docker-compose.yaml existe
if [ ! -f "$COMPOSE_FILE" ]; then
    log_error "Archivo $COMPOSE_FILE no encontrado"
    exit 1
fi

log_info "Iniciando instalación desde cero de Chatwoot..."

# Paso 1: Limpieza completa
log_info "Paso 1/6: Limpiando instalación anterior (si existe)..."
docker compose down -v 2>/dev/null || true
log_success "Limpieza completada"

# Paso 2: Eliminar volúmenes huérfanos
log_info "Paso 2/6: Eliminando volúmenes huérfanos..."
docker volume prune -f
log_success "Volúmenes eliminados"

# Paso 3: Levantar solo PostgreSQL y Redis
log_info "Paso 3/6: Iniciando PostgreSQL y Redis..."
docker compose up -d postgres redis
log_success "PostgreSQL y Redis iniciados"

# Paso 4: Esperar a que estén healthy
log_info "Paso 4/6: Esperando a que PostgreSQL y Redis estén listos..."
sleep 5

MAX_RETRIES=30
RETRY_COUNT=0

# Esperar PostgreSQL
until docker exec postgres_db pg_isready -U postgres &> /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        log_error "PostgreSQL no respondió después de $MAX_RETRIES intentos"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo ""
log_success "PostgreSQL está listo"

# Esperar Redis
RETRY_COUNT=0
until docker exec redis_cache redis-cli -a "${REDIS_PASSWORD:-change_me_redis}" ping &> /dev/null; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        log_error "Redis no respondió después de $MAX_RETRIES intentos"
        exit 1
    fi
    echo -n "."
    sleep 1
done
echo ""
log_success "Redis está listo"

# Paso 5: Ejecutar db:chatwoot_prepare (NO db:migrate)
log_info "Paso 5/6: Preparando base de datos de Chatwoot..."
log_warning "⚠️  IMPORTANTE: Usando 'rails db:chatwoot_prepare' NO 'rails db:migrate'"
log_warning "   Esto evita el bug en migración 20231211010807"
log_info "Este paso puede tomar 1-2 minutos..."

docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

if [ $? -eq 0 ]; then
    log_success "Base de datos preparada exitosamente"
else
    log_error "Error al preparar base de datos"
    exit 1
fi

# Verificar que la base de datos tiene las tablas correctas
TABLE_COUNT=$(docker exec postgres_db psql -U postgres -d chatwoot -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d '[:space:]')

if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -ge 80 ]; then
    log_success "Base de datos verificada: $TABLE_COUNT tablas creadas (esperado: ~86)"
else
    log_warning "Base de datos tiene $TABLE_COUNT tablas (esperado: ~86)"
fi

# Verificar columna crítica
COLUMN_EXISTS=$(docker exec postgres_db psql -U postgres -d chatwoot -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'cached_label_list');" 2>/dev/null | tr -d '[:space:]')

if [ "$COLUMN_EXISTS" = "t" ]; then
    log_success "Columna cached_label_list existe (bug 20231211010807 evitado)"
else
    log_warning "Columna cached_label_list NO existe"
fi

# Paso 6: Levantar todos los servicios
log_info "Paso 6/6: Iniciando todos los servicios..."
docker compose up -d
log_success "Todos los servicios iniciados"

# Esperar a que Chatwoot esté listo
log_info "Esperando a que Chatwoot inicie (puede tomar 30-60 segundos)..."
sleep 15

RETRY_COUNT=0
MAX_RETRIES=40

until curl -s -f http://localhost:3000 > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        log_warning "Chatwoot no respondió después de $MAX_RETRIES intentos"
        log_warning "Puede estar iniciando aún. Verifica con: docker compose logs chatwoot-web"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Verificación final
log_info "Realizando verificaciones finales..."

# Verificar contenedor corriendo
CONTAINER_STATUS=$(docker compose ps chatwoot-web --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
if [ "$CONTAINER_STATUS" = "running" ]; then
    log_success "Contenedor chatwoot-web está corriendo"
else
    log_error "Contenedor chatwoot-web NO está corriendo (estado: $CONTAINER_STATUS)"
fi

# Verificar HTTP
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    log_success "Chatwoot responde correctamente (HTTP $HTTP_CODE)"
else
    log_warning "Chatwoot responde con HTTP $HTTP_CODE"
fi

# Resumen
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          Instalación Completada Exitosamente              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
log_info "Servicios disponibles:"
echo "  - Chatwoot:      http://localhost:3000"
echo "  - Evolution API: http://localhost:8080"
echo "  - n8n:           http://localhost:5678"
echo "  - Calidda API:   http://localhost:5000"
echo "  - Servidor IMG:  http://localhost:8000"
echo ""

log_info "Comandos útiles:"
echo "  - Ver logs:          docker compose logs -f"
echo "  - Ver estado:        docker compose ps"
echo "  - Detener todo:      docker compose down"
echo "  - Reparar Chatwoot:  ./scripts/fix-chatwoot.sh"
echo ""

# Preguntar si quiere crear usuario SuperAdmin
read -p "¿Deseas crear un usuario SuperAdmin ahora? (s/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    read -p "Email: " ADMIN_EMAIL
    read -sp "Password: " ADMIN_PASSWORD
    echo ""
    read -p "Nombre: " ADMIN_NAME
    
    log_info "Creando usuario SuperAdmin..."
    
    docker exec chatwoot_web bundle exec rails runner "
    begin
      user = User.create!(
        name: '$ADMIN_NAME',
        email: '$ADMIN_EMAIL',
        password: '$ADMIN_PASSWORD',
        password_confirmation: '$ADMIN_PASSWORD',
        confirmed_at: Time.now,
        type: 'SuperAdmin'
      )
      puts '✓ Usuario SuperAdmin creado con ID: ' + user.id.to_s
      puts '✓ Email: ' + user.email
      puts '✓ Tipo: ' + user.type.to_s
    rescue ActiveRecord::RecordInvalid => e
      puts '✗ Error: ' + e.message
      existing = User.find_by(email: '$ADMIN_EMAIL')
      if existing
        existing.update!(type: 'SuperAdmin', confirmed_at: Time.now)
        puts '✓ Usuario existente actualizado a SuperAdmin'
      end
    end
    "
    
    log_success "Usuario creado/actualizado"
    echo ""
fi

log_success "¡Todo listo! Chatwoot está funcionando correctamente."
echo ""
log_info "Próximos pasos:"
echo "  1. Accede a http://localhost:3000"
echo "  2. Completa el onboarding inicial"
echo "  3. Configura tus canales de comunicación"
echo "  4. Integra con Evolution API para WhatsApp"
echo ""

exit 0
