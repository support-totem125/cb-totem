# 🚀 Chatbot Totem — Descripción completa

Repositorio que contiene un stack Docker para automatizar atención al cliente (WhatsApp u otros canales) mediante Evolution API, Chatwoot y n8n, y además el microservicio `vcc-totem` que implementa lógica específica para consultar un FNB/Calidda por DNI.

Este README se ha ampliado con instrucciones de instalación, configuración y uso del wrapper FastAPI (`calidda-api`) y el flujo n8n → Calidda → Chatwoot.

## Contenido principal del repo

- `docker-compose.yaml` — orquestación de servicios principales (Evolution API, Chatwoot, n8n, PostgreSQL, Redis, etc.).
- `vcc-totem/` — microproyecto con el CLI original y el wrapper HTTP:
  - `src/` — código del CLI: `api/auth.py`, `api/client.py`, `utils/messages.py`, `main.py`.
  - `api_wrapper.py` — FastAPI wrapper que expone `/health` y `/query`.
  - `requirements.txt` — dependencias Python.
- `docs/` — documentación: `N8N_WORKFLOW_COMPLETE.md` (flujo detallado) y otras guías.
- `scripts/` — scripts de soporte (`update-vcc-totem.sh`, `call-main.sh`, etc.).
- `README.md` — este archivo (actualizado).

---

## Requisitos previos

- Host con Docker y Docker Compose instalados (compatible con Linux). 
- Opcional: OpenSSL para generar claves.

---

## Instalación y puesta en marcha (rápido)

1. Clona el repositorio y sitúate en la carpeta:

```bash
git clone <URL_DEL_REPO>
cd chat-bot-totem
```

2. Copia y edita el archivo `.env` con las variables necesarias. Valores clave:

- `N8N_ENCRYPTION_KEY` — generar con `openssl rand -hex 32`
- `N8N_BASIC_AUTH_PASSWORD` — contraseña para acceder a n8n
- `POSTGRES_PASSWORD`, `REDIS_PASSWORD` — contraseñas de bases
- `EVOLUTION_API_KEY` — API key para Evolution API
- `CHATWOOT_FRONTEND_URL`, `N8N_WEBHOOK_URL` — URLs públicas si aplican
- `CHATWOOT_API_TOKEN` — token para llamadas a la API de Chatwoot (usar `api_access_token` header si tu instalación lo requiere)
- `CALIDDA_SESSION_TTL` — (opcional) tiempo en segundos que el wrapper mantiene la sesión con Calidda

3. Levantar los servicios (en background):

```bash
docker compose up -d
```

4. Verifica servicios y logs:

```bash
docker compose ps
docker compose logs -f calidda-api
docker compose logs -f chatwoot-web
docker compose logs -f n8n
```

5. Accede a las interfaces:

- Chatwoot: http://localhost:3000 — crear administrador la primera vez
- n8n: http://localhost:5678 — usuario `admin` (configurable)
- Evolution API: http://localhost:8080

---

## Uso del wrapper `calidda-api` (vcc-totem)

El objetivo es exponer la lógica del CLI (`src/main.py`) como un servicio HTTP para que n8n pueda consumirla.

- Endpoint principal: POST /query
  - Body: `{ "dni": "XXXXXXXX" }`
  - Respuesta (ejemplo):

```json
{
  "success": true,
  "dni": "08408122",
  "client_message": "...",
  "client_message_compact": "...",
  "client_message_html": "...",
  "tiene_oferta": true,
  "return_code": 0
}
```

- `/health` — endpoint de salud

Notas implementativas:
- El wrapper importa las funciones internas de `vcc-totem/src/` (evita ejecutar el CLI como subprocess). Esto permite respuestas JSON robustas y manejo de errores.
- Añadida caché de sesión (TTL configurable por `CALIDDA_SESSION_TTL`) para evitar logins por cada petición.

---

## Flujo n8n → Calidda → Chatwoot (resumen)

El flujo recomendado ya documentado en `docs/N8N_WORKFLOW_COMPLETE.md` es:

1. `Webhook` (n8n) recibe mensaje de Chatwoot
2. `Function` extrae o normaliza datos del mensaje
3. `Function - REGEX` extrae el DNI (8 dígitos)
4. `IF` — si hay DNI: POST a `http://calidda-api:5000/query`; si no hay DNI: enviar mensaje a Chatwoot pidiendo DNI
5. `HTTP Request` a Chatwoot usando header `api_access_token: <TOKEN>` y body `{ "content": "...", "message_type": 1 }`

Consejos:
- En el nodo HTTP a Chatwoot deja `Authentication` en `None` y envía manualmente el header `api_access_token` (tu instalación lo requiere).
- Usa `client_message_html` cuando el canal acepte HTML; si no, usa `client_message_compact`.

---

## Comandos útiles y ejemplos

- Levantar todo:

```bash
docker compose up -d
```

- Logs de un servicio:

```bash
docker compose logs -f calidda-api
```

- Test rápido del wrapper (desde host):

```bash
curl -s -X POST http://localhost:5000/query \
  -H 'Content-Type: application/json' \
  -d '{"dni":"08408122"}' | jq
```

- Probar token Chatwoot (GET accounts):

```bash
curl -s -X GET 'http://localhost:3000/api/v1/accounts' -H 'api_access_token: <TOKEN>' | jq
```

---

## Actualizar `vcc-totem`

El script `scripts/update-vcc-totem.sh` fue actualizado para:

- Hacer `git fetch --all` y preferir `upstream` si existe (trae cambios del repo original)
- Registrar actividad en `logs/vcc-totem-updates.log`

Ejecutar:

```bash
./scripts/update-vcc-totem.sh
tail -n 200 logs/vcc-totem-updates.log
```

---

## Troubleshooting / puntos críticos

- 401 en Chatwoot: verifica que uses el header `api_access_token` (en lugar de `Authorization: Bearer`) si tu instalación lo requiere.
- Respuestas 500 desde `calidda-api`: revisar logs del contenedor `calidda-api` y validar que las credenciales y `CALIDDA_SESSION_TTL` sean correctas.
- Si n8n no recibe webhooks: confirmar `N8N_WEBHOOK_URL` y que n8n esté accesible desde Chatwoot (o exponerlo con ngrok para pruebas locales).

---

## Buenas prácticas y recomendaciones

- No exponer tokens en git; usar variables de entorno o Docker secrets.
- Añadir reintentos en n8n para llamadas a `calidda-api` (3 intentos con backoff recomendado).
- Implementar un mensaje de fallback cuando `calidda-api` devuelve `success: false` o error.
- Para producción, agregar proxy reverso (HTTPS), políticas de rate-limiting y monitorización (logs/metrics).

---

Si quieres que actualice este README con capturas de pantalla del flujo n8n y la configuración de nodos, sube las imágenes a `docs/images/` o dime los nombres y las subo yo. También puedo generar un script de prueba end-to-end si me permites usar un `CHATWOOT_API_TOKEN` de prueba y `conversation_id`.

---

Changelog rápido de la última iteración:

- Se reemplazó el enfoque de ejecutar el CLI como subprocess por un wrapper FastAPI que importa y reutiliza funciones internas.
- Se añadió cache de sesión en `calidda-api` para reducir logins frecuentes.
- Se actualizó `scripts/update-vcc-totem.sh` para soportar `upstream` y mejores logs.
- Se creó `docs/N8N_WORKFLOW_COMPLETE.md` con el flujo detallado.

---

¿Quieres que actualice también el `vcc-totem/README.md` con ejemplos de variables de entorno exactas y un archivo `.env.example`? Puedo generarlo aquí mismo.
