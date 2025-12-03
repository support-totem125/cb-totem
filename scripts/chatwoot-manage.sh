#!/bin/bash

# =========================================
# Script para buscar y asignar labels
# en conversaciones de Chatwoot
# =========================================

CHATWOOT_HOST=${CHATWOOT_HOST:-192.168.5.25}
CHATWOOT_PORT=${CHATWOOT_PORT:-3000}
CHATWOOT_BASE_URL="http://${CHATWOOT_HOST}:${CHATWOOT_PORT}"
ACCOUNT_ID=${ACCOUNT_ID:-1}
API_TOKEN=${API_TOKEN:-"3LRrbzKNxPSstkP2jTUq6Gtn"}

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==========================================
# Función: Listar conversaciones por teléfono
# ==========================================
list_phones() {
    echo -e "${BLUE}📞 CONVERSACIONES CON NÚMEROS DE TELÉFONO${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.data.payload[]? | "\(.id)\t| \(.meta.sender.phone_number // "N/A")\t| \(.meta.sender.name // "N/A")\t| \(.status)\t| Labels: \((.labels // [] | join(", ")) // "Sin labels")"' | column -t -s $'\t'
}

# ==========================================
# Función: Asignar label a conversación
# ==========================================
assign_label() {
    local conv_id=$1
    local label=$2
    
    if [ -z "$conv_id" ] || [ -z "$label" ]; then
        echo -e "${RED}Uso: assign <conversation_id> <label_name>${NC}"
        echo -e "${YELLOW}Ejemplo: ./chatwoot-manage.sh assign 80 en_productos${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Asignando label '${label}' a conversación ${conv_id}...${NC}"
    
    response=$(curl -s -X POST \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"labels\": [\"${label}\"]}")
    
    if echo "$response" | jq -e '.payload' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Label '${label}' asignado a conversación ${conv_id}${NC}"
        echo "$response" | jq '.payload'
    else
        echo -e "${RED}❌ Error asignando label${NC}"
        echo "$response" | jq '.'
    fi
}

# ==========================================
# Función: Buscar por teléfono y asignar label
# ==========================================
search_and_assign() {
    local phone=$1
    local label=$2
    
    if [ -z "$phone" ] || [ -z "$label" ]; then
        echo -e "${RED}Uso: search-assign <phone_number> <label_name>${NC}"
        echo -e "${YELLOW}Ejemplo: ./chatwoot-manage.sh search-assign +51995370009 en_productos${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 Buscando conversación con número: ${phone}${NC}"
    
    conv_data=$(curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq ".data.payload[]? | select(.meta.sender.phone_number == \"${phone}\")")
    
    if [ -z "$conv_data" ] || [ "$conv_data" == "null" ]; then
        echo -e "${RED}❌ No se encontró conversación con el número: ${phone}${NC}"
        return 1
    fi
    
    conv_id=$(echo "$conv_data" | jq '.id')
    conv_name=$(echo "$conv_data" | jq -r '.meta.sender.name')
    
    echo -e "${GREEN}✓ Conversación encontrada: ID ${conv_id} - ${conv_name}${NC}\n"
    
    # Asignar label
    assign_label "$conv_id" "$label"
}

# ==========================================
# Función: Ver detalles de conversación
# ==========================================
conversation_details() {
    local conv_id=$1
    
    if [ -z "$conv_id" ]; then
        echo -e "${RED}Uso: details <conversation_id>${NC}"
        echo -e "${YELLOW}Ejemplo: ./chatwoot-manage.sh details 80${NC}"
        return 1
    fi
    
    echo -e "${BLUE}💬 DETALLES CONVERSACIÓN #${conv_id}${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '{
        id,
        display_id,
        contact_name: .meta.sender.name,
        phone: .meta.sender.phone_number,
        status,
        labels,
        messages_count: (.messages | length),
        created_at,
        updated_at
    }'
}

# ==========================================
# Función: Remover label
# ==========================================
remove_label() {
    local conv_id=$1
    local label=$2
    
    if [ -z "$conv_id" ] || [ -z "$label" ]; then
        echo -e "${RED}Uso: remove <conversation_id> <label_name>${NC}"
        echo -e "${YELLOW}Ejemplo: ./chatwoot-manage.sh remove 80 en_productos${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Removiendo label '${label}' de conversación ${conv_id}...${NC}"
    
    curl -s -X DELETE \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}/labels/${label}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# ==========================================
# Función: Listar labels disponibles
# ==========================================
list_labels() {
    echo -e "${BLUE}🏷️  LABELS DISPONIBLES${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.payload[]? | "ID: \(.id) | Nombre: \(.title) | Color: \(.color)"' | column -t -s '|'
}

# ==========================================
# Función: Ayuda
# ==========================================
show_help() {
    cat << EOF
${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}
${BLUE}║    Chatwoot - Gestión de Conversaciones y Labels             ║${NC}
${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}

${YELLOW}COMANDOS:${NC}

  ${GREEN}list${NC}
    Listar todas las conversaciones con teléfono
    
    Ejemplo:
      ./chatwoot-manage.sh list

  ${GREEN}labels${NC}
    Listar todos los labels disponibles
    
    Ejemplo:
      ./chatwoot-manage.sh labels

  ${GREEN}details${NC} <conversation_id>
    Ver detalles de una conversación específica
    
    Ejemplo:
      ./chatwoot-manage.sh details 80

  ${GREEN}assign${NC} <conversation_id> <label_name>
    Asignar un label a una conversación por ID
    
    Ejemplo:
      ./chatwoot-manage.sh assign 80 en_productos

  ${GREEN}search-assign${NC} <phone_number> <label_name>
    Buscar conversación por teléfono y asignar label
    
    Ejemplo:
      ./chatwoot-manage.sh search-assign +51995370009 en_productos

  ${GREEN}remove${NC} <conversation_id> <label_name>
    Remover un label de una conversación
    
    Ejemplo:
      ./chatwoot-manage.sh remove 80 en_productos

${YELLOW}EJEMPLOS PRÁCTICOS:${NC}

  # Ver todas las conversaciones con teléfono
  ./chatwoot-manage.sh list

  # Ver labels disponibles
  ./chatwoot-manage.sh labels

  # Ver detalles de conversación ID 80
  ./chatwoot-manage.sh details 80

  # Asignar label "en_productos" a conversación 80
  ./chatwoot-manage.sh assign 80 en_productos

  # Buscar por teléfono +51995370009 y asignar label
  ./chatwoot-manage.sh search-assign +51995370009 en_productos

  # Buscar por teléfono +51919284799 y asignar label
  ./chatwoot-manage.sh search-assign +51919284799 en_productos

  # Remover label de conversación 80
  ./chatwoot-manage.sh remove 80 en_productos

${YELLOW}TELÉFONOS DISPONIBLES:${NC}

  +51995370009 (Diego Moscaiza Anampa) - ID 80
  +51919284799 (Soporte Téc. Sei Totem) - ID 82 y 33

${GREEN}✓ Token: ${API_TOKEN:0:15}...${NC}
${GREEN}✓ URL: ${CHATWOOT_BASE_URL}${NC}

EOF
}

# ==========================================
# Main
# ==========================================
main() {
    case "${1:-help}" in
        list)
            list_phones
            ;;
        labels)
            list_labels
            ;;
        details)
            conversation_details "$2"
            ;;
        assign)
            assign_label "$2" "$3"
            ;;
        search-assign)
            search_and_assign "$2" "$3"
            ;;
        remove)
            remove_label "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconocido: $1${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
