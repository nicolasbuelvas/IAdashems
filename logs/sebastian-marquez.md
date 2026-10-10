# AI TRACE — Sebastian Marquez (TEAM: IAdashems)

> **Reglas:** solo tú editas este archivo. Agrega entradas al final; no reescribas ni borres entradas previas.
> Formato de entrada: Anexo A de `AI_GAME_JAM_PROTOCOLO.md`.
> El índice `logs/INDICE_LOGS.md` se genera con `python tools/indice_logs.py` — nunca lo edites a mano.

---

<!-- Nuevas entradas debajo de esta línea -->

## AI-IAdashems-SM-000001

Timestamp: 2026-10-09T22:03:57-05:00
Participant: SM (Sebastian Marquez)
Task: Crear escena y script base del jugador (movimiento X, gravedad, salto, rampas, grupo player, lock Z)
Type: AI_GENERATED
Files: player/player.tscn, player/player.gd, player/player.gd.uid
Change: CharacterBody3D 2.5D con A/D, salto Espacio, gravedad, floor_constant_speed para rampas, capa 2 / máscara 1. Constantes desde GameConfig si existe, si no 6.0 / 9.0. Placeholder cápsula. Sin escena de prueba ni suelo (fuera de player/).
Commit: PENDING
Notes: Trazabilidad duplicada en AI_TRACE.md por protocolo del evento. Validación: Godot 4.7.1 --import OK; carga headless de player.tscn OK. Pendiente probar sobre suelo/rampa cuando C entregue el nivel.

## AI-IAdashems-SM-000002

Timestamp: 2026-10-09T22:45:26-05:00
Participant: SM (Sebastian Marquez)
Task: Vida (3 HP), iframes 1 s con parpadeo, señales de daño y deslizamiento con Shift
Type: AI_GENERATED
Files: player/player.gd
Change: Contrato take_damage/is_sliding/is_invulnerable/reset_to. Slide 0.5 s a 11.0, cooldown 0.6 s al terminar, invuln y alpha 0.4. Daño ignora slide/iframes; muerte emite player_died una vez. EventBus si existe.
Commit: PENDING
Notes: Godot 4.7.1 --import OK. Pendiente playtest Shift/take_damage cuando existan EventBus, suelo y un caller de daño.
