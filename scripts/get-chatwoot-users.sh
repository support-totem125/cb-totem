#!/bin/bash

# =========================================
# Script para obtener usuarios de Chatwoot
# y sus labels asociados
# =========================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Obteniendo datos de Chatwoot${NC}"
echo -e "${BLUE}========================================${NC}"

# Verificar si Docker está corriendo
if ! docker compose ps chatwoot-web | grep -q "Up"; then
    echo -e "${RED}❌ Error: Chatwoot no está corriendo${NC}"
    echo -e "${YELLOW}Inicia los servicios con: docker compose up -d${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Chatwoot está activo${NC}\n"

# Función para ejecutar queries en PostgreSQL
run_psql() {
    docker exec -i postgres_db psql -U postgres -d chatwoot -c "$1"
}

# 1. Obtener usuarios
echo -e "${BLUE}1️⃣  USUARIOS EN CHATWOOT${NC}"
echo -e "${YELLOW}══════════════════════${NC}\n"

run_psql "
SELECT 
    id,
    name,
    email,
    type as rol,
    confirmed_at IS NOT NULL as confirmado,
    created_at
FROM users
ORDER BY id;
"

echo ""

# 2. Obtener estadísticas de usuarios
echo -e "${BLUE}2️⃣  ESTADÍSTICAS DE USUARIOS${NC}"
echo -e "${YELLOW}════════════════════════════${NC}\n"

run_psql "
SELECT 
    type as rol,
    COUNT(*) as cantidad,
    STRING_AGG(name, ', ') as usuarios
FROM users
GROUP BY type
ORDER BY type;
"

echo ""

# 3. Obtener labels disponibles
echo -e "${BLUE}3️⃣  LABELS (ETIQUETAS) DISPONIBLES${NC}"
echo -e "${YELLOW}════════════════════════════════${NC}\n"

run_psql "
SELECT 
    id,
    title,
    description,
    color,
    account_id,
    created_at
FROM labels
ORDER BY title;
"

echo ""

# 4. Obtener contactos y sus labels
echo -e "${BLUE}4️⃣  CONTACTOS CON LABELS${NC}"
echo -e "${YELLOW}═════════════════════════${NC}\n"

run_psql "
SELECT 
    c.id as contacto_id,
    c.name as contacto_nombre,
    c.phone_number,
    STRING_AGG(l.title, ', ') as labels
FROM contacts c
LEFT JOIN taggings t ON c.id = t.taggable_id AND t.taggable_type = 'Contact'
LEFT JOIN tags tag ON t.tag_id = tag.id
LEFT JOIN labels l ON tag.id = l.tag_id
GROUP BY c.id, c.name, c.phone_number
ORDER BY c.name;
"

echo ""

# 5. Obtener conversaciones y sus labels
echo -e "${BLUE}5️⃣  CONVERSACIONES CON LABELS${NC}"
echo -e "${YELLOW}═══════════════════════════════${NC}\n"

run_psql "
SELECT 
    conv.id as conversacion_id,
    conv.display_id,
    c.name as contacto,
    a.name as agente,
    conv.status,
    STRING_AGG(DISTINCT l.title, ', ') as labels,
    conv.created_at
FROM conversations conv
LEFT JOIN contacts c ON conv.contact_id = c.id
LEFT JOIN users a ON conv.assignee_id = a.id
LEFT JOIN taggings t ON conv.id = t.taggable_id AND t.taggable_type = 'Conversation'
LEFT JOIN tags tag ON t.tag_id = tag.id
LEFT JOIN labels l ON tag.id = l.tag_id
GROUP BY conv.id, c.name, a.name, conv.status, conv.created_at
ORDER BY conv.created_at DESC
LIMIT 20;
"

echo ""

# 6. Resumen general
echo -e "${BLUE}6️⃣  RESUMEN GENERAL${NC}"
echo -e "${YELLOW}══════════════════${NC}\n"

echo -e "${GREEN}Total de usuarios:${NC}"
run_psql "SELECT COUNT(*) FROM users;"

echo -e "${GREEN}Total de contactos:${NC}"
run_psql "SELECT COUNT(*) FROM contacts;"

echo -e "${GREEN}Total de conversaciones:${NC}"
run_psql "SELECT COUNT(*) FROM conversations;"

echo -e "${GREEN}Total de labels:${NC}"
run_psql "SELECT COUNT(*) FROM labels;"

echo ""
echo -e "${GREEN}✓ Reporte completado${NC}"
echo -e "${BLUE}========================================${NC}"
