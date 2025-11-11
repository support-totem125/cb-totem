# 🔧 Guía de Desarrollo Interno

> Estándares y procesos de desarrollo para el equipo Chat-Bot Totem

⚠️ **Este documento es para uso interno del equipo de desarrollo solamente**

---

## 📋 Tabla de Contenidos

1. [Principios del Equipo](#principios-del-equipo)
2. [Configuración del Ambiente](#configuración-del-ambiente)
3. [Reportar Bugs](#reportar-bugs)
4. [Requests de Features](#requests-de-features)
5. [Pull Requests Internos](#pull-requests-internos)
6. [Estándares de Código](#estándares-de-código)
7. [Proceso de Review](#proceso-de-review)

---

## 📜 Principios del Equipo

Estos son los principios que guían nuestro desarrollo:

- **Calidad primero** — El código debe ser mantenible y testeado
- **Documentación obligatoria** — Cada cambio requiere documentación
- **Code review transparente** — Todos aprendemos de los reviews
- **Comunicación clara** — Commits y PRs con mensajes descriptivos

---

## 🚀 Configuración del Ambiente

### 1. Clonar el repositorio (acceso interno)

```bash
# Clone from internal repo
git clone https://github.com/diego-moscaiza/chat-bot-totem.git
cd chat-bot-totem

# Switch to develop branch
git checkout develop

# If develop doesn't exist, create from main
git checkout -b develop main
```

### 2. Configurar entorno de desarrollo

```bash
# Copy environment file
cp .env.example .env

# Edit for development
nano .env

# Development values:
# DOMAIN_HOST=localhost
# LOG_LEVEL=debug
# DB_HOST=postgres
# REDIS_HOST=redis
# DEBUG=true
```

### 3. Iniciar servicios

```bash
# Pull latest images
docker-compose pull

# Start all services
docker-compose up -d

# Verify status
docker-compose ps

# Check logs
docker-compose logs -f

# To stop
docker-compose down
```

### 4. Familiarizarse con el código

```bash
# Project structure
tree -L 2 -I '__pycache__|node_modules|.pytest_cache'

# Read main documentation
cat README.md

# Understand architecture
cat docs/architecture/ARCHITECTURE.md

# Check existing issues/TODOs
grep -r "TODO\|FIXME" --include="*.py" --include="*.js"
```

---

## 🐛 Reportar Bugs

### En Jira o Sistema Interno

1. **Antes de reportar**
   - Verifica si ya existe en Issues/Jira
   - Revisa logs completos
   - Reproduce en ambiente limpio

2. **Reporta con contexto**
   - Ambiente donde ocurre (dev/staging/prod)
   - Pasos exactos para reproducir
   - Logs completos
   - Comportamiento esperado vs actual

### Checklist de Bug Report

```markdown
## Ambiente

- [x] Desarrollo
- [ ] Staging
- [ ] Producción
- Rama: main/develop/feature-xxx
- Commit: [hash]

## Descripción del Bug

[Descripción clara]

## Pasos para Reproducir

1. ...
2. ...
3. ...

## Comportamiento Esperado

[Qué debería suceder]

## Comportamiento Actual

[Qué sucede realmente]

## Logs Relevantes

[Output de docker-compose logs]

## Proposición de Solución

[Si tienes idea de cómo arreglarlo]
```

---

## 💡 Requests de Features

### Proponer Features

Comunica nuevas funcionalidades al equipo líder mediante:

- **Jira/Board interno** — Para planificación
- **Reuniones de sprint** — Para discusión
- **Email al equipo** — Para propuestas urgentes

### Template para Propuesta

```markdown
## Descripción

[Qué feature se necesita]

## Problema que Resuelve

[Por qué es necesario]

## Alcance

- [x] Componente afectado
- [x] Cambios en BD
- [x] Cambios en API
- [ ] Cambios en UI

## Estimación

- Complejidad: Baja/Media/Alta
- Tiempo estimado: X horas
- Dependencias: [Listar]

## Criterios de Aceptación

- [ ] Feature implementada
- [ ] Tests pasando
- [ ] Documentación actualizada
- [ ] Deployment sin errores

## Consideraciones

[Notas sobre seguridad, performance, etc]
```

---

## 🔄 Pull Requests Internos

### Flujo de Rama

```bash
# Actualiza develop
git checkout develop
git pull origin develop

# Crea rama para tu feature/fix
git checkout -b feature/nombre-descriptivo
# o
git checkout -b fix/nombre-del-bug

# Haz commits frecuentes
git add .
git commit -m "feat(scope): descripción clara"

# Cuando terminés, push a origin
git push origin feature/nombre-descriptivo
```

### Antes de Crear PR

```bash
# 1. Asegúrate de estar actualizado
git fetch origin
git rebase origin/develop

# 2. Prueba los cambios
docker-compose down
docker-compose up -d
docker-compose ps

# 3. Verifica logs sin errores
docker-compose logs --tail=50

# 4. Si hay tests, ejecutalos
docker-compose exec <service> pytest
# o
docker-compose exec <service> npm test

# 5. Revisa tu código
git diff develop
```

### Crear el PR

1. **Push a tu rama**
   ```bash
   git push origin feature/nombre
   ```

2. **Crear PR en GitHub** contra `develop` (no `main`)

3. **Template de PR**
   ```markdown
   ## Descripción
   
   [Qué cambios realizas]
   
   ## Tipo
   - [ ] Bug fix
   - [ ] Feature nueva
   - [ ] Breaking change
   - [ ] Documentación
   - [ ] Refactor
   
   ## Cambios Realizados
   
   - [x] Cambio 1
   - [x] Cambio 2
   
   ## Issues Relacionados
   
   Fixes #123
   Related to #456
   
   ## Checklist
   
   - [ ] Código testeado
   - [ ] Documentación actualizada
   - [ ] No hay warnings en logs
   - [ ] Commits limpios
   - [ ] Rebasado con develop
   ```

### Después del PR

- **Espera review** — Mínimo 1 dev must apruebe
- **Aplica cambios** — Si se solicitan ajustes
- **Merge cuando esté listo** — Alguien del equipo hace merge a develop

### No Mergear a Main Directamente

⚠️ **NUNCA hagas push a `main` directamente**

- `main` = producción
- Solo merge desde `develop` a `main`
- Solo Tech Lead puede mergear a main
- Requiere tags/release notes

---

## 🎨 Estándares de Código

### Python (vcc-totem, calidda-api, srv-img)

**Estilo**:
- PEP 8 compliant
- Line length: 100 caracteres
- Type hints cuando sea posible

**Herramientas**:
```bash
# Formatar
black .

# Linting
flake8 .

# Type checking
mypy .
```

**Ejemplo**:
```python
def query_client(dni: str) -> dict:
    """
    Consultar cliente por DNI.
    
    Args:
        dni: DNI del cliente (8 dígitos)
        
    Returns:
        dict con datos del cliente
        
    Raises:
        ValueError: Si DNI inválido
    """
    if not validate_dni(dni):
        raise ValueError("DNI inválido")
    
    # ... lógica
    return result
```

### JavaScript / TypeScript (n8n, Evolution)

**Estilo**:
- ESLint + Prettier
- Semicolons: sí
- Quotes: single

**Ejemplo**:
```javascript
async function processMessage(message: Message): Promise<Response> {
  try {
    const data = await validateInput(message);
    return await sendToDownstream(data);
  } catch (error) {
    logger.error('Error processing message', error);
    throw error;
  }
}
```

### SQL (Queries en BD)

**Estilo**:
- UPPER CASE para keywords
- snake_case para nombres
- Comentar lógica compleja

**Ejemplo**:
```sql
SELECT 
  u.id,
  u.email,
  COUNT(c.id) as conversation_count
FROM users u
LEFT JOIN conversations c ON u.id = c.user_id
WHERE u.created_at > NOW() - INTERVAL '30 days'
GROUP BY u.id
ORDER BY conversation_count DESC;
```

### Markdown (Documentación)

**Estilo**:
- Headers: h1-h6 máximo 6 niveles
- Code blocks con lenguaje especificado
- Enlaces descriptivos

---

## 📝 Commits

## 📝 Commits

### Formato de Mensaje (Conventional Commits)

```
<type>(<scope>): <subject>

<body (opcional)>

<footer (opcional)>
```

**Types válidos**:
- `feat` — Feature nueva
- `fix` — Bug fix
- `docs` — Documentación
- `style` — Cambios de formato/linting
- `refactor` — Refactoring
- `perf` — Mejoras de performance
- `test` — Tests
- `chore` — Build, deps, CI/CD

**Ejemplos**:
```bash
# Feature
git commit -m "feat(n8n): add retry logic to webhook handler"

# Bug fix  
git commit -m "fix(chatwoot): handle null user gracefully"

# Documentación
git commit -m "docs(guides): update installation steps"

# Refactor
git commit -m "refactor(api): simplify query validation"

# Con descripción más detallada
git commit -m "feat(auth): implement JWT refresh tokens

- Add refresh token generation
- Auto-refresh on expiry
- Clear tokens on logout

Closes #345"
```

### Reglas de Commits

✅ **Bueno**:
- Commits frecuentes (1-2 cambios lógicos por commit)
- Mensajes descriptivos
- Cada commit funciona independientemente
- Commits atómicos

❌ **Evitar**:
- Commits gigantes con 10+ archivos
- Mensajes genéricos ("Update", "Fix")
- Commits no funcionales
- Commits sin sentido lógico

---

## 🔍 Proceso de Review

### Como Reviewer

Cuando revises un PR, verifica:

**Calidad del Código**:
- [ ] Sigue estándares del proyecto
- [ ] Lógica clara y mantenible
- [ ] Sin dead code
- [ ] Sin console.log/print statements

**Testing**:
- [ ] Incluye tests
- [ ] Tests pasan localmente
- [ ] Cubre casos edge
- [ ] No regresiones esperadas

**Documentación**:
- [ ] READMEs actualizados
- [ ] Docstrings en funciones
- [ ] docs/ actualizado si necesario
- [ ] CHANGES.md si es feature importante

**Seguridad**:
- [ ] Sin secrets en código
- [ ] Sin vulnerabilidades obvias
- [ ] Validación de inputs
- [ ] Sin SQL injection

**Performance**:
- [ ] Sin N+1 queries
- [ ] Sin loops innecesarios
- [ ] Consideraciones de memoria
- [ ] Logs no excesivos

### Como Autor (Antes de Pedir Review)

```bash
# 1. Test localmente
docker-compose up -d
docker-compose exec <service> pytest

# 2. Revisa tu código
git diff develop
git log develop.. --oneline

# 3. Verifica no hay conflictos
git fetch origin develop
git rebase origin/develop

# 4. Si todo bien, push
git push origin feature/nombre

# 5. Crea PR en GitHub
```

### Tipos de Review

🟢 **LGTM** (Looks Good To Me)
- Aprueba y puede mergear
- O deja que otro haga merge

🟡 **Request Changes**
- Comenta específicamente qué cambiar
- El autor debe responder a comentarios
- Re-review después de cambios

🔴 **Reject**
- Si hay breaking changes no coordinados
- Si código está muy lejos de estándares
- Requiere discusión antes de continuar

### Etiquetas para PRs

- `ready` — Listo para merge
- `needs-work` — Requiere cambios
- `blocked` — Bloqueado por otro
- `documentation` — Incluye docs
- `bugfix` — Es un bug fix
- `breaking` — Breaking change

---

## 📚 Documentación

### Qué Documentar

Cuando hagas cambios importantes, documenta:

1. **Cambios arquitectura** → `docs/architecture/`
2. **Nuevas features** → `docs/guides/` o `docs/api/`
3. **Cambios config** → `docs/deployment/`
4. **Problemas resueltos** → `docs/troubleshooting/`
5. **Breaking changes** → `docs/CHANGES.md`

### Dónde Documentar

```
docs/
├── guides/              Guías de inicio
├── architecture/        Diseño del sistema
├── api/                APIs y webhooks
├── deployment/         Producción
└── troubleshooting/    Problemas y soluciones
```

### Template para Documentar

```markdown
# Título

> Resumen en una línea

**Última actualización**: Noviembre 2025

## 📋 Tabla de Contenidos

[Generar automáticamente]

## 🎯 Descripción

[Explicación clara]

## 📚 Conceptos

[Términos clave]

## 💻 Ejemplos

[Código funcional]

## 🔗 Referencias

[Links relacionados]
```

### Reglas de Documentación

✅ **Obligatorio**:
- Feature que cambia comportamiento usuario
- Cambios en API
- Nuevos comandos
- Cambios de variables de entorno

❌ **No necesario**:
- Refactors internos sin cambios de comportamiento
- Cambios pequeños en logs
- Actualizaciones de dependencias menores

---

## 🔀 Flujo de Trabajo Estándar

```
1. Obtén tarea del board
   ↓
2. Crea rama: feature/nombre o fix/nombre
   ↓
3. Haz commits frecuentes (código limpio)
   ↓
4. Prueba todo funciona (docker-compose)
   ↓
5. Actualiza documentación si necesario
   ↓
6. Push a origin
   ↓
7. Crea PR contra develop
   ↓
8. Request review (mínimo 1 dev)
   ↓
9. Responde comentarios de review
   ↓
10. Merge cuando esté aprobado
   ↓
11. Borra rama local: git branch -d feature/nombre
```

---

## ✅ Checklist Pre-PR

Antes de crear PR, verifica:

- [ ] Rama tiene nombre descriptivo (feature/x o fix/x)
- [ ] Commits tienen mensajes Conventional
- [ ] Código sigue estándares (PEP8, ESLint)
- [ ] Tests pasan localmente
- [ ] Documentación actualizada
- [ ] Sin secrets en commits
- [ ] Sin console.log/print statements
- [ ] Rebasado con develop
- [ ] Funcionalidad probada en Docker

---

## 🛠️ Troubleshooting de Desarrollo

### Tengo conflictos de merge

```bash
# Durante rebase
git rebase origin/develop
# Si hay conflictos, resolvelos, entonces:
git add .
git rebase --continue

# O cancelar y empezar otra vez
git rebase --abort
```

### Necesito sincronizar con develop

```bash
git fetch origin develop
git rebase origin/develop
git push origin feature/nombre -f  # Force push after rebase
```

### Necesito deshacer último commit

```bash
# Revert cambios a archivo específico
git checkout HEAD -- archivo.py

# Deshacer último commit (mantener cambios)
git reset --soft HEAD~1

# Deshacer últimos N commits
git reset --soft HEAD~N
```

### Accidentalmente commitié a main

```bash
# Ver commit en main que no debería estar
git log main --oneline | head

# Crear rama con esos cambios
git branch feature/nombre HEAD~1

# Resetear main a su estado anterior
git checkout main
git reset --hard HEAD~1

# Continuar en tu rama
git checkout feature/nombre
```

---

## � Contacto y Escalaciones

**Preguntas de desarrollo**: Pregunta en #dev channel  
**Bloqueado en tarea**: Avisa a Tech Lead  
**Conflicto con otro dev**: Comunica en standup  
**Urgencia**: Escala a Project Manager  

---

## 📋 Checklist Final

Antes de decir que terminaste:

- [ ] Feature completada y testeada
- [ ] Documentación actualizada
- [ ] PR creado y aprobado
- [ ] Mergeado a develop
- [ ] Rama local borrada
- [ ] Board actualizado (Tarea → Done)
- [ ] Rama remota borrada

---

**Versión**: 2.0 (Interno Only)  
**Última actualización**: Noviembre 2025  
**Acceso**: Solo equipo Chat-Bot Totem
