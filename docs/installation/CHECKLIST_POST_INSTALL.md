# ✅ Checklist de Verificación Post-Instalación Chatwoot

Use este checklist para verificar que su instalación de Chatwoot está completa y funcionando correctamente.

---

## 📋 Verificación Básica

### 1. Servicios Docker

```bash
# Verificar que todos los contenedores estén corriendo
docker compose ps
```

**Resultado esperado:**
```
NAME                STATUS              PORTS
chatwoot-web        Up X minutes        0.0.0.0:3000->3000/tcp
chatwoot-sidekiq    Up X minutes        
postgres_db         Up X minutes (healthy)
redis_cache         Up X minutes (healthy)
```

- [ ] chatwoot-web está "Up" (NO "Restarting")
- [ ] chatwoot-sidekiq está "Up"
- [ ] postgres_db está "Up" y "healthy"
- [ ] redis_cache está "Up" y "healthy"

---

### 2. Base de Datos PostgreSQL

```bash
# Verificar conexión a PostgreSQL
docker exec postgres_db pg_isready -U postgres

# Verificar que la base de datos chatwoot existe
docker exec postgres_db psql -U postgres -c "\l" | grep chatwoot

# Contar número de tablas
docker exec postgres_db psql -U postgres -d chatwoot -c "\dt" | wc -l
```

**Resultado esperado:**
- [ ] PostgreSQL responde "accepting connections"
- [ ] Base de datos "chatwoot" existe
- [ ] Número de tablas: **86-90 tablas** (no ~10-15)

---

### 3. Tabla Conversations y Columna Critical

```bash
# Verificar que la tabla conversations existe
docker exec postgres_db psql -U postgres -d chatwoot -c "\dt conversations"

# Verificar que la columna cached_label_list existe
docker exec postgres_db psql -U postgres -d chatwoot -c "\d conversations" | grep cached_label_list
```

**Resultado esperado:**
- [ ] Tabla "conversations" existe
- [ ] Columna "cached_label_list" existe con tipo **text** (no string/varchar)

---

### 4. Migración 20231211010807

```bash
# Verificar que la migración problemática está marcada como completada
docker exec postgres_db psql -U postgres -d chatwoot -c "SELECT version FROM schema_migrations WHERE version = '20231211010807';"
```

**Resultado esperado:**
- [ ] Retorna: `20231211010807`
- [ ] NO retorna error o vacío

---

### 5. Conectividad HTTP

```bash
# Verificar que Chatwoot responde
curl -I http://localhost:3000

# Verificar contenido HTML
curl -s http://localhost:3000 | grep -o '<title>.*</title>'
```

**Resultado esperado:**
- [ ] HTTP Status: **200 OK**
- [ ] Retorna: `<title>Chatwoot</title>`

---

### 6. Logs de Chatwoot

```bash
# Ver últimas líneas de log
docker compose logs chatwoot-web --tail=50
```

**Resultado esperado:**
- [ ] NO hay errores de tipo "NameError: uninitialized constant"
- [ ] NO hay errores de migración
- [ ] Aparece línea: "Listening on http://0.0.0.0:3000"
- [ ] Aparece línea: "Use Ctrl-C to stop"

---

## 🔐 Verificación de Seguridad

### 7. Variables de Entorno

```bash
# Verificar SECRET_KEY_BASE está configurado
docker exec chatwoot_web env | grep SECRET_KEY_BASE

# Verificar longitud (debe ser 128 caracteres)
docker exec chatwoot_web env | grep SECRET_KEY_BASE | cut -d'=' -f2 | wc -c
```

**Resultado esperado:**
- [ ] SECRET_KEY_BASE existe
- [ ] Longitud: **129 caracteres** (128 + newline)
- [ ] NO es un valor por defecto o vacío

---

### 8. Contraseñas de Base de Datos

```bash
# Verificar que NO estás usando contraseñas por defecto
docker exec chatwoot_web env | grep POSTGRES_PASSWORD
docker exec chatwoot_web env | grep REDIS_PASSWORD
```

**Resultado esperado:**
- [ ] POSTGRES_PASSWORD NO es "postgres" (si es producción)
- [ ] REDIS_PASSWORD NO es "redis" (si es producción)

---

## 👤 Verificación de Usuario

### 9. Usuario SuperAdmin

```bash
# Verificar que existe al menos un usuario SuperAdmin
docker exec chatwoot_web bundle exec rails runner "
admins = User.where(type: 'SuperAdmin')
puts 'Total SuperAdmins: ' + admins.count.to_s
admins.each { |u| puts '- ' + u.email + ' (ID: ' + u.id.to_s + ')' }
"
```

**Resultado esperado:**
- [ ] Existe al menos 1 SuperAdmin
- [ ] Conoces el email y contraseña del SuperAdmin

---

### 10. Login en Interfaz Web

1. Abre en el navegador: `http://localhost:3000`
2. Intenta hacer login con tu usuario SuperAdmin

**Resultado esperado:**
- [ ] La página de login carga correctamente
- [ ] Puedes iniciar sesión exitosamente
- [ ] No hay errores en la consola del navegador
- [ ] Ves el dashboard de Chatwoot

---

## 📊 Verificación de Rendimiento

### 11. Uso de Recursos

```bash
# Ver uso de CPU y memoria
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Resultado esperado:**
- [ ] chatwoot-web usa **< 50% CPU** en reposo
- [ ] chatwoot-web usa **< 1GB RAM** en reposo
- [ ] postgres_db usa **< 30% CPU** en reposo
- [ ] postgres_db usa **< 500MB RAM** en reposo

---

### 12. Redis Funcionando

```bash
# Verificar conexión a Redis
docker exec redis_cache redis-cli -a redis ping

# Verificar número de keys
docker exec redis_cache redis-cli -a redis DBSIZE
```

**Resultado esperado:**
- [ ] Comando `ping` retorna: **PONG**
- [ ] DBSIZE retorna un número >= 0

---

## 🔌 Verificación de Funcionalidad

### 13. Sidekiq (Worker)

```bash
# Verificar que Sidekiq está procesando jobs
docker compose logs chatwoot-sidekiq --tail=20
```

**Resultado esperado:**
- [ ] Aparece línea: "Booting Sidekiq"
- [ ] NO hay errores de conexión
- [ ] Muestra estadísticas de queues

---

### 14. ActionCable (WebSocket)

```bash
# Verificar logs de ActionCable
docker compose logs chatwoot-web | grep -i cable | tail -5
```

**Resultado esperado:**
- [ ] NO hay errores de ActionCable
- [ ] Si hay actividad, muestra conexiones establecidas

---

### 15. Almacenamiento de Archivos

```bash
# Verificar que el directorio de storage existe
docker exec chatwoot_web ls -la /app/storage

# Verificar permisos
docker exec chatwoot_web stat -c '%a %U:%G' /app/storage
```

**Resultado esperado:**
- [ ] Directorio `/app/storage` existe
- [ ] Tiene permisos de escritura (755 o 775)

---

## 🌐 Verificación de Producción (Opcional)

### 16. Nginx (Si aplica)

```bash
# Verificar configuración Nginx
sudo nginx -t

# Verificar que Nginx está corriendo
sudo systemctl status nginx

# Verificar SSL
curl -I https://tu-dominio.com
```

**Resultado esperado:**
- [ ] Nginx configuración es válida
- [ ] Nginx está activo y corriendo
- [ ] SSL responde con HTTP/2 200

---

### 17. Certificado SSL (Si aplica)

```bash
# Verificar fecha de expiración del certificado
sudo certbot certificates
```

**Resultado esperado:**
- [ ] Certificado existe para tu dominio
- [ ] Fecha de expiración es > 30 días
- [ ] Auto-renovación está habilitada

---

### 18. Firewall (Si aplica)

```bash
# Verificar reglas UFW
sudo ufw status
```

**Resultado esperado:**
- [ ] Puerto 80 (HTTP) está abierto
- [ ] Puerto 443 (HTTPS) está abierto
- [ ] Puerto 22 (SSH) está abierto
- [ ] Puerto 3000 está **cerrado** (solo accesible desde localhost)

---

## 📧 Verificación de Correo (Opcional)

### 19. Configuración SMTP

```bash
# Verificar variables SMTP
docker exec chatwoot_web env | grep SMTP
```

**Resultado esperado:**
- [ ] SMTP_ADDRESS está configurado
- [ ] SMTP_USERNAME está configurado
- [ ] SMTP_PASSWORD está configurado
- [ ] SMTP_PORT es correcto (587 para TLS)

---

### 20. Envío de Correo de Prueba

```bash
# Enviar correo de prueba desde Rails console
docker exec -it chatwoot_web bundle exec rails console

# Dentro de la consola:
ActionMailer::Base.mail(
  from: 'support@totemperu.com.pe',
  to: 'tu_email@gmail.com',
  subject: 'Test Chatwoot',
  body: 'Correo de prueba desde Chatwoot'
).deliver_now
```

**Resultado esperado:**
- [ ] NO hay errores en la consola
- [ ] Recibes el correo en tu inbox
- [ ] El correo NO está en spam

---

## 🔄 Verificación de Backups (Opcional)

### 21. Script de Backup

```bash
# Verificar que el script de backup existe
ls -la /usr/local/bin/backup-chatwoot.sh

# Probar ejecución manual
sudo /usr/local/bin/backup-chatwoot.sh
```

**Resultado esperado:**
- [ ] Script existe y es ejecutable
- [ ] Se crea backup en `/backups/chatwoot/`
- [ ] Backup contiene archivo .sql.gz

---

### 22. Crontab de Backups

```bash
# Verificar crontab
sudo crontab -l | grep backup-chatwoot
```

**Resultado esperado:**
- [ ] Existe entrada en crontab
- [ ] Está programado para ejecutarse diariamente
- [ ] La ruta del script es correcta

---

## 📈 Verificación de Monitoreo (Opcional)

### 23. Health Check Script

```bash
# Ejecutar script de health check
./scripts/status.sh
```

**Resultado esperado:**
- [ ] Todos los servicios reportan estado "healthy"
- [ ] No hay alertas críticas

---

### 24. Logs Rotados

```bash
# Verificar configuración de logrotate
cat /etc/logrotate.d/chatwoot
```

**Resultado esperado:**
- [ ] Archivo existe
- [ ] Logs se rotan diariamente
- [ ] Se mantienen 14 días de logs

---

## ✅ Resumen Final

### Checklist Mínimo (Instalación Básica)

- [ ] 1. Servicios Docker corriendo
- [ ] 2. Base de datos con 86+ tablas
- [ ] 3. Columna cached_label_list existe (tipo text)
- [ ] 4. Migración 20231211010807 completada
- [ ] 5. HTTP responde con 200 OK
- [ ] 6. Logs sin errores críticos
- [ ] 9. Usuario SuperAdmin creado
- [ ] 10. Login funciona correctamente

### Checklist Completo (Producción)

- [ ] Todos los items del Checklist Mínimo
- [ ] 7. SECRET_KEY_BASE único configurado
- [ ] 8. Contraseñas seguras (no defaults)
- [ ] 11. Uso de recursos aceptable
- [ ] 12. Redis funcionando
- [ ] 13. Sidekiq procesando jobs
- [ ] 16. Nginx configurado
- [ ] 17. Certificado SSL válido
- [ ] 18. Firewall configurado
- [ ] 19. SMTP configurado
- [ ] 20. Envío de correos funciona
- [ ] 21. Backups automatizados
- [ ] 23. Monitoreo activo

---

## 🎯 Puntuación

- **20-24 ✅**: Instalación completa y lista para producción
- **15-19 ⚠️**: Instalación funcional, faltan configuraciones opcionales
- **10-14 🔧**: Instalación básica, requiere configuración adicional
- **< 10 ❌**: Instalación incompleta, revisar logs y documentación

---

## 📞 Siguiente Paso

Si todos los checks básicos (1-10) están completos:

1. **Lee la documentación completa:** [CHATWOOT_VM_INSTALLATION_GUIDE.md](./CHATWOOT_VM_INSTALLATION_GUIDE.md)
2. **Configura Nginx y SSL** para producción
3. **Implementa backups automatizados**
4. **Configura monitoreo y alertas**
5. **Documenta tu configuración específica**

---

**Última actualización:** Enero 2025  
**Versión:** 1.0  
**Proyecto:** CB-Totem
