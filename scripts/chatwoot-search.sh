#!/bin/bash

# =========================================
# Script para buscar conversaciones por teléfono
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
# Función: Buscar por número de teléfono
# ==========================================
search_by_phone() {
    local phone=$1
    
    if [ -z "$phone" ]; then
        echo -e "${RED}Uso: search <phone_number>${NC}"
        echo -e "${YELLOW}Ejemplo: ./chatwoot-search.sh search +51995370009${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 Buscando conversaciones con número: ${phone}${NC}\n"
    
    result=$(curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq ".data.payload[]? | select(.meta.sender.phone_number == \"${phone}\")")
    
    if [ -z "$result" ] || [ "$result" == "null" ]; then
        echo -e "${RED}❌ No se encontró conversación con el número: ${phone}${NC}"
        return 1
    fi
    
    echo "$result" | jq -r '
        "ID: \(.id)\n" +
        "Nombre: \(.meta.sender.name)\n" +
        "Teléfono: \(.meta.sender.phone_number)\n" +
        "Estado: \(.status)\n" +
        "Labels: \((.labels // [] | join(", ")) // "Sin labels")\n" +
        "Mensajes: \(.messages | length)\n" +
        "Creado: \(.created_at)\n" +
        "Última actividad: \(.updated_at)"
    '
    
    echo ""
    echo -e "${GREEN}✓ Búsqueda completada${NC}"
}

# ==========================================
# Función: Listar todas las conversaciones con teléfono
# ==========================================
list_all_phones() {
    echo -e "${BLUE}📞 CONVERSACIONES CON NÚMEROS DE TELÉFONO${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.data.payload[]? | "\(.id)\t| \(.meta.sender.phone_number // "N/A")\t| \(.meta.sender.name // "N/A")\t| \(.status)\t| Labels: \((.labels // [] | join(", ")) // "Sin labels")"' | column -t -s $'\t'
}

# ==========================================
# Función: Contar por números únicos
# ==========================================
count_unique_phones() {
    echo -e "${BLUE}📊 ESTADÍSTICAS DE TELÉFONOS${NC}\n"
    
    curl -s -X GET \
        "${CHATWOOT_BASE_URL}/api/v1/accounts/${ACCOUNT_ID}/conversations" \
        -H "api_access_token: ${API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.data.payload[]? | .meta.sender.phone_number // "N/A"' | sort | uniq -c | sort -rn
}

# ==========================================
# Función: Ayuda
# ==========================================
show_help() {
    cat << EOF
${BLUE}╔════════════════════════════════════════════════════════╗${NC}
${BLUE}║     Chatwoot - Buscar Conversaciones por Teléfono      ║${NC}
${BLUE}╚════════════════════════════════════════════════════════╝${NC}

${YELLOW}COMANDOS:${NC}

  ${GREEN}search${NC} <phone_number>
    Buscar conversación por número de teléfono
    
    Ejemplo:
      ./chatwoot-search.sh search +51995370009

  ${GREEN}list${NC}
    Listar todas las conversaciones con sus teléfonos
    
    Ejemplo:
      ./chatwoot-search.sh list

  ${GREEN}count${NC}
    Ver estadísticas de teléfonos únicos
    
    Ejemplo:
      ./chatwoot-search.sh count

${YELLOW}EJEMPLOS DE USO:${NC}

  # Buscar conversación específica
  ./chatwoot-search.sh search +51995370009

  # Buscar otro número
  ./chatwoot-search.sh search +51919284799

  # Listar todos con números
  ./chatwoot-search.sh list

  # Ver estadísticas
  ./chatwoot-search.sh count

${GREEN}✓ Token: ${API_TOKEN:0:15}...${NC}
${GREEN}✓ URL: ${CHATWOOT_BASE_URL}${NC}

EOF
}

# ==========================================
# Main
# ==========================================
main() {
    case "${1:-help}" in
        search)
            search_by_phone "$2"
            ;;
        list)
            list_all_phones
            ;;
        count)
            count_unique_phones
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
