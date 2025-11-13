# 📦 Documentación de Instalación Chatwoot

Esta carpeta contiene la documentación completa sobre la instalación de Chatwoot en ambientes VM, incluyendo el análisis del bug conocido y soluciones.

## 📄 Documentos Disponibles

### 1. [CHATWOOT_VM_INSTALLATION_GUIDE.md](./CHATWOOT_VM_INSTALLATION_GUIDE.md)
**Guía Completa de Instalación de Chatwoot en VM** (40+ páginas)

Documentación exhaustiva que incluye:
- ✅ Por qué Chatwoot NO se instala al primer intento
- ✅ Análisis técnico del bug en migración `20231211010807`
- ✅ Versiones afectadas: v4.4.0, v4.5.2, v4.6.0, v4.7.0 (latest)
- ✅ Proceso de instalación correcto paso a paso
- ✅ Workarounds manuales y automatizados
- ✅ Configuración post-instalación
- ✅ Mejores prácticas para VMs de producción
- ✅ Nginx, SSL, backups y monitoreo
- ✅ Troubleshooting completo con 8+ problemas comunes
- ✅ Referencias oficiales y comandos útiles

**Tiempo de lectura:** 30-45 minutos  
**Audiencia:** Administradores de sistemas, DevOps

---

### 2. [QUICK_FIX_CHATWOOT.md](./QUICK_FIX_CHATWOOT.md)
**Solución Rápida al Bug de Instalación** (1 página)

Resumen ejecutivo con:
- 🚨 Descripción del problema
- ✅ 3 métodos de solución rápida
- 🔍 Verificaciones necesarias
- 🆘 Soporte y referencias

**Tiempo de lectura:** 5 minutos  
**Audiencia:** Todos

---

## 🛠️ Script Automatizado

### [../scripts/fix-chatwoot.sh](../scripts/fix-chatwoot.sh)
Script bash completo que:
- Detecta y repara instalaciones fallidas
- Aplica workaround para el bug 20231211010807
- Verifica la integridad de la base de datos
- Reinicia servicios automáticamente
- Ofrece crear usuario SuperAdmin

**Uso:**
```bash
cd /home/diego/Documentos/cb-totem
./scripts/fix-chatwoot.sh
```

---

## 🚀 Quick Start

### Si es tu primera instalación:

```bash
# 1. Limpiar todo
docker compose down -v
docker volume prune -f

# 2. Iniciar base de datos
docker compose up -d postgres redis
sleep 10

# 3. USAR EL COMANDO CORRECTO (no 'rails db:migrate')
docker compose run --rm chatwoot-web bundle exec rails db:chatwoot_prepare

# 4. Iniciar servicios
docker compose up -d
```

### Si ya falló la instalación:

```bash
# Opción 1: Usar el script automatizado
./scripts/fix-chatwoot.sh

# Opción 2: Reparación manual rápida
docker compose down
docker compose up -d postgres
sleep 5

docker exec -i postgres_db psql -U postgres <<EOF
\c chatwoot
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS cached_label_list VARCHAR;
INSERT INTO schema_migrations (version) VALUES ('20231211010807') ON CONFLICT DO NOTHING;
\q
EOF

docker compose run --rm chatwoot-web bundle exec rails db:migrate
docker compose up -d
```

---

## 🔍 Verificación

Después de la instalación, verifica que todo funcione:

```bash
# 1. Contenedor corriendo
docker compose ps chatwoot-web
# Debe mostrar "Up"

# 2. Número de tablas
docker exec postgres_db psql -U postgres -d chatwoot -c "\dt" | wc -l
# Debe retornar ~86-90

# 3. Columna crítica existe
docker exec postgres_db psql -U postgres -d chatwoot -c "\d conversations" | grep cached_label_list
# Debe mostrar: cached_label_list | text |

# 4. HTTP responde
curl -I http://localhost:3000
# HTTP/1.1 200 OK
```

---

## 📚 Contexto

### El Problema

Chatwoot tiene un bug conocido en las versiones v4.4.0+ donde la migración `20231211010807_add_cached_labels_list.rb` falla con el error:

```
NameError: uninitialized constant ActsAsTaggableOn::Taggable::Cache
```

Esto causa que:
- El contenedor entre en loop infinito de reinicios
- La base de datos quede incompleta (~10 tablas en lugar de 86)
- El servicio nunca inicie correctamente

### La Causa Raíz

El código de la migración intenta llamar a `ActsAsTaggableOn::Taggable::Cache.included(Conversation)` pero este módulo no está disponible durante la ejecución de migraciones porque requiere que toda la aplicación esté completamente cargada.

### La Solución

1. **Usar `rails db:chatwoot_prepare`** en lugar de `rails db:migrate`
2. **O aplicar workaround manual** agregando la columna y marcando la migración como completada
3. **O ejecutar el script automatizado** que detecta y repara el problema

---

## 🎯 Lecciones Aprendidas

1. ✅ **NUNCA usar `rails db:migrate`** → Usar `rails db:chatwoot_prepare`
2. ✅ **NO usar `latest`** → Usar versión específica como `v4.6.0`
3. ✅ **Generar SECRET_KEY_BASE único** → `openssl rand -hex 64`
4. ✅ **SuperAdmin ≠ Administrator** → Son diferentes niveles de acceso
5. ✅ **Nginx es esencial** → Para WebSocket y SSL en producción
6. ✅ **Backups desde día 1** → Script de backup automatizado
7. ✅ **Monitoreo activo** → Health checks y rotación de logs

---

## 📖 Para Más Información

- [Documentación oficial de Chatwoot Docker](https://developers.chatwoot.com/self-hosted/deployment/docker)
- [Documentación oficial de Chatwoot Linux VM](https://developers.chatwoot.com/self-hosted/deployment/linux-vm)
- [Chatwoot GitHub Repository](https://github.com/chatwoot/chatwoot)
- [ActsAsTaggableOn Caching Wiki](https://github.com/mbleigh/acts-as-taggable-on/wiki/Caching)
- [Archivo de migración problemático](https://github.com/chatwoot/chatwoot/blob/main/db/migrate/20231211010807_add_cached_labels_list.rb)

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisa la [guía completa de troubleshooting](./CHATWOOT_VM_INSTALLATION_GUIDE.md#troubleshooting)
2. Verifica los logs: `docker compose logs chatwoot-web --tail=100`
3. Ejecuta el script de diagnóstico: `./scripts/diagnose.sh`
4. Consulta el [README principal](../../README.md)
5. Revisa los [issues de Chatwoot en GitHub](https://github.com/chatwoot/chatwoot/issues)

---

**Última actualización:** Enero 2025  
**Versión:** 1.0  
**Estado:** ✅ Documentación completa y probada

---

**Proyecto:** CB-Totem - Chat Bot Totem  
**Componente:** Chatwoot Self-Hosted v4.6.0+  
**Ambiente:** Ubuntu VM con Docker Compose
