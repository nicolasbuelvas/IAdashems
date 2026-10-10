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


## AI-IAdashems-SM-000003

Timestamp: 2026-10-09T23:35:33-05:00
Participant: SM (Sebastian Marquez)
Task: Crear proyectil de herbicida y disparo con E, cooldown de 5 s y progreso
Type: AI_GENERATED
Files: player/herbicide.tscn, player/herbicide.gd, player/player.gd
Change: Añadido Area3D en capa 4/máscaras 1 y 3, movimiento XY a 14, impacto en cuerpos/áreas y autodestrucción. E dispara apuntando al último input de ocho direcciones o hacia donde mira; cooldown 5 s emite progreso cada frame y ready al finalizar.
Limitaciones: EventBus todavía no aparece en el repo; las señales quedan opcionales. Dirección W/S mapea +Y/-Y del plano XY, con Z fijo a cero. La detección requiere colisionadores en las capas declaradas; timeout de 5 s evita proyectiles huérfanos. Godot 4.7.1 cargó herbicide.tscn headless. player.tscn run falló al no poder abrir user://logs; no se verificó gameplay.
Commit: PENDING


## AI-IAdashems-SM-000004

Timestamp: 2026-10-09T23:54:34-05:00
Participant: SM (Sebastian Marquez)
Task: ContactArea, cámara lateral, reacción al calor y escena autónoma de prueba
Type: AI_GENERATED
Files: player/player.tscn, player/player.gd, player/follow_camera.tscn, player/follow_camera.gd, player/test_player.tscn, player/test_anomaly.gd, player/test_heat_bus.gd
Change: Área de contacto filtra grupo anomaly y llama on_player_contact. Cámara ortográfica sigue X/Y con Z fijo y suavizado. Tinte térmico desde heat_changed a partir de 70. Test autónomo con piso, rampa, dummy, cámara y bus de calor local (H activa calor).
Limitaciones: EventBus global no existe; la escena de prueba usa un EventBus local para probar heat_changed. Dummy desaparece al recibir herbicida y registra contacto por consola. El test depende de los sprites ya referenciados por player.tscn en Sprites/.
Commit: PENDING


## AI-IAdashems-SM-000005

Timestamp: 2026-10-10T00:57:45-05:00
Participant: SM (Sebastian Marquez)
Task: Revisar hitbox y habilitar una prueba controlable del jugador
Type: DEBUGGING
Files: player/player.gd, player/player.tscn, player/test_player.tscn, project.godot
Change: Alineada cápsula física de 1.55 u y ContactArea de 1.65 u; se ajustó la altura del sprite. Ahora correr/quieto/dash cambian la animación y se voltea al caminar a la izquierda. test_player queda como escena de arranque F5 e incluye guía de controles y luz.
Limitaciones: Pendiente comprobar el movimiento y el aspecto visual en ejecución interactiva. project.godot ya contenía autoloads del plugin MCP sin relación con este cambio; se preservaron.
Commit: PENDING


## AI-IAdashems-SM-000006

Timestamp: 2026-10-10T01:01:08-05:00
Participant: SM (Sebastian Marquez)
Task: Ajustar hitbox y hacer controlable la escena de prueba
Type: DEBUGGING
Files: player/player.gd, player/player.tscn, player/test_player.tscn, project.godot
Change: Hitbox física y ContactArea quedaron de tamaños alineados; se agregaron estados de animación correr/quieto/dash y flip horizontal. test_player es la escena principal, muestra controles y tiene luz para inspección.
Limitaciones: Se validó carga headless y el runtime reportó contacto, emisión heat_changed y golpe del herbicida. Sin inspección visual automatizada; falta playtest manual de movimiento, salto y presentación.
Commit: PENDING


## AI-IAdashems-SM-000007

Timestamp: 2026-10-10T01:12:57-05:00
Participant: SM (Sebastian Marquez)
Task: Corregir sensación de levitación y validar separación entre colisión y contacto
Type: DEBUGGING
Files: player/player.gd, player/player.tscn
Change: El estado quieto ahora usa el frame de correr con menor margen transparente bajo los pies (14 px en vez de 46 px), se bajó el sprite y el dash recibe un offset visual leve hacia el piso. Se conserva el collider sólido para world y ContactArea como sensor no bloqueante de anomalías.
Limitaciones: Godot 4.7.1 headless validó la carga sin errores; la ventana está abierta para confirmar visualmente el apoyo final.
Commit: PENDING
