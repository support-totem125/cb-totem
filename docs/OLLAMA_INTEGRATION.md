# Integración de Ollama + n8n

## Cambios Realizados

### 1. Reducción de Recursos en `docker-compose.yaml`

Se redujeron los límites de memoria y CPUs en todos los servicios para liberar espacio para Ollama:

| Servicio | Antes | Después | Liberado |
|----------|-------|---------|----------|
| PostgreSQL | 256m → 192m | 96m → 96m | 64m |
| Redis | 128m → 96m | 64m → 48m | 32m |
| Evolution API | 256m → 192m | 128m → 96m | 64m |
| Chatwoot Web | 400m → 256m | 256m → 128m | 144m |
| Chatwoot Sidekiq | 512m → 256m | 385m → 192m | 256m |
| n8n | 385m → 256m | 256m → 192m | 129m |
| Calidda API | 96m → 80m | 48m → 32m | 16m |
| srv-img | 96m → 80m | 48m → 32m | 16m |
| **TOTAL LIBERADO** | - | - | **~721 MB** |

### 2. Nuevo Servicio: Ollama

Se agregó el servicio `ollama` con configuración optimizada:

```yaml
ollama:
  image: ollama/ollama:latest
  container_name: ollama_ai
  restart: unless-stopped
  mem_limit: 2560m          # 2.5 GB máximo
  mem_reservation: 2048m    # 2 GB garantizado
  cpus: 1.0                 # 1 core
  ports:
    - "11434:11434"
  volumes:
    - ollama_data:/root/.ollama
  networks:
    - app_network
```

---

## Distribución de Recursos (TOTAL: 4 GB RAM)

```
PostgreSQL:       96m
Redis:            48m
Evolution API:    96m
Chatwoot Web:     128m
Chatwoot Sidekiq: 192m
n8n:              192m
Calidda API:      32m
srv-img:          32m
Ollama:           2048m (reservado)
─────────────────────────
TOTAL:            2864m ≈ 2.8 GB (dentro del límite de 4 GB)
```

---

## Cómo Usar Ollama

### 1. Levantar los Contenedores

```bash
cd /home/diego/Documentos/cb-totem
docker compose up -d
```

### 2. Descargar un Modelo (después de que Ollama esté corriendo)

Espera a que Ollama inicie (~30 segundos) y luego descarga un modelo:

```bash
# Opción 1: Mistral 7B (MÁS RECOMENDADO - 4.1 GB)
docker exec ollama_ai ollama pull mistral

# Opción 2: Neural Chat (3.9 GB)
docker exec ollama_ai ollama pull neural-chat

# Opción 3: Phi-2 (1.4 GB - MÁS LIGERO)
docker exec ollama_ai ollama pull phi
```

**Recomendación**: Usa `mistral` o `phi` según tu velocidad de internet.

### 3. Verificar que el Modelo está Descargado

```bash
curl http://localhost:11434/api/tags
```

Deberías ver algo como:
```json
{
  "models": [
    {
      "name": "mistral:latest",
      "modified_at": "2024-11-21T..."
    }
  ]
}
```

---

## Integración con n8n

### Opción 1: Usando HTTP Request Node (Recomendado)

1. En n8n, crea un nuevo workflow
2. Agrega un nodo **HTTP Request**
3. Configura de la siguiente manera:

**URL**: `http://ollama:11434/api/generate`
**Method**: `POST`
**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
  "model": "mistral",
  "prompt": "¿Cuál es la capital de Perú?",
  "stream": false
}
```

**Respuesta esperada**:
```json
{
  "model": "mistral",
  "created_at": "2024-11-21T...",
  "response": "La capital de Perú es Lima.",
  "done": true,
  "done_reason": "stop",
  "context": [...]
}
```

### Opción 2: Con Expresiones n8n

Para hacer dinámico el prompt desde un nodo anterior:

**Body**:
```json
{
  "model": "mistral",
  "prompt": "{{ $node[\"Nodo Anterior\"].json.pregunta }}",
  "stream": false,
  "temperature": 0.7
}
```

### Opción 3: Streaming (para respuestas largas)

Si necesitas streaming de la respuesta:

**Body**:
```json
{
  "model": "mistral",
  "prompt": "Escribe un poema sobre la naturaleza",
  "stream": true
}
```

En este caso, recibirás la respuesta en chunks (línea por línea).

---

## Parámetros Disponibles en Ollama

| Parámetro | Tipo | Rango | Descripción |
|-----------|------|-------|-------------|
| `model` | string | - | Nombre del modelo (ej: mistral, phi) |
| `prompt` | string | - | Texto a procesar |
| `stream` | boolean | true/false | Respuesta en tiempo real o completa |
| `temperature` | float | 0.0-1.0 | Creatividad (0=determinista, 1=aleatorio) |
| `top_p` | float | 0.0-1.0 | Variabilidad de tokens |
| `top_k` | integer | 1+ | Top K tokens a considerar |
| `num_predict` | integer | 1+ | Máximo de tokens en respuesta |

---

## Ejemplos de Flujos en n8n

### Ejemplo 1: Chat Simple

```
[Trigger HTTP] → [HTTP Request a Ollama] → [Responder al usuario]
```

### Ejemplo 2: Procesamiento de Mensajes WhatsApp

```
[Evolution API - Mensaje WhatsApp] 
  → [Pasar a Ollama para análisis]
  → [Guardar respuesta en PostgreSQL]
  → [Enviar respuesta por WhatsApp]
```

### Ejemplo 3: Resumen Automático

```
[Obtener documento]
  → [HTTP Request a Ollama]
  → [Prompt: "Resume esto en 3 puntos"]
  → [Guardar resumen]
```

---

## Troubleshooting

### ❌ "Connection refused" en n8n

**Causa**: Ollama no está corriendo
**Solución**: 
```bash
docker compose ps | grep ollama
docker compose logs ollama
```

### ❌ "Model not found"

**Causa**: El modelo no fue descargado
**Solución**:
```bash
docker exec ollama_ai ollama pull mistral
```

### ❌ Respuestas lentas

**Causa**: Recursos insuficientes o modelo muy grande
**Soluciones**:
- Usa `phi` en lugar de `mistral`
- Aumenta temperatura para respuestas más rápidas
- Reduce `num_predict` (máximo de tokens)

### ❌ "Out of memory"

**Causa**: No hay RAM suficiente
**Solución**: 
- Detén otros servicios
- Usa modelo más pequeño (`phi`)

---

## Monitoreo de Recursos

Para ver el consumo real de Ollama:

```bash
docker stats ollama_ai

# Ejemplo de salida:
# CONTAINER   CPU%  MEM USAGE / LIMIT
# ollama_ai   15%   1.2GB / 2.5GB
```

---

## Notas Importantes

1. **Primera ejecución**: El primer request a Ollama puede tardar 5-10 segundos (carga del modelo)
2. **Velocidad**: Mistral genera ~10 tokens/segundo en 2 cores
3. **Privacidad**: Todos los datos se procesan localmente
4. **Costos**: $0 (solo consumo de electricidad)

---

## Próximos Pasos

1. Levanta los contenedores: `docker compose up -d`
2. Descarga un modelo: `docker exec ollama_ai ollama pull mistral`
3. Crea un workflow en n8n con HTTP Request
4. Prueba la integración
