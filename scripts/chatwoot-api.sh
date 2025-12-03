#!/bin/bash

# =========================================
# Script para interactuar con API Chatwoot
# =========================================

# Configuración
CHATWOOT_HOST=${CHATWOOT_HOST:-192.168.5.25}
CHATWOOT_PORT=${CHATWOOT_PORT:-3000}
CHATWOOT_BASE_URL="http://${CHATWOOT_HOST}:${CHATWOOT_PORT}"
ACCOUNT_ID=${ACCOUNT_ID:-1}
# Token por defecto - cambiar si es necesario
API_TOKEN=${API_TOKEN:-"3LRrbzKNxPSstkP2jTUq6Gtn"}

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para obtener labels
get_labels() {
    echo -e "\n${BLUE}Obteniendo labels disponibles...${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# Función para obtener conversaciones
get_conversations() {
    echo -e "\n${BLUE}Obteniendo conversaciones...${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# Función para asignar label a conversación
assign_label() {
    local conversation_id=$1
    local label_name=$2
    
    if [ -z "$conversation_id" ] || [ -z "$label_name" ]; then
        echo -e "${RED}❌ Uso: assign_label <conversation_id> <label_name>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Asignando label '${label_name}' a conversación ${conversation_id}...${NC}"
    
    curl -s -X POST \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conversation_id}/labels" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"labels\": [\"${label_name}\"]}" | jq '.'
}

# Función para remover label de conversación
remove_label() {
    local conversation_id=$1
    local label_name=$2
    
    if [ -z "$conversation_id" ] || [ -z "$label_name" ]; then
        echo -e "${RED}❌ Uso: remove_label <conversation_id> <label_name>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Removiendo label '${label_name}' de conversación ${conversation_id}...${NC}"
    
    curl -s -X DELETE \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conversation_id}/labels/${label_name}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# Función para obtener detalles de una conversación
get_conversation() {
    local conversation_id=$1
    
    if [ -z "$conversation_id" ]; then
        echo -e "${RED}❌ Uso: get_conversation <conversation_id>${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Obteniendo detalles de conversación ${conversation_id}...${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations/${conversation_id}" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq '.'
}

# Mostrar ayuda
show_help() {
    cat << EOF
${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}
${BLUE}║          Script API Chatwoot - Gestión de Labels               ║${NC}
${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}

${YELLOW}USO:${NC}
  ./chatwoot-api.sh <comando> [argumentos]

${YELLOW}COMANDOS:${NC}

  ${GREEN}labels${NC}
    Obtener todos los labels disponibles

  ${GREEN}conversations${NC}
    Obtener lista de conversaciones

  ${GREEN}conversation${NC} <conversation_id>
    Obtener detalles de una conversación específica

  ${GREEN}assign${NC} <conversation_id> <label_name>
    Asignar un label a una conversación
    
    Ejemplo:
      ./chatwoot-api.sh assign 7 validando_dni

  ${GREEN}remove${NC} <conversation_id> <label_name>
    Remover un label de una conversación
    
    Ejemplo:
      ./chatwoot-api.sh remove 7 validando_dni

${YELLOW}VARIABLES DE ENTORNO:${NC}
  CHATWOOT_HOST      (default: 192.168.5.25)
  CHATWOOT_PORT      (default: 3000)
  ACCOUNT_ID         (default: 1)

${YELLOW}EJEMPLOS:${NC}

  # Ver todos los labels
  ./chatwoot-api.sh labels

  # Ver conversaciones
  ./chatwoot-api.sh conversations

  # Ver detalles de conversación 7
  ./chatwoot-api.sh conversation 7

  # Asignar label a conversación
  ./chatwoot-api.sh assign 7 validando_dni

  # Remover label de conversación
  ./chatwoot-api.sh remove 7 validando_dni

${GREEN}✓ Ejecuta sin argumentos para obtener ayuda${NC}

EOF
}

# Main
main() {
    echo -e "${GREEN}✓ Token API: ${API_TOKEN:0:20}...${NC}"
    
    # Procesar comando
    case "${1:-help}" in
        labels)
            get_labels
            ;;
        conversations)
            get_conversations
            ;;
        conversation)
            get_conversation "$2"
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

# Ejecutar
main "$@"
