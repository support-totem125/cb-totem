# 🏗️ Arquitectura del Sistema

> Diseño de alto nivel de Chat-Bot Totem y cómo interactúan los componentes

---

## 📊 Diagrama General

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENTES                                      │
│         (WhatsApp, Email, Web, etc.)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────▼──────────────────┐
         │   Evolution API                  │
         │   (Puente WhatsApp/Canales)      │
         │   Port: 8080                     │
         └───────────────┬──────────────────┘
                         │
         ┌───────────────▼──────────────────────────┐
         │   Chatwoot Platform                      │
         │   (CRM de Atención al Cliente)           │
         │   Port: 3000 (Web)                       │
         │   Port: 6006 (Action Cable WebSockets)   │
         └───────────────┬──────────────────────────┘
                         │
         ┌───────────────▼──────────────────────────┐
         │   n8n                                    │
         │   (Motor de Automatización)              │
         │   Port: 5678                             │
         │   Webhooks ← Recibe de Chatwoot          │
         │   HTTP → Envía a microservicios         │
         └──────────┬──────────────────┬────────────┘
                    │                  │
       ┌────────────▼─────────┐  ┌─────▼──────────┐
       │   calidda-api        │  │   srv-img      │
       │   (Consultas FNB)    │  │   (Imágenes)   │
       │   Port: 5000         │  │   Port: 8000   │
       │   GET /query         │  │   GET /images  │
       │   Imports: vcc-totem │  │   Assets       │
       └────────────┬─────────┘  └─────────────────┘
                    │
         ┌──────────▼──────────────────────────────┐
         │   PostgreSQL                           │
         │   (Base de Datos Principal)             │
         │   Port: 5432                            │
         │   BD: chatwoot                          │
         │   Extensiones: pgvector, UUID          │
         └─────────────────────────────────────────┘
         
         ┌─────────────────────────────────────────┐
         │   Redis                                 │
         │   (Cache y Sesiones)                    │
         │   Port: 6379                            │
         │   TTL configurable                      │
         └─────────────────────────────────────────┘
```

---

## 🔌 Componentes Principales

### 1. Evolution API
**Propósito**: Puente entre WhatsApp/canales y Chatwoot

**Características**:
- Integración nativa con WhatsApp
- Gestión de conexiones
- Webhook para nuevos mensajes

**Tecnología**: Node.js  
**Puerto**: 8080  
**Base de datos**: Internal (opcional)

---

### 2. Chatwoot
**Propósito**: CRM omnicanal para atención al cliente

**Características**:
- Gestión de tickets
- Múltiples canales (WhatsApp, Email, etc.)
- Panel de administración
- API REST
- WebSockets (Action Cable)

**Tecnología**: Ruby on Rails  
**Puertos**:
- 3000 — Web interface
- 6006 — Action Cable (WebSockets)

**Base de datos**: PostgreSQL  
**Cache**: Redis

**Flujo de inicialización**:
```bash
1. init-chatwoot.sh inicia
2. Espera a PostgreSQL (pg_isready)
3. Ejecuta: rails db:migrate
4. Crea tablas si no existen
5. Inicia: rails s -p 3000
```

---

### 3. n8n
**Propósito**: Automatización de flujos de trabajo

**Características**:
- Webhooks para recibir eventos
- Nodos para lógica (condicionales, funciones)
- Integraciones HTTP
- Editor visual

**Tecnología**: Node.js + Vue.js  
**Puerto**: 5678

**Flujo típico**:
```
1. Chatwoot envía webhook → n8n
2. n8n procesa (extrae datos)
3. n8n consulta microservicio (calidda-api)
4. n8n envía respuesta → Chatwoot
5. Chatwoot responde al cliente
```

---

### 4. calidda-api (vcc-totem)
**Propósito**: Microservicio para consultas especializadas

**Características**:
- Consulta por DNI
- Búsqueda en FNB Calidda
- Cache de sesión
- Respuesta JSON

**Tecnología**: Python (FastAPI)  
**Puerto**: 5000  
**Endpoint principal**: `POST /query`

**Ejemplo**:
```bash
# Solicitud
curl -X POST http://calidda-api:5000/query \
  -H 'Content-Type: application/json' \
  -d '{"dni":"08408122"}'

# Respuesta
{
  "success": true,
  "data": {
    "nombre": "Juan",
    "saldo": 5000.00,
    ...
  },
  "return_code": 0
}
```

**Sesión**:
- Se mantiene en cache (Redis)
- TTL configurable con `CALIDDA_SESSION_TTL`
- Evita relogin por cada consulta

---

### 5. srv-img
**Propósito**: Servidor de imágenes y assets

**Características**:
- Servir imágenes de catálogos
- Cache de imágenes
- Optimización automática

**Tecnología**: Python  
**Puerto**: 8000  
**Ruta**: `/api/imagenes/catalogos/...`

---

### 6. PostgreSQL
**Propósito**: Base de datos principal

**Características**:
- Múltiples bases de datos
- Extensiones (pgvector, UUID)
- Replicación soportada
- Backups automáticos

**Puerto**: 5432  
**Base de datos**: `chatwoot`  
**Usuario**: `postgres`

**Tablas principales** (creadas por Chatwoot):
- users — Usuarios del sistema
- accounts — Cuentas/organizaciones
- conversations — Conversaciones de tickets
- messages — Mensajes de tickets
- contacts — Contactos de clientes
- inboxes — Canales de recepción (WhatsApp, Email, etc.)
- agents — Agentes de soporte

---

### 7. Redis
**Propósito**: Cache y sesiones

**Características**:
- Cache de sesiones Chatwoot
- Cache de sesiones calidda-api
- Jobs (Sidekiq de Chatwoot)
- Rate limiting

**Puerto**: 6379  
**Memoria**: 50MB (configurable)  
**Política**: LRU (Least Recently Used)

---

## 🔄 Flujos de Datos

### Flujo 1: Mensaje Entrada desde WhatsApp

```
1. Cliente envía mensaje WhatsApp
2. WhatsApp → Evolution API
3. Evolution API → Chatwoot (API)
4. Chatwoot crea ticket
5. Chatwoot envía webhook → n8n
6. n8n recibe en endpoint (POST /webhook/...)
7. n8n procesa (extrae datos, valida)
8. n8n consulta calidda-api (si necesario)
9. calidda-api busca en FNB
10. calidda-api responde JSON
11. n8n arma respuesta para cliente
12. n8n POST → Chatwoot API
13. Chatwoot responde al cliente
14. Chatwoot → Evolution API → WhatsApp
15. Cliente recibe respuesta
```

### Flujo 2: Búsqueda por DNI

```
Cliente: "Consultar DNI 08408122"
    ↓
Chatwoot recibe mensaje
    ↓
n8n webhook recibe evento
    ↓
n8n extrae DNI (REGEX)
    ↓
n8n POST http://calidda-api:5000/query
    │
    └─→ calidda-api procesa
        ├─ Verifica sesión en Redis
        ├─ Si expirada: login a FNB
        ├─ Guarda sesión en Redis
        └─ Busca en FNB
            ↓
        calidda-api responde JSON
    ↓
n8n arma mensaje formateado
    ↓
n8n POST a Chatwoot API
    ├─ Header: api_access_token
    ├─ Body: conversación_id, contenido
    └─ message_type: 1 (respuesta)
    ↓
Chatwoot envía a cliente
    ↓
Cliente ve respuesta
```

---

## 🌐 Comunicación Entre Componentes

### Chatwoot ↔ n8n
```
Chatwoot → n8n:
  POST http://n8n:5678/webhook/chatwoot
  Headers: Authorization (si configurada)
  Body: evento de Chatwoot
  
n8n → Chatwoot:
  POST http://chatwoot:3000/api/v1/...
  Header: api_access_token: <TOKEN>
  Body: respuesta/acción
```

### n8n ↔ calidda-api
```
n8n → calidda-api:
  POST http://calidda-api:5000/query
  Headers: Content-Type: application/json
  Body: {"dni": "08408122"}
  
calidda-api → n8n:
  HTTP 200 OK
  Body: {"success": true, "data": {...}}
```

### calidda-api ↔ Redis
```
Sesión en Redis:
  Key: calidda_session_<username>
  Value: token + timestamp
  TTL: CALIDDA_SESSION_TTL segundos
```

### PostgreSQL ↔ Chatwoot
```
Conexión pooling:
  - DATABASE_POOL_SIZE: 20 (prod)
  - Timeout: 30 segundos
  - Adaptador: postgresql
```

---

## 🔐 Seguridad

### Niveles de Seguridad

```
Internet
    ↓ (Firewall)
────────────────────────────────────
    ↓
Reverse Proxy (Nginx/Caddy)
    ├─ HTTPS/TLS
    ├─ Rate limiting
    ├─ WAF (opcional)
    ↓
────────────────────────────────────
Internal Network (Docker Network)
    ↓
Chatwoot (Puerto 3000)
    ├─ Autenticación
    ├─ API token
    ↓
Evolution API (Puerto 8080)
    ├─ API key
    ↓
n8n (Puerto 5678)
    ├─ Basic auth
    ├─ Encryption key
    ↓
calidda-api (Puerto 5000)
    ├─ No expuesto públicamente
    ├─ Sesión en Redis con contraseña
    ↓
PostgreSQL (Puerto 5432)
    ├─ No expuesto públicamente
    ├─ Contraseña
    ├─ Pool de conexiones
    ↓
Redis (Puerto 6379)
    ├─ No expuesto públicamente
    ├─ Contraseña
```

---

## 📈 Escalabilidad

### Horizontal (Múltiples instancias)

```
Load Balancer (Nginx/HA Proxy)
    ├─ Chatwoot #1
    ├─ Chatwoot #2
    ├─ Chatwoot #3
    ↓
PostgreSQL (Replicación)
    ├─ Master
    └─ Replicas
    
Redis (Cluster o Sentinel)
    ├─ Node #1
    ├─ Node #2
    └─ Node #3
```

### Vertical

- Aumentar RAM (para cache)
- Aumentar CPU (para procesamiento)
- Aumentar almacenamiento (para BD y backups)

---

## 🔄 Actualización de Componentes

### Cadena de Dependencias

```
PostgreSQL (Base)
    ↓ (Debe estar healthy)
Chatwoot Web & Sidekiq
    ↓ (Debe estar healthy)
n8n
    ↓ (Debe estar healthy)
calidda-api
    ↓ (Depende de n8n)
srv-img
    ↓ (Depende de n8n)
Evolution API (Independiente)
```

---

## 🛠️ Stack Tecnológico

| Componente    | Lenguaje   | Framework | Versión  |
| ------------- | ---------- | --------- | -------- |
| Chatwoot      | Ruby       | Rails     | 2.13.x   |
| n8n           | JavaScript | Node.js   | Latest   |
| calidda-api   | Python     | FastAPI   | 0.100+   |
| srv-img       | Python     | Flask     | 2.x      |
| Evolution API | JavaScript | Node.js   | Latest   |
| PostgreSQL    | SQL        | -         | 13+      |
| Redis         | C          | -         | 6.x, 7.x |

---

## 📦 Volúmenes y Persistencia

```
Named Volumes:
  ├─ postgres_db_volume
  │   └─ /var/lib/postgresql/data
  ├─ redis_volume
  │   └─ /data
  └─ n8n_volume
      └─ /home/node/.n8n

Bind Mounts (Rutas relativas):
  ├─ ./vcc-totem (código)
  ├─ ./srv-img-totem (código)
  ├─ ./scripts (scripts de inicialización)
  └─ ./logs (logs del sistema)
```

---

## 🔍 Health Checks

Cada contenedor tiene health checks:

```yaml
health:
  test:
    - CMD
    - pg_isready
    - -U
    - postgres
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 40s
```

**Estados posibles**:
- `starting` — Iniciando
- `healthy` — Listo
- `unhealthy` — Error
- `none` — Sin health check

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025
