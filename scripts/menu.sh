#!/bin/bash

# ==============================================
# Easy Panel - Script de Gestión
# ==============================================

set -e

# Obtener ruta del proyecto de forma dinámica
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar el banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║        EASY PANEL - MANAGER            ║"
    echo "║  Evolution API + Chatwoot + n8n        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Función para mostrar el menú
show_menu() {
    echo -e "${GREEN}=== MENÚ PRINCIPAL ===${NC}\n"
    echo "1)  🚀 Iniciar todos los servicios"
    echo "2)  🛑 Detener todos los servicios"
    echo "3)  🔄 Reiniciar todos los servicios"
    echo "4)  📊 Ver estado de los servicios"
    echo "5)  📝 Ver logs de todos los servicios"
    echo ""
    echo "6)  🔧 Gestionar Evolution API"
    echo "7)  💬 Gestionar Chatwoot"
    echo "8)  ⚙️  Gestionar n8n"
    echo "9)  🗄️  Gestionar Base de Datos"
    echo "10) 💾 Gestionar Redis"
    echo "11) 📷 Gestionar Servidor de Imágenes (srv-img)"
    echo "12) 🔌 Gestionar API de Calidda (vcc-totem)"
    echo ""
    echo "13) 🔑 Generar claves y contraseñas"
    echo "14) 📦 Actualizar servicios"
    echo "15) 🧹 Limpiar contenedores e imágenes"
    echo "16) 💾 Backup de datos"
    echo "17) 🔄 Restaurar backup"
    echo ""
    echo "18) ℹ️  Información de acceso"
    echo "19) 🔍 Verificar configuración"
    echo ""
    echo "0)  ❌ Salir"
    echo ""
    echo -n "Selecciona una opción: "
}

# Normalizar entrada: eliminar espacios alrededor y retornos de carro
sanitize_input() {
    # remove CR and trim leading/trailing whitespace
    option=${option//$'\r'/}
    option=$(printf "%s" "$option" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

# Función para iniciar servicios
start_services() {
    echo -e "\n${GREEN}🚀 Iniciando todos los servicios...${NC}\n"
    dc up -d
    echo -e "\n${GREEN}✅ Servicios iniciados correctamente${NC}"
    sleep 2
    dc ps
}

# Función para detener servicios
stop_services() {
    echo -e "\n${YELLOW}🛑 Deteniendo todos los servicios...${NC}\n"
    dc down
    echo -e "\n${GREEN}✅ Servicios detenidos correctamente${NC}"
}

# Función para reiniciar servicios
restart_services() {
    echo -e "\n${YELLOW}🔄 Reiniciando todos los servicios...${NC}\n"
    dc restart
    echo -e "\n${GREEN}✅ Servicios reiniciados correctamente${NC}"
}

# Función para ver estado
show_status() {
    echo -e "\n${BLUE}📊 Estado de los servicios:${NC}\n"
    dc ps
}

# Función para ver logs
show_logs() {
    echo -e "\n${BLUE}📝 Mostrando logs (Ctrl+C para salir)...${NC}\n"
    dc logs -f --tail=100
}

# Menú de Evolution API
evolution_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE EVOLUTION API ===${NC}\n"
    echo "1) Ver logs de Evolution API"
    echo "2) Reiniciar Evolution API"
    echo "3) Detener Evolution API"
    echo "4) Iniciar Evolution API"
    echo "5) Ver información de conexión"
    echo "6) Abrir en navegador"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de Evolution API (Ctrl+C para salir)...${NC}\n"
            dc logs -f evolution-api
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando Evolution API...${NC}\n"
            dc restart evolution-api
            echo -e "\n${GREEN}✅ Evolution API reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo Evolution API...${NC}\n"
            dc stop evolution-api
            echo -e "\n${GREEN}✅ Evolution API detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando Evolution API...${NC}\n"
            dc start evolution-api
            echo -e "\n${GREEN}✅ Evolution API iniciado${NC}"
            ;;
        5)
            show_evolution_info
            ;;
        6)
            xdg-open "http://localhost:8080" 2>/dev/null || echo "Abre manualmente: http://localhost:8080"
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de Chatwoot
chatwoot_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE CHATWOOT ===${NC}\n"
    echo "1) Ver logs de Chatwoot Web"
    echo "2) Ver logs de Chatwoot Sidekiq"
    echo "3) Reiniciar Chatwoot Web"
    echo "4) Reiniciar Chatwoot Sidekiq"
    echo "5) Reiniciar ambos"
    echo "6) Detener Chatwoot Web"
    echo "7) Detener Chatwoot Sidekiq"
    echo "8) Detener ambos"
    echo "9) Iniciar Chatwoot Web"
    echo "10) Iniciar Chatwoot Sidekiq"
    echo "11) Iniciar ambos"
    echo "12) Abrir en navegador"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de Chatwoot Web (Ctrl+C para salir)...${NC}\n"
            dc logs -f chatwoot-web
            ;;
        2)
            echo -e "\n${BLUE}📝 Logs de Chatwoot Sidekiq (Ctrl+C para salir)...${NC}\n"
            dc logs -f chatwoot-sidekiq
            ;;
        3)
            echo -e "\n${YELLOW}🔄 Reiniciando Chatwoot Web...${NC}\n"
            dc restart chatwoot-web
            echo -e "\n${GREEN}✅ Chatwoot Web reiniciado${NC}"
            ;;
        4)
            echo -e "\n${YELLOW}🔄 Reiniciando Chatwoot Sidekiq...${NC}\n"
            dc restart chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot Sidekiq reiniciado${NC}"
            ;;
        5)
            echo -e "\n${YELLOW}🔄 Reiniciando Chatwoot completo...${NC}\n"
            dc restart chatwoot-web chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot reiniciado${NC}"
            ;;
        6)
            echo -e "\n${YELLOW}🛑 Deteniendo Chatwoot Web...${NC}\n"
            dc stop chatwoot-web
            echo -e "\n${GREEN}✅ Chatwoot Web detenido${NC}"
            ;;
        7)
            echo -e "\n${YELLOW}🛑 Deteniendo Chatwoot Sidekiq...${NC}\n"
            dc stop chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot Sidekiq detenido${NC}"
            ;;
        8)
            echo -e "\n${YELLOW}🛑 Deteniendo Chatwoot completo...${NC}\n"
            dc stop chatwoot-web chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot detenido${NC}"
            ;;
        9)
            echo -e "\n${GREEN}🚀 Iniciando Chatwoot Web...${NC}\n"
            dc start chatwoot-web
            echo -e "\n${GREEN}✅ Chatwoot Web iniciado${NC}"
            ;;
        10)
            echo -e "\n${GREEN}🚀 Iniciando Chatwoot Sidekiq...${NC}\n"
            dc start chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot Sidekiq iniciado${NC}"
            ;;
        11)
            echo -e "\n${GREEN}🚀 Iniciando Chatwoot completo...${NC}\n"
            dc start chatwoot-web chatwoot-sidekiq
            echo -e "\n${GREEN}✅ Chatwoot iniciado${NC}"
            ;;
        12)
            xdg-open "http://localhost:3000" 2>/dev/null || echo "Abre manualmente: http://localhost:3000"
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de n8n
n8n_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE N8N ===${NC}\n"
    echo "1) Ver logs de n8n"
    echo "2) Reiniciar n8n"
    echo "3) Detener n8n"
    echo "4) Iniciar n8n"
    echo "5) Ver credenciales de acceso"
    echo "6) Abrir en navegador"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de n8n (Ctrl+C para salir)...${NC}\n"
            dc logs -f n8n
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando n8n...${NC}\n"
            dc restart n8n
            echo -e "\n${GREEN}✅ n8n reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo n8n...${NC}\n"
            dc stop n8n
            echo -e "\n${GREEN}✅ n8n detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando n8n...${NC}\n"
            dc start n8n
            echo -e "\n${GREEN}✅ n8n iniciado${NC}"
            ;;
        5)
            show_n8n_info
            ;;
        6)
            xdg-open "http://localhost:5678" 2>/dev/null || echo "Abre manualmente: http://localhost:5678"
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de Base de Datos
database_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE BASE DE DATOS ===${NC}\n"
    echo "1) Ver logs de PostgreSQL"
    echo "2) Reiniciar PostgreSQL"
    echo "3) Detener PostgreSQL"
    echo "4) Iniciar PostgreSQL"
    echo "5) Acceder a PostgreSQL (psql)"
    echo "6) Listar bases de datos"
    echo "7) Backup de todas las bases de datos"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de PostgreSQL (Ctrl+C para salir)...${NC}\n"
            dc logs -f postgres
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando PostgreSQL...${NC}\n"
            dc restart postgres
            echo -e "\n${GREEN}✅ PostgreSQL reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo PostgreSQL...${NC}\n"
            dc stop postgres
            echo -e "\n${GREEN}✅ PostgreSQL detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando PostgreSQL...${NC}\n"
            dc start postgres
            echo -e "\n${GREEN}✅ PostgreSQL iniciado${NC}"
            ;;
        5)
            echo -e "\n${BLUE}🔧 Accediendo a PostgreSQL...${NC}\n"
            docker exec -it postgres_db psql -U postgres
            ;;
        6)
            echo -e "\n${BLUE}📋 Bases de datos:${NC}\n"
            docker exec postgres_db psql -U postgres -c "\l"
            ;;
        7)
            backup_database
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de Redis
redis_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE REDIS ===${NC}\n"
    
    echo "1) Ver logs de Redis"
    echo "2) Reiniciar Redis"
    echo "3) Detener Redis"
    echo "4) Iniciar Redis"
    echo "5) Acceder a Redis CLI"
    echo "6) Ver información de Redis"
    echo "7) Limpiar cache de Redis"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de Redis (Ctrl+C para salir)...${NC}\n"
            dc logs -f redis
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando Redis...${NC}\n"
            dc restart redis
            echo -e "\n${GREEN}✅ Redis reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo Redis...${NC}\n"
            dc stop redis
            echo -e "\n${GREEN}✅ Redis detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando Redis...${NC}\n"
            dc start redis
            echo -e "\n${GREEN}✅ Redis iniciado${NC}"
            ;;
        5)
            echo -e "\n${BLUE}🔧 Accediendo a Redis CLI...${NC}\n"
            source .env
            docker exec -it redis_cache redis-cli -a "${REDIS_PASSWORD}"
            ;;
        6)
            echo -e "\n${BLUE}ℹ️  Información de Redis:${NC}\n"
            source .env
            docker exec redis_cache redis-cli -a "${REDIS_PASSWORD}" INFO
            ;;
        7)
            echo -e "\n${YELLOW}⚠️  ¿Estás seguro de limpiar el cache de Redis? (s/n): ${NC}"
            read -r confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                source .env
                docker exec redis_cache redis-cli -a "${REDIS_PASSWORD}" FLUSHALL
                echo -e "\n${GREEN}✅ Cache limpiado${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de Servidor de Imágenes
srv_img_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE SERVIDOR DE IMÁGENES ===${NC}\n"
    echo "1) Ver logs de srv-img"
    echo "2) Reiniciar srv-img"
    echo "3) Detener srv-img"
    echo "4) Iniciar srv-img"
    echo "5) Ver información de conexión"
    echo "6) Abrir en navegador"
    echo "7) Ver catálogos disponibles"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de srv-img (Ctrl+C para salir)...${NC}\n"
            dc logs -f srv-img
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando srv-img...${NC}\n"
            dc restart srv-img
            echo -e "\n${GREEN}✅ srv-img reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo srv-img...${NC}\n"
            dc stop srv-img
            echo -e "\n${GREEN}✅ srv-img detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando srv-img...${NC}\n"
            dc start srv-img
            echo -e "\n${GREEN}✅ srv-img iniciado${NC}"
            ;;
        5)
            echo -e "\n${BLUE}=== SERVIDOR DE IMÁGENES ===${NC}"
            echo -e "${GREEN}URL Base:${NC} http://localhost:8000"
            echo -e "${GREEN}Health Check:${NC} http://localhost:8000/"
            echo -e "${GREEN}Catálogos:${NC} http://localhost:8000/api/catalogos"
            echo -e "${GREEN}Documentación:${NC} http://localhost:8000/docs"
            ;;
        6)
            xdg-open "http://localhost:8000/docs" 2>/dev/null || echo "Abre manualmente: http://localhost:8000/docs"
            ;;
        7)
            echo -e "\n${BLUE}📋 Verificando catálogos en srv-img-totem...${NC}\n"
            if [ -d "$PROJECT_DIR/srv-img-totem/imagenes" ]; then
                ls -lh "$PROJECT_DIR/srv-img-totem/imagenes"
            else
                echo -e "${YELLOW}⚠️  Directorio imagenes/ no encontrado${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Menú de API de Calidda
calidda_api_menu() {
    clear
    show_banner
    echo -e "${GREEN}=== GESTIÓN DE API DE CALIDDA ===${NC}\n"
    echo "1) Ver logs de calidda-api"
    echo "2) Reiniciar calidda-api"
    echo "3) Detener calidda-api"
    echo "4) Iniciar calidda-api"
    echo "5) Ver información de conexión"
    echo "6) Abrir en navegador"
    echo "7) Probar endpoint principal"
    echo "0) Volver al menú principal"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            echo -e "\n${BLUE}📝 Logs de calidda-api (Ctrl+C para salir)...${NC}\n"
            dc logs -f calidda-api
            ;;
        2)
            echo -e "\n${YELLOW}🔄 Reiniciando calidda-api...${NC}\n"
            dc restart calidda-api
            echo -e "\n${GREEN}✅ calidda-api reiniciado${NC}"
            ;;
        3)
            echo -e "\n${YELLOW}🛑 Deteniendo calidda-api...${NC}\n"
            dc stop calidda-api
            echo -e "\n${GREEN}✅ calidda-api detenido${NC}"
            ;;
        4)
            echo -e "\n${GREEN}🚀 Iniciando calidda-api...${NC}\n"
            dc start calidda-api
            echo -e "\n${GREEN}✅ calidda-api iniciado${NC}"
            ;;
        5)
            echo -e "\n${BLUE}=== API DE CALIDDA (VCC-TOTEM) ===${NC}"
            echo -e "${GREEN}URL Base:${NC} http://localhost:5000"
            echo -e "${GREEN}Health Check:${NC} http://localhost:5000/"
            echo -e "${GREEN}Endpoint Principal:${NC} http://localhost:5000/run"
            echo -e "${GREEN}Código Fuente:${NC} vcc-totem/src/main.py"
            ;;
        6)
            xdg-open "http://localhost:5000" 2>/dev/null || echo "Abre manualmente: http://localhost:5000"
            ;;
        7)
            echo -e "\n${BLUE}🔍 Probando endpoint principal...${NC}\n"
            curl -f http://localhost:5000/ 2>/dev/null && echo -e "\n${GREEN}✅ API respondiendo correctamente${NC}" || echo -e "\n${RED}❌ API no responde${NC}"
            ;;
        0)
            return
            ;;
    esac
    echo -e "\nPresiona Enter para continuar..."
    read -r
}

# Generar claves
generate_keys() {
    clear
    show_banner
    echo -e "${GREEN}=== GENERADOR DE CLAVES Y CONTRASEÑAS ===${NC}\n"
    
    echo -e "${YELLOW}Generando claves seguras...${NC}\n"
    
    echo -e "${BLUE}N8N Encryption Key:${NC}"
    openssl rand -hex 32
    echo ""
    
    echo -e "${BLUE}Contraseña segura para PostgreSQL:${NC}"
    openssl rand -hex 16
    echo ""
    
    echo -e "${BLUE}Contraseña segura para Redis:${NC}"
    openssl rand -hex 16
    echo ""
    
    echo -e "${BLUE}API Key para Evolution:${NC}"
    openssl rand -hex 16 | tr '[:lower:]' '[:upper:]'
    echo ""
    
    echo -e "${BLUE}Secret Key Base para Chatwoot:${NC}"
    openssl rand -hex 64
    echo ""
    
    echo -e "${GREEN}✅ Claves generadas. Cópialas al archivo .env${NC}"
}

# Actualizar servicios
update_services() {
    echo -e "\n${YELLOW}📦 Descargando últimas versiones...${NC}\n"
    dc pull
    echo -e "\n${YELLOW}🔄 Recreando servicios...${NC}\n"
    dc up -d
    echo -e "\n${GREEN}✅ Servicios actualizados correctamente${NC}"
}

# Limpiar Docker
clean_docker() {
    echo -e "\n${YELLOW}🧹 Limpieza de Docker${NC}\n"
    echo "1) Limpiar contenedores detenidos"
    echo "2) Limpiar imágenes no utilizadas"
    echo "3) Limpiar todo (contenedores, imágenes, volúmenes)"
    echo "0) Cancelar"
    echo ""
    echo -n "Selecciona una opción: "
    read -r option; sanitize_input
    
    case $option in
        1)
            docker container prune -f
            echo -e "\n${GREEN}✅ Contenedores limpiados${NC}"
            ;;
        2)
            docker image prune -a -f
            echo -e "\n${GREEN}✅ Imágenes limpiadas${NC}"
            ;;
        3)
            echo -e "\n${RED}⚠️  ADVERTENCIA: Esto eliminará TODOS los datos. ¿Continuar? (s/n): ${NC}"
            read -r confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                dc down -v
                docker system prune -a -f --volumes
                echo -e "\n${GREEN}✅ Limpieza completa realizada${NC}"
            fi
            ;;
        0)
            return
            ;;
    esac
}

# Backup de base de datos
backup_database() {
    BACKUP_DIR="$PROJECT_DIR/backups"
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql"
    
    echo -e "\n${YELLOW}💾 Creando backup de la base de datos...${NC}\n"
    docker exec -T postgres_db pg_dumpall -U postgres > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        echo -e "\n${GREEN}✅ Backup creado: $BACKUP_FILE${NC}"
        echo -e "${BLUE}Tamaño: $(du -h "$BACKUP_FILE" | cut -f1)${NC}"
    else
        echo -e "\n${RED}❌ Error al crear backup${NC}"
    fi
}

# Restaurar backup
restore_backup() {
    BACKUP_DIR="$PROJECT_DIR/backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        echo -e "\n${RED}❌ No hay backups disponibles${NC}"
        return
    fi
    
    echo -e "\n${YELLOW}💾 Backups disponibles:${NC}\n"
    ls -lh "$BACKUP_DIR"
    echo ""
    echo -n "Ingresa el nombre del archivo de backup: "
    read -r backup_file
    
    if [ -f "$BACKUP_DIR/$backup_file" ]; then
        echo -e "\n${RED}⚠️  ADVERTENCIA: Esto reemplazará todos los datos actuales. ¿Continuar? (s/n): ${NC}"
        read -r confirm
        if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
            echo -e "\n${YELLOW}🔄 Restaurando backup...${NC}\n"
            docker exec -i postgres_db psql -U postgres < "$BACKUP_DIR/$backup_file"
            echo -e "\n${GREEN}✅ Backup restaurado${NC}"
        fi
    else
        echo -e "\n${RED}❌ Archivo no encontrado${NC}"
    fi
}

# Mostrar información de Evolution API
show_evolution_info() {
    source .env
    echo -e "\n${BLUE}=== EVOLUTION API ===${NC}"
    echo -e "${GREEN}URL:${NC} http://localhost:8080"
    echo -e "${GREEN}API Key:${NC} ${EVOLUTION_API_KEY}"
    echo -e "${GREEN}Documentación:${NC} http://localhost:8080/docs"
}

# Mostrar información de n8n
show_n8n_info() {
    source .env
    echo -e "\n${BLUE}=== N8N ===${NC}"
    echo -e "${GREEN}URL:${NC} http://localhost:5678"
    echo -e "${GREEN}Usuario:${NC} ${N8N_BASIC_AUTH_USER}"
    echo -e "${GREEN}Contraseña:${NC} ${N8N_BASIC_AUTH_PASSWORD}"
}

# Mostrar toda la información de acceso
show_access_info() {
    clear
    show_banner
    source .env
    
    echo -e "${GREEN}=== INFORMACIÓN DE ACCESO ===${NC}\n"
    
    echo -e "${BLUE}🔹 EVOLUTION API${NC}"
    echo -e "   URL: ${GREEN}http://localhost:8080${NC}"
    echo -e "   API Key: ${GREEN}${EVOLUTION_API_KEY}${NC}"
    echo -e "   Docs: ${GREEN}http://localhost:8080/docs${NC}"
    echo ""
    
    echo -e "${BLUE}🔹 CHATWOOT${NC}"
    echo -e "   URL: ${GREEN}http://localhost:3000${NC}"
    echo -e "   Nota: Crear cuenta de administrador en el primer acceso"
    echo ""
    
    echo -e "${BLUE}🔹 N8N${NC}"
    echo -e "   URL: ${GREEN}http://localhost:5678${NC}"
    echo -e "   Usuario: ${GREEN}${N8N_BASIC_AUTH_USER}${NC}"
    echo -e "   Contraseña: ${GREEN}${N8N_BASIC_AUTH_PASSWORD}${NC}"
    echo ""
    
    echo -e "${BLUE}🔹 POSTGRESQL${NC}"
    echo -e "   Host: ${GREEN}localhost:5432${NC}"
    echo -e "   Usuario: ${GREEN}${POSTGRES_USER}${NC}"
    echo -e "   Contraseña: ${GREEN}${POSTGRES_PASSWORD}${NC}"
    echo -e "   Bases de datos: ${GREEN}evolution, chatwoot, n8n${NC}"
    echo ""
    
    echo -e "${BLUE}🔹 REDIS${NC}"
    echo -e "   Host: ${GREEN}localhost:6379${NC}"
    echo -e "   Contraseña: ${GREEN}${REDIS_PASSWORD}${NC}"
    echo ""
    
    echo -e "${BLUE}🔹 SERVIDOR DE IMÁGENES (srv-img)${NC}"
    echo -e "   URL: ${GREEN}http://localhost:8000${NC}"
    echo -e "   Documentación: ${GREEN}http://localhost:8000/docs${NC}"
    echo -e "   Catálogos: ${GREEN}http://localhost:8000/api/catalogos${NC}"
    echo ""
    
    echo -e "${BLUE}🔹 API DE CALIDDA (vcc-totem)${NC}"
    echo -e "   URL: ${GREEN}http://localhost:5000${NC}"
    echo -e "   Endpoint: ${GREEN}http://localhost:5000/run${NC}"
    echo -e "   Código: ${GREEN}vcc-totem/src/main.py${NC}"
}

# Verificar configuración
check_config() {
    clear
    show_banner
    echo -e "${GREEN}=== VERIFICACIÓN DE CONFIGURACIÓN ===${NC}\n"
    
    source .env
    
    echo -e "${BLUE}Verificando archivo .env...${NC}"
    
    # Verificar claves críticas
    if [ -z "$N8N_ENCRYPTION_KEY" ]; then
        echo -e "${RED}❌ N8N_ENCRYPTION_KEY no está configurado${NC}"
    else
        echo -e "${GREEN}✅ N8N_ENCRYPTION_KEY configurado${NC}"
    fi
    
    if [ "$N8N_BASIC_AUTH_PASSWORD" = "change_me_n8n" ]; then
        echo -e "${YELLOW}⚠️  N8N_BASIC_AUTH_PASSWORD usa el valor por defecto${NC}"
    else
        echo -e "${GREEN}✅ N8N_BASIC_AUTH_PASSWORD configurado${NC}"
    fi
    
    if [ -n "$POSTGRES_PASSWORD" ]; then
        echo -e "${GREEN}✅ POSTGRES_PASSWORD configurado${NC}"
    else
        echo -e "${RED}❌ POSTGRES_PASSWORD no está configurado${NC}"
    fi
    
    if [ -n "$REDIS_PASSWORD" ]; then
        echo -e "${GREEN}✅ REDIS_PASSWORD configurado${NC}"
    else
        echo -e "${RED}❌ REDIS_PASSWORD no está configurado${NC}"
    fi
    
    if [ -n "$EVOLUTION_API_KEY" ]; then
        echo -e "${GREEN}✅ EVOLUTION_API_KEY configurado${NC}"
    else
        echo -e "${RED}❌ EVOLUTION_API_KEY no está configurado${NC}"
    fi
    
    echo -e "\n${BLUE}Verificando servicios Docker...${NC}"
    if dc ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Hay servicios en ejecución${NC}"
    else
        echo -e "${YELLOW}⚠️  No hay servicios en ejecución${NC}"
    fi
    
    echo -e "\n${BLUE}Verificando script de bases de datos...${NC}"
    if [ -f "scripts/create-multiple-databases.sh" ]; then
        echo -e "${GREEN}✅ Script de bases de datos existe${NC}"
    else
        echo -e "${RED}❌ Script de bases de datos no encontrado${NC}"
    fi
    
    echo -e "\n${BLUE}Verificando servicios adicionales...${NC}"
    if [ -d "$PROJECT_DIR/srv-img-totem" ]; then
        echo -e "${GREEN}✅ srv-img-totem encontrado${NC}"
        if [ -f "$PROJECT_DIR/srv-img-totem/main.py" ]; then
            echo -e "${GREEN}✅ main.py existe${NC}"
        else
            echo -e "${RED}❌ main.py no encontrado${NC}"
        fi
    else
        echo -e "${RED}❌ Directorio srv-img-totem no encontrado${NC}"
    fi
    
    if [ -d "$PROJECT_DIR/vcc-totem" ]; then
        echo -e "${GREEN}✅ vcc-totem encontrado${NC}"
        if [ -f "$PROJECT_DIR/vcc-totem/api_wrapper.py" ]; then
            echo -e "${GREEN}✅ api_wrapper.py existe${NC}"
        else
            echo -e "${RED}❌ api_wrapper.py no encontrado${NC}"
        fi
    else
        echo -e "${RED}❌ Directorio vcc-totem no encontrado${NC}"
    fi
    
    echo -e "\n${BLUE}Verificando servicios en ejecución...${NC}"
    dc ps 2>/dev/null | grep -E "(evolution-api|chatwoot-web|n8n|postgres|redis|srv-img|calidda-api)" | while read line; do
        if echo "$line" | grep -q "Up"; then
            SERVICE=$(echo "$line" | awk '{print $1}')
            echo -e "${GREEN}✅ $SERVICE está corriendo${NC}"
        fi
    done
}

# Bucle principal
main() {
    while true; do
        clear
        show_banner
    show_menu
    read -r option; sanitize_input
        
        case $option in
            1) start_services ;;
            2) stop_services ;;
            3) restart_services ;;
            4) show_status ;;
            5) show_logs ;;
            6) evolution_menu ;;
            7) chatwoot_menu ;;
            8) n8n_menu ;;
            9) database_menu ;;
            10) redis_menu ;;
            11) srv_img_menu ;;
            12) calidda_api_menu ;;
            13) generate_keys ;;
            14) update_services ;;
            15) clean_docker ;;
            16) backup_database ;;
            17) restore_backup ;;
            18) show_access_info ;;
            19) check_config ;;
            0)
                echo -e "\n${GREEN}👋 ¡Hasta luego!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}❌ Opción inválida${NC}"
                ;;
        esac
        
        if [ "$option" != "5" ] && [ "$option" != "6" ] && [ "$option" != "7" ] && [ "$option" != "8" ] && [ "$option" != "9" ] && [ "$option" != "10" ] && [ "$option" != "11" ] && [ "$option" != "12" ] && [ "$option" != "18" ] && [ "$option" != "19" ]; then
            echo -e "\nPresiona Enter para continuar..."
            read -r
        fi
    done
}

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado${NC}"
    exit 1
fi

# Detectar comando de Docker Compose (soporta docker-compose y docker compose)
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}❌ Docker Compose no está instalado${NC}"
    exit 1
fi

# Función wrapper para docker-compose (reemplaza todas las llamadas)
dc() {
    $DOCKER_COMPOSE "$@"
}

# Ejecutar menú principal
main
