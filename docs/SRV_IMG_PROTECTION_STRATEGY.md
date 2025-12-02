# Estrategia de Protección de Base de Datos - srv-img

## 📋 Resumen Ejecutivo

Tu proyecto tiene **dos niveles de scripts** para proteger la base de datos:

| Contexto              | Script                    | Ubicación                       | Uso                                        |
| --------------------- | ------------------------- | ------------------------------- | ------------------------------------------ |
| **Desarrollo Local**  | `restore_database.py`     | `srv-img-totem/scripts/sqlite/` | Restaurar backups locales interactivamente |
| **Docker/Producción** | `rebuild-srv-img-safe.sh` | `scripts/`                      | Reconstruir imagen de forma segura         |

---

## 🎯 Estrategia: ¿Por qué DOS scripts?

### Problema Original
Al reconstruir la imagen Docker, podías perder los datos si no estaban protegidos. **Esto ya está solucionado.**

### Solución Implementada

#### **Nivel 1: Volumen Persistente Docker** ✅
- La BD se guarda en un **volumen Docker persistente** (`srv_img_data`)
- El volumen **NO se borra** cuando reconstruyes la imagen
- El volumen **NO se borra** cuando paras el contenedor
- La BD se preserva automáticamente

```
docker-compose.yaml:
  srv-img:
    volumes:
      - srv_img_data:/srv/data    ← BD aquí, permanente
```

#### **Nivel 2: Backup Pre-Reconstrucción** 🛡️
- Antes de reconstruir, se hace un **backup automático**
- Si algo sale mal, tienes una copia de seguridad en el **host**
- Script: `scripts/rebuild-srv-img-safe.sh`

#### **Nivel 3: Restauración Interactiva** 🔄
- Si necesitas restaurar un backup, usa: `restore_database.py`
- Es interactivo: elige qué backup restaurar
- Crea backup de seguridad antes de restaurar

---

## 🚀 Cómo Usar Cada Script

### Escenario 1: DESARROLLO LOCAL (sin Docker)

**Cuando usarlo:**
- Trabajas en tu máquina local, sin contenedores
- Tienes la BD en `srv-img-totem/catalogos.db`

**Pasos:**
```bash
# 1. Hacer backup
cd srv-img-totem
python scripts/sqlite/backup_database.py

# 2. Restaurar si es necesario
python scripts/sqlite/restore_database.py

# 3. Crear nueva BD
python scripts/sqlite/create_database.py
```

**Qué hace:**
- ✅ Usa backups locales en `srv-img-totem/backups/`
- ✅ Interactivo: seleccionas qué restaurar
- ✅ NO toca el volumen Docker
- ✅ Perfecto para desarrollo

---

### Escenario 2: DOCKER - Reconstruir Imagen

**Cuando usarlo:**
- Cambios en el código de srv-img
- Cambios en requirements.txt
- Necesitas actualizar dependencias
- Cambios en el Dockerfile

**Pasos:**
```bash
# Opción A: SEGURA (recomendada) - Hace backup automático
cd /home/diego/Documentos/cb-totem
./scripts/rebuild-srv-img-safe.sh

# Opción B: Manual rápida (sin backup)
docker compose build --no-cache srv-img
docker compose up -d srv-img
```

**Qué hace `rebuild-srv-img-safe.sh`:**
1. ✅ Verifica estado del contenedor
2. ✅ **Hace backup de la BD** en `backups/srv-img/`
3. ✅ Detiene el contenedor
4. ✅ Reconstruye la imagen
5. ✅ Reinicia el contenedor
6. ✅ Verifica que la BD está intacta
7. ✅ Comprueba que la API responde

**Salida esperada:**
```
✓ RECONSTRUCCIÓN COMPLETADA EXITOSAMENTE
✓ Base de datos está presente en el volumen
✓ Base de datos es válida (verificación SQLite OK)
✓ API respondiendo correctamente
```

---

### Escenario 3: DOCKER - Restaurar Backup

**Cuando usarlo:**
- Algo salió mal en la BD
- Necesitas volver a una versión anterior
- Pruebas han corrompido datos
- La BD está vacía y necesitas cargar datos

**Pasos:**
```bash
# 1. Acceder al contenedor
docker compose exec srv-img bash

# 2. Ejecutar restore
cd /srv && python scripts/sqlite/restore_database.py

# 3. Salir del contenedor
exit
```

**O desde el host:**
```bash
# Copiar script de restore al contenedor
docker compose cp srv-img-totem/scripts/sqlite/restore_database.py srv-img:/srv/

# Ejecutar dentro del contenedor
docker compose exec srv-img python /srv/restore_database.py
```

---

## 📊 Flujo Completo: Cambio de Código + Reconstrucción

```
┌─────────────────────────────────────────────┐
│ 1. Haces cambios en srv-img-totem/          │
│    (main.py, src/, etc.)                    │
└────────────┬────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 2. Ejecutar rebuild seguro:                 │
│    ./scripts/rebuild-srv-img-safe.sh        │
└────────────┬────────────────────────────────┘
             │
             ▼
      ┌──────────────┐
      │ AUTOMÁTICO:  │
      │ • Backup BD  │
      │ • Build      │
      │ • Deploy     │
      │ • Verificar  │
      └──────┬───────┘
             │
             ▼
┌─────────────────────────────────────────────┐
│ 3. BD está intacta y nuevo código corre    │
│    ¡Listo para producción!                 │
└─────────────────────────────────────────────┘
```

---

## 🛡️ Protección Contra Pérdida de Datos

### ¿Qué NO puede perder?

| Elemento          | Ubicación                  | Protección                    | Nivel     |
| ----------------- | -------------------------- | ----------------------------- | --------- |
| **Base de datos** | `/srv/data/catalogos.db`   | Volumen persistente + Backups | 🔴 Crítico |
| **Imágenes**      | `/srv/imagenes/catalogos/` | Bind mount en Dockerfile      | 🟡 Alta    |
| **Configuración** | `.env`                     | En el host                    | 🟢 Normal  |

### ¿Qué puede pasar en cada escenario?

```
Acción                      BD (Volumen)  Backups (Host)  Resultado
─────────────────────────────────────────────────────────────────
docker compose down         PRESERVADA ✓  NO AFECTA      Datos seguros
docker compose up -d        RECUPERADA ✓  NO AFECTA      Acceso normal
build --no-cache            PRESERVADA ✓  NO AFECTA      Código nuevo + BD antigua
rebuild-srv-img-safe.sh     PRESERVADA ✓  COPIA NUEVA    Backup + Rebuild + Verificación
rm -rf volumen              PERDIDA ✗     TIENES COPIA ✓  Puedes restaurar
```

---

## 📋 Checklist: Antes de Reconstruir

- [ ] Cambios en código están en git
- [ ] Ejecutaste: `./scripts/rebuild-srv-img-safe.sh`
- [ ] Verificaste: `docker compose ps srv-img` (healthy)
- [ ] Probaste: `curl http://localhost:8000/`
- [ ] Confirmaste que la BD tiene los datos esperados

---

## 🔍 Comandos Útiles

```bash
# Ver estado del servicio
docker compose ps srv-img

# Ver logs en tiempo real
docker compose logs srv-img -f

# Acceder al contenedor
docker compose exec srv-img bash

# Ver tamaño de la BD
docker exec srv_img du -h /srv/data/catalogos.db

# Verificar integridad de BD
docker exec srv_img sqlite3 /srv/data/catalogos.db ".tables"

# Ver backups disponibles
ls -lh backups/srv-img/

# Hacer backup manual
cd srv-img-totem && python scripts/sqlite/backup_database.py

# Restaurar interactivamente
docker compose exec srv-img python /srv/scripts/sqlite/restore_database.py
```

---

## ⚙️ Configuración en docker-compose.yaml

```yaml
srv-img:
  build:
    context: .
    dockerfile: Dockerfile.srv-img
  container_name: srv_img
  restart: unless-stopped
  volumes:
    - srv_img_data:/srv/data           # ← BD persistente
  # ... resto de configuración

volumes:
  srv_img_data:
    driver: local                       # ← Volumen local del host
```

---

## ❓ FAQ

### P: ¿Se borra la BD al reconstruir?
**R:** No. La BD está en un volumen persistente que no se borra.

### P: ¿Qué pasa si fallo durante la reconstrucción?
**R:** Tienes un backup en `backups/srv-img/` que puedes restaurar manualmente.

### P: ¿Dónde están los backups?
**R:** En `backups/srv-img/` del host (creados automáticamente por `rebuild-srv-img-safe.sh`)

### P: ¿Puedo restaurar desde otra máquina?
**R:** Sí, copia el archivo `.db` de `backups/srv-img/` al volumen de la otra máquina en `/srv/data/`

### P: ¿Cuánto espacio ocupa el backup?
**R:** Igual que la BD. Si la BD es 5MB, el backup es 5MB.

### P: ¿Puedo automatizar los backups?
**R:** Sí, usa el script de restore (implementa un cron job con `rebuild-srv-img-safe.sh`)

---

## 🎓 Resumen Final

| Script                    | Contexto     | Uso           | Protección                |
| ------------------------- | ------------ | ------------- | ------------------------- |
| `backup_database.py`      | Local        | Backup manual | Manual                    |
| `restore_database.py`     | Local/Docker | Restaurar     | Manual + Confirmación     |
| `rebuild-srv-img-safe.sh` | Docker       | Build seguro  | Automática + Verificación |

**TL;DR:** 
- **Desarrollo local:** Usa `restore_database.py`
- **Docker production:** Usa `rebuild-srv-img-safe.sh`
- **Ambos contextos:** BD está protegida en volumen persistente

---

**Última actualización:** 2025-12-02
