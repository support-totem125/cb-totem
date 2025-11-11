# 🔄 Guía Rápida: Auto-Detect de Cambios en Repos

**Problema**: VS Code no mostraba el icono ↓ para actualizar `vcc-totem` y `srv-img-totem`

**Solución**: Usar el archivo `.code-workspace` que configura auto-fetch

---

## ⚡ Instalación Rápida (1 minuto)

### Paso 1: Cierra VS Code

### Paso 2: Abre como Workspace

```
File → Open Workspace from File
  → Selecciona: chat-bot-totem.code-workspace
```

### Paso 3: Listo ✅

VS Code mostrará automáticamente:
- ✅ Icono ↓ cuando haya cambios disponibles
- ✅ Fetch cada 5 minutos
- ✅ Los 3 repos en el panel Source Control

---

## 📋 Scripts Disponibles

```bash
# Ver cambios en todos los repos
./scripts/status.sh

# Hacer sync automático (para cron)
./scripts/sync.sh

# Sincronización continua (para cron)
./scripts/sync-watch.sh
```

---

## 🎯 Flujo de Uso

```
1. Ves icono ↓ en vcc-totem
   ↓
2. Haces click en el icono
   ↓
3. VS Code hace pull
   ↓
4. Cambios descargados
   ↓
5. Script update redeploya servicios
```

---

Ver documentación completa: `docs/deployment/MONITOREO_REPOS.md`
