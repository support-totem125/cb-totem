# 📋 CÓDIGOS PARA COPIAR-PEGAR EN n8n

## 1️⃣ NODO: Function - REGEX DNI

**Copiar TODO el código abajo y pegarlo en n8n:**

```javascript
// ============ EXTRACIÓN DE DNI CON REGEX ============

// Obtener mensaje del webhook
const message = $input.all()[0].json.text || '';

// REGEX: Busca exactamente 8 dígitos consecutivos
const dniMatch = message.match(/\b(\d{8})\b/);

// Si NO encontró DNI
if (!dniMatch) {
  return [{
    status: "no_dni",
    dni: null,
    message: message,
    error: "No se encontró DNI",
    conversation_id: $input.all()[0].json.conversation_id || null,
    contact_id: $input.all()[0].json.contact_id || null
  }];
}

// Si SÍ encontró DNI
const dni = dniMatch[1];
return [{
  status: "success",
  dni: dni,
  message: message,
  conversation_id: $input.all()[0].json.conversation_id || null,
  contact_id: $input.all()[0].json.contact_id || null
}];
```

**Pasos en n8n:**
1. Click en `+` → busca **Function**
2. Nombre: `Function - REGEX DNI`
3. Conecta: Webhook → Function
4. Pega el código arriba
5. Click Ejecutar (prueba)

**Output esperado:**
```json
{
  "status": "success",
  "dni": "45678901",
  "message": "Hola, mi DNI es 45678901",
  "conversation_id": "12345"
}
```

---

## 2️⃣ NODO: IF - Validar DNI

**Pasos en n8n:**
1. Click en `+` → busca **IF**
2. Nombre: `IF - Validar DNI`
3. Conecta: Function → IF
4. En **Condition**, copia esto:

```
$node["Function - REGEX DNI"].data[0].dni !== null
```

5. **TRUE branch** (derecha) → Command (Paso 3)
6. **FALSE branch** (abajo) → HTTP (error a Chatwoot)

---

## 3️⃣ NODO: Execute Command - main.py

**Pasos en n8n:**
1. Click en `+` → busca **Execute Command**
2. Nombre: `Command - Execute main.py`
3. Conecta: IF → Command
4. **Working Directory:** `/home/node/vcc-totem`
5. **Command:** `bash`
6. **Arguments (en orden):**

```
-c
```

```
echo {{$node['Function - REGEX DNI'].data[0].dni}} > lista_dnis.txt && python3 main.py && tail -1 consultas_credito/*.txt
```

7. Click Ejecutar (prueba)

---

## 4️⃣ NODO: Function - Parsear Resultado

**Copiar TODO el código abajo:**

```javascript
// ============ PARSEAR RESPUESTA DE main.py ============

// Obtener salida del comando
const cmdOutput = $input.all()[0].data?.stdout || $input.all()[0].data || '';

// Debug: ver qué recibimos
console.log('CMD Output:', cmdOutput);

// Si no hay salida, error
if (!cmdOutput || cmdOutput.trim().length === 0) {
  return [{
    response: "❌ Error: No se pudo consultar Calidda. Contacta a soporte. 📞",
    status: "error",
    tipo: "error",
    html_safe: true
  }];
}

// Separar por líneas
const lines = cmdOutput.trim().split('\n');

// ============ DETECTAR TIPO DE RESPUESTA ============

// ¿Tiene línea de crédito disponible?
const hasCredit = lines.some(line => 
  line.includes('LÍNEA DE CRÉDITO') || 
  line.includes('Monto:') ||
  line.includes('disponible')
);

// ¿Hay error o no disponible?
const hasError = lines.some(line => 
  line.includes('Error') || 
  line.includes('No encontrado') || 
  line.includes('no tiene') ||
  line.includes('sin línea') ||
  line.includes('No disponible')
);

// ============ EXTRAER DATOS ============

let nombre = "Cliente";
let monto = "No disponible";
let vigencia = "Consultar";
let estado = "No disponible";

for (const line of lines) {
  // Nombre
  if (line.includes('Nombre:') || line.includes('nombre:')) {
    const parts = line.split(':');
    if (parts.length > 1) {
      nombre = parts[1].trim();
    }
  }
  
  // Monto
  if (line.includes('Monto:') || line.includes('monto:')) {
    const parts = line.split(':');
    if (parts.length > 1) {
      monto = parts[1].trim();
    }
  }
  
  // Vigencia/Vencimiento
  if (line.includes('Vigencia:') || line.includes('vigencia:') || 
      line.includes('Vencimiento:') || line.includes('vencimiento:')) {
    const parts = line.split(':');
    if (parts.length > 1) {
      vigencia = parts[1].trim();
    }
  }
  
  // Estado
  if (line.includes('Estado:') || line.includes('estado:')) {
    const parts = line.split(':');
    if (parts.length > 1) {
      estado = parts[1].trim();
    }
  }
}

// ============ FORMATEAR RESPUESTA ============

let responseText = "";
let tipoMensaje = "info";

if (hasCredit && !hasError && monto !== "No disponible") {
  // ✅ CON LÍNEA DE CRÉDITO
  responseText = `🎉 ¡Hola ${nombre}! Buenas noticias.\n\nTienes una línea de crédito de ${monto} disponible.\n\nVigencia: ${vigencia}\n\n¿Te interesa conocer más detalles?`;
  tipoMensaje = "oferta";
} else if (hasError) {
  // ❌ SIN LÍNEA DE CRÉDITO
  responseText = `Hola ${nombre}, por el momento no tienes una línea de crédito activa. Te contactaremos pronto con nuevas oportunidades. 📞`;
  tipoMensaje = "sin_oferta";
} else {
  // ⚠️ ERROR O SIN DATOS
  responseText = `Lo sentimos ${nombre}, no pudimos procesar tu solicitud. Por favor contacta a soporte. 📞`;
  tipoMensaje = "error";
}

// ============ RETORNAR DATOS ============

return [{
  response: responseText,
  status: "success",
  tipo: tipoMensaje,
  nombre: nombre,
  monto: monto,
  vigencia: vigencia,
  estado: estado,
  html_safe: true
}];
```

**Pasos en n8n:**
1. Click en `+` → busca **Function**
2. Nombre: `Function - Parsear Resultado`
3. Conecta: Command → Function
4. Pega el código arriba
5. Click Ejecutar (prueba)

---

## 5️⃣ NODO: HTTP Request - Chatwoot

**Pasos en n8n:**
1. Click en `+` → busca **HTTP Request**
2. Nombre: `HTTP - Enviar a Chatwoot`
3. Conecta: Function → HTTP
4. **Method:** `POST`
5. **URL:**
```
http://chatwoot:3000/api/v1/conversations/{{$node['Function - REGEX DNI'].data[0].conversation_id}}/messages
```

6. **Headers** (agrega los dos)
   - Key: `api_access_token` | Value: `{{$env.CHATWOOT_API_TOKEN}}`
   - Key: `Content-Type` | Value: `application/json`

7. **Body** (JSON):
```json
{
  "content": "{{$node['Function - Parsear Resultado'].data[0].response}}",
  "private": false
}
```

8. **Response Handling:** Marca `Success Codes: 200, 201, 204`

---

## 🧪 TEST RÁPIDO CON CURL

```bash
# Probar webhook directamente
curl -X POST http://192.168.1.74:5678/webhook/credito-dni \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hola soy Juan, mi DNI es 45678901",
    "conversation_id": "test_conv_123",
    "contact_id": "test_contact_456"
  }'
```

---

## 📊 Variable Importante

**Antes de activar el workflow, asegúrate de setear:**

En n8n → Settings → Variables
- **Key:** `CHATWOOT_API_TOKEN`
- **Value:** `(tu token de Chatwoot)`

Para obtener el token:
1. Ve a Chatwoot → Account Settings → Access Tokens
2. Copia el token
3. Pégalo en n8n Variables

---

## ✅ Orden de Creación

1. ✅ Webhook (ya existe)
2. ✅ Function - REGEX DNI
3. ✅ IF - Validar DNI
4. ✅ Command - Execute main.py
5. ✅ Function - Parsear Resultado
6. ✅ HTTP - Enviar a Chatwoot

**Conexiones:**
```
Webhook → Function-REGEX → IF → Command → Function-Parsear → HTTP-Chatwoot
```

---

## 🚀 PRÓXIMO PASO

1. Copia código REGEX (sección 1️⃣)
2. Crea nodo Function en n8n
3. Pega código
4. Prueba con webhook test
5. Si funciona, continúa con IF
6. Repite con Command, etc.

¿Necesitas ayuda con algún nodo específico?
