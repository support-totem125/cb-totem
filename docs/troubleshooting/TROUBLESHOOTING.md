# 🔧 Guía de Troubleshooting

> Solución de problemas comunes en Chat-Bot Totem

---

## 📋 Tabla de Contenidos

1. [Problemas Generales](#problemas-generales)
2. [Chatwoot](#chatwoot)
3. [n8n](#n8n)
4. [calidda-api](#calidda-api)
5. [PostgreSQL](#postgresql)
6. [Redis](#redis)
7. [Redes y Conectividad](#redes-y-conectividad)
8. [Performance](#performance)

---

## 🚨 Problemas Generales

### Docker no inicia

**Error**: "Cannot connect to Docker daemon"

**Causas posibles**:
- Docker no está instalado
- Docker no está corriendo
- Usuario no tiene permisos

**Solución**:
```bash
# Verificar Docker está instalado
docker --version

# Iniciar Docker (si está instalado)
sudo systemctl start docker

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Reintentar
docker ps
```

---

### Docker Compose no funciona

**Error**: "command not found: docker-compose"

**Causas posibles**:
- Docker Compose no instalado
- Versión muy antigua

**Solución**:
```bash
# Verificar versión
docker-compose --version

# Si no está instalado:
sudo apt-get install docker-compose

# O instalar última versión:
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

### Puertos en uso

**Error**: "bind: address already in use"

**Causas posibles**:
- Puerto ya ocupado por otro servicio
- Contenedor anterior no paró

**Solución**:
```bash
# Encontrar qué está usando puerto (ej: 3000)
sudo lsof -i :3000
# o
sudo netstat -tulpn | grep 3000

# Matar proceso
sudo kill -9 <PID>

# O cambiar puerto en docker-compose.yaml:
# ports: ["3001:3000"]

# O parar todos los contenedores
docker-compose down
```

---

## � Chatwoot

### Chatwoot no inicia - Error de /bin/bash

**Error exacto**:
```
Error response from daemon: failed to create task for container: 
error during container init: exec: "/bin/bash": 
stat /bin/bash: no such file or directory: unknown
```

**Contenedor afectado**: `chatwoot_web`

**Causa**: 
La imagen de Chatwoot usa Alpine Linux (imagen pequeña) que no tiene `/bin/bash`. El `docker-compose.yaml` estaba especificando un entrypoint incorrecto.

**Solución**:
```yaml
# Cambiar en docker-compose.yaml, sección chatwoot-web:

# ANTES (❌ Incorrecto):
entrypoint: /bin/bash

# DESPUÉS (✅ Correcto):
entrypoint: /bin/sh
```

Luego reiniciar:
```bash
docker compose down
docker compose up -d
```

**Explicación técnica**:
- Alpine Linux es minimalista (~5MB vs ~100MB)
- Solo tiene `/bin/sh` (POSIX shell), no `/bin/bash`
- Tanto `/bin/sh` como `/bin/bash` funcionan para ejecutar scripts shell

---

### Chatwoot no inicia / Crashea

**Error en logs**:
```
ERROR: relation "users" does not exist
ERROR: PG::UndefinedTable
exit code 137
exit code 1
```

**Causa**: Las migraciones de base de datos no se ejecutaron

**Solución Rápida**:
```bash
# 1. Ver logs detallados
docker-compose logs chatwoot-web

# 2. Esperar 2-3 minutos (migraciones ejecutándose)
sleep 180

# 3. Verificar si se resolvió
docker-compose logs chatwoot-web | tail -20

# 4. Si sigue fallando, reiniciar
docker-compose restart chatwoot-web

# 5. Si aún no funciona, verificar postgresql
docker-compose logs postgres_db
```

**Si PostgreSQL es el problema**:
```bash
# Eliminar y recrear PostgreSQL
docker-compose down -v
docker-compose up -d postgres_db
sleep 30
docker-compose up -d
```

---

### Chatwoot muy lento

**Síntomas**:
- Las páginas cargan lentamente
- Respuestas tardadas a clics
- CPU/RAM en 100%

**Causas posibles**:
- Falta memoria
- Base de datos sin índices
- Too many connections

**Solución**:
```bash
# 1. Ver recursos
docker stats chatwoot-web

# 2. Si RAM < 500MB, aumentar en docker-compose.yaml:
deploy:
  resources:
    limits:
      memory: 2G

# 3. Verificar conexiones a BD
docker-compose exec postgres_db psql -U postgres -c \
  "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# 4. Si hay muchas conexiones:
# Aumentar en .env: DATABASE_POOL_SIZE=25

# 5. Reiniciar
docker-compose down
docker-compose up -d
```

---

### Error 500 en Chatwoot

**Síntomas**:
- "500 Internal Server Error"
- Algunas páginas funcionan, otras no

**Causas posibles**:
- Error en código
- Base de datos corrupta
- Sesión inválida

**Solución**:
```bash
# 1. Ver logs de error
docker-compose logs chatwoot-web | grep -i error | tail -50

# 2. Verificar base de datos
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "SELECT COUNT(*) FROM users;"

# 3. Limpiar sesiones (si es cache)
docker-compose exec redis_cache redis-cli FLUSHDB

# 4. Reiniciar Chatwoot
docker-compose restart chatwoot-web

# 5. Si persiste, resetear base de datos (DESTRUCTIVO):
docker-compose exec chatwoot-web bundle exec rails db:reset
```

---

### No puedo acceder a Chatwoot

**Síntomas**:
- Connection refused
- Timeout
- No carga

**Causas posibles**:
- Chatwoot no está corriendo
- Firewall bloqueando
- Puerto incorrecto

**Solución**:
```bash
# 1. Verificar que está corriendo
docker-compose ps | grep chatwoot

# 2. Verificar puerto
docker-compose exec chatwoot-web netstat -tulpn | grep 3000

# 3. Probar acceso local
curl http://localhost:3000

# 4. Ver logs
docker-compose logs chatwoot-web

# 5. Verificar DOMAIN_HOST
grep DOMAIN_HOST .env

# 6. Si usas IP/dominio:
curl http://<tu-ip>:3000
# Si no funciona, es firewall

# 7. Configurar firewall
sudo ufw allow 3000/tcp
```

---

## 🟡 n8n

### n8n no inicia

**Error en logs**:
```
Error initializing database
Cannot find encryption key
```

**Causa**: N8N_ENCRYPTION_KEY no configurada

**Solución**:
```bash
# 1. Ver logs
docker-compose logs n8n

# 2. Verificar variable
grep N8N_ENCRYPTION_KEY .env

# 3. Si está vacía, generar:
echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)"

# 4. Actualizar .env
nano .env
# Pegar el valor arriba

# 5. Reiniciar
docker-compose restart n8n
```

---

### Webhooks no funcionan

**Síntomas**:
- n8n no recibe webhooks de Chatwoot
- Eventos no se activan

**Causas posibles**:
- URL de webhook incorrecta
- Firewall bloqueando
- n8n no accesible desde Chatwoot

**Solución**:
```bash
# 1. Verificar que n8n está corriendo
docker-compose ps n8n

# 2. Probar acceso a n8n
curl http://localhost:5678

# 3. Probar desde contenedor Chatwoot:
docker-compose exec chatwoot-web curl http://n8n:5678

# 4. Ver logs de n8n
docker-compose logs -f n8n

# 5. En n8n, verificar webhook URL:
# Debería ser: http://n8n:5678/webhook/...
# NO: http://localhost:5678/webhook/...

# 6. Si Chatwoot está en otro servidor:
# Usar URL pública: https://dominio.com/webhook/...
# Configurar en .env: N8N_WEBHOOK_URL=https://dominio.com
```

---

### Workflows lentos o se cuelgan

**Síntomas**:
- Workflow tarda mucho
- Se queda en pausa indefinida
- Timeout errors

**Causas posibles**:
- Consulta a API externa lenta
- Timeout configurado bajo
- Recursos insuficientes

**Solución**:
```bash
# 1. Verificar recursos
docker stats n8n

# 2. Aumentar timeout en .env:
REQUEST_TIMEOUT=60000  # 60 segundos

# 3. En workflow n8n, aumentar timeout:
# HTTP Request node → Timeout: 60s

# 4. Agregar reintentos:
# HTTP Request node → Retry: 3 veces con backoff

# 5. Si es calidda-api:
# Verificar que calidda-api responde
docker-compose logs calidda-api
curl http://localhost:5000/health
```

---

### Error de autenticación en n8n

**Error**: "Invalid username or password"

**Causa**: Contraseña incorrecta

**Solución**:
```bash
# 1. Verificar contraseña en .env
grep N8N_BASIC_AUTH_PASSWORD .env

# 2. Usar esa contraseña para login
# Usuario: admin (default)

# 3. Si olvidaste, cambiar:
# (Nota: requiere resetear n8n)
# docker-compose exec n8n n8n user-management:update --email=admin@example.com

# 4. O más simple, en .env:
N8N_BASIC_AUTH_PASSWORD=nueva_contraseña

# Reiniciar:
docker-compose restart n8n
```

---

## 🔴 calidda-api

### calidda-api devuelve 500

**Error en respuesta**:
```json
{"error": "Internal Server Error"}
```

**Causas posibles**:
- Error en código
- Conexión a FNB fallida
- Credenciales incorrectas

**Solución**:
```bash
# 1. Ver logs detallados
docker-compose logs calidda-api

# 2. Verificar que está corriendo
docker-compose ps calidda-api

# 3. Probar endpoint de salud
curl http://localhost:5000/health

# 4. Probar con ejemplo
curl -X POST http://localhost:5000/query \
  -H 'Content-Type: application/json' \
  -d '{"dni":"08408122"}'

# 5. Ver logs mientras se ejecuta
docker-compose logs -f calidda-api

# 6. Posible error de sesión:
# Verificar CALIDDA_SESSION_TTL en .env
# Si está bajo (< 60), aumentar:
CALIDDA_SESSION_TTL=3600

# 7. Limpiar sesiones Redis:
docker-compose exec redis_cache redis-cli DEL calidda_session_*
```

---

### calidda-api lento

**Síntomas**:
- Consultas tardan >10 segundos
- Timeout en n8n

**Causa**: Sesión FNB expirando, requiere relogin cada vez

**Solución**:
```bash
# 1. Aumentar SESSION_TTL en .env:
CALIDDA_SESSION_TTL=7200  # 2 horas

# 2. Reiniciar
docker-compose restart calidda-api

# 3. Monitorear en logs
docker-compose logs -f calidda-api

# 4. Verificar FNB está accesible:
docker-compose exec calidda-api ping <ip-fnb>

# 5. Ver estado de Redis
docker-compose exec redis_cache redis-cli INFO memory
```

---

### "No such module" error

**Error**:
```
ModuleNotFoundError: No module named 'vcc_totem'
```

**Causa**: Dependencias no instaladas

**Solución**:
```bash
# 1. Verificar que vcc-totem existe
ls -la vcc-totem/

# 2. Verificar que está montado en calidda-api
docker-compose exec calidda-api ls -la /src/

# 3. Instalar dependencias
docker-compose exec calidda-api pip install -r requirements.txt

# 4. Reiniciar
docker-compose restart calidda-api
```

---

## 🟣 PostgreSQL

### PostgreSQL no inicia

**Error**:
```
initdb: error: could not access directory "/var/lib/postgresql/data": Permission denied
```

**Causa**: Permisos de archivo

**Solución**:
```bash
# 1. Detener y limpiar
docker-compose down -v

# 2. Recrear con permisos correctos
docker-compose up -d postgres_db

# 3. Esperar a que inicie
sleep 30

# 4. Verificar
docker-compose logs postgres_db
```

---

### Base de datos corrupta

**Error**:
```
relation does not exist
index does not exist
```

**Causa**: Base de datos inconsistente

**Solución**:
```bash
# 1. Ver estado
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "SELECT COUNT(*) FROM users;"

# 2. Si falla, intentar reparación:
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "REINDEX DATABASE chatwoot;"

# 3. Si sigue, resetear (DESTRUCTIVO - BORRA TODO):
docker-compose down -v
docker-compose up -d
docker-compose logs -f postgres_db  # Esperar inicialización
```

---

### PostgreSQL muy lento

**Síntomas**:
- Queries lentas
- CPU en 100%

**Causas posibles**:
- Índices faltantes
- Vacuum no corriendo
- Stats outdated

**Solución**:
```bash
# 1. Analizar tabla
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "ANALYZE chatwoot_schema.users;"

# 2. Vacuum
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "VACUUM ANALYZE chatwoot_schema.users;"

# 3. Ver tablas grandes
docker-compose exec postgres_db psql -U postgres -d chatwoot -c "
  SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
  FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 10;"

# 4. Si una tabla es muy grande, considerar partición (avanzado)
```

---

## 🔵 Redis

### Redis no inicia

**Error**:
```
port 6379 already in use
```

**Causas posibles**:
- Puerto en uso
- Redis anterior no paró

**Solución**:
```bash
# 1. Encontrar proceso
sudo lsof -i :6379

# 2. Matar
sudo kill -9 <PID>

# 3. O cambiar puerto en docker-compose.yaml:
redis:
  ports:
    - "6380:6379"

# 4. Reintentar
docker-compose up -d redis_cache
```

---

### Redis out of memory

**Error**:
```
OOM command not allowed when used memory > maxmemory
```

**Causa**: Redis lleno (límite: 50MB)

**Solución**:
```bash
# 1. Ver uso actual
docker-compose exec redis_cache redis-cli INFO memory

# 2. Aumentar límite en docker-compose.yaml:
redis:
  command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

# 3. O en .env:
REDIS_LIMIT=256mb

# 4. Limpiar cache viejo:
docker-compose exec redis_cache redis-cli FLUSHDB

# 5. Reiniciar
docker-compose down
docker-compose up -d
```

---

## 🌐 Redes y Conectividad

### No puedo acceder desde otra máquina

**Error**: "Connection refused" desde IP/dominio

**Causas posibles**:
- DOMAIN_HOST incorrecto
- Firewall bloqueando
- Reverse proxy no configurado

**Solución**:
```bash
# 1. Verificar DOMAIN_HOST
grep DOMAIN_HOST .env

# 2. Debe ser la IP del servidor (no localhost)
# DOMAIN_HOST=192.168.1.74  ← Cambiar si es localhost

# 3. Configurar firewall
sudo ufw allow 3000/tcp
sudo ufw allow 5678/tcp
sudo ufw allow 8080/tcp

# 4. Probar conectividad
ping <ip-servidor>
telnet <ip-servidor> 3000

# 5. Si no funciona, necesitas reverse proxy:
# - Nginx/Caddy para redirigir hacia localhost:3000
# - HTTPS requiere certificado SSL
```

---

### Webhook no se envía

**Síntomas**:
- n8n no recibe eventos de Chatwoot
- Webhook appears en configuración pero no funciona

**Causas posibles**:
- URL incorrecta
- Authentication fallida
- n8n no accesible

**Solución**:
```bash
# 1. Verificar URL en Chatwoot (Settings > Webhooks)
# Debería ser: http://n8n:5678/webhook/<webhook_id>

# 2. Probar desde línea de comandos
curl -X POST http://n8n:5678/webhook/test_webhook \
  -H 'Content-Type: application/json' \
  -d '{"test": true}'

# 3. Ver logs en n8n
docker-compose logs -f n8n

# 4. Si falla, crear test en n8n:
# - Ir a n8n
# - New Workflow
# - Agregar Webhook (trigger)
# - Copiar URL
# - Usar esa URL en Chatwoot

# 5. Si Chatwoot no puede acceder a n8n:
# Está en red interna, debe ser: http://n8n:5678
# NO debe ser: http://localhost:5678
```

---

## 📈 Performance

### Sistema muy lento

**Síntomas**:
- Todo es lento
- CPU/RAM en máximo
- Disk usage muy alto

**Checklist de diagnóstico**:

```bash
# 1. Ver recursos
docker stats

# 2. Ver disco
du -sh /var/lib/docker

# 3. Ver tablas grandes
docker-compose exec postgres_db psql -U postgres -d chatwoot -c "
  SELECT schemaname, tablename, 
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
  FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 5;"

# 4. Ver índices
docker-compose exec postgres_db psql -U postgres -d chatwoot -c "
  SELECT tablename, indexname FROM pg_indexes ORDER BY tablename;"
```

**Optimizaciones**:

```bash
# 1. Aumentar recursos
# En docker-compose.yaml:
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G

# 2. Limpieza de base de datos
docker-compose exec postgres_db psql -U postgres -d chatwoot -c "
  DELETE FROM conversations WHERE created_at < now() - interval '6 months';"

# 3. Aumentar Redis
REDIS_LIMIT=256mb

# 4. Optimizar PostgreSQL
docker-compose exec postgres_db psql -U postgres -d chatwoot -c \
  "VACUUM ANALYZE;"

# 5. Reiniciar servicios
docker-compose restart
```

---

## ✅ Checklist de Diagnostico Rápido

```bash
# 1. Estado general
docker-compose ps

# 2. Recursos
docker stats

# 3. Logs de errores
docker-compose logs postgres_db | grep -i error
docker-compose logs chatwoot-web | grep -i error
docker-compose logs n8n | grep -i error

# 4. Conectividad
curl http://localhost:3000
curl http://localhost:5678
curl http://localhost:5000/health

# 5. Base de datos
docker-compose exec postgres_db pg_isready -U postgres

# 6. Cache
docker-compose exec redis_cache redis-cli ping

# 7. Network
docker network ls
docker network inspect app_network
```

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Dificultad**: Intermedia ⭐⭐
