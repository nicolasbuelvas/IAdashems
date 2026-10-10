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


## AI-IAdashems-SM-000003

Timestamp: 2026-10-09T23:35:33-05:00
Participant: SM (Sebastian Marquez)
Task: Crear proyectil de herbicida y disparo con E, cooldown de 5 s y progreso
Type: AI_GENERATED
Files: player/herbicide.tscn, player/herbicide.gd, player/player.gd
Change: Añadido Area3D en capa 4/máscaras 1 y 3, movimiento XY a 14, impacto en cuerpos/áreas y autodestrucción. E dispara apuntando al último input de ocho direcciones o hacia donde mira; cooldown 5 s emite progreso cada frame y ready al finalizar.
Commit: PENDING
Notes: Godot 4.7.1 cargó herbicide.tscn headless. player.tscn run falló al no poder abrir user://logs; no se verificó gameplay. Se conservaron los cambios preexistentes de player.tscn y Sprites fuera de este cambio.


## AI-IAdashems-SM-000004

Timestamp: 2026-10-09T23:54:34-05:00
Participant: SM (Sebastian Marquez)
Task: ContactArea, cámara lateral, reacción al calor y escena autónoma de prueba
Type: AI_GENERATED
Files: player/player.tscn, player/player.gd, player/follow_camera.tscn, player/follow_camera.gd, player/test_player.tscn, player/test_anomaly.gd, player/test_heat_bus.gd
Change: Área de contacto filtra grupo anomaly y llama on_player_contact. Cámara ortográfica sigue X/Y con Z fijo y suavizado. Tinte térmico desde heat_changed a partir de 70. Test autónomo con piso, rampa, dummy y bus de calor local.
Commit: PENDING
Notes: Cambios preexistentes en player.tscn y Sprites/ se conservaron. Godot 4.7.1 cargó test_player.tscn headless sin errores de parseo; no se simularon inputs ni impactos en runtime.


## AI-IAdashems-SM-000005

Timestamp: 2026-10-10T00:57:45-05:00
Participant: SM (Sebastian Marquez)
Task: Revisar hitbox y habilitar una prueba controlable del jugador
Type: DEBUGGING
Files: player/player.gd, player/player.tscn, player/test_player.tscn, project.godot
Change: Cápsula y ContactArea alineadas al tamaño visual; animaciones correr/quieto/dash conducidas desde movimiento y orientación. La escena de prueba es la principal para F5, con controles visibles y luz.
Commit: PENDING
Notes: Pendiente playtest interactivo. Se preservaron cambios previos del plugin MCP en project.godot.


## AI-IAdashems-SM-000006

Timestamp: 2026-10-10T01:01:08-05:00
Participant: SM (Sebastian Marquez)
Task: Ajustar hitbox y hacer controlable la escena de prueba
Type: DEBUGGING
Files: player/player.gd, player/player.tscn, player/test_player.tscn, project.godot
Change: Hitbox física y ContactArea alineadas; animaciones conducidas desde movimiento; prueba como escena principal con overlay de controles y luz.
Commit: PENDING
Notes: Godot 4.7.1 headless sin errores; runtime reportó contacto, heat_changed y golpe del herbicida. Pendiente playtest manual visual y de movimiento.


## AI-IAdashems-SM-000007

Timestamp: 2026-10-10T01:12:57-05:00
Participant: SM (Sebastian Marquez)
Task: Corregir sensación de levitación y validar separación entre colisión y contacto
Type: DEBUGGING
Files: player/player.gd, player/player.tscn
Change: Idle usa el frame con menor espacio transparente bajo los pies; se ajustó el offset vertical de sprite y dash. Se mantiene la separación de collider sólido y ContactArea sensor.
Commit: PENDING
Notes: Godot 4.7.1 headless validó carga sin errores; ventana abierta para confirmación visual del apoyo.

## AI-IAdashems-SM-000008

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Mejorar el peso del salto y la sensación del dash; restringir disparo y acciones simultáneas
Type: AI_ASSISTED
Files: player/player.gd
Change: Ajustada la gravedad efectiva del jugador con aceleración al caer y al soltar Espacio, extendido el dash a 0.65 s con frenado gradual, squash/stretch visual al despegar/aterrizar y restringido el herbicida a disparos horizontales. Salto, dash y disparo se bloquean entre sí en el mismo ciclo; el dash exige estar en el suelo.
Limitaciones: Los valores son una primera pasada de balance y requieren playtest visual para confirmar altura, duración y sensación.
Commit: PENDING

## AI-IAdashems-SM-000009

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Añadir aceleración y suavizar los cambios de dirección del jugador
Type: AI_ASSISTED
Files: player/player.gd
Change: El movimiento horizontal ahora acelera hasta la velocidad objetivo, frena al soltar y usa una respuesta diferenciada al invertir dirección y durante el aire. El sprite mantiene su orientación mientras el impulso cambia, para evitar un giro visual instantáneo.
Limitaciones: Parámetros iniciales de control; requieren ajuste mediante playtest, especialmente la inversión de dirección en el aire.
Commit: PENDING

## AI-IAdashems-SM-000010

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Mejorar el comportamiento de seguimiento de cámara con anticipación suave
Type: AI_ASSISTED
Files: player/follow_camera.gd
Change: La cámara ya existente ahora anticipa horizontalmente según la velocidad real del jugador. La anticipación y el seguimiento usan suavizado exponencial independiente para mostrar más recorrido al moverse y recentrar con suavidad al frenar o cambiar de dirección.
Limitaciones: Distancia y velocidad de anticipación son parámetros iniciales; pendientes de ajustar en playtest con el nivel completo y sus límites.
Commit: PENDING

## AI-IAdashems-SM-000011

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Hacer más progresiva la aceleración, conservar impulso tras el dash y afinar salto/cámara
Type: AI_ASSISTED
Files: player/player.gd, player/follow_camera.gd
Change: Reducida la aceleración y frenado horizontal para tardar cerca de 0.33 s en alcanzar velocidad de carrera y cerca de 0.4 s en invertirla. El dash termina conservando velocidad por 0.55 s; el salto tiene gravedad reducida de forma breve cerca del ápice y al soltar Espacio cae más rápido. La cámara sigue el impulso con anticipación suavizada.
Limitaciones: Parámetros de balance iniciales; faltan pruebas jugables para valorar la curva de velocidad y el arrastre tras el dash en el nivel completo.
Commit: PENDING

## AI-IAdashems-SM-000012

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Aumentar velocidad de carrera y hacer el dash dependiente del momentum; permitir salto con control aéreo
Type: AI_ASSISTED
Files: player/player.gd, player/follow_camera.gd
Change: Velocidad máxima base 8, aceleración de suelo más gradual y umbral de dash al 72 % de la velocidad máxima en la dirección solicitada. El dash mantiene dirección fija; saltar lo termina, conserva el impulso y permite corregir trayectoria en el aire. Se ajustó la anticipación de cámara al nuevo rango de velocidades.
Limitaciones: El umbral y la transferencia del impulso requieren playtest para confirmar que el dash se siente alcanzable y que el salto durante dash queda legible.
Commit: PENDING
