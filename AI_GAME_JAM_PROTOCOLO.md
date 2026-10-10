# AI GAME JAM

## Protocolo de integridad, trazabilidad y uso de IA

**Versión:** 1.0  
**Fecha:** 30 de septiembre de 2026  
**Uso:** Organización, jurados y participantes.

**Principio rector:** La inteligencia artificial está permitida; el proceso debe ser reconstruible.

Copia operativa del reglamento oficial, adaptada a este repositorio (`IAdashems` / Godot). Los prompts listos para pegar están en [docs/PROMPTS_OFICIALES.md](docs/PROMPTS_OFICIALES.md). Los agentes deben seguir [AGENTS.md](AGENTS.md).

---

# Resumen ejecutivo

Este protocolo establece un marco práctico para permitir el uso intensivo de IA durante una Game Jam sin perder la capacidad de verificar cómo evolucionó cada proyecto.

La regla central no es limitar el uso de la IA, sino exigir evidencia suficiente para reconstruir el proceso desde el repositorio inicial hasta el producto final.

Un prompt puede orientar al asistente, pero no constituye por sí solo un mecanismo de seguridad. La evidencia debe estar fuera del chat: repositorio remoto, checkpoints y registros de auditoría.

**Modelo recomendado:**

PROMPT / RESPUESTA IA + DIFF + COMMIT + CHECKPOINT + LOG EXTERNO = TRAZABILIDAD RECONSTRUIBLE

### En este equipo

- Repositorio oficial: `ai-dashems`
- `TEAM_ID`: IAdashems
- Bitácora **por integrante** en `logs/` (evita conflictos de fusión)
- Índice generado: `python tools/indice_logs.py` → `logs/INDICE_LOGS.md`
- `AI_TRACE.md` es el mapa, no el diario de entradas
- Agentes: `AGENTS.md` (Prompt 2 por defecto)

---

# 1. Objetivo y alcance

Mantener condiciones de competencia verificables. No se penaliza la velocidad de las herramientas generativas; se diferencia desarrollo asistido por IA de trabajo previo oculto, historial falsificado o evidencia manipulada.

### 1.1. Qué debe poder responder la auditoría

- ¿Con qué estado del repositorio inició el equipo?
- ¿Qué funcionalidades aparecieron y en qué orden?
- ¿Qué cambios vinieron de IA y cuáles ajustaron las personas?
- ¿Qué prompts o tareas explican los cambios grandes?
- ¿Qué commit corresponde a cada hito?
- ¿Hay saltos temporales o cambios masivos a revisar?
- ¿El repo final se relaciona con los checkpoints del evento?

**Criterio de justicia:** un cambio grande o muchas líneas en pocos minutos no es fraude automático. Con IA puede ser legítimo. La señal activa revisión de evidencia, no sanción automática.

# 2. Reglamento de participación y uso de IA

### 2.1. Uso permitido

- Generación, corrección, refactorización y explicación de código.
- Diseño de mecánicas, arquitectura, narrativa y documentación.
- Pruebas, depuración y apoyo en integración.
- Recursos gráficos o contenido si la convocatoria lo permite.
- Agentes con acceso al repositorio, con trazabilidad activa.

### 2.2. Conductas no permitidas

- Iniciar con un juego o base sustancial previa, salvo recursos declarados.
- Importar un proyecto externo como si fuera del evento.
- Copiar de otro equipo sin autorización.
- Reescribir, borrar o falsificar historial Git validado por un checkpoint.
- Modificar timestamps o commits para simular actividad.
- Eliminar o falsificar registros de trazabilidad.
- Desactivar controles de integridad.
- Presentar un registro fabricado a posteriori.

### 2.3. Recursos preexistentes

Declarar librerías, plantillas, addons (p. ej. Godot MCP), paquetes y boilerplate usados desde el inicio.

# 3. Repositorio y Git

| Control | Regla | Motivo |
| --- | --- | --- |
| Commit inicial | Registrar hash de partida | Punto de inicio |
| Rama principal | Protegida | Menos reescritura |
| Force push | Prohibido | No reemplazar commits validados |
| Rebase | No sobre historia validada | Continuidad entre checkpoints |
| Remoto | Obligatorio | Evidencia no solo local |
| Commits | Frecuentes y descriptivos | Reconstruir evolución |

Cadencia de referencia: cada 10–20 minutos o al completar una funcionalidad. No forzar commits vacíos.

Ejemplos:

```
[14:20][IAdashems][AI] Sistema inicial de movimiento
[14:34][IAdashems][HUMAN] Ajuste de físicas y límites
```

# 4. Checkpoints oficiales

Fotografías verificables del repo. Datos mínimos: EVENT_ID, TEAM_ID, SERVER_TIMESTAMP, CURRENT_COMMIT, PREVIOUS_CHECKPOINT_COMMIT, FILES_CHANGED, LINES_ADDED/REMOVED, UNTRACKED_FILES, BRANCH, REPOSITORY_STATUS.

Comandos útiles:

```
git rev-parse HEAD
git status --porcelain
git diff --stat <checkpoint_anterior>..HEAD
git log --oneline --decorate -n 20
```

El timestamp oficial debe venir del servidor de la organización, no del reloj local ni de la IA.

# 5. Trazabilidad del uso de IA

Registrar tareas que produzcan decisiones o cambios relevantes, no cada saludo.

### 5.1. Identificador

En este repo: `AI-IAdashems-<INICIAL>-NNNNNN` (NB, SV, SM, CM), correlativo **por archivo de integrante**.

### 5.2. Archivos de log

Cada persona edita solo `logs/<su-nombre>.md` (append-only). Luego:

```
python tools/indice_logs.py
```

`logs/INDICE_LOGS.md` no se edita a mano.

**Límite:** el log en el repo mejora la lectura para jurados, pero la organización puede tener copia externa autoritativa.

# 6. Registro externo

Si la organización usa un log append-only con hashes encadenados, ese registro prevalece sobre la copia local.

# 7–8. Amenazas y señales de revisión

Señales (revisión humana, no culpabilidad automática): miles de líneas entre checkpoints, arquitectura completa de golpe, ausencia de commits, untracked masivo, historial inconsistente, rebase post-checkpoint, borrado de auditoría, similitud con otro equipo, dependencias no declaradas.

No sancionar solo por velocidad, volumen o calidad del código.

# 9. Arquitectura

El chat ayuda; el servidor (o el remoto + checkpoints) demuestra.

EVIDENCIA FINAL = AI LOG (`logs/`) + GIT HISTORY + CHECKPOINT HISTORY

# 10. Cierre

Al terminar la ventana: commit final, push, checkpoint/tag, `HANDOFF_FINAL` (Prompt 7), evidencia archivada.

# Anexo A. Formato de entrada (bitácora)

```markdown
## AI-IAdashems-XX-000001

Timestamp: [SERVER_TIME o N/A]
Participant: [PXX]
Task: [descripción]
Type: [AI_GENERATED / AI_ASSISTED / DEBUGGING / DESIGN / TESTING / DOCS]
Files: [lista]
Change: [resumen]
Commit: [hash o PENDING]
Notes: [pendientes]
```

# Anexo B. JSONL externo (organización)

```json
{"event_id":"EVT-000001","event":"AI-GAME-JAM","team":"IAdashems","participant":"SV","server_timestamp":"[ISO8601]","event_type":"AI_REQUEST","request_id":"AI-IAdashems-SV-000001","payload_hash":"...","previous_hash":"...","git_commit":null}
```

# Anexo C. Mensajes de commit

```
[AI] feat: add enemy chase behavior
[AI+HUMAN] fix: tune collision response
[HUMAN] balance: adjust player speed
[AI] docs: update setup instructions
```

**Idea final:** no preguntar «¿usó IA?», sino poder responder «¿cómo pasó este equipo del estado inicial al juego final?».
