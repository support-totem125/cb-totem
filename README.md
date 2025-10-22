# 🚀 Chatbot Totem - Stack de Servicios Docker

Stack completo con Evolution API, Chatwoot y n8n para automatización y atención al cliente.

## 📦 Servicios Incluidos

- **Evolution API v2.2.3** - API de WhatsApp (Puerto 8080)
- **Chatwoot** - Plataforma de atención al cliente (Puerto 3000)
- **n8n** - Automatización de workflows (Puerto 5678)
- **PostgreSQL 15** - Base de datos compartida
- **Redis 7** - Cache compartido

## 🔧 Configuración Inicial

### 1. Configurar variables de entorno

Edita el archivo `.env` y asegúrate de:

1. **Generar la clave de encriptación de n8n:**
```bash
openssl rand -hex 32
```
Copia el resultado y pégalo en `N8N_ENCRYPTION_KEY`

2. **Cambiar la contraseña de n8n:**
Reemplaza `change_me_n8n` en `N8N_BASIC_AUTH_PASSWORD`

3. **Verificar las contraseñas:**
   - PostgreSQL: `POSTGRES_PASSWORD` ✅ (ya configurada)
   - Redis: `REDIS_PASSWORD` ✅ (ya configurada)
   - Evolution API Key: `EVOLUTION_API_KEY` ✅ (ya configurada)

### 2. Iniciar los servicios

```bash
# Levantar todos los servicios
docker-compose up -d

# Ver los logs
docker-compose logs -f

# Ver el estado de los servicios
docker-compose ps
```

### 3. Acceder a los servicios

- **Evolution API**: http://localhost:8080
  - API Key: Ver en `.env` → `EVOLUTION_API_KEY`
  
- **Chatwoot**: http://localhost:3000
  - Primera vez: Crear cuenta de administrador
  
- **n8n**: http://localhost:5678
  - Usuario: `admin` (configurable en `.env`)
  - Contraseña: Ver en `.env` → `N8N_BASIC_AUTH_PASSWORD`

## 📊 Gestión de Servicios

### Detener servicios
```bash
docker-compose down
```

### Reiniciar un servicio específico
```bash
docker-compose restart evolution-api
docker-compose restart chatwoot-web
docker-compose restart n8n
```

### Ver logs de un servicio específico
```bash
docker-compose logs -f evolution-api
docker-compose logs -f chatwoot-web
docker-compose logs -f n8n
```

### Actualizar servicios
```bash
docker-compose pull
docker-compose up -d
```

## 🗄️ Bases de Datos

El script `create-multiple-databases.sh` crea automáticamente tres bases de datos en PostgreSQL:
- `evolution` - Para Evolution API
- `chatwoot` - Para Chatwoot
- `n8n` - Para n8n

## 🔐 Seguridad

### Para producción:

1. **Cambiar todas las contraseñas** en el archivo `.env`
2. **Configurar HTTPS** usando un reverse proxy (Nginx, Caddy, Traefik)
3. **Actualizar las URLs** en `.env`:
   - `CHATWOOT_FRONTEND_URL`
   - `EVOLUTION_SERVER_URL`
   - `N8N_WEBHOOK_URL`
4. **Habilitar SSL** en Chatwoot:
   - Cambiar `FORCE_SSL=true`

## 📧 Configuración de Email (Chatwoot)

Para que Chatwoot pueda enviar emails, configura las variables SMTP en `.env`:

```env
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=tu-email@gmail.com
SMTP_PASSWORD=tu-contraseña-de-aplicación
```

## 🔗 Integración Evolution API + Chatwoot

Para conectar Evolution API con Chatwoot:

1. En Evolution API, habilita la integración:
```env
CHATWOOT_ENABLED=true
```

2. Configura la conexión en el dashboard de Evolution API

## 📝 Volúmenes de Datos

Los datos se almacenan en volúmenes Docker:
- `postgres_data` - Datos de PostgreSQL
- `redis_data` - Datos de Redis
- `evolution_instances` - Instancias de WhatsApp
- `evolution_store` - Almacenamiento de Evolution API
- `chatwoot_data` - Datos de Chatwoot
- `n8n_data` - Workflows y configuración de n8n

### Backup de datos
```bash
# Backup de PostgreSQL
docker exec postgres_db pg_dumpall -U postgres > backup.sql

# Restaurar backup
docker exec -i postgres_db psql -U postgres < backup.sql
```

## 🐛 Solución de Problemas

### Los servicios no inician
```bash
# Ver logs detallados
docker-compose logs

# Verificar que los puertos no estén en uso
sudo netstat -tulpn | grep -E '3000|5678|8080'
```

### Resetear todo
```bash
# ⚠️ CUIDADO: Esto eliminará todos los datos
docker-compose down -v
docker-compose up -d
```

### Evolution API no conecta con WhatsApp
1. Verifica que el puerto 8080 esté accesible
2. Revisa los logs: `docker-compose logs -f evolution-api`
3. Verifica la API Key en las peticiones

## 📚 Documentación Oficial

- [Evolution API](https://doc.evolution-api.com/v2/en/)
- [Chatwoot](https://www.chatwoot.com/docs)
- [n8n](https://docs.n8n.io/)

## 🆘 Soporte

Para problemas o dudas:
1. Revisa los logs de los servicios
2. Consulta la documentación oficial
3. Verifica la configuración del archivo `.env`

---

**Nota**: Este stack está optimizado para desarrollo. Para producción, considera implementar medidas adicionales de seguridad y configurar un proxy reverso con SSL.
