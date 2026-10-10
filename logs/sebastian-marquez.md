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

## AI-IAdashems-SM-000013

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Alargar el dash hasta perder velocidad y penalizar su finalización sin cancelarlo
Type: AI_ASSISTED
Files: player/player.gd
Change: El dash conserva dirección fija durante el impulso y la fase de frenado hasta velocidad casi cero. Saltar durante el dash lo cancela y pasa el momentum al control aéreo; dejar que termine aplica 1 s de recuperación sin movimiento ni acciones.
Limitaciones: La duración real depende de la velocidad de entrada, el frenado y las colisiones; requiere playtest para balancear longitud, recuperación e invulnerabilidad.
Commit: PENDING

## AI-IAdashems-SM-000014

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Suavizar el castigo al completar el dash e integrar los cambios de main
Type: AI_ASSISTED
Files: player/player.gd, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: La recuperación de 1 s reduce la velocidad horizontal al 55 % y permite saltar y disparar; se elimina la inmovilización y el descarte de entradas. Se integraron los cambios disponibles de origin/main mediante merge.
Limitaciones: El porcentaje de velocidad es un valor inicial para probar. La compilación y el gameplay deben verificarse en Godot después de resolver la integración.
Commit: PENDING

## AI-IAdashems-SM-000015

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Dar más sensación de profundidad a la cámara lateral con inclinación dinámica
Type: AI_ASSISTED
Files: player/follow_camera.gd, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: La cámara conserva su ángulo lateral actual y añade un balanceo de hasta 2 grados según la velocidad horizontal, suavizado con interpolación exponencial y centrado al reducir la velocidad.
Limitaciones: El ángulo máximo y la respuesta son valores iniciales; falta playtest visual para confirmar que aporta profundidad sin distraer. No se pudo ejecutar Godot en este entorno.
Commit: PENDING

## AI-IAdashems-SM-000016

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Inclinar la cámara para revelar profundidad 3D y ajustar el sprite animado del hongo
Type: AI_ASSISTED
Files: player/follow_camera.gd, player/follow_camera.tscn, anomalies/cucumber.gd, anomalies/cucumber.tscn, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: Se reemplazó el balanceo dinámico por una cámara oblicua fija (pitch -11°, yaw -12°), compensando el seguimiento para conservar el encuadre. El hongo ahora reproduce run, usa billboard hacia cámara y una escala/posición alineadas con su cápsula de colisión.
Limitaciones: Los ángulos y escala requieren inspección visual en Godot; no se pudo ejecutar el motor en este entorno.
Commit: PENDING

## AI-IAdashems-SM-000017

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Hacer que el sprite del hongo mire en la dirección de su desplazamiento
Type: AI_ASSISTED
Files: anomalies/cucumber.gd, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: El AnimatedSprite3D invierte horizontalmente la textura cuando la velocidad X del hongo es negativa y conserva la orientación cuando se detiene.
Limitaciones: No se pudo validar visualmente en ejecución porque Godot no está disponible en este entorno.
Commit: PENDING

## AI-IAdashems-SM-000018

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Integrar sprites de idle/disparo, proyectil de papa y enemigo lechuga
Type: AI_ASSISTED
Files: player/player.gd, player/player.tscn, player/herbicide.tscn, anomalies/lettuce.tscn, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: Se añadieron idle de dos fotogramas y disparo de tres fotogramas a AnimatedSprite3D. El movimiento queda bloqueado solo durante los ~0.38 s de la animación de disparo; el cooldown conserva su duración independiente. El proyectil usa papaXLL y la lechuga usa su sprite estático.
Limitaciones: Falta ejecutar las escenas en Godot para revisar importación, escala visual y transición de estados; el motor no está disponible en este entorno.
Commit: PENDING

## AI-IAdashems-SM-000019

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Agregar efectos visuales de temperatura alta sin modificar el HUD
Type: AI_ASSISTED
Files: effects/heat_screen_effect.gd, effects/heat_screen_effect.gdshader, effects/heat_screen_effect.tscn, player/follow_camera.gd, game/game.tscn, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: La escena principal escucha heat_changed y aumenta gradualmente una distorsión térmica, una viñeta roja en los bordes y vibración suave de cámara desde HEAT_HIGH_THRESHOLD. La capa de efectos se dibuja debajo del HUD; no se modificó su contenido ni el escenario.
Commit: PENDING
Notes: git diff --check pasó. Godot no está disponible en PATH, por lo que no se pudo validar la importación del shader ni probar visualmente los efectos en runtime; valores de distorsión y vibración quedan sujetos a ajuste visual.

## AI-IAdashems-SM-000020

Timestamp: N/A
Participant: SM (Sebastian Marquez)
Task: Aplicar concreto PBR a la oficina y agregar sombras proyectadas reversibles
Type: AI_ASSISTED
Files: level/materials/office_concrete.tres, level/building.tscn, game/game.tscn, player/player.tscn, player/herbicide.tscn, anomalies/cucumber.tscn, anomalies/pea.tscn, anomalies/lettuce.tscn, logs/sebastian-marquez.md, logs/INDICE_LOGS.md
Change: Se creó un material propio desde los mapas color, roughness, normal GL y AO, con repetición para las superficies largas y sin displacement. Se aplicó a pisos y paredes de fondo; la luz direccional principal proyecta sombras de opacidad reducida y los sprites recortan alfa para formar siluetas. Las sombras se revierten desactivando shadow_enabled en esa luz.
Commit: PENDING
Notes: git diff --check y validaciones estáticas de rutas/referencias completadas. No hay ejecutable Godot disponible en PATH; faltan validación de carga de escenas, revisión visual del tiling y medición de rendimiento en la PC del equipo.
