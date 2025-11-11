#!/bin/bash

################################################################################
#                                                                              #
#  DIAGNOSE.SH - Diagnóstico completo del servidor                           #
#                                                                              #
#  Ejecuta este script en tu servidor para identificar problemas              #
#                                                                              #
#  USO:                                                                       #
#    ./scripts/diagnose.sh                                                   #
#                                                                              #
################################################################################

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔍 DIAGNÓSTICO DEL SERVIDOR - chat-bot-totem                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# 1. VERIFICAR DOCKER
# ============================================================================

echo -e "${YELLOW}📦 VERIFICANDO DOCKER...${NC}"
echo ""

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker NO está instalado${NC}"
else
    echo -e "${GREEN}✓ Docker está instalado${NC}"
    docker --version
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}✗ Docker Compose NO está instalado${NC}"
else
    echo -e "${GREEN}✓ Docker Compose está instalado${NC}"
    docker-compose --version
fi

echo ""

# ============================================================================
# 2. VERIFICAR SERVICIOS CORRIENDO
# ============================================================================

echo -e "${YELLOW}🚀 ESTADO DE SERVICIOS...${NC}"
echo ""

docker-compose ps

echo ""

# ============================================================================
# 3. VERIFICAR CONFIGURACIÓN .env
# ============================================================================

echo -e "${YELLOW}⚙️  CONFIGURACIÓN .env CRÍTICA...${NC}"
echo ""

if [[ ! -f ".env" ]]; then
    echo -e "${RED}✗ No encontré .env${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Archivo .env encontrado${NC}"
echo ""

# Variables críticas
check_env() {
    local var=$1
    local value=$(grep "^${var}=" .env | cut -d= -f2- || echo "NO ENCONTRADA")
    printf "  %-30s = %s\n" "${var}" "${value}"
}

check_env "DOMAIN_HOST"
check_env "N8N_HOST"
check_env "N8N_WEBHOOK_URL"
check_env "POSTGRES_PASSWORD"
check_env "REDIS_PASSWORD"

echo ""

# ============================================================================
# 4. VERIFICAR CONECTIVIDAD N8N
# ============================================================================

echo -e "${YELLOW}🌐 CONECTIVIDAD N8N...${NC}"
echo ""

N8N_URL="http://localhost:5678"

if curl -s --connect-timeout 5 "$N8N_URL" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ N8N accesible en $N8N_URL${NC}"
else
    echo -e "${RED}✗ N8N NO accesible en $N8N_URL${NC}"
    echo "  Intenta: docker-compose logs n8n"
fi

echo ""

# ============================================================================
# 5. VERIFICAR WEBHOOKS N8N
# ============================================================================

echo -e "${YELLOW}🔗 WEBHOOKS EN N8N...${NC}"
echo ""

# Este comando obtiene los webhooks de N8N (requiere acceso a la API)
echo "Para verificar webhooks, accede a: http://localhost:5678"
echo "Abre tu workflow 'chat-bot-fnb'"
echo "Verifica el nodo 'Recibir Mensaje'"

echo ""

# ============================================================================
# 6. LOGS DE SERVICIOS
# ============================================================================

echo -e "${YELLOW}📋 ÚLTIMOS ERRORES EN LOGS...${NC}"
echo ""

echo "N8N (últimas 10 líneas):"
docker-compose logs --tail 10 n8n 2>/dev/null | tail -5 || echo "  (Sin logs)"

echo ""
echo "PostgreSQL (últimas 10 líneas):"
docker-compose logs --tail 10 postgres 2>/dev/null | tail -5 || echo "  (Sin logs)"

echo ""

# ============================================================================
# 7. INFORMACIÓN DE RED
# ============================================================================

echo -e "${YELLOW}🌍 INFORMACIÓN DE RED...${NC}"
echo ""

echo "IP del servidor:"
hostname -I || echo "  No disponible"

echo ""
echo "Localhost resuelve a:"
ping -c 1 localhost 2>/dev/null | head -1 || echo "  No disponible"

echo ""

# ============================================================================
# 8. RECOMENDACIONES
# ============================================================================

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}💡 RECOMENDACIONES DE DIAGNÓSTICO:${NC}"
echo ""

echo "1. Si N8N NO es accesible:"
echo "   docker-compose restart n8n"
echo "   docker-compose logs n8n"
echo ""

echo "2. Si los webhooks siguen siendo /webhook-test/:"
echo "   docker-compose exec n8n curl http://localhost:5678/"
echo ""

echo "3. Si Evolution API no envía mensajes:"
echo "   docker-compose logs evolution-api"
echo "   Verifica que el webhook esté registrado en Evolution API"
echo ""

echo "4. Compara con tu VM local:"
echo "   grep 'N8N_WEBHOOK_URL' .env"
echo "   Debe ser: N8N_WEBHOOK_URL=http://localhost:5678/"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
