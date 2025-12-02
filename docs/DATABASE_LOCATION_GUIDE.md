# Guía: Dónde Está Tu Base de Datos SQLite en Docker

## 📍 Respuesta Corta

Tu base de datos `catalogos.db` está en:

```
HOST (Tu máquina):
  /var/lib/docker/volumes/cb-totem_srv_img_data/_data/catalogos.db

CONTENEDOR (Dentro de Docker):
  /srv/data/catalogos.db

SON EL MISMO ARCHIVO - Linked por Docker
```

---

## 🎯 Explicación Visual

### Diagrama del Flujo de Datos

```
┌────────────────────────────────────────────────────────┐
│              TU MÁQUINA FÍSICA (HOST)                  │
│                                                        │
│  /var/lib/docker/volumes/                             │
│  └── cb-totem_srv_img_data/                           │
│      └── _data/                                        │
│          └── catalogos.db ← ARCHIVO REAL (36 KB)      │
│                                                        │
│  Este archivo es persistente:                          │
│  ✓ NO se borra al reconstruir imagen                  │
│  ✓ NO se borra al parar contenedor                    │
│  ✓ Está en el disco duro de tu máquina               │
└────────────┬───────────────────────────────────────────┘
             │
             │ VOLUMEN DOCKER
             │ (conexión virtual)
             │
┌────────────▼───────────────────────────────────────────┐
│           CONTENEDOR DOCKER (srv_img)                  │
│                                                        │
│  /srv/data/                                            │
│  └── catalogos.db ← MISMA referencia (no es copia)    │
│                                                        │
│  La aplicación Python accede al archivo aquí          │
│  pero en realidad lee/escribe en el host              │
└────────────────────────────────────────────────────────┘
```

---

## ❓ FAQ: ¿Cómo Funciona?

### P: ¿Es un binario ejecutable?
**R:** No. Es un archivo de base de datos SQLite normal (formato binario de BD, no ejecutable).

### P: ¿Dónde se ejecuta/procesa?
**R:** En la aplicación Python dentro del contenedor:
```
Python Application (en contenedor)
       ↓
    SQLite Library (librería Python)
       ↓
Abre archivo /srv/data/catalogos.db
       ↓
(que en realidad apunta a)
       ↓
/var/lib/docker/volumes/.../catalogos.db (en host)
       ↓
Disco duro de tu máquina
```

### P: ¿Se pierde cuando reconstruyo la imagen?
**R:** **NO.** El volumen es independiente de la imagen.

```
Reconstrucción de imagen Docker:
  ┌─────────────────────┐
  │ Borra:              │
  │ • Código            │
  │ • Dependencias      │
  │ • Sistema de archivos temp │
  └─────────────────────┘

  ┌─────────────────────┐
  │ CONSERVA:           │
  │ • Volúmenes Docker  │
  │ • catalogos.db      │ ← SEGURO
  └─────────────────────┘
```

### P: ¿Puedo editarlo desde el host?
**R:** No recomendado (SQLite está siendo usado por el contenedor). Mejor:
- Hacer backup con Docker: `docker compose cp`
- Hacer consultas con Python
- Usar tus scripts de backup/restore

---

## 🔧 Cómo Acceder a Tu BD

### Opción 1: Ver desde el Contenedor
```bash
# Ver tabla de estructura
docker compose exec srv-img python3 << 'EOF'
import sqlite3
conn = sqlite3.connect('/srv/data/catalogos.db')
cursor = conn.cursor()
cursor.execute("PRAGMA table_info(productos)")
for col in cursor.fetchall():
    print(f"{col[1]:30s} {col[2]:15s}")
conn.close()
EOF

# Ver cantidad de registros
docker compose exec srv-img python3 -c "
import sqlite3
conn = sqlite3.connect('/srv/data/catalogos.db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM productos')
print(f'Registros: {cursor.fetchone()[0]}')
conn.close()
"
```

### Opción 2: Hacer Backup
```bash
# Hacer backup dentro del contenedor
docker compose exec srv-img cp /srv/data/catalogos.db /srv/data/catalogos_backup.db

# Copiar backup a tu máquina
docker compose cp srv-img:/srv/data/catalogos_backup.db ./backups/local_backup.db
```

### Opción 3: Usar Tus Scripts Python
```bash
# Entrar al contenedor
docker compose exec srv-img bash

# Dentro del contenedor
cd /srv
python scripts/sqlite/backup_database.py
python scripts/sqlite/create_database.py
python scripts/sqlite/restore_database.py

# Salir
exit
```

---

## 📊 Estructura de Tu BD Actual

```
Base de Datos: catalogos.db (36 KB)
└── Tabla: productos
    ├── id (INTEGER) - PK
    ├── codigo (VARCHAR) - UNIQUE
    ├── nombre (VARCHAR)
    ├── descripcion (VARCHAR)
    ├── precio (FLOAT)
    ├── categoria (VARCHAR)
    ├── imagen_listado (VARCHAR)
    ├── imagen_caracteristicas (VARCHAR)
    ├── imagen_caracteristicas_2 (VARCHAR)
    ├── cuotas (JSON)
    ├── mes (VARCHAR)
    ├── ano (INTEGER)
    ├── segmento (VARCHAR)
    ├── estado (VARCHAR)
    └── stock (BOOLEAN)

Registros actuales: 0 (tabla vacía)
```

---

## 🔐 Seguridad y Persistencia

### ¿Qué No Se Borra?

| Acción                                    | BD Persiste | Volumen Persiste |
| ----------------------------------------- | ----------- | ---------------- |
| `docker compose down`                     | ✅ SÍ        | ✅ SÍ             |
| `docker compose build --no-cache srv-img` | ✅ SÍ        | ✅ SÍ             |
| `docker compose restart srv-img`          | ✅ SÍ        | ✅ SÍ             |
| `docker compose rm srv-img`               | ✅ SÍ        | ✅ SÍ             |

### ¿Qué SÍ Se Borra?

```bash
# Esto ELIMINA el volumen (cuidado):
docker volume rm cb-totem_srv_img_data

# Esto es seguro (no borra datos):
docker compose down     # Solo para servicios
```

---

## 💡 Recomendaciones

### Para Desarrollo

```bash
# Hacer backup regularmente
docker compose exec srv-img cp /srv/data/catalogos.db /srv/data/catalogos_backup.db

# O usar tu script
docker compose exec srv-img python /srv/scripts/sqlite/backup_database.py
```

### Para Reconstrucciones

```bash
# Usar el script seguro que creé:
cd /home/diego/Documentos/cb-totem
./scripts/rebuild-srv-img-safe.sh

# Este script automáticamente:
# ✓ Hace backup
# ✓ Reconstruye imagen
# ✓ Verifica que la BD está intacta
```

### Para Cargar Datos

```bash
# Tu BD está vacía (0 registros)
# Cargar datos con tus scripts:
docker compose exec srv-img python /srv/test/load_all_products.py

# Verificar que se cargaron:
docker compose exec srv-img python3 -c "
import sqlite3
conn = sqlite3.connect('/srv/data/catalogos.db')
cursor = conn.cursor()
cursor.execute('SELECT COUNT(*) FROM productos')
print(f'Registros: {cursor.fetchone()[0]}')
conn.close()
"
```

---

## 🎓 Resumen

| Pregunta                   | Respuesta                                                          |
| -------------------------- | ------------------------------------------------------------------ |
| ¿Dónde está?               | `/var/lib/docker/volumes/cb-totem_srv_img_data/_data/catalogos.db` |
| ¿Es binario?               | No, es un archivo SQLite normal                                    |
| ¿Cómo lo maneja Docker?    | Con un volumen (link automático host↔contenedor)                   |
| ¿Se pierde al reconstruir? | NO, está en volumen persistente                                    |
| ¿Puedo editarlo?           | Mejor acceder desde Python/Docker                                  |
| ¿Cómo hago backup?         | `docker compose cp` o tus scripts Python                           |
| ¿Cómo restauro?            | `restore_database.py` o copia manual                               |

**La conclusión es:** Tu BD está perfectamente segura, accesible, y muy fácil de manejar. 🎉
