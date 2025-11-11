# ⚡ Inicio Rápido en 5 Minutos

> 🎯 **Objetivo**: Tener Chat-Bot Totem funcionando completamente en 5 minutos

---

# ⚡ Inicio Rápido en 5 Minutos

> 🎯 **Objetivo**: Tener Chat-Bot Totem funcionando completamente en 5 minutos

---

## 📋 Paso a Paso

### Paso 1: Inicializar repositorios (30 segundos)

```bash
bash scripts/init-repos.sh
```

Este script clona automáticamente `vcc-totem` y `srv-img-totem` si no existen.

---

### Paso 2: Copiar configuración (30 segundos)

```bash
cp .env.example .env
```

---

### Paso 3: Editar configuración (2 minutos)

```bash
nano .env
```

**BUSCA Y CAMBIA ESTOS 3 VALORES:**

```bash
# Línea ~17-18 - Define tu servidor
DOMAIN_HOST=localhost              # ← Tu dominio o IP
SERVER_IP_ADDR=127.0.0.1           # ← Tu IP local

# Línea ~28-32 - Genera contraseñas seguras
POSTGRES_PASSWORD=cad69267...      # ← Ejecuta: openssl rand -hex 16
REDIS_PASSWORD=f2cd6ac2...         # ← Ejecuta: openssl rand -hex 16
```

**Generar contraseñas seguras (opcional):**
```bash
# En otra terminal:
openssl rand -hex 16

# Copiar resultado y reemplazar valores anteriores
```

---

### Paso 4: Iniciar (2 minutos)

```bash
docker-compose up -d
```

**Espera a que aparezca:**
```
Creating postgres_db ... done
Creating redis_cache ... done
Creating evolution_api ... done
Creating chatwoot_web ... done
Creating n8n ... done
...
```

---

### Paso 5: Verificar (1 minuto)

```bash
docker-compose ps
```

**Deberías ver todos en "Up":**
```
NAME                 STATUS
postgres_db          Up
redis_cache          Up
evolution_api        Up
chatwoot_web         Up
chatwoot_sidekiq     Up
n8n                  Up
calidda_api          Up
srv_img              Up
```

**Ver logs de Chatwoot:**
```bash
docker-compose logs chatwoot-web | head -20
```

**Deberías ver:**
```
✅ PostgreSQL está disponible
🔄 Ejecutando migraciones de base de datos...
✅ Migraciones completadas
✅ Chatwoot inicializado correctamente
[Server running on port 3000]
```

---

## ✅ ¡Listo! Acceder a los servicios

Con `DOMAIN_HOST=localhost`:

```
📍 Chatwoot:       http://localhost:3000
📍 n8n:            http://localhost:5678
📍 Evolution:      http://localhost:8080
📍 Imágenes:       http://localhost:8000
📍 API Calidda:    http://localhost:5000
```

**Si usaste IP o dominio, reemplaza `localhost` con tu valor**

---

## 🆘 Si algo falla

### ❓ "Connection refused" o similar
```bash
# Espera 1 minuto más y verifica:
docker-compose ps

# Si chatwoot-web está "Up", espera otro minuto
# (Las migraciones pueden tardar)
```

### ❓ "POSTGRES ERROR: relation users does not exist"
```bash
# Normal en el primer inicio
# El script init-chatwoot.sh está ejecutando migraciones
# Espera 2-3 minutos
docker-compose logs chatwoot-web
```

### ❓ "Cannot connect to Docker daemon"
```bash
# Asegúrate de que Docker está corriendo:
docker ps

# Si no funciona, reinicia Docker
```

### ❓ "Port 3000 already in use"
```bash
# Puerto ocupado por otro servicio
# Opción 1: Detener otro servicio
# Opción 2: Cambiar puerto en docker-compose.yaml:
# ports: ["3001:3000"]
```

---

## 📖 Siguientes Pasos

1. **Crear usuario en Chatwoot**
   - Abrir http://localhost:3000
   - Crear usuario admin
   - Configurar

2. **Configurar N8N**
   - Abrir http://localhost:5678
   - Usuario/Contraseña está en `.env` (N8N_BASIC_AUTH_*)

3. **Conectar Evolution API**
   - Documentación en `/docs/api`

4. **Hacer backup de `.env`**
   - NUNCA compartir el archivo
   - Guardar en lugar seguro

5. **Leer documentación completa**
   - [Guía de Instalación](./02-INSTALLATION_GUIDE.md)
   - [Seguridad](../deployment/SECURITY_CHECKLIST.md)

---

## 🌍 Cambiar de Servidor/Dominio

Solo cambiar `DOMAIN_HOST` en `.env`:

```bash
# Editar .env
nano .env

# Cambiar:
DOMAIN_HOST=tu-dominio.com

# Reiniciar:
docker-compose restart
```

**¡Eso es todo!** Las URLs se actualizan automáticamente.

---

## ⏱️ Timeline de inicio

```
docker-compose up -d
├─ 0s:    PostgreSQL inicia
├─ 5s:    Redis inicia
├─ 10s:   Evolution inicia
├─ 15s:   Chatwoot ejecuta init-chatwoot.sh
│        ├─ Espera postgres: 2s
│        ├─ Migraciones: 10-30s
│        └─ Servidor inicia: 2s
├─ 45s:   Todos los servicios online
└─ 60s:   ✅ LISTO para usar
```

---

## 🎯 Checklist Rápido

- [ ] Ejecuté: `cp .env.example .env`
- [ ] Edité: `DOMAIN_HOST` en .env
- [ ] Ejecuté: `docker-compose up -d`
- [ ] Ejecuté: `docker-compose ps` (todos "Up")
- [ ] Verifiqué: `docker-compose logs chatwoot-web` (sin errors)
- [ ] Accedí: http://localhost:3000
- [ ] Creé usuario admin en Chatwoot
- [ ] Hice backup de `.env`

---

## 🚀 ¿Listo para producción?

Antes de pasar a producción, lee:
- [Guía de Despliegue](../deployment/DEPLOYMENT_GUIDE.md)
- [Checklist de Seguridad](../deployment/SECURITY_CHECKLIST.md)

---

**¿Problemas?** Ver: [Troubleshooting](../troubleshooting/TROUBLESHOOTING.md)

**Versión**: 2.0  
**Tiempo estimado**: 5 minutos  
**Dificultad**: Muy fácil ⭐
