#!/bin/bash
#
# Script de verificación post-actualización
# Ejecuta este script para verificar que todo está correcto
#

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   VERIFICACIÓN POST-ACTUALIZACIÓN DEL PROYECTO             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones
check_file() {
    local file=$1
    local description=$2
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} ${description}: ${file}"
    else
        echo -e "${RED}❌${NC} ${description}: ${file} (NO ENCONTRADO)"
        return 1
    fi
}

check_variable() {
    local var=$1
    local file=".env"
    if grep -q "^${var}=" "$file"; then
        echo -e "${GREEN}✅${NC} Variable ${BLUE}${var}${NC} definida en .env"
    else
        echo -e "${RED}❌${NC} Variable ${BLUE}${var}${NC} NO definida en .env"
        return 1
    fi
}

echo ""
echo "📁 Verificando archivos críticos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_file "docker-compose.yaml" "Docker Compose"
check_file ".env" "Archivo de configuración"
check_file "scripts/init-chatwoot.sh" "Script de inicialización de Chatwoot"
check_file "INSTALLATION_GUIDE.md" "Guía de instalación"
check_file "CHANGES_SUMMARY.md" "Resumen de cambios"

echo ""
echo "🔧 Verificando configuración en .env..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_variable "DOMAIN_HOST"
check_variable "SERVER_IP_ADDR"
check_variable "POSTGRES_PASSWORD"
check_variable "REDIS_PASSWORD"
check_variable "CHATWOOT_SECRET_KEY_BASE"

echo ""
echo "🐳 Verificando cambios en docker-compose.yaml..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar que NO haya rutas hardcodeadas en volumenes
if grep -q "/home/admin/Documents/chat-bot-totem" docker-compose.yaml; then
    echo -e "${RED}❌${NC} Aún hay rutas hardcodeadas en docker-compose.yaml"
    echo "   Busca: /home/admin/Documents/chat-bot-totem"
    return 1
else
    echo -e "${GREEN}✅${NC} No hay rutas hardcodeadas"
fi

# Verificar que init-chatwoot.sh está en chatwoot-web
if grep -q "init-chatwoot.sh" docker-compose.yaml; then
    echo -e "${GREEN}✅${NC} Script de inicialización montado en Chatwoot"
else
    echo -e "${RED}❌${NC} Script de inicialización NO está en Chatwoot"
    return 1
fi

# Verificar rutas relativas
if grep -q "\./vcc-totem" docker-compose.yaml && grep -q "\./srv-img-totem" docker-compose.yaml; then
    echo -e "${GREEN}✅${NC} Se usan rutas relativas correctas"
else
    echo -e "${RED}❌${NC} No se usan rutas relativas"
    return 1
fi

echo ""
echo "🌐 Verificando variables de dominio..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q '\${DOMAIN_HOST' docker-compose.yaml; then
    echo -e "${GREEN}✅${NC} Variables de dominio se usan en docker-compose.yaml"
else
    echo -e "${YELLOW}⚠️${NC}  No se encontraron variables \${DOMAIN_HOST} en docker-compose.yaml"
fi

echo ""
echo "📋 Cambios principales aplicados:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. ✅ Rutas absolutas → Rutas relativas"
echo "  2. ✅ URLs hardcodeadas → Variables DOMAIN_HOST"
echo "  3. ✅ Script de inicialización de Chatwoot"
echo "  4. ✅ Variables DOMAIN_HOST y SERVER_IP_ADDR"
echo "  5. ✅ Documentación completa (INSTALLATION_GUIDE.md)"

echo ""
echo "📚 Próximos pasos:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  LEER la guía de instalación:"
echo "   ${BLUE}cat INSTALLATION_GUIDE.md${NC}"
echo ""
echo "2️⃣  EDITAR el archivo .env con tus valores:"
echo "   ${BLUE}nano .env${NC}"
echo "   - DOMAIN_HOST (tu dominio o IP)"
echo "   - POSTGRES_PASSWORD"
echo "   - REDIS_PASSWORD"
echo "   - Contraseñas de Chatwoot y N8N"
echo ""
echo "3️⃣  INICIAR los servicios:"
echo "   ${BLUE}docker-compose up -d${NC}"
echo ""
echo "4️⃣  VERIFICAR que todo funciona:"
echo "   ${BLUE}docker-compose ps${NC}"
echo "   ${BLUE}docker-compose logs chatwoot-web${NC}"
echo ""
echo "5️⃣  ACCEDER a los servicios:"
echo "   - Chatwoot:  http://\${DOMAIN_HOST}:3000"
echo "   - n8n:       http://\${DOMAIN_HOST}:5678"
echo "   - Evolution: http://\${DOMAIN_HOST}:8080"
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   ✨ ¡VERIFICACIÓN COMPLETADA EXITOSAMENTE! ✨             ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
