# Fix Rápido para Bug de Instalación de Chatwoot

## 🚨 Problema

Chatwoot **NO se instala al primer intento** debido al error:

```
NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache
```

**Versiones afectadas:** v4.4.0, v4.5.2, v4.6.0, v4.7.0 (latest)

---

## ✅ Solución en 3 Pasos

### Método 1: Instalación Limpia (Recomendado)

```bash
# 1. Limpiar todo
docker compose down -v
docker volume prune -f

# 2. Iniciar solo base de datos y Redis
docker compose up -d postgres redis
sleep 10

# 3. Usar el comando CORRECTO (no 'rails db:migrate')
docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

# 4. Iniciar servicios
docker compose up -d
```

### Método 2: Reparar Instalación Fallida

```bash
#!/bin/bash
# fix-chatwoot.sh

echo "🔧 Reparando instalación de Chatwoot..."

# Detener servicios
docker compose down

# Iniciar solo PostgreSQL
docker compose up -d postgres
sleep 5

# Aplicar workaround
docker exec -i postgres_db psql -U postgres <<EOF
\c chatwoot
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS cached_label_list VARCHAR;
INSERT INTO schema_migrations (version) VALUES ('20231211010807') ON CONFLICT DO NOTHING;
SELECT 'Workaround aplicado exitosamente' AS status;
\q
EOF

# Ejecutar migraciones restantes
docker compose run --rm chatwoot-web bundle exec rails db:migrate

# Iniciar todos los servicios
docker compose up -d

echo "✅ Reparación completada"
```

### Método 3: Script Automatizado

Descarga y ejecuta el script de reparación:

```bash
# Descargar script
curl -o fix-chatwoot.sh https://raw.githubusercontent.com/tu-repo/scripts/fix-chatwoot.sh

# Dar permisos
chmod +x fix-chatwoot.sh

# Ejecutar
./fix-chatwoot.sh
```

---

## 🔍 Verificación

```bash
# Verificar que esté corriendo
docker compose ps | grep chatwoot
# Debe mostrar "Up" sin "Restarting"

# Verificar número de tablas
docker exec postgres_db psql -U postgres -d chatwoot -c "\dt" | wc -l
# Debe retornar ~86-90

# Verificar columna crítica
docker exec postgres_db psql -U postgres -d chatwoot -c "\d conversations" | grep cached_label_list
# Debe mostrar: cached_label_list | text |

# Verificar que responde
curl -I http://localhost:3000
# HTTP/1.1 200 OK
```

---

## 📚 Documentación Completa

Ver: [docs/installation/CHATWOOT_VM_INSTALLATION_GUIDE.md](./CHATWOOT_VM_INSTALLATION_GUIDE.md)

---

## ⚠️ Importante

1. **NUNCA uses `rails db:migrate`** → Usa `rails db:chatwoot_prepare`
2. **NO uses `latest`** → Usa versión específica como `v4.6.0`
3. **Genera SECRET_KEY_BASE único:** `openssl rand -hex 64`
4. **SuperAdmin ≠ Administrator** → Son diferentes niveles

---

## 🆘 Soporte

Si el problema persiste:

1. Verifica logs: `docker compose logs chatwoot-web --tail=100`
2. Revisa la guía completa en `docs/installation/`
3. Reporta el issue con logs completos
