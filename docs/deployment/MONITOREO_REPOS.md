# 🔄 Guía: Detectar Cambios en Repositorios

Este documento explica cómo VS Code detecta cambios en los repositorios `vcc-totem` y `srv-img-totem`.

---

## 📋 Problema

VS Code no muestra automáticamente el icono de "pull disponible" (↓) en `vcc-totem` y `srv-img-totem` porque:

1. Son repositorios **Git independientes** dentro de la carpeta principal
2. VS Code solo hace `git fetch` automático en repositorios **abiertos directamente**
3. Las subcarpetas necesitan `git fetch` explícito para detectar cambios remotos

---

## ✅ Solución: Usar VS Code Workspace

### Paso 1: Abrir como Workspace

1. En VS Code, ve a: **File → Open Workspace from File**
2. Selecciona: `/home/admin/Documents/chat-bot-totem/chat-bot-totem.code-workspace`
3. VS Code abrirá los 3 repositorios como proyectos separados

### Paso 2: Configuración Automática

El archivo `.code-workspace` contiene:

```json
"settings": {
  "git.autofetch": true,          // Auto-fetch cada 5 minutos
  "git.autofetchPeriod": 300,     // 5 minutos en segundos
  "git.autorefresh": true         // Actualizar UI automáticamente
}
```

Esto hace que VS Code automáticamente:
- ✅ Detecte cambios en los 3 repos
- ✅ Muestre el icono de "cambios disponibles"
- ✅ Actualice cada 5 minutos

---

## 🚀 Scripts Disponibles

### 1. `check-updates.sh` - Verificación Rápida

Verifica si hay cambios disponibles en TODOS los repos:

```bash
./scripts/check-updates.sh
```

Output:
```
🔍 Verificando Actualizaciones Disponibles

→ 🤖 Chat-Bot Totem (Main)
  Fetching... ✓
  Branch: main
  ✓ Todo actualizado

→ 🟣 VCC-Totem
  Fetching... ✓
  Branch: main
  📥 2 cambios disponibles para descargar

→ 🖼️  SRV-IMG-Totem
  Fetching... ✓
  Branch: main
  ✓ Todo actualizado

════════════════════════════════════════════════════════════
⚠️  Hay 1 repositorio(s) con actualizaciones disponibles

Ejecuta para actualizar:
  • bash scripts/update-vcc-totem.sh
  • bash scripts/update-srv-img-totem.sh
```

### 2. `fetch-all-repos.sh` - Fetch Manual

Hace `git fetch` en todos los repos y muestra resumen:

```bash
./scripts/fetch-all-repos.sh
```

### 3. `monitor-repos.sh` - Monitoreo Continuo

Script para ejecutar periódicamente (cron):

```bash
# Agregar a crontab para ejecutar cada 5 minutos:
crontab -e

# Agregar esta línea:
*/5 * * * * /home/admin/Documents/chat-bot-totem/scripts/monitor-repos.sh
```

---

## 🔧 Configuración Recomendada

### Opción A: Auto-Fetch (Recomendado)

El workspace ya está configurado. Solo asegúrate de:

1. Abrir como Workspace (no carpeta)
2. Dar permiso a VS Code de hacer fetch periódico

**Ventaja**: VS Code muestra cambios automáticamente
**Desventaja**: Usa un poco más de recursos

### Opción B: Fetch Manual Periódico

Ejecutar manualmente cada cierto tiempo:

```bash
# Terminal integrada en VS Code
./scripts/check-updates.sh    # Ver cambios
./scripts/update-vcc-totem.sh  # Actualizar repo específico
```

**Ventaja**: Control total
**Desventaja**: Requiere ejecución manual

### Opción C: Cron Job (Producción)

Para servidores, agregar a crontab:

```bash
# Cada 5 minutos
*/5 * * * * /home/admin/Documents/chat-bot-totem/scripts/monitor-repos.sh

# Cada hora
0 * * * * /home/admin/Documents/chat-bot-totem/scripts/fetch-all-repos.sh
```

---

## 📊 Flujo de Trabajo

### Para Desarrollo

```
1. Abrir workspace: chat-bot-totem.code-workspace
   ↓
2. VS Code muestra cambios automáticamente cada 5 min
   ↓
3. Ver icono ↓ en repos con cambios disponibles
   ↓
4. Click en ↓ o ejecutar script
   ↓
5. Cambios descargados
```

### Para Servidor (Producción)

```
1. Agregar scripts a crontab
   ↓
2. Ejecutar fetch automáticamente cada 5 min
   ↓
3. Si hay cambios, ejecutar update script
   ↓
4. Servicios se reinician automáticamente
```

---

## 🔍 Verificar Estado Manual

```bash
# En cualquier repo, verificar cambios disponibles:
cd vcc-totem
git fetch origin
git status

# Ver commits disponibles:
git log HEAD..@{u}  # Cambios a descargar
git log @{u}..HEAD  # Cambios a subir
```

---

## ⚡ Troubleshooting

### Icono de pull no aparece en VS Code

**Solución**:
1. Abre como **Workspace**, no como carpeta
2. Verifica que `git.autofetch` está activado (Settings)
3. Ejecuta manualmente: `./scripts/check-updates.sh`

### El fetch no encuentra cambios

**Solución**:
```bash
# Verificar remoto configurado correctamente
cd vcc-totem
git remote -v

# Si no ve cambios, intenta:
git fetch upstream main
git fetch origin main
git fetch --all
```

### Scripts no se ejecutan

**Solución**:
```bash
# Hacer ejecutables:
chmod +x scripts/*.sh

# Ejecutar con bash explícitamente:
bash scripts/check-updates.sh
```

---

## 📝 Archivos Relacionados

- `chat-bot-totem.code-workspace` - Configuración de VS Code
- `scripts/check-updates.sh` - Verificar cambios
- `scripts/fetch-all-repos.sh` - Hacer fetch
- `scripts/update-vcc-totem.sh` - Actualizar vcc-totem
- `scripts/update-srv-img-totem.sh` - Actualizar srv-img-totem

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Estado**: ✅ Producción
