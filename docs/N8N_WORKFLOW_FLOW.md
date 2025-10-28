# 🎯 FLUJO SIMPLIFICADO: REGEX → main.py → Chatwoot

## 📊 Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│ CLIENTE EN CHATWOOT                                             │
│ Mensaje: "Hola, mi DNI es 45678901"                            │
└────────────────┬────────────────────────────────────────────────┘
                 │ (webhook POST)
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ n8n WEBHOOK                                                     │
│ Recibe: {"text": "...", "conversation_id": "..."}             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ ✅ NODO 1: REGEX (JavaScript Function)                         │
│ Extrae: /\b(\d{8})\b/                                          │
│ Resultado: "45678901"                                          │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ ✅ NODO 2: IF (Validar DNI)                                    │
│ Condición: dni !== null                                        │
│ TRUE → NODO 3                                                  │
│ FALSE → Error a Chatwoot                                       │
└────────────────┬────────────────────────────────────────────────┘
                 │ (TRUE)
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ ✅ NODO 3: COMMAND (Execute main.py)                           │
│                                                                 │
│ Acciones:                                                       │
│ 1. Escribe DNI en lista_dnis.txt                               │
│ 2. Ejecuta: python3 main.py                                    │
│                                                                 │
│    └─ main.py:                                                 │
│       ├─ Lee lista_dnis.txt (DNI: 45678901)                   │
│       ├─ Consulta Calidda API (con credenciales .env)          │
│       ├─ Obtiene: nombre, monto, vigencia, etc.               │
│       ├─ Valida datos                                          │
│       ├─ Genera archivo: consultas_credito/45678901_*.txt      │
│       └─ Archivo contiene respuesta formateada                │
│                                                                 │
│ 3. Lee archivo generado (tail -1)                              │
│ Output: "LÍNEA DE CRÉDITO DISPONIBLE: ..."                    │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ ✅ NODO 4: FUNCTION (Parsear archivo)                          │
│ Entrada: Contenido del archivo                                 │
│ Acciones:                                                       │
│ 1. Parsea líneas del archivo                                   │
│ 2. Extrae: nombre, monto, vigencia                             │
│ 3. Formatea respuesta amigable                                 │
│ Salida: "🎉 ¡Hola Juan! Tienes S/.1,000.00..."                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ ✅ NODO 5: HTTP REQUEST (Enviar a Chatwoot)                    │
│ POST /conversations/{id}/messages                              │
│ Body: {"content": "🎉 ¡Hola Juan! ...", "private": false}      │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│ BOT EN CHATWOOT                                                 │
│ Mensaje: "🎉 ¡Hola Juan! Tienes S/.1,000.00..."              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔑 Puntos Clave

### **¿Por qué REGEX?**
- ✅ 100% confiable para extraer 8 dígitos
- ✅ Valida formato (números consecutivos)
- ✅ Evita falsos positivos

### **¿Por qué main.py?**
- ✅ Consulta Calidda directamente
- ✅ Valida datos en API (no en n8n)
- ✅ Genera respuesta formateada
- ✅ Seguro (credenciales en .env)

### **¿Qué hace n8n?**
- ✅ Orquesta el flujo
- ✅ Lee REGEX output (DNI)
- ✅ Ejecuta comando
- ✅ Lee archivo output
- ✅ Formatea para Chatwoot
- ✅ Envía respuesta

---

## 📝 Configuración de main.py

**Ubicación:** `/home/node/vcc-totem/main.py`

**Requiere `.env` con:**
```bash
CALIDDA_USUARIO=tu_usuario
CALIDDA_PASSWORD=tu_password
BASE_URL=https://appweb.calidda.com.pe
LOGIN_API=/FNB_Services/api/Seguridad/autenticar
CONSULTA_API=/FNB_Services/api/financiamiento/lineaCredito
DELAY_MIN=10
DELAY_MAX=30
TIMEOUT=300
MAX_CONSULTAS_POR_SESION=80
```

**Input:** `lista_dnis.txt` con DNI (una línea)

**Output:** `consultas_credito/{DNI}_{timestamp}.txt` con respuesta formateada

---

## 🧪 Test Local (Antes de n8n)

```bash
# 1. Ir al directorio
cd /home/admin/Documents/chat-bot-totem/vcc-totem

# 2. Crear .env
cp .env.example .env
# Editar .env con credenciales reales

# 3. Crear lista de prueba
echo "12345678" > lista_dnis.txt

# 4. Ejecutar script
python3 main.py

# 5. Ver resultado
cat consultas_credito/12345678_*.txt

# Salida esperada:
# LÍNEA DE CRÉDITO DISPONIBLE:
# - Nombre: Juan Pérez
# - DNI: 12345678
# - Monto: S/.1,000.00
# - Vigencia: 31/12/2025
```

---

## 🚀 Implementación en n8n

1. **Webhook:** Crear y anotar URL
2. **Function (REGEX):** Copiar código de extracción
3. **IF:** Validar `dni !== null`
4. **Command:** Ejecutar `main.py` con DNI del REGEX
5. **Function (Parsear):** Leer y formatear archivo
6. **HTTP:** Enviar a Chatwoot
7. **Activar:** Toggle workflow a ON
8. **Integrar:** URL webhook en Chatwoot Settings

---

## ✅ Checklist

- [ ] .env configurado en vcc-totem (credenciales Calidda)
- [ ] main.py probado localmente con DNI de prueba
- [ ] REGEX funciona (extrae DNI correctamente)
- [ ] Webhook creado en n8n
- [ ] 5 nodos creados y conectados
- [ ] main.py ejecutable desde n8n
- [ ] Archivo de respuesta se genera correctamente
- [ ] Función parsea correctamente
- [ ] HTTP envía a Chatwoot sin errores
- [ ] Workflow activado
- [ ] Webhook integrado en Chatwoot
- [ ] Prueba end-to-end exitosa
