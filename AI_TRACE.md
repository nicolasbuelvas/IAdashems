# AI TRACE — IAdashems

Registro de trazabilidad del uso de IA (AI Game Jam).

## Índice de logs

**👉 [logs/INDICE_LOGS.md](logs/INDICE_LOGS.md)**

Cada integrante tiene su **propio archivo de log** en `logs/`, de modo que cada uno
sube sus entradas sin pisar las de los demás y sin generar conflictos de fusión:

| Integrante | Log |
| :--- | :--- |
| Nicolas Buelvas | [logs/nicolas-buelvas.md](logs/nicolas-buelvas.md) |
| Stiven Valencia | [logs/stiven-valencia.md](logs/stiven-valencia.md) |
| Sebastian Marquez | [logs/sebastian-marquez.md](logs/sebastian-marquez.md) |
| Carol Mosquera | [logs/carol-mosquera.md](logs/carol-mosquera.md) |

## Flujo

1. Agrega tu entrada al **final** de **tu** archivo (formato del Anexo A del protocolo).
2. Regenera el índice: `python tools/indice_logs.py`
3. Commitea **tu archivo + `logs/INDICE_LOGS.md`**.

> `logs/INDICE_LOGS.md` es un archivo **generado**: no lo edites a mano.
> Si Git reporta un conflicto ahí, resuelve re-ejecutando el script sobre la versión fusionada.

## AI-IAdashems-SM-000001

Timestamp: 2026-10-09T22:03:57-05:00
Participant: SM (Sebastian Marquez)
Task: Crear escena y script base del jugador (movimiento X, gravedad, salto, rampas, grupo player, lock Z)
Type: AI_GENERATED
Files: player/player.tscn, player/player.gd, player/player.gd.uid
Change: CharacterBody3D 2.5D con A/D, salto Espacio, gravedad, floor_constant_speed para rampas, capa 2 / máscara 1. Constantes desde GameConfig si existe, si no 6.0 / 9.0. Placeholder cápsula. Sin escena de prueba ni suelo (fuera de player/).
Limitaciones: No se pudo jugar el criterio de rampa/suelo en runtime porque no hay nivel; se validó carga headless de la escena. Input por teclas físicas (InputMap aún no definido).
Commit: PENDING

## AI-IAdashems-SM-000002

Timestamp: 2026-10-09T22:45:26-05:00
Participant: SM (Sebastian Marquez)
Task: Vida (3 HP), iframes 1 s con parpadeo, señales de daño y deslizamiento con Shift
Type: AI_GENERATED
Files: player/player.gd
Change: Contrato take_damage/is_sliding/is_invulnerable/reset_to. Slide 0.5 s a 11.0, cooldown 0.6 s al terminar, invuln y alpha 0.4. Daño ignora slide/iframes; muerte emite player_died una vez. EventBus si existe.
Limitaciones: EventBus y GameConfig aún no están en el repo; las señales no se pueden verificar en runtime. Parpadeo sobre AnimatedSprite3D. Cooldown del slide empieza al terminar el deslizamiento, no al iniciarlo.
Commit: PENDING
