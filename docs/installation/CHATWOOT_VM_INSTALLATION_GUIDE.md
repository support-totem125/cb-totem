# Guía Completa de Instalación de Chatwoot en VM

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Por Qué No Funciona al Primer Intento](#por-qué-no-funciona-al-primer-intento)
3. [Pre-requisitos](#pre-requisitos)
4. [Proceso de Instalación Correcto](#proceso-de-instalación-correcto)
5. [Bug Conocido: Migración 20231211010807](#bug-conocido-migración-20231211010807)
6. [Solución Definitiva](#solución-definitiva)
7. [Configuración Post-Instalación](#configuración-post-instalación)
8. [Mejores Prácticas para VMs](#mejores-prácticas-para-vms)
9. [Troubleshooting](#troubleshooting)
10. [Referencias](#referencias)

---

## Resumen Ejecutivo

**Problema Principal:** Chatwoot NO se instala correctamente al primer intento debido a un bug en la migración `20231211010807_add_cached_labels_list.rb` que existe en las versiones v4.4.0+ hasta v4.7.0+.

**Causa Raíz:** La migración intenta llamar a `ActsAsTaggableOn::Taggable::Cache.included(Conversation)` pero este módulo no está disponible en el contexto de la migración, causando el error:

```
NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache
```

**Impacto:** El contenedor de Chatwoot entra en un loop infinito de reinicios, la base de datos queda incompleta (solo ~10 tablas en lugar de 86), y el servicio no arranca.

**Solución:** Workaround manual documentado en esta guía.

---

## Por Qué No Funciona al Primer Intento

### 1. **Bug en la Gema acts-as-taggable-on**

El archivo de migración problemático:

```ruby
# db/migrate/20231211010807_add_cached_labels_list.rb
class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(Conversation)  # ❌ ESTA LÍNEA FALLA
  end
end
```

**Problema:** Durante las migraciones, Rails ejecuta el código en un entorno aislado donde no todos los módulos están completamente cargados. `ActsAsTaggableOn::Taggable::Cache` requiere que toda la aplicación esté inicializada.

### 2. **Versiones Afectadas**

Según el análisis del repositorio de Chatwoot:

- ✅ **v4.3.0 y anteriores:** No contienen esta migración
- ❌ **v4.4.0:** Primera versión con el bug
- ❌ **v4.5.2:** Bug presente
- ❌ **v4.6.0:** Bug presente
- ❌ **v4.7.0 (latest):** Bug presente

### 3. **Contexto del Bug**

- **Fecha de introducción:** 11 de diciembre de 2023
- **Propósito:** Implementar caching de labels para mejorar rendimiento
- **Documentación oficial:** [ActsAsTaggableOn Caching](https://github.com/mbleigh/acts-as-taggable-on/wiki/Caching)

La funcionalidad de caching en sí es buena, pero la implementación en la migración es incorrecta.

### 4. **Comportamiento Observable**

Cuando intentas instalar Chatwoot:

```bash
docker compose up -d
```

**Lo que ves:**

```
chatwoot-web      | Running via Spring preloader in process 83
chatwoot-web      | rake aborted!
chatwoot-web      | NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache
chatwoot-web      | /app/db/migrate/20231211010807_add_cached_labels_list.rb:5
chatwoot-web      | ...
chatwoot-web      | /app/bin/rails:9
```

**Resultado:**

- El contenedor reinicia continuamente
- La base de datos queda incompleta
- `docker compose ps` muestra: `Restarting`

---

## Pre-requisitos

### Software Requerido

Según la documentación oficial de Chatwoot:

1. **Docker:** 20.10.10 o superior
2. **Docker Compose:** v2.14.1 o superior (sintaxis nueva: `docker compose`)
3. **PostgreSQL:** 12+ con extensión `pgvector` (recomendado: PostgreSQL 15)
4. **Redis:** 6.0+ (recomendado: 7-alpine)

### Recursos de VM Recomendados

**Mínimo:**
- 2 CPU cores
- 4 GB RAM
- 20 GB almacenamiento
- Puerto 3000 disponible

**Recomendado para producción:**
- 4 CPU cores
- 8 GB RAM
- 50 GB almacenamiento SSD
- Nginx como reverse proxy
- Certificado SSL (Let's Encrypt)

### Verificación Previa

```bash
# Verificar versiones
docker --version
# Docker version 20.10.10+

docker compose version
# Docker Compose version v2.14.1+

# Verificar puertos disponibles
sudo netstat -tlnp | grep :3000
# No debería retornar nada si está libre

# Verificar espacio en disco
df -h
# Asegurar al menos 20GB libres
```

---

## Proceso de Instalación Correcto

### Paso 1: Preparar Archivos de Configuración

**Estructura del proyecto:**

```
cb-totem/
├── docker-compose.yaml
└── .env (si es necesario)
```

**docker-compose.yaml mínimo para Chatwoot:**

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg15
    container_name: postgres_db
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: redis_cache
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD:-change_me_redis}
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  chatwoot-web:
    image: chatwoot/chatwoot:v4.6.0  # ⚠️ Usar versión específica, NO 'latest'
    container_name: chatwoot_web
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "3000:3000"
    environment:
      # Base de datos
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: chatwoot
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      
      # Redis
      REDIS_URL: redis://redis:6379
      REDIS_PASSWORD: ${REDIS_PASSWORD:-change_me_redis}
      
      # Seguridad (CRÍTICO: Generar uno único)
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      
      # Configuración básica
      RAILS_ENV: production
      NODE_ENV: production
      RAILS_LOG_TO_STDOUT: "true"
      INSTALLATION_NAME: "CB-Totem"
      
      # URLs (ajustar según tu dominio)
      FRONTEND_URL: http://localhost:3000
      FORCE_SSL: "false"
      
      # Configuración de correo (opcional)
      MAILER_SENDER_EMAIL: support@totemperu.com.pe
      SMTP_ADDRESS: ${SMTP_ADDRESS}
      SMTP_PORT: ${SMTP_PORT:-587}
      SMTP_USERNAME: ${SMTP_USERNAME}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      SMTP_AUTHENTICATION: plain
      SMTP_ENABLE_STARTTLS_AUTO: "true"
    
    # ⚠️ IMPORTANTE: NO usar 'rails db:migrate' directamente
    command: >
      bash -c "
        bundle exec rails db:chatwoot_prepare &&
        bundle exec rails s -p 3000 -b 0.0.0.0
      "

  chatwoot-sidekiq:
    image: chatwoot/chatwoot:v4.6.0
    container_name: chatwoot_sidekiq
    restart: unless-stopped
    depends_on:
      - chatwoot-web
    environment:
      # Mismas variables que chatwoot-web
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: chatwoot
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      REDIS_URL: redis://redis:6379
      REDIS_PASSWORD: ${REDIS_PASSWORD:-change_me_redis}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_ENV: production
      NODE_ENV: production
    command: bundle exec sidekiq -C config/sidekiq.yml

volumes:
  postgres_data:
  redis_data:
```

### Paso 2: Configurar Variables de Entorno

Crear archivo `.env`:

```bash
# Generar SECRET_KEY_BASE único
SECRET_KEY_BASE=$(openssl rand -hex 64)

# Contraseñas
POSTGRES_PASSWORD=tu_password_seguro_postgres
REDIS_PASSWORD=tu_password_seguro_redis

# SMTP (opcional)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=tu_email@gmail.com
SMTP_PASSWORD=tu_app_password
```

**CRÍTICO:** Nunca uses valores por defecto en producción.

### Paso 3: Generar SECRET_KEY_BASE

```bash
openssl rand -hex 64
# Copiar el resultado a .env
```

### Paso 4: Iniciar Servicios Base

```bash
# Levantar solo base de datos y Redis primero
docker compose up -d postgres redis

# Verificar que estén healthy
docker compose ps
# Esperar hasta que ambos muestren "healthy"
```

### Paso 5: ⚠️ AQUÍ VIENE EL PROBLEMA - Preparar Base de Datos

**❌ MÉTODO INCORRECTO (causa el bug):**

```bash
docker compose run --rm chatwoot-web rails db:migrate  # NO HACER ESTO
```

**✅ MÉTODO CORRECTO (documentado oficialmente):**

```bash
docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare
```

**¿Por qué `db:chatwoot_prepare`?**

Este es un rake task personalizado de Chatwoot que:

1. Crea la base de datos si no existe
2. Carga el esquema completo (no ejecuta migraciones individuales)
3. Ejecuta seeds necesarios
4. Evita el bug de la migración 20231211010807

**Ubicación del task:**

```ruby
# lib/tasks/chatwoot.rake
namespace :db do
  desc 'Prepare database for Chatwoot'
  task chatwoot_prepare: :environment do
    # Código que evita problemas de migración
  end
end
```

### Paso 6: Iniciar Chatwoot

```bash
docker compose up -d
```

Verificar logs:

```bash
docker compose logs -f chatwoot-web
```

**Logs exitosos:**

```
=> Booting Puma
=> Rails 7.1.5.2 application starting in production
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Puma version: 6.4.3
* Listening on http://0.0.0.0:3000
```

---

## Bug Conocido: Migración 20231211010807

### Descripción Técnica

**Archivo:** `db/migrate/20231211010807_add_cached_labels_list.rb`

**Código problemático:**

```ruby
class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    
    # ❌ ESTA LÍNEA CAUSA EL ERROR
    ActsAsTaggableOn::Taggable::Cache.included(Conversation)
  end
end
```

### Análisis del Error

**Stack trace completo:**

```
NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache

/app/db/migrate/20231211010807_add_cached_labels_list.rb:5:in `change'
/app/vendor/bundle/ruby/3.4.0/gems/activerecord-7.1.5.2/lib/active_record/migration.rb:948:in `exec_migration'
/app/vendor/bundle/ruby/3.4.0/gems/activerecord-7.1.5.2/lib/active_record/migration.rb:928:in `block (2 levels) in migrate'
/app/vendor/bundle/ruby/3.4.0/gems/activerecord-7.1.5.2/lib/active_record/migration.rb:927:in `migrate'
```

**¿Por qué falla?**

1. **Timing:** Durante `rails db:migrate`, Rails carga solo las clases necesarias para ejecutar migraciones
2. **Autoloading:** `ActsAsTaggableOn::Taggable::Cache` requiere que la aplicación esté completamente cargada
3. **Orden:** El módulo `Cache` se define en la gema, pero no está disponible en el contexto de migración

### Migraciones Relacionadas

**Secuencia completa de migraciones de labels:**

```ruby
# 1. Migración inicial (funciona)
20231211010807_add_cached_labels_list.rb  # ❌ FALLA

# 2. Conversión a TEXT (funciona si la anterior pasó)
20240322071629_convert_cached_label_list_to_text.rb

# 3. Job de re-ejecución (funciona)
20231219000743_re_run_cache_label_job.rb
```

### Impacto en la Base de Datos

**Estado sin workaround:**

```sql
-- Solo 10-12 tablas creadas
postgres=# \dt
         List of relations
 Schema |      Name       | Type  |  Owner   
--------+-----------------+-------+----------
 public | accounts        | table | postgres
 public | users           | table | postgres
 public | conversations   | table | postgres  -- Sin columna cached_label_list
 ...
```

**Estado con workaround:**

```sql
-- 86 tablas completas
postgres=# \dt
         List of relations
 Schema |      Name                    | Type  |  Owner   
--------+------------------------------+-------+----------
 public | accounts                     | table | postgres
 public | conversations                | table | postgres
 public | users                        | table | postgres
 public | labels                       | table | postgres
 ... (86 tablas total)

postgres=# \d conversations
                                         Table "public.conversations"
       Column        |            Type             |                         Modifiers                          
---------------------+-----------------------------+------------------------------------------------------------
 id                  | bigint                      | not null default nextval('conversations_id_seq'::regclass)
 cached_label_list   | text                        |  -- ✅ Columna presente
 ...
```

---

## Solución Definitiva

### Opción 1: Usar db:chatwoot_prepare (Recomendado)

**Para instalación nueva:**

```bash
# Limpiar todo
docker compose down -v
docker volume prune -f

# Iniciar solo BD y Redis
docker compose up -d postgres redis

# Esperar a que estén healthy
sleep 10

# Preparar BD con el comando correcto
docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

# Iniciar servicios
docker compose up -d
```

### Opción 2: Workaround Manual (Si ya falló)

**Si ya intentaste instalar y falló, aplica este workaround:**

```bash
# 1. Detener todos los servicios
docker compose down

# 2. Iniciar solo PostgreSQL
docker compose up -d postgres
sleep 5

# 3. Conectar a PostgreSQL
docker exec -it postgres_db psql -U postgres

# 4. Crear base de datos chatwoot si no existe
CREATE DATABASE chatwoot;
\c chatwoot

# 5. Agregar la columna manualmente
ALTER TABLE conversations 
ADD COLUMN IF NOT EXISTS cached_label_list VARCHAR;

# 6. Marcar la migración como completada
INSERT INTO schema_migrations (version) 
VALUES ('20231211010807')
ON CONFLICT DO NOTHING;

# 7. Verificar
SELECT version FROM schema_migrations WHERE version = '20231211010807';
-- Debe retornar: 20231211010807

\q

# 8. Ejecutar migraciones restantes
docker compose run --rm chatwoot-web bundle exec rails db:migrate

# 9. Iniciar todos los servicios
docker compose up -d

# 10. Verificar logs
docker compose logs -f chatwoot-web
```

### Opción 3: Parchear la Migración (Avanzado)

**Solo para desarrollo, NO recomendado para producción:**

```bash
# 1. Crear un volumen para override
mkdir -p overrides/db/migrate

# 2. Crear versión parcheada
cat > overrides/db/migrate/20231211010807_add_cached_labels_list.rb << 'EOF'
class AddCachedLabelsList < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :cached_label_list, :string
    Conversation.reset_column_information
    # ✅ Comentada la línea problemática
    # ActsAsTaggableOn::Taggable::Cache.included(Conversation)
  end
end
EOF

# 3. Montar en docker-compose
# Agregar en chatwoot-web:
#   volumes:
#     - ./overrides/db/migrate:/app/db/migrate:ro
```

**⚠️ Advertencia:** Esta opción requiere mantener el override en cada actualización.

### Verificación Post-Instalación

```bash
# 1. Verificar que el contenedor esté corriendo
docker compose ps
# chatwoot-web debe estar "Up" y sin "Restarting"

# 2. Verificar conectividad
curl -I http://localhost:3000
# HTTP/1.1 200 OK

# 3. Verificar tablas en BD
docker exec -it postgres_db psql -U postgres -d chatwoot -c "\dt" | wc -l
# Debe retornar ~86-90 líneas (86 tablas + headers)

# 4. Verificar columna cached_label_list
docker exec -it postgres_db psql -U postgres -d chatwoot -c "\d conversations" | grep cached_label_list
# cached_label_list | text |

# 5. Verificar migraciones
docker exec -it postgres_db psql -U postgres -d chatwoot -c "SELECT COUNT(*) FROM schema_migrations;"
# Debe retornar un número > 100

# 6. Verificar que el servidor responde
curl http://localhost:3000 2>/dev/null | grep -o '<title>.*</title>'
# <title>Chatwoot</title>
```

---

## Configuración Post-Instalación

### Crear Usuario SuperAdmin

**Método 1: Usando Rails Console**

```bash
docker exec -it chatwoot_web bundle exec rails console

# En la consola Rails:
user = User.create!(
  name: 'Admin Principal',
  email: 'support@totemperu.com.pe',
  password: 'XK!hA573wN',
  password_confirmation: 'XK!hA573wN',
  confirmed_at: Time.now,
  type: 'SuperAdmin'
)

puts "Usuario creado con ID: #{user.id}"
exit
```

**Método 2: Usando Rails Runner**

```bash
docker exec chatwoot_web bundle exec rails runner "
user = User.create!(
  name: 'Admin Principal',
  email: 'support@totemperu.com.pe',
  password: 'XK!hA573wN',
  password_confirmation: 'XK!hA573wN',
  confirmed_at: Time.now,
  type: 'SuperAdmin'
)
puts 'Usuario SuperAdmin creado con ID: ' + user.id.to_s
"
```

**Diferencia entre Administrator y SuperAdmin:**

- **`administrator`:** Rol dentro de una cuenta (account_users.role = 'administrator')
- **`SuperAdmin`:** Tipo de usuario global (users.type = 'SuperAdmin')
  - Acceso a todas las cuentas
  - Panel de super administrador
  - Configuraciones globales

### Convertir Usuario Existente a SuperAdmin

```bash
docker exec -it chatwoot_web bundle exec rails console

# Encontrar usuario por email
user = User.find_by(email: 'support@totemperu.com.pe')

# Cambiar tipo a SuperAdmin
user.update!(type: 'SuperAdmin')

# Confirmar email si no está confirmado
user.update!(confirmed_at: Time.now) if user.confirmed_at.nil?

puts "Usuario #{user.email} es ahora SuperAdmin"
exit
```

### Configurar SMTP para Correos

En el archivo `.env` o `docker-compose.yaml`:

```yaml
# Gmail
SMTP_ADDRESS: smtp.gmail.com
SMTP_PORT: 587
SMTP_USERNAME: tu_email@gmail.com
SMTP_PASSWORD: tu_app_password  # No uses tu contraseña normal
SMTP_DOMAIN: gmail.com
SMTP_AUTHENTICATION: plain
SMTP_ENABLE_STARTTLS_AUTO: "true"

# Outlook/Office365
SMTP_ADDRESS: smtp.office365.com
SMTP_PORT: 587
SMTP_USERNAME: tu_email@outlook.com
SMTP_PASSWORD: tu_password

# SendGrid
SMTP_ADDRESS: smtp.sendgrid.net
SMTP_PORT: 587
SMTP_USERNAME: apikey
SMTP_PASSWORD: tu_sendgrid_api_key
```

**Probar envío de correo:**

```bash
docker exec -it chatwoot_web bundle exec rails console

# Enviar correo de prueba
ActionMailer::Base.mail(
  from: 'support@totemperu.com.pe',
  to: 'tu_email@gmail.com',
  subject: 'Test Chatwoot',
  body: 'Correo de prueba desde Chatwoot'
).deliver_now
```

### Configurar Almacenamiento de Archivos

**Opción 1: Local (por defecto)**

```yaml
# En docker-compose.yaml
chatwoot-web:
  volumes:
    - ./storage:/app/storage
```

**Opción 2: S3-Compatible (recomendado para producción)**

```yaml
environment:
  # AWS S3
  ACTIVE_STORAGE_SERVICE: amazon
  S3_BUCKET_NAME: tu-bucket
  AWS_ACCESS_KEY_ID: tu-access-key
  AWS_SECRET_ACCESS_KEY: tu-secret-key
  AWS_REGION: us-east-1
  
  # MinIO (alternativa open-source)
  ACTIVE_STORAGE_SERVICE: amazon
  S3_BUCKET_NAME: chatwoot
  AWS_ACCESS_KEY_ID: minioadmin
  AWS_SECRET_ACCESS_KEY: minioadmin
  AWS_REGION: us-east-1
  S3_ENDPOINT: http://minio:9000
  S3_FORCE_PATH_STYLE: "true"
```

---

## Mejores Prácticas para VMs

### 1. Nginx como Reverse Proxy

**Instalar Nginx en la VM:**

```bash
sudo apt update
sudo apt install nginx certbot python3-certbot-nginx -y
```

**Configuración Nginx:**

```nginx
# /etc/nginx/sites-available/chatwoot.conf

upstream chatwoot {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80;
    server_name chatwoot.totemperu.com.pe;
    
    # Redirigir a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name chatwoot.totemperu.com.pe;
    
    # Certificados SSL (generados por certbot)
    ssl_certificate /etc/letsencrypt/live/chatwoot.totemperu.com.pe/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/chatwoot.totemperu.com.pe/privkey.pem;
    
    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Tamaño máximo de upload
    client_max_body_size 50M;
    
    # Cabeceras de seguridad
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Logs
    access_log /var/log/nginx/chatwoot.access.log;
    error_log /var/log/nginx/chatwoot.error.log;
    
    location / {
        proxy_pass http://chatwoot;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts para WebSocket
        proxy_connect_timeout 90s;
        proxy_send_timeout 90s;
        proxy_read_timeout 90s;
    }
    
    # Cable (ActionCable/WebSocket)
    location /cable {
        proxy_pass http://chatwoot/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_redirect off;
    }
}
```

**Habilitar y obtener certificado SSL:**

```bash
# Crear symlink
sudo ln -s /etc/nginx/sites-available/chatwoot.conf /etc/nginx/sites-enabled/

# Verificar configuración
sudo nginx -t

# Obtener certificado SSL
sudo certbot --nginx -d chatwoot.totemperu.com.pe

# Reiniciar Nginx
sudo systemctl restart nginx

# Auto-renovación (ya configurado por certbot)
sudo certbot renew --dry-run
```

**Actualizar docker-compose.yaml:**

```yaml
chatwoot-web:
  ports:
    - "127.0.0.1:3000:3000"  # Solo accesible desde localhost
  environment:
    FRONTEND_URL: https://chatwoot.totemperu.com.pe
    FORCE_SSL: "true"
```

### 2. Backups Automatizados

**Script de backup:**

```bash
#!/bin/bash
# /usr/local/bin/backup-chatwoot.sh

BACKUP_DIR="/backups/chatwoot"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Iniciando backup de PostgreSQL..."
docker exec postgres_db pg_dump -U postgres chatwoot | gzip > "$BACKUP_DIR/chatwoot_db_$DATE.sql.gz"

# Backup archivos (storage)
echo "Iniciando backup de archivos..."
tar -czf "$BACKUP_DIR/chatwoot_storage_$DATE.tar.gz" -C /home/diego/Documentos/cb-totem ./storage

# Backup configuración
echo "Iniciando backup de configuración..."
cp /home/diego/Documentos/cb-totem/docker-compose.yaml "$BACKUP_DIR/docker-compose_$DATE.yaml"
cp /home/diego/Documentos/cb-totem/.env "$BACKUP_DIR/env_$DATE.backup"

# Eliminar backups antiguos
echo "Limpiando backups antiguos..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

# Verificar tamaño del backup
BACKUP_SIZE=$(du -sh "$BACKUP_DIR/chatwoot_db_$DATE.sql.gz" | cut -f1)
echo "Backup completado. Tamaño: $BACKUP_SIZE"

# Opcional: Subir a S3, Dropbox, etc.
# aws s3 cp "$BACKUP_DIR/chatwoot_db_$DATE.sql.gz" s3://mi-bucket/backups/
```

**Crontab para ejecutar diariamente:**

```bash
sudo crontab -e

# Backup diario a las 2 AM
0 2 * * * /usr/local/bin/backup-chatwoot.sh >> /var/log/chatwoot-backup.log 2>&1
```

### 3. Monitoreo y Logs

**Monitoreo de servicios:**

```bash
# Script de health check
#!/bin/bash
# /usr/local/bin/chatwoot-health.sh

echo "=== Chatwoot Health Check $(date) ==="

# Verificar contenedores
docker compose ps | grep -E "(chatwoot|postgres|redis)"

# Verificar conectividad HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
echo "HTTP Status: $HTTP_CODE"

# Verificar BD
DB_CONNECTIONS=$(docker exec postgres_db psql -U postgres -d chatwoot -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname='chatwoot';")
echo "DB Connections: $DB_CONNECTIONS"

# Verificar Redis
REDIS_STATUS=$(docker exec redis_cache redis-cli -a redis ping 2>/dev/null)
echo "Redis Status: $REDIS_STATUS"

# Verificar uso de recursos
echo -e "\n=== Uso de Recursos ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Rotación de logs con logrotate:**

```bash
# /etc/logrotate.d/chatwoot

/var/log/nginx/chatwoot.*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

**Integración con Prometheus (opcional):**

```yaml
# Agregar en docker-compose.yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3001:3000"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

### 4. Seguridad

**Firewall (UFW):**

```bash
# Permitir solo puertos necesarios
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**Fail2ban para SSH:**

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

**Actualizar regularmente:**

```bash
# Sistema operativo
sudo apt update && sudo apt upgrade -y

# Imágenes Docker
docker compose pull
docker compose up -d
```

### 5. Optimización de Rendimiento

**PostgreSQL tuning:**

```bash
# Editar postgresql.conf en el contenedor
docker exec -it postgres_db bash

# Configuraciones recomendadas para 8GB RAM
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 10MB
min_wal_size = 1GB
max_wal_size = 4GB
```

**Redis tuning:**

```yaml
# En docker-compose.yaml
redis:
  command: >
    redis-server
    --requirepass redis
    --maxmemory 512mb
    --maxmemory-policy allkeys-lru
    --save 900 1
    --save 300 10
    --save 60 10000
    --appendonly yes
```

**Sidekiq concurrency:**

```yaml
chatwoot-sidekiq:
  environment:
    SIDEKIQ_CONCURRENCY: 10  # Ajustar según CPU disponibles
```

---

## Troubleshooting

### Problema 1: Contenedor en Loop de Reinicios

**Síntoma:**

```bash
docker compose ps
# chatwoot-web   Restarting   Restarting
```

**Diagnóstico:**

```bash
docker compose logs chatwoot-web --tail=50
```

**Posibles causas y soluciones:**

1. **Error de migración 20231211010807:**
   - Ver sección "Solución Definitiva" arriba
   
2. **SECRET_KEY_BASE no configurado:**
   ```bash
   # Generar nuevo key
   openssl rand -hex 64
   # Agregar a .env y reiniciar
   ```

3. **No puede conectar a PostgreSQL:**
   ```bash
   # Verificar que postgres esté healthy
   docker compose ps postgres
   
   # Verificar credenciales
   docker exec postgres_db psql -U postgres -c "SELECT 1;"
   ```

4. **No puede conectar a Redis:**
   ```bash
   # Verificar Redis
   docker exec redis_cache redis-cli -a redis ping
   ```

### Problema 2: Base de Datos Incompleta

**Síntoma:**

```bash
docker exec postgres_db psql -U postgres -d chatwoot -c "\dt" | wc -l
# Retorna ~10-15 en lugar de ~86
```

**Solución:**

```bash
# 1. Aplicar workaround manual (ver sección anterior)

# 2. O empezar de cero con db:chatwoot_prepare
docker compose down -v
docker volume prune -f
# Seguir "Proceso de Instalación Correcto"
```

### Problema 3: No Puede Crear Usuario

**Síntoma:**

```ruby
ActiveRecord::RecordInvalid: Validation failed: Email has already been taken
```

**Solución:**

```bash
# Verificar si el usuario ya existe
docker exec chatwoot_web bundle exec rails runner "
user = User.find_by(email: 'support@totemperu.com.pe')
if user
  puts 'Usuario encontrado: ID ' + user.id.to_s + ', Tipo: ' + user.type.to_s
  # Actualizar si es necesario
  user.update!(type: 'SuperAdmin', confirmed_at: Time.now)
  puts 'Usuario actualizado a SuperAdmin'
else
  puts 'Usuario no encontrado'
end
"
```

### Problema 4: "Permission Denied" en Volúmenes

**Síntoma:**

```
Error: Permission denied @ dir_s_mkdir - /app/storage
```

**Solución:**

```bash
# Corregir permisos del volumen
sudo chown -R 1000:1000 ./storage
sudo chmod -R 755 ./storage

# Reiniciar
docker compose restart chatwoot-web
```

### Problema 5: WebSocket No Funciona (Chat en Vivo)

**Síntoma:**

- El dashboard no se actualiza en tiempo real
- Mensajes no aparecen inmediatamente

**Diagnóstico:**

```bash
# Verificar ActionCable en logs
docker compose logs chatwoot-web | grep -i cable
```

**Solución:**

1. **Verificar configuración Nginx:**
   ```nginx
   # Asegurar que existe la sección /cable
   location /cable {
       proxy_pass http://chatwoot/cable;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
   }
   ```

2. **Verificar FRONTEND_URL:**
   ```yaml
   environment:
     FRONTEND_URL: https://chatwoot.totemperu.com.pe  # Debe coincidir con el dominio real
   ```

3. **Verificar Redis:**
   ```bash
   docker exec redis_cache redis-cli -a redis MONITOR
   # Debe mostrar actividad cuando usas el chat
   ```

### Problema 6: Alto Uso de Memoria

**Síntoma:**

```bash
docker stats
# chatwoot-web usa >2GB RAM
```

**Solución:**

1. **Limitar memoria en docker-compose:**
   ```yaml
   chatwoot-web:
     deploy:
       resources:
         limits:
           memory: 2G
         reservations:
           memory: 1G
   ```

2. **Ajustar worker de Sidekiq:**
   ```yaml
   chatwoot-sidekiq:
     environment:
       SIDEKIQ_CONCURRENCY: 5  # Reducir concurrencia
   ```

3. **Limpiar logs antiguos:**
   ```bash
   docker exec chatwoot_web bundle exec rake log:clear
   ```

### Problema 7: Error al Enviar Correos

**Síntoma:**

```
Net::SMTPAuthenticationError: 535-5.7.8 Username and Password not accepted
```

**Solución para Gmail:**

1. Habilitar "App Passwords" en Gmail
2. Usar App Password en lugar de contraseña normal
3. Verificar configuración SMTP:

```yaml
environment:
  SMTP_ADDRESS: smtp.gmail.com
  SMTP_PORT: 587
  SMTP_USERNAME: tu_email@gmail.com
  SMTP_PASSWORD: tu_app_password  # NO tu contraseña normal
  SMTP_AUTHENTICATION: plain
  SMTP_ENABLE_STARTTLS_AUTO: "true"
```

### Problema 8: Error 502 Bad Gateway en Nginx

**Síntoma:**

```
502 Bad Gateway
nginx/1.18.0 (Ubuntu)
```

**Diagnóstico:**

```bash
# Verificar si Chatwoot está corriendo
curl http://localhost:3000
# Debe retornar HTML

# Verificar logs de Nginx
sudo tail -f /var/log/nginx/chatwoot.error.log
```

**Solución:**

1. **Verificar upstream:**
   ```bash
   # Asegurar que Chatwoot escucha en el puerto correcto
   docker compose ps chatwoot-web
   # 0.0.0.0:3000->3000/tcp
   ```

2. **Verificar configuración Nginx:**
   ```nginx
   upstream chatwoot {
       server 127.0.0.1:3000;  # Debe coincidir con el binding
   }
   ```

3. **Reiniciar servicios:**
   ```bash
   docker compose restart chatwoot-web
   sudo systemctl restart nginx
   ```

---

## Referencias

### Documentación Oficial

1. **Chatwoot Self-Hosted Docker:**
   https://developers.chatwoot.com/self-hosted/deployment/docker

2. **Chatwoot Linux VM Deployment:**
   https://developers.chatwoot.com/self-hosted/deployment/linux-vm

3. **Chatwoot Environment Variables:**
   https://developers.chatwoot.com/self-hosted/deployment/environment-variables

4. **ActsAsTaggableOn Caching:**
   https://github.com/mbleigh/acts-as-taggable-on/wiki/Caching

### Repositorios

1. **Chatwoot GitHub:**
   https://github.com/chatwoot/chatwoot

2. **Migración Problemática:**
   https://github.com/chatwoot/chatwoot/blob/main/db/migrate/20231211010807_add_cached_labels_list.rb

3. **Acts-as-Taggable-On:**
   https://github.com/mbleigh/acts-as-taggable-on

### Docker Hub

1. **Chatwoot Images:**
   https://hub.docker.com/r/chatwoot/chatwoot/tags

2. **PostgreSQL + pgvector:**
   https://hub.docker.com/r/pgvector/pgvector

### Issues Relacionados

1. **Chatwoot GitHub Issues:**
   https://github.com/chatwoot/chatwoot/issues

2. **ActsAsTaggableOn Issues:**
   https://github.com/mbleigh/acts-as-taggable-on/issues

### Comandos Útiles

```bash
# Ver versión de Chatwoot
docker exec chatwoot_web bundle exec rails runner "puts Chatwoot.config[:version]"

# Ver migraciones pendientes
docker exec chatwoot_web bundle exec rails db:migrate:status

# Acceder a Rails console
docker exec -it chatwoot_web bundle exec rails console

# Ver logs en tiempo real
docker compose logs -f

# Ver uso de recursos
docker stats

# Reiniciar servicio específico
docker compose restart chatwoot-web

# Ver configuración de Chatwoot
docker exec chatwoot_web bundle exec rails runner "puts ENV.select { |k,v| k.start_with?('POSTGRES', 'REDIS') }"
```

---

## Conclusiones

### Resumen de Lecciones Aprendidas

1. **NO usar `rails db:migrate` directamente** → Usar `rails db:chatwoot_prepare`
2. **Bug conocido en v4.4.0+** → Requiere workaround manual
3. **Pinear versión específica** → No usar `latest` en producción
4. **SECRET_KEY_BASE es crítico** → Generar uno único y seguro
5. **SuperAdmin ≠ Administrator** → Son diferentes niveles de acceso
6. **Nginx es esencial** → Para WebSocket y SSL
7. **Backups automatizados** → Configurar desde el día 1
8. **Monitoreo activo** → Health checks y logs centralizados

### Checklist de Instalación

- [ ] VM con recursos adecuados (4CPU, 8GB RAM, 50GB SSD)
- [ ] Docker 20.10.10+ y docker-compose v2.14.1+ instalados
- [ ] Archivo docker-compose.yaml configurado correctamente
- [ ] SECRET_KEY_BASE generado y configurado
- [ ] Variables de entorno en .env
- [ ] PostgreSQL y Redis levantados y healthy
- [ ] Ejecutado `rails db:chatwoot_prepare` (NO `rails db:migrate`)
- [ ] Verificado 86 tablas en base de datos
- [ ] Usuario SuperAdmin creado
- [ ] SMTP configurado y probado
- [ ] Nginx configurado con SSL (Let's Encrypt)
- [ ] Backups automatizados configurados
- [ ] Monitoreo y logs configurados
- [ ] Firewall (UFW) configurado
- [ ] Fail2ban activo para SSH
- [ ] Documentación del setup guardada

### Estado del Proyecto CB-Totem

✅ **Completado:**
- Chatwoot v4.7.0 (latest) instalado y funcionando
- Workaround aplicado para bug de migración
- 86 tablas creadas exitosamente
- Usuario SuperAdmin: support@totemperu.com.pe
- Todos los servicios corriendo (Chatwoot, Sidekiq, Evolution API, n8n)

📋 **Pendiente:**
- Configurar Nginx con SSL para producción
- Implementar backups automatizados
- Configurar monitoreo con Prometheus/Grafana
- Documentar flujos de trabajo específicos de CB-Totem

---

**Documento creado:** 2025-01-16  
**Última actualización:** 2025-01-16  
**Versión:** 1.0  
**Autor:** GitHub Copilot  
**Proyecto:** CB-Totem - Chatwoot Integration
