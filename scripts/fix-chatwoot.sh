#!/bin/bash

#############################################################################
# Script: fix-chatwoot.sh
# Descripción: Repara la instalación fallida de Chatwoot aplicando workaround
#              para el bug de migración 20231211010807
# Autor: CB-Totem Team
# Fecha: 2025-01-16
# Uso: ./fix-chatwoot.sh
#############################################################################

set -e  # Detener en cualquier error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_DB="${POSTGRES_DB:-chatwoot}"
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
echo "║         Chatwoot Migration Fix Script v1.0                ║"
echo "║         Fixing bug in migration 20231211010807            ║"
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

log_info "Iniciando proceso de reparación..."

# Paso 1: Detener servicios
log_info "Paso 1/6: Deteniendo servicios de Chatwoot..."
docker compose down
log_success "Servicios detenidos"

# Paso 2: Iniciar solo PostgreSQL
log_info "Paso 2/6: Iniciando PostgreSQL..."
docker compose up -d postgres
log_success "PostgreSQL iniciado"

# Esperar a que PostgreSQL esté listo
log_info "Esperando a que PostgreSQL esté listo..."
sleep 5

MAX_RETRIES=30
RETRY_COUNT=0
until docker exec postgres_db pg_isready -U "$POSTGRES_USER" &> /dev/null; do
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

# Paso 3: Verificar si la base de datos existe
log_info "Paso 3/6: Verificando base de datos..."
DB_EXISTS=$(docker exec postgres_db psql -U "$POSTGRES_USER" -t -c "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DB';" | tr -d '[:space:]')

if [ "$DB_EXISTS" != "1" ]; then
    log_warning "Base de datos '$POSTGRES_DB' no existe, creándola..."
    docker exec postgres_db psql -U "$POSTGRES_USER" -c "CREATE DATABASE $POSTGRES_DB;"
    log_success "Base de datos creada"
else
    log_success "Base de datos existe"
fi

# Paso 4: Verificar si la tabla conversations existe
log_info "Paso 4/6: Verificando tabla conversations..."
TABLE_EXISTS=$(docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'conversations');" | tr -d '[:space:]')

if [ "$TABLE_EXISTS" = "t" ]; then
    log_success "Tabla conversations existe"
    
    # Verificar si la columna cached_label_list ya existe
    COLUMN_EXISTS=$(docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'cached_label_list');" | tr -d '[:space:]')
    
    if [ "$COLUMN_EXISTS" = "t" ]; then
        log_warning "Columna cached_label_list ya existe, omitiendo..."
    else
        log_info "Agregando columna cached_label_list..."
        docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER TABLE conversations ADD COLUMN cached_label_list VARCHAR;"
        log_success "Columna agregada"
    fi
    
    # Verificar si la migración ya está marcada como completada
    MIGRATION_EXISTS=$(docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = '20231211010807');" | tr -d '[:space:]')
    
    if [ "$MIGRATION_EXISTS" = "t" ]; then
        log_warning "Migración 20231211010807 ya marcada como completada"
    else
        log_info "Marcando migración 20231211010807 como completada..."
        docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "INSERT INTO schema_migrations (version) VALUES ('20231211010807');"
        log_success "Migración marcada como completada"
    fi
else
    log_warning "Tabla conversations no existe. La base de datos necesita inicialización completa."
    log_info "Ejecutando db:chatwoot_prepare..."
    
    # Si la tabla no existe, usar el método oficial
    docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare
    log_success "Base de datos inicializada"
fi

# Paso 5: Ejecutar migraciones restantes
log_info "Paso 5/6: Ejecutando migraciones restantes..."
docker compose run --rm chatwoot-web bundle exec rails db:migrate
log_success "Migraciones completadas"

# Paso 6: Iniciar todos los servicios
log_info "Paso 6/6: Iniciando todos los servicios..."
docker compose up -d
log_success "Servicios iniciados"

# Esperar a que Chatwoot esté listo
log_info "Esperando a que Chatwoot inicie..."
sleep 10

# Verificaciones finales
echo ""
log_info "Realizando verificaciones finales..."

# Verificar contenedor corriendo
CONTAINER_STATUS=$(docker compose ps chatwoot-web --format json 2>/dev/null | jq -r '.State' 2>/dev/null || echo "unknown")
if [ "$CONTAINER_STATUS" = "running" ]; then
    log_success "Contenedor chatwoot-web está corriendo"
else
    log_error "Contenedor chatwoot-web NO está corriendo (estado: $CONTAINER_STATUS)"
    log_info "Revisa los logs con: docker compose logs chatwoot-web"
fi

# Verificar número de tablas
TABLE_COUNT=$(docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d '[:space:]')
if [ "$TABLE_COUNT" -ge 80 ]; then
    log_success "Base de datos tiene $TABLE_COUNT tablas (esperado: ~86)"
else
    log_warning "Base de datos solo tiene $TABLE_COUNT tablas (esperado: ~86)"
fi

# Verificar columna cached_label_list
COLUMN_TYPE=$(docker exec postgres_db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "SELECT data_type FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'cached_label_list';" | tr -d '[:space:]')
if [ -n "$COLUMN_TYPE" ]; then
    log_success "Columna cached_label_list existe (tipo: $COLUMN_TYPE)"
else
    log_error "Columna cached_label_list NO existe"
fi

# Verificar HTTP
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    log_success "Chatwoot responde correctamente (HTTP $HTTP_CODE)"
else
    log_warning "Chatwoot responde con HTTP $HTTP_CODE (esperado: 200)"
fi

# Resumen
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  Reparación Completada                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
log_info "Comandos útiles:"
echo "  - Ver logs:          docker compose logs -f chatwoot-web"
echo "  - Ver estado:        docker compose ps"
echo "  - Reiniciar:         docker compose restart chatwoot-web"
echo "  - Acceder a Rails:   docker exec -it chatwoot_web bundle exec rails console"
echo ""

log_info "Accede a Chatwoot en: http://localhost:3000"
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

log_success "¡Todo listo! Chatwoot debería estar funcionando correctamente."

exit 0
