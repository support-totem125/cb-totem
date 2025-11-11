# 📚 Referencia Rápida de Scripts

Guía completa de todos los scripts disponibles en el proyecto.

---

## 🚀 Scripts de Instalación Inicial

### `init-repos.sh` - Clonar Repositorios Externos
**Cuándo usarlo**: Una sola vez, después de `git clone` principal

```bash
bash scripts/init-repos.sh
```

**Qué hace**:
- Clona `vcc-totem` desde GitHub
- Clona `srv-img-totem` desde GitHub
- Valida que ambos repos se descargaron correctamente
- Muestra información de branch y commit

**Salida esperada**:
```
╔════════════════════════════════════════════════════════════╗
║        Inicializando Repositorios Externos                 ║
╚════════════════════════════════════════════════════════════╝

→ Procesando: vcc-totem
  📥 Clonando desde: https://github.com/diego-moscaiza/vcc-totem.git
  ✓ Clonado exitosamente
  Branch: main
  Commit: 6b0ff41

→ Procesando: srv-img-totem
  📥 Clonando desde: https://github.com/diego-moscaiza/srv-img-totem.git
  ✓ Clonado exitosamente
  Branch: main
  Commit: b7c55c3

📊 Resumen:
  ✓ Repositorios clonados: 2
```

---

### `init-chatwoot.sh` - Configurar Chatwoot
**Cuándo usarlo**: Después de `init-repos.sh` y antes de `docker-compose up`

```bash
bash scripts/init-chatwoot.sh
```

**Qué hace**:
- Inicializa base de datos de Chatwoot
- Crea usuarios de administrador
- Configura permisos necesarios

---

### `create-multiple-databases.sh` - Crear Bases de Datos
**Cuándo usarlo**: Setup inicial de PostgreSQL

```bash
bash scripts/create-multiple-databases.sh
```

**Qué hace**:
- Crea múltiples bases de datos en PostgreSQL
- Configura usuarios y permisos
- Prepara ambiente para servicios

---

## 📊 Scripts de Monitoreo y Sincronización

### `status.sh` - Ver Cambios Disponibles
**Cuándo usarlo**: Cuando quieres saber qué cambió en los repos remotos (SIN descargar)

```bash
bash scripts/status.sh
```

**Qué hace**:
- Ejecuta `git fetch` sin cambiar archivos
- Muestra cuántos commits hay disponibles
- Indica en qué repos hay cambios
- NO modifica tu código local

**Salida esperada**:
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
```

---

### `sync.sh` - Descargar Cambios (Manual)
**Cuándo usarlo**: Cuando quieres descargar los cambios manualmente

```bash
bash scripts/sync.sh
```

**Qué hace**:
- Ejecuta `git fetch` en todos los repos
- Descarga cambios pero no los aplica a archivos
- Registra log de cambios
- Muestra resumen detallado

**Uso típico**:
```bash
bash scripts/status.sh    # Ver qué cambió
bash scripts/sync.sh      # Descargar cambios
# Revisar cambios manualmente
git pull origin main      # Aplicar cambios
```

---

### `sync-watch.sh` - Sincronización Automática (Cron)
**Cuándo usarlo**: Configurar en crontab para monitoreo automático

```bash
# Agregar a crontab (ejecutar cada 5 minutos)
*/5 * * * * /home/admin/Documents/chat-bot-totem/scripts/sync-watch.sh
```

**Qué hace**:
- Ejecuta automáticamente `git fetch` en todos los repos
- Crea archivo de estado en `/tmp/chat-bot-totem-status.txt`
- Genera notificación si hay cambios
- Ideal para servidores en producción

**Configuración recomendada**:
```bash
# Cada 5 minutos
*/5 * * * * /path/to/scripts/sync-watch.sh

# Cada hora
0 * * * * /path/to/scripts/sync.sh

# Cada día a las 3 AM
0 3 * * * /path/to/scripts/sync.sh
```

---

## 🔄 Scripts de Actualización

### `update-vcc-totem.sh` - Actualizar VCC-Totem
**Cuándo usarlo**: Cuando hay nuevos cambios en vcc-totem

```bash
bash scripts/update-vcc-totem.sh
```

**Qué hace**:
- Descarga cambios de vcc-totem
- Actualiza dependencias de Python
- Reinicia servicio de vcc-totem en Docker
- Verifica que el servicio esté saludable

---

### `update-srv-img-totem.sh` - Actualizar SRV-IMG-Totem
**Cuándo usarlo**: Cuando hay nuevos cambios en srv-img-totem

```bash
bash scripts/update-srv-img-totem.sh
```

**Qué hace**:
- Descarga cambios de srv-img-totem
- Actualiza dependencias de Python
- Reinicia servicio de srv-img-totem en Docker
- Verifica que el servicio esté saludable

---

## 🔧 Scripts de Utilidad

### `validate.sh` - Validar Instalación
**Cuándo usarlo**: Después de instalación para verificar que todo está correcto

```bash
bash scripts/validate.sh
```

**Qué hace**:
- Verifica que archivos críticos existen
- Valida variables de .env
- Comprueba dependencias Docker
- Verifica permisos de directorios
- Genera reporte detallado

**Salida esperada**:
```
╔════════════════════════════════════════════════════════════╗
║   VERIFICACIÓN POST-ACTUALIZACIÓN DEL PROYECTO             ║
╚════════════════════════════════════════════════════════════╝

✅ Archivo: README.md
✅ Archivo: docker-compose.yaml
✅ Archivo: .env
✅ Variable POSTGRES_PASSWORD definida en .env
...
```

---

### `watch.sh` - Vigilar Cambios en Docker Config
**Cuándo usarlo**: Monitoreo de cambios en docker-compose.yaml en tiempo real

```bash
bash scripts/watch.sh
```

**Qué hace**:
- Vigila cambios en `docker-compose.yaml`
- Vigila cambios en `.env`
- Valida cambios automáticamente
- Notifica cuando hay problemas
- Se ejecuta en background continuamente

**Uso típico**:
```bash
# Ejecutar en terminal separada
bash scripts/watch.sh &

# Editar docker-compose.yaml
nano docker-compose.yaml

# El script detecta cambios automáticamente
```

---

### `menu.sh` - Menú Interactivo
**Cuándo usarlo**: Interfaz amigable para ejecutar tareas comunes

```bash
bash scripts/menu.sh
```

**Qué hace**:
- Presenta menú interactivo con opciones
- Permite iniciar/parar servicios
- Permite ver logs
- Permite ejecutar backups
- Permite gestionar bases de datos

**Ejemplo de menú**:
```
═══════════════════════════════════════════════════════════
        CHAT-BOT TOTEM - MENÚ DE GESTIÓN
═══════════════════════════════════════════════════════════

1. Ver estado de servicios
2. Iniciar servicios
3. Detener servicios
4. Ver logs
5. Hacer backup
6. Restaurar backup
7. Salir

Selecciona una opción: 
```

---

## 📋 Tabla Comparativa de Scripts

| Script                    | Función                  | Cuándo     | Automático | Modifica código |
| ------------------------- | ------------------------ | ---------- | ---------- | --------------- |
| `status.sh`               | Ver cambios              | Frecuente  | No         | ❌ No            |
| `sync.sh`                 | Descargar cambios        | Manual     | No         | ❌ No            |
| `sync-watch.sh`           | Monitoreo automático     | Cron       | ✅ Sí       | ❌ No            |
| `watch.sh`                | Vigilar config Docker    | Desarrollo | ✅ Sí       | ❌ No            |
| `validate.sh`             | Validar instalación      | Post-setup | No         | ❌ No            |
| `menu.sh`                 | Interfaz amigable        | Manual     | No         | ❌ No            |
| `update-vcc-totem.sh`     | Actualizar vcc-totem     | Manual     | No         | ✅ Sí            |
| `update-srv-img-totem.sh` | Actualizar srv-img-totem | Manual     | No         | ✅ Sí            |

---

## 🔄 Flujos de Trabajo Recomendados

### Desarrollo Local
```bash
# 1. Abrir workspace en VS Code
File → Open Workspace from File → chat-bot-totem.code-workspace

# 2. Verificar cambios (opcional)
bash scripts/status.sh

# 3. Descargar si hay cambios
bash scripts/sync.sh && git pull

# 4. Actualizar servicios
bash scripts/update-vcc-totem.sh
bash scripts/update-srv-img-totem.sh

# 5. Ver logs
docker-compose logs -f
```

### Servidor en Producción
```bash
# 1. Configurar cron para sincronización automática
*/5 * * * * /path/to/scripts/sync-watch.sh >> /var/log/chat-bot-sync.log 2>&1

# 2. Si hay cambios detectados, actualizar
bash scripts/update-vcc-totem.sh
bash scripts/update-srv-img-totem.sh

# 3. Monitorear logs
tail -f /var/log/chat-bot-sync.log
```

### Validación Post-Instalación
```bash
# 1. Instalar
bash scripts/init-repos.sh
bash scripts/init-chatwoot.sh
docker-compose up -d

# 2. Validar
bash scripts/validate.sh

# 3. Si hay errores, revisar logs
docker-compose logs
```

---

## 🆘 Troubleshooting

### "bash: scripts/status.sh: No existe el archivo"
**Solución**: Asegúrate de estar en la carpeta correcta
```bash
cd /path/to/chat-bot-totem
bash scripts/status.sh
```

### "Permission denied" al ejecutar script
**Solución**: Hacer ejecutables
```bash
chmod +x scripts/*.sh
bash scripts/status.sh
```

### Scripts ejecutados pero sin output
**Solución**: Ejecutar con bash explícitamente
```bash
bash scripts/status.sh
# En lugar de:
./scripts/status.sh
```

---

## 📞 Referencia Rápida

```bash
# Ver cambios
bash scripts/status.sh

# Descargar cambios
bash scripts/sync.sh

# Actualizar servicios
bash scripts/update-vcc-totem.sh
bash scripts/update-srv-img-totem.sh

# Validar instalación
bash scripts/validate.sh

# Menú interactivo
bash scripts/menu.sh
```

---

**Versión**: 2.0  
**Última actualización**: Noviembre 2025  
**Estado**: ✅ Producción
