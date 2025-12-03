#!/bin/bash

# =========================================
# Script simplificado para gestionar labels
# en Chatwoot via API REST
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
# Función: Listar conversaciones resumen
# ==========================================
list_conversations() {
    echo -e "${BLUE}📋 CONVERSACIONES RECIENTES${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.payload[]? | "\(.id)\t| \(.contact.name // "N/A")\t| \(.status)\t| Labels: \((.labels // [] | join(", ")) // "Sin labels")"' | column -t -s $'\t'
}

# ==========================================
# Función: Asignar label a conversación
# ==========================================
assign_label() {
    local conv_id=$1
    local label=$2
    
    if [ -z "$conv_id" ] || [ -z "$label" ]; then
        echo -e "${RED}Uso: assign_label <conversation_id> <label_name>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Asignando label '${label}' a conversación ${conv_id}...${NC}"
    
    response=$(curl -s -X POST \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"labels\": [\"${label}\"]}")
    
    echo "$response" | jq '.'
    
    if echo "$response" | jq -e '.payload' > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Label asignado correctamente${NC}"
    else
        echo -e "${RED}❌ Error asignando label${NC}"
    fi
}

# ==========================================
# Función: Remover label de conversación
# ==========================================
remove_label() {
    local conv_id=$1
    local label=$2
    
    if [ -z "$conv_id" ] || [ -z "$label" ]; then
        echo -e "${RED}Uso: remove_label <conversation_id> <label_name>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Removiendo label '${label}' de conversación ${conv_id}...${NC}"
    
    curl -s -X DELETE \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}/labels/${label}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# ==========================================
# Función: Ver labels disponibles
# ==========================================
list_labels() {
    echo -e "${BLUE}🏷️  LABELS DISPONIBLES${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.payload[] | "ID: \(.id) | Nombre: \(.title) | Color: \(.color)"' | column -t -s '|'
}

# ==========================================
# Función: Ver detalles de una conversación
# ==========================================
conversation_details() {
    local conv_id=$1
    
    if [ -z "$conv_id" ]; then
        echo -e "${RED}Uso: details <conversation_id>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}💬 DETALLES CONVERSACIÓN #${conv_id}${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conv_id}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '{
        id,
        display_id,
        contact: .contact.name,
        status,
        labels,
        messages_count: (.messages | length),
        created_at,
        updated_at
    }'
}

# ==========================================
# Función: Ayuda
# ==========================================
show_help() {
    cat << EOF
${BLUE}╔══════════════════════════════════════════════════════╗${NC}
${BLUE}║    Chatwoot API - Gestión de Labels en Conversaciones  ║${NC}
${BLUE}╚══════════════════════════════════════════════════════╝${NC}

${YELLOW}COMANDOS:${NC}

  ${GREEN}list${NC}
    Listar todas las conversaciones
    
    Ejemplo:
      ./chatwoot-labels.sh list

  ${GREEN}labels${NC}
    Listar todos los labels disponibles
    
    Ejemplo:
      ./chatwoot-labels.sh labels

  ${GREEN}details${NC} <conversation_id>
    Ver detalles de una conversación
    
    Ejemplo:
      ./chatwoot-labels.sh details 66

  ${GREEN}assign${NC} <conversation_id> <label_name>
    Asignar un label a una conversación
    
    Ejemplo:
      ./chatwoot-labels.sh assign 66 validando_dni

  ${GREEN}remove${NC} <conversation_id> <label_name>
    Remover un label de una conversación
    
    Ejemplo:
      ./chatwoot-labels.sh remove 66 validando_dni

${YELLOW}VARIABLES DE ENTORNO:${NC}
  CHATWOOT_HOST    (default: 192.168.5.25)
  CHATWOOT_PORT    (default: 3000)
  API_TOKEN        (default: 3LRrbzKNxPSstkP2jTUq6Gtn)
  ACCOUNT_ID       (default: 1)

${YELLOW}EJEMPLOS RÁPIDOS:${NC}

  # Ver conversaciones
  ./chatwoot-labels.sh list

  # Ver labels
  ./chatwoot-labels.sh labels

  # Ver detalles de conversación 66
  ./chatwoot-labels.sh details 66

  # Asignar label "validando_dni" a conversación 66
  ./chatwoot-labels.sh assign 66 validando_dni

  # Remover label de conversación 66
  ./chatwoot-labels.sh remove 66 validando_dni

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
            list_conversations
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
