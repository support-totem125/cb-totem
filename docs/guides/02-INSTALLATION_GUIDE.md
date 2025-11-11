# 📋 Guía Completa de Instalación y Configuración

> Instalación paso a paso para desarrolladores, administradores y DevOps

---

## 🎯 Objetivos de esta guía

Esta guía cubre:

1. ✅ **Requisitos y validación** del ambiente
2. ✅ **Instalación paso a paso** con explicaciones
3. ✅ **Configuración por ambiente** (desarrollo, staging, producción)
4. ✅ **Verificación** de que todo funciona
5. ✅ **Troubleshooting** de problemas comunes
6. ✅ **Comandos Docker** útiles
7. ✅ **Siguientes pasos** después de la instalación

---

## 🖥️ Requisitos del Sistema

### Mínimos
- **CPU**: 2 cores
- **RAM**: 4GB
- **Disco**: 20GB libres
- **Docker**: 20.10+
- **Docker Compose**: 1.29+

### Recomendados (Producción)
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disco**: 50GB+ (SSD)
- **Docker**: Última versión estable
- **Banda ancha**: 10 Mbps+

### Software Requerido

#### Linux/macOS
```bash
# Verificar Docker
docker --version
# Output: Docker version 20.10.0+

# Verificar Docker Compose
docker-compose --version
# Output: Docker Compose version 1.29.0+

# Verificar Git (opcional)
git --version
```

#### Windows
- Windows 10/11 Pro, Enterprise o Education
- WSL2 (Windows Subsystem for Linux 2) habilitado
- Docker Desktop for Windows instalado

---

## 📥 Instalación de Docker (si no tienes)

### Ubuntu/Debian
```bash
# Actualizar paquetes
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker ps
```

### macOS
```bash
# Con Homebrew
brew install docker docker-compose

# O descargar Docker Desktop desde:
# https://www.docker.com/products/docker-desktop
```

### Windows
1. Descargar [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Ejecutar instalador
3. Habilitar WSL2
4. Reiniciar

---

## 🚀 Instalación de Chat-Bot Totem

### Paso 1: Clonar repositorio

```bash
# Clonar
git clone https://github.com/diego-moscaiza/chat-bot-totem.git
cd chat-bot-totem

# O si no tienes Git, descargar ZIP desde GitHub
unzip chat-bot-totem-main.zip
cd chat-bot-totem
```

### Paso 2: Copiar archivo de configuración

```bash
# Copiar ejemplo
cp .env.example .env

# Listar contenido para verificar
ls -la .env
# Output: -rw-r--r-- 1 user user 4521 Nov 10 14:30 .env
```

### Paso 3: Editar variables de entorno

```bash
# Abrir con tu editor preferido
nano .env
# o
vim .env
# o
code .env  # Si usas VS Code
```

**Variables CRÍTICAS a cambiar:**

```bash
# === CONFIGURACIÓN DEL SERVIDOR ===
DOMAIN_HOST=localhost                    # ← Cambiar a tu dominio/IP
SERVER_IP_ADDR=127.0.0.1                 # ← Cambiar a tu IP

# === CONTRASEÑAS DE BD ===
POSTGRES_PASSWORD=cad69267bd6dc425c505  # ← Generar con: openssl rand -hex 16
REDIS_PASSWORD=f2cd6ac2b7b29ec718ec     # ← Generar con: openssl rand -hex 16

# === CHATWOOT ===
CHATWOOT_SECRET_KEY_BASE=dedfddcd4d4eab8...  # ← Generar con: openssl rand -hex 64

# === N8N ===
N8N_BASIC_AUTH_PASSWORD=ab491fbae1c66740... # ← Cambiar contraseña
N8N_ENCRYPTION_KEY=4cda7990564763617887...  # ← Generar con: openssl rand -hex 32

# === EVOLUTION API ===
EVOLUTION_API_KEY=B6D9F3E856A4CA92838D9C44E # ← Cambiar API key
```

**Generar contraseñas seguras:**

```bash
# PostgreSQL/Redis (32 caracteres)
openssl rand -hex 16

# Chatwoot (128 caracteres)
openssl rand -hex 64

# N8N Encryption (64 caracteres)
openssl rand -hex 32
```

### Paso 4: Validar configuración

```bash
# Verificar que el archivo .env se creó correctamente
cat .env | head -20

# Verificar Docker
docker ps
# Output: CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS    NAMES

# Verificar Docker Compose
docker-compose --version
# Output: Docker Compose version 1.29.0+
```

### Paso 5: Iniciar servicios

```bash
# Iniciar en background
docker-compose up -d

# Ver progreso en tiempo real
docker-compose logs -f
```

**Esperar a que aparezca algo como:**
```
postgres_db is healthy
redis_cache is healthy
evolution_api is healthy
chatwoot_web is running
n8n is running
calidda_api is running
srv_img is running
```

### Paso 6: Verificar estado

```bash
# Ver estado de contenedores
docker-compose ps

# Deberías ver algo como:
# NAME              STATUS
# postgres_db       Up 2 minutes
# redis_cache       Up 2 minutes
# evolution_api     Up 2 minutes (healthy)
# chatwoot_web      Up 1 minute
# chatwoot_sidekiq  Up 1 minute
# n8n               Up 1 minute
# calidda_api       Up 1 minute
# srv_img           Up 1 minute
```

### Paso 7: Acceder a los servicios

```bash
# Si DOMAIN_HOST=localhost:
echo "Chatwoot:  http://localhost:3000"
echo "n8n:       http://localhost:5678"
echo "Evolution: http://localhost:8080"
```

**Crear usuario admin en Chatwoot:**
1. Abrir http://localhost:3000
2. Llenar formulario de registro
3. Este usuario será admin

---

## 🌐 Configuración por Ambiente

### Desarrollo (Localhost)

```bash
# .env
DOMAIN_HOST=localhost
SERVER_IP_ADDR=127.0.0.1
FORCE_SSL=false
N8N_PROTOCOL=http
DEBUG=true
LOG_LEVEL=debug
```

**Comandos útiles:**
```bash
# Logs en tiempo real
docker-compose logs -f chatwoot-web

# Ejecutar comando en contenedor
docker-compose exec chatwoot-web bash

# Ver variables de entorno
docker-compose exec chatwoot-web env | grep DOMAIN
```

### Staging (Red interna)

```bash
# .env
DOMAIN_HOST=192.168.1.74              # Tu IP en la red
SERVER_IP_ADDR=192.168.1.74
FORCE_SSL=false
N8N_PROTOCOL=http
LOG_LEVEL=info
```

**Verificar acceso:**
```bash
# Desde otra máquina en la red:
curl -I http://192.168.1.74:3000
# HTTP/1.1 200 OK
```

### Producción (Dominio HTTPS)

```bash
# .env
DOMAIN_HOST=chatbot.tudominio.com
SERVER_IP_ADDR=<IP_DEL_SERVIDOR>
FORCE_SSL=true
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
LOG_LEVEL=warn
POSTGRES_BACKUP=daily
REDIS_BACKUP=daily
```

**Configuración adicional requerida:**
1. Certificado SSL/TLS
2. Proxy reverso (Nginx, Caddy)
3. Firewall configurado
4. Backups automáticos
5. Monitoreo activo

---

## 📦 Comandos Docker Útiles

### Estado y logs

```bash
# Ver estado
docker-compose ps

# Logs de un servicio
docker-compose logs chatwoot-web

# Logs en tiempo real
docker-compose logs -f postgres_db

# Últimas 100 líneas
docker-compose logs --tail=100 chatwoot-web

# Entre fechas
docker-compose logs --since 10m n8n
```

### Gestión de contenedores

```bash
# Iniciar/parar/reiniciar
docker-compose start
docker-compose stop
docker-compose restart chatwoot-web

# Eliminar contenedores (sin borrar datos)
docker-compose down

# Eliminar todo incluyendo volúmenes (CUIDADO - borra datos)
docker-compose down -v

# Recrear contenedores
docker-compose up -d --force-recreate
```

### Acceso a contenedores

```bash
# Entrar a un contenedor (bash/shell)
docker-compose exec chatwoot-web bash
docker-compose exec postgres_db sh

# Ejecutar comando específico
docker-compose exec postgres_db pg_dump -U postgres chatwoot > backup.sql

# Ejecutar como usuario específico
docker-compose exec -u root chatwoot-web apt-get update
```

### Base de datos

```bash
# Acceder a PostgreSQL
docker-compose exec postgres_db psql -U postgres -d chatwoot

# Comandos útiles en psql:
\d                      # Listar tablas
\dt                     # Mostrar tablas
SELECT * FROM users;    # Ver usuarios
\q                      # Salir

# Hacer backup
docker-compose exec -T postgres_db pg_dump -U postgres chatwoot > backup.sql

# Restaurar backup
docker-compose exec -T postgres_db psql -U postgres chatwoot < backup.sql
```

### Redis

```bash
# Conectarse a Redis
docker-compose exec redis_cache redis-cli

# Comandos útiles en redis-cli:
INFO                    # Información de Redis
KEYS *                  # Ver todas las claves
DEL key_name            # Eliminar clave
FLUSHDB                 # Limpiar toda la BD
exit                    # Salir
```

### Recursos

```bash
# Ver uso de CPU/RAM/IO
docker stats

# Ver uso de disco
docker ps -a --no-trunc | awk '{print $1}' | xargs docker inspect --format='{{.Id}} {{.State.Pid}}'
du -sh /var/lib/docker/containers/*/

# Limpiar recursos no utilizados
docker system prune -a
```

---

## ✅ Validación Post-Instalación

### Checklist automático

```bash
#!/bin/bash
echo "🔍 Validando instalación..."

# 1. Docker
echo -n "Docker: "
docker ps > /dev/null 2>&1 && echo "✅" || echo "❌"

# 2. Compose
echo -n "Docker Compose: "
docker-compose ps > /dev/null 2>&1 && echo "✅" || echo "❌"

# 3. PostgreSQL
echo -n "PostgreSQL: "
docker-compose exec -T postgres_db pg_isready -U postgres > /dev/null 2>&1 && echo "✅" || echo "❌"

# 4. Redis
echo -n "Redis: "
docker-compose exec -T redis_cache redis-cli ping > /dev/null 2>&1 && echo "✅" || echo "❌"

# 5. Chatwoot API
echo -n "Chatwoot API: "
curl -s http://localhost:3000 > /dev/null && echo "✅" || echo "❌"

# 6. n8n API
echo -n "n8n API: "
curl -s http://localhost:5678 > /dev/null && echo "✅" || echo "❌"

# 7. calidda-api
echo -n "calidda-api: "
curl -s http://localhost:5000/health > /dev/null 2>&1 && echo "✅" || echo "❌"

echo "✅ Validación completada"
```

### Verificaciones manuales

```bash
# 1. Verificar que los contenedores están corriendo
docker-compose ps
# Todos deberían estar "Up"

# 2. Verificar que PostgreSQL tiene las tablas
docker-compose exec postgres_db psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"

# 3. Verificar acceso a APIs
curl -I http://localhost:3000    # Chatwoot
curl -I http://localhost:5678    # n8n
curl -I http://localhost:8080    # Evolution

# 4. Verificar .env está bien configurado
grep DOMAIN_HOST .env
grep POSTGRES_PASSWORD .env | head -c 30
```

---

## 🆘 Troubleshooting

### Chatwoot no inicia

```bash
# Ver logs detallados
docker-compose logs chatwoot-web

# Errores comunes:
# "relation users does not exist" → Esperar, migraciones en progreso
# "Errno 111 Connection refused" → PostgreSQL no está listo
# "exit code 137" → Sin memoria, aumentar RAM asignada
```

**Solución:**
```bash
# Esperar 2-3 minutos
sleep 180
docker-compose logs chatwoot-web

# Si sigue fallando:
docker-compose restart chatwoot-web
```

### PostgreSQL no inicia

```bash
# Ver logs
docker-compose logs postgres_db

# Error común: "permission denied"
# Solución:
docker-compose down -v
docker-compose up -d postgres_db
```

### Puerto ya en uso

```bash
# Encontrar proceso usando puerto 3000
lsof -i :3000
# o
netstat -tulpn | grep 3000

# Matar proceso
kill -9 <PID>

# O cambiar puerto en docker-compose.yaml:
# ports: ["3001:3000"]
```

### No puedo acceder desde otra máquina

```bash
# Verificar DOMAIN_HOST
grep DOMAIN_HOST .env
# Debe ser la IP del servidor o dominio, no localhost

# Verificar firewall
sudo ufw allow 3000/tcp
sudo ufw allow 5678/tcp
sudo ufw allow 8080/tcp

# Probar conexión
telnet <tu-ip> 3000
```

### Falta espacio en disco

```bash
# Ver uso de disco
du -sh /var/lib/docker

# Limpiar imágenes sin usar
docker image prune -a

# Limpiar volúmenes sin usar
docker volume prune

# Limpiar contenedores parados
docker container prune
```

---

## 🔒 Configuración Post-Instalación

### 1. Cambiar contraseña admin de Chatwoot

```bash
# En la interfaz web:
# 1. Ir a Settings → Account
# 2. Cambiar contraseña
```

### 2. Cambiar contraseña n8n

```bash
# En .env:
N8N_BASIC_AUTH_PASSWORD=<nueva_contraseña>

# Reiniciar:
docker-compose restart n8n
```

### 3. Backup de .env

```bash
# NUNCA subir .env a Git
# Hacer backup en lugar seguro
cp .env .env.backup
chmod 600 .env .env.backup

# Ver en .gitignore que .env está ahí
grep .env .gitignore
```

---

## 📚 Siguientes Pasos

1. **Leer documentación técnica**
   - [Arquitectura del sistema](../architecture/ARCHITECTURE.md)
   - [API Reference](../api/API_REFERENCE.md)

2. **Configurar automatizaciones**
   - [Flujos n8n](../api/N8N_WORKFLOWS.md)

3. **Preparar para producción**
   - [Guía de despliegue](../deployment/DEPLOYMENT_GUIDE.md)
   - [Checklist de seguridad](../deployment/SECURITY_CHECKLIST.md)

4. **Configurar backups**
   - [Backups automáticos](../deployment/DEPLOYMENT_GUIDE.md#backups)

5. **Monitoreo**
   - [Logging y monitoreo](../troubleshooting/LOGS.md)

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Dificultad**: Media ⭐⭐
