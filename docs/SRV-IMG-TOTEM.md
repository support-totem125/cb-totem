📚 # Guía Actualizada - srv-img-totem Agregado

## Resumen de cambios

Se ha agregado el servicio **srv-img-totem** al proyecto chat-bot-totem. Este es un servidor FastAPI que sirve imágenes locales a través de una API REST.

---

## Estructura actualizada del proyecto

```
chat-bot-totem/
├── docker-compose.yaml        (✅ ACTUALIZADO)
├── README.md
├── docs/
│   ├── guia.md
│   ├── SRV-IMG-TOTEM.md        (NUEVO - esta guía)
│   ├── N8N_WORKFLOW_COMPLETE.md
│   └── WATCHTOWER_CONFIG.md
├── logs/
├── scripts/
│   ├── auto-sync.sh
│   ├── create-multiple-databases.sh
│   ├── manage.sh
│   ├── update-vcc-totem.sh
│   ├── update-srv-img-totem.sh (NUEVO)
│   └── watchtower-info.sh
├── vcc-totem/                  (API Calidda)
│   ├── api_wrapper.py
│   ├── requirements.txt
│   └── src/
├── srv-img-totem/              (✅ NUEVO - Servidor de Imágenes)
│   ├── main.py
│   ├── requirements.txt
│   ├── imagenes/               (Directorio donde se almacenan las imágenes)
│   └── README.md
└── ...
```

---

## Servicios disponibles

| Servicio        | Puerto   | Descripción                                    |
| --------------- | -------- | ---------------------------------------------- |
| Evolution API   | 8080     | WhatsApp API                                   |
| Chatwoot        | 3000     | Plataforma de atención al cliente              |
| n8n             | 5678     | Automatización de workflows                    |
| PostgreSQL      | 5432     | Base de datos principal                        |
| Redis           | 6379     | Cache distribuido                              |
| **calidda-api** | **5000** | **API wrapper para consultar Calidda por DNI** |
| **srv-img**     | **8000** | **✅ NUEVO - Servidor de Imágenes**             |

---

## Configuración de srv-img-totem

### Clonación

El repositorio ya ha sido clonado en `/home/admin/Documents/chat-bot-totem/srv-img-totem`.

### Endpoints principales

Una vez el servicio esté corriendo en el contenedor Docker, accede a:

- **Información general**: `http://localhost:8000/`
- **Listar imágenes**: `http://localhost:8000/imagenes`
- **Listar todas (incluyendo subdirectorios)**: `http://localhost:8000/todas-las-imagenes`
- **Ver imagen**: `http://localhost:8000/ver/{nombre_archivo}`
- **Ver imagen por ruta**: `http://localhost:8000/ver-ruta/masivos/financia-calidda-n-1.jpg`
- **Descargar imagen**: `http://localhost:8000/imagen/{nombre_archivo}`
- **Acceso directo estático**: `http://localhost:8000/static/{ruta_completa}`
- **Diagnóstico**: `http://localhost:8000/diagnostico`
- **Documentación interactiva**: `http://localhost:8000/docs`

### Estructura de directorios de imágenes

```
srv-img-totem/imagenes/
├── catalogos/
│   └── 2025/
│       └── noviembre/
│           └── fnb/
├── masivos/
│   └── financia-calidda-n-1.jpg
└── A.jpg
```

Puedes agregar más imágenes en subdirectorios según tus necesidades.

### Comandos útiles

**Iniciar/Detener solo el servicio de imágenes**:
```bash
docker compose up -d srv-img
docker compose down srv-img
docker compose restart srv-img
```

**Ver logs del servicio**:
```bash
docker compose logs -f srv-img
```

**Test rápido desde host**:
```bash
curl http://localhost:8000/
curl http://localhost:8000/todas-las-imagenes
curl http://localhost:8000/ver/financia-calidda-n-1.jpg > imagen.jpg
```

**Ver diagnóstico completo**:
```bash
curl -s http://localhost:8000/diagnostico | jq
```

---

## Actualización de srv-img-totem

Se ha creado un script de actualización similar al de `vcc-totem`:

```bash
./scripts/update-srv-img-totem.sh
```

Este script:
- ✅ Trae cambios del repositorio remoto
- ✅ Registra actividad en `logs/srv-img-totem-updates.log`
- ✅ Redeploya el servicio automáticamente
- ✅ Verifica el estado después de la actualización

---

## Integración con n8n (Uso futuro)

Una vez que tengas imágenes almacenadas en `srv-img-totem/imagenes/`, puedes:

1. Llamar desde n8n al endpoint de srv-img-totem
2. Obtener URLs de imágenes para:
   - Enviarlas a través de Evolution API (WhatsApp)
   - Incluirlas en mensajes de Chatwoot
   - Usar en workflows más complejos

Ejemplo de nodo HTTP en n8n:
```json
{
  "method": "GET",
  "url": "http://srv-img:8000/ver/financia-calidda-n-1.jpg"
}
```

---

## Troubleshooting

### Puerto 8000 ya en uso

Si el puerto 8000 está en uso, edita `docker-compose.yaml`:

```yaml
srv-img:
  ports:
    - "8001:8000"  # Cambiar a otro puerto
```

### Imágenes no se encuentran

1. Verifica que las imágenes existan en `srv-img-totem/imagenes/`
2. Consulta el endpoint `/diagnostico` para ver la estructura de archivos
3. Verifica permisos: `ls -la srv-img-totem/imagenes/`

### Formatos no soportados

El servicio solo soporta: `.png`, `.jpg`, `.jpeg`, `.gif`, `.bmp`, `.webp`

---

## Scripts de gestión

El archivo `scripts/manage.sh` puede actualizarse en el futuro para incluir opciones para:

- Listar imágenes disponibles
- Reiniciar solo srv-img
- Ver logs de srv-img
- Obtener diagnóstico de srv-img

---

## Referencia rápida

| Acción             | Comando                             |
| ------------------ | ----------------------------------- |
| Iniciar srv-img    | `docker compose up -d srv-img`      |
| Detener srv-img    | `docker compose stop srv-img`       |
| Reiniciar srv-img  | `docker compose restart srv-img`    |
| Logs de srv-img    | `docker compose logs -f srv-img`    |
| Actualizar srv-img | `./scripts/update-srv-img-totem.sh` |
| Ver estado         | `docker compose ps srv-img`         |
| Acceder a la API   | `http://localhost:8000/docs`        |

---

## Próximos pasos

1. ✅ Verifica que `srv-img` esté corriendo: `docker compose ps`
2. ✅ Accede a `http://localhost:8000/docs` para ver la documentación interactiva
3. ✅ Carga imágenes en `srv-img-totem/imagenes/`
4. ✅ Integra con n8n cuando sea necesario

---

**Última actualización**: 4 de Noviembre de 2025

