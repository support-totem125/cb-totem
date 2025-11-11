# 🤖 Chat-Bot Totem

> **Plataforma de automatización de atención al cliente** integrada con **Chatwoot**, **n8n**, **Evolution API** y microservicios Python especializados.

![Status](https://img.shields.io/badge/status-production%20ready-brightgreen)
![Version](https://img.shields.io/badge/version-2.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Tabla de Contenidos

- [Descripción General](#descripción-general)
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación Rápida](#instalación-rápida)
- [Documentación](#documentación)
- [Arquitectura](#arquitectura)
- [API y Servicios](#api-y-servicios)
- [Troubleshooting](#troubleshooting)
- [Contribuciones](#contribuciones)

---

## 🎯 Descripción General

Chat-Bot Totem es una **solución completa** para automatizar atención al cliente mediante:

- **Chatwoot**: CRM de atención al cliente omnicanal (WhatsApp, Email, etc.)
- **n8n**: Automatización de flujos de trabajo (no-code/low-code)
- **Evolution API**: Integración nativa con WhatsApp
- **vcc-totem**: Microservicio especializado para consultas (ej: consultas por DNI a FNB Calidda)
- **PostgreSQL + Redis**: Base de datos y cache
- **Docker**: Orquestación completa

**Caso de uso común**: Cliente envía DNI por WhatsApp → n8n consulta base de datos → Respuesta automática.

---

## ✨ Características

- ✅ **100% Portable** — Funciona en cualquier servidor sin cambios de rutas
- ✅ **Configurable** — Una sola variable `DOMAIN_HOST` para configurar todo
- ✅ **Auto-inicialización** — Chatwoot se inicia correctamente sin intervención manual
- ✅ **Documentación Profesional** — Guías claras para cada rol
- ✅ **Seguridad** — Checklist pre-producción incluido
- ✅ **Escalable** — Arquitectura con Docker permite múltiples instancias
- ✅ **Monitoreo** — Health checks y logging integrados

---

## 📦 Requisitos

### Mínimos
- **Docker** ≥ 20.10
- **Docker Compose** ≥ 1.29
- **RAM**: 4GB mínimo (8GB recomendado)
- **Espacio en disco**: 20GB mínimo
- **OS**: Linux (recomendado), macOS o Windows con WSL2

### Opcionales
- **OpenSSL**: Para generar claves criptográficas seguras
- **Git**: Para clonar el repositorio
- **Dominio**: Para deployar en producción (HTTPS)

---

## 🚀 Instalación Rápida

### 1️⃣ Clonar repositorio
```bash
git clone https://github.com/diego-moscaiza/chat-bot-totem.git
cd chat-bot-totem
```

### 2️⃣ Inicializar repositorios externos
```bash
bash scripts/init-repos.sh
```
Este script clona automáticamente `vcc-totem` y `srv-img-totem` si no existen.

### 3️⃣ Configurar ambiente
```bash
cp .env.example .env
nano .env
# Editar: DOMAIN_HOST, POSTGRES_PASSWORD, REDIS_PASSWORD
```

### 4️⃣ Iniciar servicios
```bash
docker-compose up -d
docker-compose ps  # Verificar que todos estén "Up"
```

### 5️⃣ Acceder
```
- Chatwoot:    http://localhost:3000
- n8n:         http://localhost:5678
- Evolution:   http://localhost:8080
```

**⏱️ Tiempo total**: 5 minutos

Para más detalles, ver [QUICK_START_5MIN.md](./docs/guides/01-QUICK_START.md)

---

## 📚 Documentación

| Documento                                                                 | Descripción                      | Tiempo |
| ------------------------------------------------------------------------- | -------------------------------- | ------ |
| **[01 - Inicio Rápido](./docs/guides/01-QUICK_START.md)**                 | Instalación en 5 minutos         | 5 min  |
| **[02 - Guía de Instalación](./docs/guides/02-INSTALLATION_GUIDE.md)**    | Instalación completa paso a paso | 15 min |
| **[03 - Guía de Configuración](./docs/guides/03-CONFIGURATION_GUIDE.md)** | Variables de entorno y ambientes | 10 min |
| **[04 - Arquitectura](./docs/architecture/ARCHITECTURE.md)**              | Diseño del sistema               | 20 min |
| **[05 - API Reference](./docs/api/API_REFERENCE.md)**                     | Documentación de endpoints       | 15 min |
| **[06 - Flujo n8n](./docs/api/N8N_WORKFLOWS.md)**                         | Workflows de automatización      | 20 min |
| **[07 - Deployment](./docs/deployment/DEPLOYMENT_GUIDE.md)**              | Guía de despliegue               | 15 min |
| **[08 - Seguridad](./docs/deployment/SECURITY_CHECKLIST.md)**             | Checklist pre-producción         | 30 min |
| **[09 - Troubleshooting](./docs/troubleshooting/TROUBLESHOOTING.md)**     | Solución de problemas            | 10 min |
| **[10 - Cambios](./docs/CHANGES.md)**                                     | Historial de cambios v2.0        | 5 min  |

### Por Rol

**👨‍💼 Administrador**
1. [01 - Inicio Rápido](./docs/guides/01-QUICK_START.md)
2. [02 - Guía de Instalación](./docs/guides/02-INSTALLATION_GUIDE.md)
3. [08 - Seguridad](./docs/deployment/SECURITY_CHECKLIST.md)

**👨‍💻 Desarrollador**
1. [04 - Arquitectura](./docs/architecture/ARCHITECTURE.md)
2. [05 - API Reference](./docs/api/API_REFERENCE.md)
3. [06 - Flujo n8n](./docs/api/N8N_WORKFLOWS.md)

**🔧 DevOps**
1. [07 - Deployment](./docs/deployment/DEPLOYMENT_GUIDE.md)
2. [08 - Seguridad](./docs/deployment/SECURITY_CHECKLIST.md)
3. [09 - Troubleshooting](./docs/troubleshooting/TROUBLESHOOTING.md)

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│           CLIENT (WhatsApp, Email, etc.)               │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────▼──────────────┐
         │   Evolution API / Inbox  │ (Recibe mensajes)
         └───────────┬──────────────┘
                     │
         ┌───────────▼──────────────┐
         │   Chatwoot Platform      │ (Gestión de tickets)
         └───────────┬──────────────┘
                     │
         ┌───────────▼──────────────┐
         │   n8n (Workflows)        │ (Automatización)
         └───────────┬──────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
   ┌──▼───┐    ┌─────▼────┐   ┌────▼──────┐
   │calidda-api  │vcc-totem │   │srv-img │ (Microservicios)
   └──────┘    └──────────┘   └────────┘
      │              │              │
      └──────────────┼──────────────┘
                     │
         ┌───────────▼──────────────┐
         │   PostgreSQL + Redis     │ (Datos y cache)
         └──────────────────────────┘
```

Ver [Arquitectura Detallada](./docs/architecture/ARCHITECTURE.md)

---

## 🔌 API y Servicios

### Chatwoot API
**Base**: `http://localhost:3000/api/v1`
```bash
# Obtener accounts
curl -H 'api_access_token: <TOKEN>' \
  http://localhost:3000/api/v1/accounts
```

### calidda-api (Microservicio)
**Base**: `http://localhost:5000`
```bash
# Consultar por DNI
curl -X POST http://localhost:5000/query \
  -H 'Content-Type: application/json' \
  -d '{"dni":"08408122"}'

# Response:
# {"success": true, "data": {...}, "return_code": 0}
```

### n8n Webhooks
**Base**: `http://localhost:5678`

Ver [API Reference Completa](./docs/api/API_REFERENCE.md)

---

## 🐳 Comandos Docker Útiles

```bash
# Estado de servicios
docker-compose ps

# Logs en tiempo real
docker-compose logs -f chatwoot-web
docker-compose logs -f calidda-api

# Reiniciar un servicio
docker-compose restart chatwoot-web

# Acceder a PostgreSQL
docker exec -it postgres_db psql -U postgres -d chatwoot

# Hacer backup
docker-compose exec -T postgres_db pg_dump -U postgres chatwoot > backup.sql

# Parar todo
docker-compose down
```

Ver más en [Guía de Instalación](./docs/guides/02-INSTALLATION_GUIDE.md)

---

## 🆘 Troubleshooting

### ❓ Chatwoot no inicia
```bash
docker-compose logs chatwoot-web
# Si dice "relation does not exist": espera 1-2 minutos
# El script init-chatwoot.sh está ejecutando migraciones
```

### ❓ No puedo acceder desde otra máquina
```bash
# Verifica DOMAIN_HOST en .env:
grep DOMAIN_HOST .env
# Debe ser tu IP o dominio, NO localhost
```

### ❓ calidda-api devuelve 500
```bash
docker-compose logs calidda-api
# Verificar credenciales y CALIDDA_SESSION_TTL
```

Ver [Troubleshooting Completo](./docs/troubleshooting/TROUBLESHOOTING.md)

---

## 📊 Estructura del Proyecto

```
chat-bot-totem/
├── README.md                          ← Está aquí
├── docker-compose.yaml                ← Configuración de servicios
├── .env.example                       ← Ejemplo de variables
├── .env                               ← Tu configuración (no compartir)
│
├── docs/                              ← Documentación
│   ├── guides/                        ← Guías paso a paso
│   │   ├── 01-QUICK_START.md
│   │   ├── 02-INSTALLATION_GUIDE.md
│   │   └── 03-CONFIGURATION_GUIDE.md
│   ├── architecture/                  ← Documentación técnica
│   │   ├── ARCHITECTURE.md
│   │   └── SYSTEM_DESIGN.md
│   ├── api/                           ← Documentación de APIs
│   │   ├── API_REFERENCE.md
│   │   └── N8N_WORKFLOWS.md
│   ├── deployment/                    ← Despliegue
│   │   ├── DEPLOYMENT_GUIDE.md
│   │   ├── SECURITY_CHECKLIST.md
│   │   └── ENVIRONMENTS.md
│   ├── troubleshooting/               ← Solución de problemas
│   │   ├── TROUBLESHOOTING.md
│   │   ├── FAQ.md
│   │   └── LOGS.md
│   └── CHANGES.md                     ← Historial de cambios
│
├── scripts/                           ← Scripts de utilidad
│   ├── init-chatwoot.sh               ← Auto-inicialización
│   ├── manage.sh
│   └── ...
│
├── vcc-totem/                         ← Microservicio (consultas)
│   ├── src/
│   │   ├── main.py
│   │   ├── api/
│   │   └── utils/
│   └── requirements.txt
│
├── srv-img-totem/                     ← Servidor de imágenes
│   ├── main.py
│   └── requirements.txt
│
└── logs/                              ← Archivos de log
```

---

## 🔐 Seguridad

**Antes de producción, leer**: [SECURITY_CHECKLIST.md](./docs/deployment/SECURITY_CHECKLIST.md)

Aspectos críticos:
- ✅ Cambiar contraseñas por defecto
- ✅ Generar claves criptográficas seguras
- ✅ Configurar HTTPS/SSL
- ✅ Limitar acceso a puertos
- ✅ Implementar backups automáticos
- ✅ Configurar monitoreo

---

## 🔄 Cambios Principales (v2.0)

**Resumen**:
- ✅ Rutas relativas (antes: hardcodeadas)
- ✅ Variables de dominio centralizadas (antes: URLs fijas a localhost)
- ✅ Auto-inicialización de Chatwoot (antes: crasheaba sin migraciones)
- ✅ Documentación profesional (antes: ninguna)

Ver detalles: [CHANGES.md](./docs/CHANGES.md)

---

## 🤝 Contribuciones

Contribuciones bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 📞 Soporte

- 📖 **Documentación**: Ver carpeta `/docs`
- 🐛 **Issues**: Abrir issue en GitHub
- 💬 **Discusiones**: GitHub Discussions

---

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver [LICENSE](./LICENSE) para más detalles.

---

## 👨‍💻 Autores

- **Diego Moscaiza** — Desarrollo y arquitectura

---

## 🙏 Agradecimientos

- **Chatwoot** — Plataforma de CRM
- **n8n** — Motor de automatización
- **Evolution API** — Integración WhatsApp
- **PostgreSQL** — Base de datos
- **Docker** — Containerización

---

**Última actualización**: Noviembre 2025  
**Versión**: 2.0 - Production Ready
