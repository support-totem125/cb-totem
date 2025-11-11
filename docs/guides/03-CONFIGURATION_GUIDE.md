# ⚙️ Guía de Configuración por Ambiente

> Cómo configurar Chat-Bot Totem para diferentes entornos (desarrollo, staging, producción)

---

## 📋 Tabla de Contenidos

1. [Configuración General](#configuración-general)
2. [Desarrollo (Localhost)](#desarrollo-localhost)
3. [Staging (Red Interna)](#staging-red-interna)
4. [Producción (Dominio HTTPS)](#producción-dominio-https)
5. [Variables de Entorno Detalladas](#variables-de-entorno-detalladas)
6. [Generador de Contraseñas](#generador-de-contraseñas)

---

## 🎯 Configuración General

### DOMAIN_HOST (Variable Principal)

Esta es la **variable más importante**. Define dónde está accesible tu instancia:

```bash
# Desarrollo
DOMAIN_HOST=localhost

# Staging (Red interna)
DOMAIN_HOST=192.168.1.74

# Producción
DOMAIN_HOST=chatbot.tudominio.com
```

Automáticamente se usa en:
- `CHATWOOT_FRONTEND_URL=http://${DOMAIN_HOST}:3000`
- `N8N_WEBHOOK_URL=http://${DOMAIN_HOST}:5678/`
- `N8N_HOST=${DOMAIN_HOST}`
- `ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=${DOMAIN_HOST},...`

### SERVER_IP_ADDR (IP del Servidor)

```bash
# Desarrollo
SERVER_IP_ADDR=127.0.0.1

# Staging
SERVER_IP_ADDR=192.168.1.74

# Producción
SERVER_IP_ADDR=192.168.1.100  # IP real del servidor
```

---

## 🖥️ Desarrollo (Localhost)

### Configuración Recomendada

```bash
# === SERVIDOR ===
DOMAIN_HOST=localhost
SERVER_IP_ADDR=127.0.0.1

# === SEGURIDAD ===
FORCE_SSL=false
N8N_PROTOCOL=http
N8N_SECURE_COOKIE=false

# === LOGGING ===
DEBUG=true
LOG_LEVEL=debug
RAILS_LOG_TO_STDOUT=true
N8N_LOG_OUTPUT=console

# === BASE DE DATOS ===
POSTGRES_PASSWORD=dev123456      # Puede ser simple en desarrollo
REDIS_PASSWORD=dev123456
DATABASE_POOL_SIZE=5

# === CHATWOOT ===
CHATWOOT_SECRET_KEY_BASE=<generar>

# === N8N ===
N8N_BASIC_AUTH_PASSWORD=admin123
N8N_ENCRYPTION_KEY=<generar>

# === TIMEOUTS ===
REQUEST_TIMEOUT=30000
POSTGRES_TIMEOUT=10
```

### Instalación

```bash
cp .env.example .env

# Editar valores arriba
nano .env

# Iniciar
docker-compose up -d
docker-compose logs -f
```

### Verificación

```bash
# Acceso directo
curl http://localhost:3000
curl http://localhost:5678
curl http://localhost:8080

# Ver logs en tiempo real
docker-compose logs -f chatwoot-web
docker-compose logs -f n8n
```

### Comandos útiles para desarrollo

```bash
# Ver logs detallados
docker-compose logs -f

# Ejecutar rake en Chatwoot
docker-compose exec chatwoot-web bundle exec rake db:reset

# Recompiler assets de Chatwoot
docker-compose exec chatwoot-web bundle exec rake assets:precompile

# Ejecutar migraciones manually
docker-compose exec chatwoot-web bundle exec rails db:migrate

# Acceder a Rails console
docker-compose exec chatwoot-web bundle exec rails console
```

---

## 🌐 Staging (Red Interna)

### Configuración Recomendada

```bash
# === SERVIDOR ===
DOMAIN_HOST=192.168.1.74        # Tu IP en la red
SERVER_IP_ADDR=192.168.1.74
HOSTNAME=chatbot-staging

# === SEGURIDAD ===
FORCE_SSL=false
N8N_PROTOCOL=http
N8N_SECURE_COOKIE=false

# === LOGGING ===
LOG_LEVEL=info
RAILS_LOG_TO_STDOUT=true
N8N_LOG_OUTPUT=console

# === BASE DE DATOS ===
POSTGRES_PASSWORD=<generar: openssl rand -hex 16>
REDIS_PASSWORD=<generar: openssl rand -hex 16>
DATABASE_POOL_SIZE=10

# === CHATWOOT ===
CHATWOOT_SECRET_KEY_BASE=<generar: openssl rand -hex 64>
CHATWOOT_MAIL_FROM_EMAIL=noreply@staging.internal
FORCE_EMAIL_DELIVERY=true

# === N8N ===
N8N_BASIC_AUTH_PASSWORD=<generar segura>
N8N_ENCRYPTION_KEY=<generar: openssl rand -hex 32>

# === ACTION CABLE ===
ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=192.168.1.74,192.168.1.*,localhost,127.0.0.1
```

### Instalación

```bash
# En el servidor staging:
git clone https://github.com/diego-moscaiza/chat-bot-totem.git
cd chat-bot-totem

cp .env.example .env
nano .env  # Editar valores arriba

docker-compose up -d
```

### Verificación

```bash
# Desde otra máquina en la red:
curl -I http://192.168.1.74:3000
curl -I http://192.168.1.74:5678

# Verificar firewall (si necesario)
sudo ufw allow 3000/tcp
sudo ufw allow 5678/tcp
sudo ufw allow 8080/tcp
```

### Backups regulares

```bash
# Script de backup diario
#!/bin/bash
BACKUP_DIR="/backups/chatwoot"
mkdir -p $BACKUP_DIR

docker-compose exec -T postgres_db pg_dump -U postgres chatwoot > \
  $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql

# Guardar solo últimos 7 días
find $BACKUP_DIR -type f -mtime +7 -delete
```

---

## 🚀 Producción (Dominio HTTPS)

### Configuración Recomendada

```bash
# === SERVIDOR ===
DOMAIN_HOST=chatbot.tudominio.com
SERVER_IP_ADDR=192.168.1.100        # IP real del servidor
HOSTNAME=chatbot-prod

# === SEGURIDAD ===
FORCE_SSL=true
N8N_PROTOCOL=https
N8N_SECURE_COOKIE=true
SESSION_COOKIE_SECURE=true

# === LOGGING ===
LOG_LEVEL=warn
RAILS_LOG_TO_STDOUT=true
N8N_LOG_OUTPUT=console
SENTRY_DSN=<opcional - para error tracking>

# === BASE DE DATOS ===
POSTGRES_PASSWORD=<generar: openssl rand -hex 16>
REDIS_PASSWORD=<generar: openssl rand -hex 16>
DATABASE_POOL_SIZE=20
DATABASE_TIMEOUT=30

# === CHATWOOT ===
CHATWOOT_SECRET_KEY_BASE=<generar: openssl rand -hex 64>
CHATWOOT_MAIL_FROM_EMAIL=noreply@chatbot.tudominio.com
FORCE_EMAIL_DELIVERY=true
SMTP_ADDRESS=smtp.tuservidor.com
SMTP_PORT=587
SMTP_USERNAME=<tu-email>
SMTP_PASSWORD=<tu-contraseña>
SMTP_AUTHENTICATION=plain

# === N8N ===
N8N_BASIC_AUTH_PASSWORD=<generar segura - min 12 caracteres>
N8N_ENCRYPTION_KEY=<generar: openssl rand -hex 32>
N8N_WEBHOOK_URL=https://chatbot.tudominio.com/webhook/

# === EVOLUTION API ===
EVOLUTION_API_KEY=<generar segura>

# === TIMEOUTS ===
REQUEST_TIMEOUT=60000
POSTGRES_TIMEOUT=30

# === ACTION CABLE ===
ACTION_CABLE_ALLOWED_REQUEST_ORIGINS=chatbot.tudominio.com,localhost,127.0.0.1
```

### Instalación Pre-requisitos

Antes de iniciar, debes tener:

1. **Dominio DNS configurado**
   ```bash
   # Apunta a la IP de tu servidor
   chatbot.tudominio.com A 192.168.1.100
   ```

2. **Certificado SSL**
   ```bash
   # Con Let's Encrypt (gratuito)
   sudo certbot certonly --standalone -d chatbot.tudominio.com
   
   # O con tu proveedor de SSL
   ```

3. **Proxy Reverso (Nginx o Caddy)**
   
   **Nginx:**
   ```nginx
   # /etc/nginx/sites-available/chatbot
   server {
       listen 80;
       server_name chatbot.tudominio.com;
       
       # Redirigir HTTPS
       return 301 https://$server_name$request_uri;
   }
   
   server {
       listen 443 ssl http2;
       server_name chatbot.tudominio.com;
       
       ssl_certificate /etc/letsencrypt/live/chatbot.tudominio.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/chatbot.tudominio.com/privkey.pem;
       
       # Configuración SSL
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers on;
       
       # Headers de seguridad
       add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
       add_header X-Content-Type-Options "nosniff" always;
       add_header X-Frame-Options "SAMEORIGIN" always;
       
       # Proxy a Chatwoot
       location / {
           proxy_pass http://localhost:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto https;
       }
   }
   ```
   
   **Caddy:**
   ```caddy
   chatbot.tudominio.com {
       reverse_proxy localhost:3000 {
           header_uri X-Forwarded-Proto https
           header_uri X-Forwarded-Host {host}
       }
   }
   ```

4. **Firewall**
   ```bash
   # UFW (Ubuntu)
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   
   # Bloquear puertos internos
   sudo ufw deny 3000/tcp
   sudo ufw deny 5678/tcp
   sudo ufw deny 8080/tcp
   ```

### Instalación

```bash
# En el servidor producción:
git clone https://github.com/diego-moscaiza/chat-bot-totem.git
cd chat-bot-totem

cp .env.example .env
nano .env  # Editar valores arriba

# CRÍTICO: No expongas .env en Git
echo ".env" >> .gitignore
git add .gitignore && git commit -m "Add .env to gitignore"

docker-compose up -d
```

### Verificación

```bash
# HTTPS debe funcionar
curl -I https://chatbot.tudominio.com

# Ver certificado
openssl s_client -connect chatbot.tudominio.com:443

# Monitorear en tiempo real
docker-compose logs -f
```

### Backups automáticos

```bash
# Script cron diario
#!/bin/bash
BACKUP_DIR="/backups/chatwoot"
S3_BUCKET="s3://mi-bucket/backups"
mkdir -p $BACKUP_DIR

# Backup local
docker-compose exec -T postgres_db pg_dump -U postgres chatwoot | \
  gzip > $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Subir a S3
aws s3 sync $BACKUP_DIR $S3_BUCKET --delete

# Guardar solo últimos 30 días localmente
find $BACKUP_DIR -type f -mtime +30 -delete
```

Agregar a crontab:
```bash
0 2 * * * /root/scripts/backup.sh
```

### Monitoreo

```bash
# Script de monitoreo
#!/bin/bash
ALERTEMAIL="admin@tudominio.com"

# Verificar servicios
docker-compose ps | grep -q "Up.*chatwoot-web" || \
  mail -s "ALERTA: Chatwoot caído" $ALERTEMAIL

# Verificar espacio
ESPACIO_USADO=$(du -sh /var/lib/docker | awk '{print $1}')
if [ $ESPACIO_USADO -gt 40G ]; then
  mail -s "ALERTA: Espacio bajo" $ALERTEMAIL
fi

# Verificar base de datos
docker-compose exec -T postgres_db pg_isready -U postgres || \
  mail -s "ALERTA: PostgreSQL caído" $ALERTEMAIL
```

Agregar a crontab:
```bash
*/15 * * * * /root/scripts/monitor.sh
```

---

## 📝 Variables de Entorno Detalladas

### Red / Dominio

| Variable         | Desarrollo  | Staging       | Producción    |
| ---------------- | ----------- | ------------- | ------------- |
| `DOMAIN_HOST`    | `localhost` | `192.168.x.x` | `dominio.com` |
| `SERVER_IP_ADDR` | `127.0.0.1` | `192.168.x.x` | `IP_real`     |
| `FORCE_SSL`      | `false`     | `false`       | `true`        |
| `N8N_PROTOCOL`   | `http`      | `http`        | `https`       |

### Seguridad

| Variable                   | Descripción               | Cómo generar           |
| -------------------------- | ------------------------- | ---------------------- |
| `POSTGRES_PASSWORD`        | Contraseña BD             | `openssl rand -hex 16` |
| `REDIS_PASSWORD`           | Contraseña cache          | `openssl rand -hex 16` |
| `CHATWOOT_SECRET_KEY_BASE` | Clave secreta Chatwoot    | `openssl rand -hex 64` |
| `N8N_ENCRYPTION_KEY`       | Clave de encriptación n8n | `openssl rand -hex 32` |
| `N8N_BASIC_AUTH_PASSWORD`  | Contraseña n8n            | Min 12 caracteres      |
| `EVOLUTION_API_KEY`        | API key Evolution         | Generar en panel       |

### Logging

| Variable              | Valores                  | Recomendado              |
| --------------------- | ------------------------ | ------------------------ |
| `LOG_LEVEL`           | debug, info, warn, error | debug (dev), warn (prod) |
| `DEBUG`               | true/false               | true (dev), false (prod) |
| `RAILS_LOG_TO_STDOUT` | true/false               | true (siempre)           |

---

## 🔐 Generador de Contraseñas

### Script automatizado

```bash
#!/bin/bash
# generate-secrets.sh

echo "🔐 Generando secretos criptográficos..."
echo ""

echo "POSTGRES_PASSWORD=$(openssl rand -hex 16)"
echo "REDIS_PASSWORD=$(openssl rand -hex 16)"
echo "CHATWOOT_SECRET_KEY_BASE=$(openssl rand -hex 64)"
echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)"
echo "N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 12)"

echo ""
echo "✅ Copia los valores arriba a tu .env"
```

Ejecutar:
```bash
chmod +x generate-secrets.sh
./generate-secrets.sh
```

---

## ✅ Checklist de Configuración

### Desarrollo
- [ ] Cloné repositorio
- [ ] Copié `.env.example` a `.env`
- [ ] Edité `DOMAIN_HOST=localhost`
- [ ] Ejecuté `docker-compose up -d`
- [ ] Verificué acceso en http://localhost:3000

### Staging
- [ ] Cloné repositorio en servidor staging
- [ ] Copié y edité `.env`
- [ ] Cambié `DOMAIN_HOST` a IP del servidor
- [ ] Generé contraseñas seguras
- [ ] Configuré firewall
- [ ] Ejecuté `docker-compose up -d`
- [ ] Verifiqué acceso desde otra máquina
- [ ] Creé script de backups

### Producción
- [ ] Cloné repositorio en servidor producción
- [ ] Copié y edité `.env`
- [ ] Cambié `DOMAIN_HOST` a dominio
- [ ] Generé todas las contraseñas
- [ ] Cambié `FORCE_SSL=true`
- [ ] Instalé certificado SSL
- [ ] Configuré proxy reverso (Nginx/Caddy)
- [ ] Configuré firewall
- [ ] Ejecuté `docker-compose up -d`
- [ ] Verificé HTTPS funciona
- [ ] Configuré backups automáticos
- [ ] Configuré monitoreo
- [ ] Ejecuté [SECURITY_CHECKLIST.md](../deployment/SECURITY_CHECKLIST.md)

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Dificultad**: Media ⭐⭐
