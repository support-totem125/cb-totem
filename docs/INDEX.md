# 📚 Índice de Documentación

> Guía para navegar toda la documentación del proyecto Chat-Bot Totem

---

## 🎯 ¿Dónde Empezar?

### Si tienes **5 minutos**
👉 [**01 - Inicio Rápido**](./guides/01-QUICK_START.md)
- Instalación en 5 minutos
- Copiar, editar, ejecutar
- ¡Listo!

### Si tienes **15 minutos**
👉 [**02 - Guía de Instalación**](./guides/02-INSTALLATION_GUIDE.md)
- Instalación paso a paso
- Explicaciones completas
- Verificación detallada

### Si tienes **30 minutos**
👉 [**03 - Guía de Configuración**](./guides/03-CONFIGURATION_GUIDE.md)
- Configuración por ambiente
- Desarrollo, staging, producción
- Ejemplos para cada caso

---

## 📖 Documentación por Sección

### 🚀 Primeros Pasos

| Documento                                                      | Objetivo                | Tiempo | Para quién              |
| -------------------------------------------------------------- | ----------------------- | ------ | ----------------------- |
| [01 - Inicio Rápido](./guides/01-QUICK_START.md)               | Instalar en 5 minutos   | 5 min  | Todos                   |
| [02 - Instalación Completa](./guides/02-INSTALLATION_GUIDE.md) | Instalación detallada   | 20 min | Administradores         |
| [03 - Configuración](./guides/03-CONFIGURATION_GUIDE.md)       | Configurar por ambiente | 30 min | Administradores, DevOps |

### 🏗️ Arquitectura y Diseño

| Documento                                                  | Objetivo               | Tiempo | Para quién      |
| ---------------------------------------------------------- | ---------------------- | ------ | --------------- |
| [Arquitectura del Sistema](./architecture/ARCHITECTURE.md) | Entender cómo funciona | 20 min | Desarrolladores |
| [Diagrama de Flujos](./architecture/SYSTEM_DESIGN.md)      | Visualizar flujos      | 15 min | Todos           |

### 🔌 APIs y Integraciones

| Documento                               | Objetivo                    | Tiempo | Para quién      |
| --------------------------------------- | --------------------------- | ------ | --------------- |
| [API Reference](./api/API_REFERENCE.md) | Documentación de endpoints  | 30 min | Desarrolladores |
| [Flujos n8n](./api/N8N_WORKFLOWS.md)    | Workflows de automatización | 25 min | Desarrolladores |

### 🚢 Despliegue y DevOps

| Documento                                              | Objetivo                   | Tiempo | Para quién |
| ------------------------------------------------------ | -------------------------- | ------ | ---------- |
| [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md) | Deploy en producción       | 30 min | DevOps     |
| [Ambientes de Ejecución](./deployment/ENVIRONMENTS.md) | Configuración de ambientes | 20 min | DevOps     |

### 🔐 Seguridad

| Documento                                                    | Objetivo       | Tiempo | Para quién    |
| ------------------------------------------------------------ | -------------- | ------ | ------------- |
| [Checklist de Seguridad](./deployment/SECURITY_CHECKLIST.md) | Pre-producción | 45 min | DevOps, Admin |

### 🆘 Solución de Problemas

| Documento                                               | Objetivo             | Tiempo | Para quién      |
| ------------------------------------------------------- | -------------------- | ------ | --------------- |
| [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md) | Resolver problemas   | 15 min | Todos           |
| [FAQ](./troubleshooting/FAQ.md)                         | Preguntas frecuentes | 10 min | Todos           |
| [Logs y Monitoreo](./troubleshooting/LOGS.md)           | Entender logs        | 20 min | Administradores |

### 📋 Información General

| Documento                    | Objetivo                  | Tiempo | Para quién |
| ---------------------------- | ------------------------- | ------ | ---------- |
| [Cambios v2.0](./CHANGES.md) | Novedades de esta versión | 10 min | Todos      |

---

## 👤 Documentación por Rol

### 👨‍💼 Administrador del Sistema

**Objetivo**: Instalar, configurar y mantener el sistema

**Leer en orden**:
1. [01 - Inicio Rápido](./guides/01-QUICK_START.md) (5 min)
2. [02 - Instalación Completa](./guides/02-INSTALLATION_GUIDE.md) (20 min)
3. [03 - Configuración](./guides/03-CONFIGURATION_GUIDE.md) (30 min)
4. [Checklist de Seguridad](./deployment/SECURITY_CHECKLIST.md) (45 min)
5. [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md) (15 min)

**Tareas típicas**:
- [ ] Instalar servicios
- [ ] Cambiar contraseñas
- [ ] Configurar dominio
- [ ] Hacer backups
- [ ] Configurar monitoreo
- [ ] Actualizar regularmente

---

### 👨‍💻 Desarrollador

**Objetivo**: Entender la arquitectura y desarrollar integraciones

**Leer en orden**:
1. [Arquitectura del Sistema](./architecture/ARCHITECTURE.md) (20 min)
2. [Diagrama de Flujos](./architecture/SYSTEM_DESIGN.md) (15 min)
3. [API Reference](./api/API_REFERENCE.md) (30 min)
4. [Flujos n8n](./api/N8N_WORKFLOWS.md) (25 min)
5. [Cambios v2.0](./CHANGES.md) (10 min)

**Tareas típicas**:
- [ ] Entender arquitectura
- [ ] Crear workflows en n8n
- [ ] Integrar APIs externas
- [ ] Crear microservicios
- [ ] Escribir tests
- [ ] Proponer mejoras

---

### 🔧 DevOps / SysAdmin

**Objetivo**: Desplegar, escalar y monitorear en producción

**Leer en orden**:
1. [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md) (30 min)
2. [Ambientes de Ejecución](./deployment/ENVIRONMENTS.md) (20 min)
3. [Checklist de Seguridad](./deployment/SECURITY_CHECKLIST.md) (45 min)
4. [Logs y Monitoreo](./troubleshooting/LOGS.md) (20 min)
5. [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md) (15 min)

**Tareas típicas**:
- [ ] Automatizar backups
- [ ] Configurar monitoreo
- [ ] Implementar CI/CD
- [ ] Escalar horizontalmente
- [ ] Auditoría de seguridad
- [ ] Plan de disaster recovery

---

### 👤 Usuario Final / Soporte

**Objetivo**: Usar y soportar a otros usuarios

**Leer en orden**:
1. [01 - Inicio Rápido](./guides/01-QUICK_START.md) (5 min)
2. [FAQ](./troubleshooting/FAQ.md) (10 min)

**No necesita leer**:
- Cambios técnicos
- Detalles de arquitectura
- Configuración avanzada

---

## 🔍 Búsqueda por Tema

### Instalación y Setup
- **"¿Cómo instalo?"** → [02 - Instalación Completa](./guides/02-INSTALLATION_GUIDE.md)
- **"¿Cómo empiezo rápido?"** → [01 - Inicio Rápido](./guides/01-QUICK_START.md)
- **"¿Cómo configuro?"** → [03 - Configuración](./guides/03-CONFIGURATION_GUIDE.md)

### Desarrollo
- **"¿Cómo funciona el sistema?"** → [Arquitectura](./architecture/ARCHITECTURE.md)
- **"¿Qué APIs hay?"** → [API Reference](./api/API_REFERENCE.md)
- **"¿Cómo creo workflows?"** → [Flujos n8n](./api/N8N_WORKFLOWS.md)

### Despliegue
- **"¿Cómo depliego en producción?"** → [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md)
- **"¿Cómo configuro ambientes?"** → [Ambientes](./deployment/ENVIRONMENTS.md)

### Seguridad
- **"¿Es seguro para producción?"** → [Checklist de Seguridad](./deployment/SECURITY_CHECKLIST.md)
- **"¿Cómo genero contraseñas seguras?"** → [Seguridad](./deployment/SECURITY_CHECKLIST.md#generador-de-contraseñas)
- **"¿Cómo configuro HTTPS?"** → [Configuración Producción](./guides/03-CONFIGURATION_GUIDE.md#producción-dominio-https)

### Problemas
- **"¿Chatwoot no inicia?"** → [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md#chatwoot-no-inicia)
- **"¿No puedo acceder?"** → [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md#no-puedo-acceder-desde-otra-máquina)
- **"¿Error desconocido?"** → [FAQ](./troubleshooting/FAQ.md)

### Mantenimiento
- **"¿Cómo hago backup?"** → [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md#backups)
- **"¿Cómo monitoreo?"** → [Logs y Monitoreo](./troubleshooting/LOGS.md)
- **"¿Cómo actualizo?"** → [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md#actualizaciones)

### Cambios
- **"¿Qué cambió en v2.0?"** → [Cambios](./CHANGES.md)
- **"¿Cómo actualizo de v1.0?"** → [Cambios](./CHANGES.md#proceso-de-actualización)

---

## 📚 Estructura de Documentación

```
docs/
├── 📄 CHANGES.md                        ← Novedades de v2.0
│
├── guides/                              ← COMENZAR AQUÍ
│   ├── 01-QUICK_START.md               (5 min)
│   ├── 02-INSTALLATION_GUIDE.md        (20 min)
│   └── 03-CONFIGURATION_GUIDE.md       (30 min)
│
├── architecture/                        ← Entender el sistema
│   ├── ARCHITECTURE.md                 (20 min)
│   └── SYSTEM_DESIGN.md                (15 min)
│
├── api/                                 ← Para desarrolladores
│   ├── API_REFERENCE.md                (30 min)
│   └── N8N_WORKFLOWS.md                (25 min)
│
├── deployment/                          ← Para DevOps
│   ├── DEPLOYMENT_GUIDE.md             (30 min)
│   ├── ENVIRONMENTS.md                 (20 min)
│   └── SECURITY_CHECKLIST.md           (45 min)
│
└── troubleshooting/                     ← Resolver problemas
    ├── TROUBLESHOOTING.md              (15 min)
    ├── FAQ.md                          (10 min)
    └── LOGS.md                         (20 min)
```

---

## ⏱️ Tiempo Total de Lectura

| Rol               | Lectura Mínima | Lectura Completa |
| ----------------- | -------------- | ---------------- |
| **Usuario Final** | 15 min         | 30 min           |
| **Administrador** | 45 min         | 2 horas          |
| **Desarrollador** | 1 hora         | 2.5 horas        |
| **DevOps**        | 1.5 horas      | 3 horas          |

---

## 🔗 Enlaces Rápidos

### Documentación Principal
- [README.md](../README.md) — Descripción general del proyecto
- [01 - Inicio Rápido](./guides/01-QUICK_START.md) — ⭐ EMPIEZA AQUÍ

### Configuración
- [.env.example](../.env.example) — Ejemplo de variables
- [docker-compose.yaml](../docker-compose.yaml) — Orquestación de servicios

### Código
- [vcc-totem/](../vcc-totem/) — Microservicio de consultas
- [srv-img-totem/](../srv-img-totem/) — Servidor de imágenes
- [scripts/](../scripts/) — Scripts de utilidad

---

## 📞 ¿No Encontraste lo que Buscas?

1. **Revisa el [README.md](../README.md)** — Descripción general
2. **Busca en [FAQ](./troubleshooting/FAQ.md)** — Preguntas frecuentes
3. **Lee [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md)** — Solución de problemas
4. **Abre un issue en GitHub** — Reporta el problema

---

## 🎓 Tips para Navegar

1. **Empieza simple**: [01 - Inicio Rápido](./guides/01-QUICK_START.md)
2. **Profundiza**: [02 - Instalación](./guides/02-INSTALLATION_GUIDE.md)
3. **Especializa**: Lee documentación de tu rol
4. **Resuelve problemas**: Usa [Troubleshooting](./troubleshooting/TROUBLESHOOTING.md)

---

## ✅ Checklist de Lectura Recomendada

**Para todos**:
- [ ] [01 - Inicio Rápido](./guides/01-QUICK_START.md)

**Para instalación inicial**:
- [ ] [02 - Instalación Completa](./guides/02-INSTALLATION_GUIDE.md)
- [ ] [03 - Configuración](./guides/03-CONFIGURATION_GUIDE.md)

**Para producción**:
- [ ] [Guía de Despliegue](./deployment/DEPLOYMENT_GUIDE.md)
- [ ] [Checklist de Seguridad](./deployment/SECURITY_CHECKLIST.md)

**Para desarrollo**:
- [ ] [Arquitectura](./architecture/ARCHITECTURE.md)
- [ ] [API Reference](./api/API_REFERENCE.md)

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Total de documentos**: 12  
**Total de páginas**: 100+
