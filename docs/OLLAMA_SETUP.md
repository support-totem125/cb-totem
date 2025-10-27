# 🤖 Configuración de Ollama con n8n

## 📋 ¿Qué es Ollama?

**Ollama** es un servidor local que ejecuta modelos de IA de código abierto sin necesidad de Internet ni credenciales. Perfecto para:
- ✅ Agentes de IA sin costos
- ✅ Procesamiento local y privado
- ✅ Integración con n8n
- ✅ Alternativa a OpenAI

## 🚀 Instalación y Configuración

### 1. Levantar Ollama

```bash
cd /home/admin/Documents/chat-bot-totem
docker compose up -d ollama
```

### 2. Esperar a que Ollama esté listo

```bash
sleep 10
docker logs ollama -f
```

Verás algo como:
```
time=2025-10-27T10:00:00.000Z level=info msg="Ollama is running"
```

### 3. Descargar un Modelo (La primera vez tarda)

Hay varias opciones según tu RAM disponible:

#### 🟢 **Ligero (4GB RAM)** - Recomendado
```bash
docker exec ollama ollama pull mistral
```

#### 🟡 **Medio (6GB RAM)**
```bash
docker exec ollama ollama pull neural-chat
```

#### 🔴 **Pesado (8GB+ RAM)**
```bash
docker exec ollama ollama pull dolphin-mixtral
```

#### 🔵 **Clásico (4GB RAM)**
```bash
docker exec ollama ollama pull llama2
```

### 4. Verificar que el modelo está descargado

```bash
docker exec ollama ollama list
```

Deberías ver algo como:
```
NAME           ID              SIZE   MODIFIED
mistral:latest xxxxxxxx...     4.1 GB 1 minute ago
```

### 5. Probar Ollama localmente

```bash
# Desde tu máquina
curl http://192.168.1.74:11434/api/generate -d '{
  "model": "mistral",
  "prompt": "Hola, ¿cómo estás?",
  "stream": false
}'
```

Deberías recibir una respuesta JSON con la IA respondiendo.

---

## 🔗 Integración con n8n

### Opción A: Usar HTTP Request Node (Más control)

1. En n8n, crea un nodo **"HTTP Request"**
2. Configura:
   - **Method**: POST
   - **URL**: `http://ollama:11434/api/generate`
   - **Body** (JSON):
     ```json
     {
       "model": "mistral",
       "prompt": "Tu prompt aquí",
       "stream": false
     }
     ```

3. Procesa la respuesta con un nodo **"Function"** para extraer el texto

### Opción B: Usar OpenAI-Compatible API (Mejor)

Ollama tiene un endpoint compatible con OpenAI. En n8n:

1. Crea un nodo **"AI Agent"** o **"OpenAI"**
2. Configura como URL: `http://ollama:11434/v1`
3. Modelo: `mistral` (o el que descargaste)
4. API Key: `dummy` (Ollama no requiere clave)

---

## 📊 Modelos Disponibles

| Modelo          | Tamaño | Velocidad | Memoria | Mejor para                     |
| --------------- | ------ | --------- | ------- | ------------------------------ |
| mistral         | 4.1 GB | Rápido    | 4GB     | Propósito general, recomendado |
| neural-chat     | 4.1 GB | Rápido    | 4GB     | Conversación natural           |
| llama2          | 3.8 GB | Medio     | 4GB     | Textos extensos                |
| dolphin-mixtral | 26 GB  | Lento     | 8GB+    | Tarea complejas                |
| openchat        | 3.9 GB | Rápido    | 4GB     | Chat rápido                    |

**Recomendación**: Comienza con `mistral` - es rápido y de buena calidad.

---

## 🔧 Configuración en n8n

### Crear un Workflow con Ollama

1. **Nodo 1: Webhook** (entrada de datos)
2. **Nodo 2: HTTP Request** a Ollama
   ```
   POST http://ollama:11434/api/generate
   Body: {
     "model": "mistral",
     "prompt": "{{ $json.message }}",
     "stream": false
   }
   ```
3. **Nodo 3: Function** (procesar respuesta)
   ```javascript
   return {
     json: {
       response: JSON.parse(item.json.response).response
     }
   };
   ```

### Variables Útiles
```
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=mistral
```

---

## 🐛 Troubleshooting

### ❌ "Connection refused"
```bash
# Verificar que Ollama está corriendo
docker ps | grep ollama

# Ver logs
docker logs ollama
```

### ❌ "Model not found"
```bash
# Ver modelos disponibles
docker exec ollama ollama list

# Descargar modelo faltante
docker exec ollama ollama pull mistral
```

### ❌ "Out of memory"
```bash
# Reducir recursos o usar modelo más ligero
docker exec ollama ollama pull neural-chat
```

---

## 📈 Performance Tips

1. **En docker-compose.yaml** ya está limitado a 6GB, aumentar si es necesario
2. **Usar GPU** (si disponible, agregar `--gpus all` en docker-compose)
3. **Modelos pequeños** para menor latencia
4. **Caché de respuestas** en n8n para reducir llamadas

---

## 🔌 URLs Útiles

| Servicio   | URL                         |
| ---------- | --------------------------- |
| Ollama API | `http://192.168.1.74:11434` |
| n8n        | `http://192.168.1.74:5678`  |
| Chatwoot   | `http://192.168.1.74:3000`  |

---

## 📝 Ejemplo Completo: Chatbot en Chatwoot con Ollama

1. Mensaje llega a Chatwoot
2. Webhook dispara n8n
3. n8n envía mensaje a Ollama
4. Ollama genera respuesta
5. n8n envía respuesta a Chatwoot
6. Usuario ve respuesta automática

**¡Con esto tienes un chatbot de IA sin costos!** 🚀

