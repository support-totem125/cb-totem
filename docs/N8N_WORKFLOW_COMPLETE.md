# Flujo n8n → Calidda (vcc-totem) → Chatwoot

Este documento unifica el flujo y los fragmentos de código para n8n. He listado aquí cada nodo que aparece en el workflow (según el diagrama), su propósito y la configuración lista para copiar/pegar.

IMPORTANTE: guarda las capturas en `docs/images/` si quieres que se muestren inline (sugiero los nombres indicados más abajo).

---

## Panorama general (nodos en orden)

El flujo que aparece en la imagen contiene estos nodos (orden lógico y nombres que aparecen en tu diagrama):

- `Recibir Mensaje` (Webhook)
- `Validar si es mensaje entrante` (Function / Condition)
- `Obtener datos del mensaje` (Set o Function — opcional, normaliza campos)
- `Verificar mensaje y extraer DNI` (Function - REGEX DNI)
- `¿Se encontró DNI?` (IF)
  - Rama TRUE:
    - `Búsqueda en FNB por DNI` (HTTP Request → calidda-api /query)
    - `Respuesta al Cliente (Chatwoot)` (HTTP Request → Chatwoot)
  - Rama FALSE:
    - `Pedir DNI al cliente (Chatwoot)` (HTTP Request → Chatwoot)

En el editor de n8n los nodos suelen llamarse como en tu imagen; abajo indico configuración y código para cada uno.

---

## Nodo por nodo — configuración y snippets

### 1) `Recibir Mensaje` (Webhook)
- Tipo: Webhook (Trigger)
- Método: POST
- Path: por ejemplo `/chatwoot-webhook`
- Nota: Este nodo recibe el payload que Chatwoot envía. En la mayoría de los webhooks el body tiene los campos `conversation.id`, `account.id` y `content`/`message`.

Output esperado (ejemplo):
```json
{
  "body": {
    "conversation": {"id": 123},
    "account": {"id": 2},
    "content": "Hola, mi dni es 08408122"
  }
}
```

### 2) `Validar si es mensaje entrante` (Function / Condition)
- Propósito: filtrar mensajes entrantes relevantes (por ejemplo, ignorar notificaciones del sistema o mensajes salientes).
- Si quieres hacerlo en un nodo Function, ejemplo mínimo:

```javascript
const body = $input.first().json.body || {};
// Puedes validar que exista conversation y que el mensaje no sea de tipo bot
if (!body.conversation || !body.content) {
  return [{ valid: false }];
}
return [{ valid: true, body }];
```

En n8n puedes seguir con un nodo IF que compruebe `{{$json.valid}} === true`.

### 3) `Obtener datos del mensaje` (Set / Function — normalización)
- Propósito: extraer y normalizar campos que luego usarán otros nodos: `dni`, `conversation_id`, `account_id`, `content`.
- Si el payload de Chatwoot usa otro path, aquí lo normalizas.

Ejemplo usando un nodo Set (campos que debes crear):
- `conversation_id` → `{{$json.body.conversation.id}}`
- `account_id` → `{{$json.body.account.id}}`
- `content` → `{{$json.body.content || $json.body.message || ''}}`

### 4) `Verificar mensaje y extraer DNI` (Function - REGEX DNI)
- Propósito: buscar un patrón de DNI (8 dígitos) en `content` y retornar datos útiles para la siguiente lógica.
- Código a pegar en un nodo Function:

```javascript
const content = $json.content || ' ';
const dniMatch = content.match(/\b(\d{8})\b/);
if (!dniMatch) {
  return [{ status: 'no_dni', dni: null, conversation_id: $json.conversation_id, account_id: $json.account_id, content }];
}
return [{ status: 'found', dni: dniMatch[1], conversation_id: $json.conversation_id, account_id: $json.account_id, content }];
```

### 5) `¿Se encontró DNI?` (IF)
- Condición (expresión):

```
$node["Verificar mensaje y extraer DNI"].json[0].dni !== null
```

- Rama TRUE: continuar con la búsqueda en Calidda
- Rama FALSE: enviar mensaje pidiendo DNI

---

Rama TRUE (detalle):

### 6) `Búsqueda en FNB por DNI` (HTTP Request — calidda-api)
- Method: POST
- URL: `http://calidda-api:5000/query` (si n8n corre en mismo Docker network) o `http://localhost:5000/query` si llamas desde host
- Authentication: None
- Send Body: ON
- Body Content Type: JSON
- Body (JSON):

```json
{
  "dni": "{{$node['Verificar mensaje y extraer DNI'].json[0].dni}}"
}
```

- Timeout recomendado: 30s (configurable)
- Resultado esperado (fragmento): `success`, `client_message`, `client_message_compact`, `client_message_html`, `tiene_oferta`, `return_code`.

Nota: sustituye el nombre del nodo si lo llamaste distinto (por ejemplo `HTTP - Calidda API`).

### 7) (Opcional) `Formatear respuesta` (Function/Set)
- Propósito: elegir qué campo usar para enviar al cliente (HTML o compact). También preparar el body final para Chatwoot.
- Por ejemplo, un nodo Function que devuelva el body JSON a enviar:

```javascript
const resp = $node['Búsqueda en FNB por DNI'].json;
const contentHtml = resp.client_message_html || resp.client_message;
const contentPlain = resp.client_message_compact || resp.client_message;
return [{
  chatwoot_body_html: { content: contentHtml, message_type: 1 },
  chatwoot_body_plain: { content: contentPlain, message_type: 1 },
  account_id: $node['Verificar mensaje y extraer DNI'].json[0].account_id,
  conversation_id: $node['Verificar mensaje y extraer DNI'].json[0].conversation_id
}];
```

### 8) `Respuesta al Cliente (Chatwoot)` (HTTP Request)
- Method: POST
- URL:
```
http://chatwoot-web:3000/api/v1/accounts/{{ $json.account_id }}/conversations/{{ $json.conversation_id }}/messages
```
- Headers (env vars recomendadas):

```json
{
  "api_access_token": "{{$env.CHATWOOT_API_TOKEN}}",
  "Content-Type": "application/json"
}
```

- Body (usar HTML o texto según canal):

```json
{{$node['Formatear respuesta'].json[0].chatwoot_body_html}}
```

Notas importantes:
- En tu instalación hemos verificado que Chatwoot acepta el header `api_access_token` en lugar de `Authorization: Bearer`.
- Si el canal no admite HTML, usa `chatwoot_body_plain`.

Rama FALSE (detalle):

### 9) `Pedir DNI al cliente (Chatwoot)` (HTTP Request)
- Si no se encontró DNI, envía un mensaje amable pidiendo que el cliente reenvíe su DNI.
- Configuración: igual que `Respuesta al Cliente` pero con body simple:

```json
{
  "content": "Hola 👋, por favor envía tu DNI (8 dígitos) para que podamos verificar tu estado.",
  "message_type": 1
}
```

---

## Diagramas y capturas (nombres sugeridos)

Coloca las imágenes en `docs/images/` con estos nombres para que se muestren correctamente:

- `docs/images/n8n_webhook.png` — captura del nodo `Recibir Mensaje` (Webhook)
- `docs/images/validate_incoming.png` — `Validar si es mensaje entrante`
- `docs/images/get_message_data.png` — `Obtener datos del mensaje` (Set)
- `docs/images/regex_extract_dni.png` — `Verificar mensaje y extraer DNI` (Function)
- `docs/images/if_found_dni.png` — vista del nodo IF (`¿Se encontró DNI?`)
- `docs/images/http_calidda_query.png` — configuración del nodo HTTP `Búsqueda en FNB por DNI`
- `docs/images/chatwoot_request.png` — configuración del nodo HTTP `Respuesta al Cliente (Chatwoot)`

Si me confirmas que subo la imagen desde aquí, la guardo en `docs/images/` y la inserto inline en este documento.

---

## Tips y recomendaciones finales

- Evita ejecutar scripts locales desde n8n: usa el wrapper HTTP (`vcc-totem/api_wrapper.py`).
- Añade reintentos en el nodo HTTP a Calidda (3 reintentos con backoff) si tu n8n lo permite.
- Maneja errores: cuando `calidda-api` devuelve `success: false` o `return_code != 0`, envía un mensaje de fallback al cliente indicando que ocurrió un error técnico y que se intentará nuevamente.
- Revisa los logs de `calidda-api` y n8n para diagnosticar fallos; usa variables de entorno para tokens (`CHATWOOT_API_TOKEN`) y TTL (`CALIDDA_SESSION_TTL`).

---

Si quieres que yo suba las imágenes y haga el insert automático en el markdown, dime los archivos o autoriza subirlas y las inserto en la sección de capturas.
