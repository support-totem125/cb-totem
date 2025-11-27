# 🔄 Flujo de Trabajo: Cambios en srv-img-totem

## 📋 Resumen Rápido

Cuando hagas cambios en `srv-img-totem/`, necesitas **reconstruir la imagen Docker** para que se reflejen:

```bash
cd /home/diego/Documentos/cb-totem
docker compose build srv-img      # Reconstruye imagen (desde repo local)
docker compose restart srv-img    # Reinicia contenedor
```

**NOTA**: El Dockerfile usa el repositorio **local** (`COPY srv-img-totem .`), así que es rápido. Mantén la carpeta `srv-img-totem/` en el directorio.

---

## 🔧 Proceso Completo (Paso a Paso)

### 1️⃣ Después de hacer cambios en `srv-img-totem/`

**Archivos que puedes cambiar sin reconstruir**:
- `.env` (variables de entorno)
- Scripts de configuración

**Archivos que REQUIEREN reconstrucción**:
- `main.py` ⚠️
- `catalogos_manager.py` ⚠️
- `requirements.txt` ⚠️
- Cualquier archivo Python ⚠️
- Carpetas `api/`, `imagenes/` ⚠️

### 2️⃣ Reconstruir la imagen

```bash
# Opción A: Con caché (recomendado - más rápido)
docker compose build srv-img

# Opción B: Sin caché (si algo falla)
docker compose build --no-cache srv-img
```

**Tiempo esperado**:
- Con caché: ~15-20 segundos
- Sin caché: ~40-50 segundos

### 3️⃣ Reiniciar el contenedor

```bash
docker compose restart srv-img
```

O si necesitas reiniciar todo:

```bash
docker compose restart
```

### 4️⃣ Verificar cambios aplicados

```bash
# Ver logs de srv-img
docker compose logs srv-img -f

# Probar el endpoint
curl http://localhost:8000/health

# Ver si healthcheck pasa
docker compose ps | grep srv_img
# Debería mostrar "Up X seconds (healthy)" o similar
```

---

## 🚀 Flujo Automatizado (Recomendado)

Crea un script bash para hacerlo en un comando:

**Archivo**: `scripts/rebuild-srv-img.sh`

```bash
#!/bin/bash
set -e

echo "🔨 Reconstruyendo srv-img..."
docker compose build srv-img

echo "🔄 Reiniciando srv-img..."
docker compose restart srv-img

echo "⏳ Esperando inicialización..."
sleep 3

echo "✅ Verificando estado..."
docker compose ps | grep srv_img

echo ""
echo "📊 Logs:"
docker compose logs --tail 10 srv-img
```

**Uso**:
```bash
chmod +x scripts/rebuild-srv-img.sh
./scripts/rebuild-srv-img.sh
```

---

## 🐛 Solución de Problemas

### ❌ "Cambios no aparecen después de reconstruir"

**Causas comunes**:
1. No reconstruiste la imagen (`docker compose build srv-img`)
2. No reiniciaste el contenedor (`docker compose restart srv-img`)
3. El caché antiguo interfiere

**Solución**:
```bash
# Reconstruir sin caché
docker compose build --no-cache srv-img
docker compose restart srv-img

# Verificar que la imagen cambió
docker images | grep srv-img
```

### ❌ "El contenedor sigue usando imagen anterior"

```bash
# Ver SHA de imagen en uso
docker compose ps | grep srv_img

# Reconstruir
docker compose build srv-img

# Ver si SHA cambió
docker compose ps | grep srv_img
```

### ❌ "main.py falla con errores de módulos"

Si después de cambiar `requirements.txt`:

```bash
# Reconstruir limpiamente
docker compose build --no-cache srv-img
docker compose restart srv-img

# Ver logs detallados
docker compose logs srv-img --tail 50
```

---

## 📊 Estado de Caché

### Ver qué está cacheado

```bash
docker builder prune  # Ver espacio de caché
```

### Limpiar todo el caché (nuclear option)

```bash
docker builder prune -a  # ⚠️ Limpia TODO, próxima build tardará más
```

---

## 🎯 Mejor Práctica: Flujo Recomendado

### Durante desarrollo local:

```bash
# 1. Haz cambios en srv-img-totem/
nano srv-img-totem/main.py

# 2. Reconstruye (con caché)
docker compose build srv-img

# 3. Reinicia
docker compose restart srv-img

# 4. Prueba
curl http://localhost:8000/health

# 5. Ver logs si hay error
docker compose logs srv-img -f
```

### Antes de deployar a producción:

```bash
# 1. Reconstruir sin caché para garantizar consistency
docker compose build --no-cache srv-img

# 2. Ejecutar tests
python3 srv-img-totem/test_catalogo.py

# 3. Reiniciar
docker compose restart srv-img

# 4. Verificar endpoints
curl http://localhost:8000/health
curl http://localhost:8000/catalogo/2025/fnb/noviembre
```

---

## 📝 Recordatorio Importante

**Docker build = Multi-stage compilation**:
```
Dockerfile.srv-img
├─ Stage 1 (builder): Compile dependencies
│  └─ requirements.txt → wheels
│
├─ Stage 2 (runtime): Final image
│  └─ Copy app code
│  └─ Copy wheels
│  └─ Run python main.py
```

Cuando cambias código, **solo Stage 2 se reconstruye** (con caché), por eso es rápido.

Cuando cambias `requirements.txt`, **ambos stages se reconstruyen**.

---

## 🔗 Referencias

- **Dockerfile**: `Dockerfile.srv-img`
- **Aplicación**: `srv-img-totem/main.py`
- **Dependencias**: `srv-img-totem/requirements.txt`
- **Catálogos**: `srv-img-totem/api/catalogos/`
- **Imágenes**: `srv-img-totem/imagenes/`

---

## ✅ Checklist Después de Cambios

```bash
# 1. Reconstruir
[ ] docker compose build srv-img

# 2. Reiniciar
[ ] docker compose restart srv-img

# 3. Esperar
[ ] sleep 3

# 4. Verificar
[ ] docker compose ps | grep srv_img
[ ] curl http://localhost:8000/health

# 5. Ver logs
[ ] docker compose logs srv-img --tail 20
```

---

**Última actualización**: 27 de Noviembre 2025  
**Status**: ✅ Imagen compilada con caché, lista para cambios futuros
