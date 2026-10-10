# AI TRACE — Carol Mosquera (TEAM: IAdashems)

> **Reglas:** solo tú editas este archivo. Agrega entradas al final; no reescribas ni borres entradas previas.
> Formato de entrada: Anexo A de `AI_GAME_JAM_PROTOCOLO.md`.
> El índice `logs/INDICE_LOGS.md` se genera con `python tools/indice_logs.py` — nunca lo edites a mano.

---

<!-- Nuevas entradas debajo de esta línea -->

## AI-IAdashems-CM-000001

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Mapa 3D simple (una habitación del edificio) con personaje que se mueve izquierda/derecha usando sprites PAPA_CORRIENDO
Type: AI_GENERATED
Files: level/habitacion.tscn, level/follow_camera.gd, player/player.tscn, player/player.gd
Change: Habitación de 15x3 m armada con piezas Kenney (scaffolding-floor, wall-a-flat, wall-a-flat-window) a escala 3, colisiones de piso y límites laterales, cámara fija que sigue al jugador en X, jugador CharacterBody3D con AnimatedSprite3D (6 frames) movido con A/D o flechas. No se pudo ejecutar Godot en la sesión: escena sin probar visualmente.
Commit: PENDING
Notes: Verificar en el editor la orientación de las paredes planas y el tamaño del sprite (pixel_size 0.005). Pendiente: salto, idle, más habitaciones.

## AI-IAdashems-CM-000002

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Hacer jugable PASILLO.tscn (GridMap propio) con el personaje caminando sobre el piso
Type: AI_ASSISTED
Files: PASILLO.tscn, player/player.gd, player/player.tscn, level/follow_camera.gd
Change: A PASILLO.tscn (GridMap intacto) se le agregaron Player, camara lateral que sigue por el eje Z, luz, entorno y colisiones (piso, pared izquierda, topes en los extremos). player.gd ahora se mueve sobre el eje X local del nodo para poder rotarlo en pasillos que van en Z; follow_camera.gd sigue por un eje configurable. Sin Godot en la sesion: no se ejecuto.
Commit: PENDING (lo hace el usuario manualmente)
Notes: Las colisiones asumen piso en y=0.5 (celda y=0, centrada) y pared en x=-3. Si el GridMap se edita, ajustar nodo Colisiones. habitacion.tscn no se pudo ver: causa sin confirmar.

## AI-IAdashems-CM-000003

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Enemigo (Sprite1.png) que huye del jugador y explicacion para expandir el mapa
Type: AI_GENERATED
Files: enemy/enemy.gd, enemy/enemy.tscn, level/gridmap_collider.gd, PASILLO.tscn
Change: Enemigo CharacterBody3D con Sprite3D que se aleja del jugador dentro de flee_distance sobre el eje del pasillo. Script gridmap_collider.gd genera colisiones desde las celdas del GridMap (piso id 46, pared id 85), reemplazando las colisiones manuales de piso y pared en PASILLO.tscn. Sin Godot en la sesion: no se ejecuto.
Commit: PENDING (lo hace el usuario manualmente)
Notes: Los topes LimiteFondo/LimiteFrente siguen manuales y hay que moverlos al ampliar el mapa. Los ids 46/85 se dedujeron del orden de Meshes.tscn; verificar en la MeshLibrary.

## AI-IAdashems-CM-000004

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Preparar ramaEnemigoMapa para el merge con main (player y camara de main)
Type: AI_ASSISTED
Files: PASILLO.tscn, level/habitacion.tscn, level/follow_camera.gd (borrado), player/Sprite/PAPA_CORRIENDO (borrado)
Change: PASILLO.tscn ahora agrupa GridMap y colisiones en un nodo Mapa rotado -90 grados en Y para que el pasillo corra por X (el player de main solo se mueve en X). Player y Enemy sin rotacion; se quito el override speed. Se usa la camara de main (player/follow_camera.tscn), inclinada 20 grados para que se vea el piso. habitacion.tscn usa la misma camara. Se borraron mi follow_camera.gd y mis sprites duplicados (identicos por hash a Sprites/PAPA_CORRIENDO de main). Sin Godot en la sesion: no probado.
Commit: PENDING (lo hace el usuario manualmente)
Notes: Hasta el merge, player/follow_camera.tscn y el player de main no existen en esta rama: no abrir PASILLO.tscn en el editor antes de mergear. Despues del merge revisar altura de camara y posicion z del jugador (piso entre z=-2 y 1).

## AI-IAdashems-CM-000005

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Convertir el pasillo en nodo base de habitacion (largo/alto configurables, apilables y conectables) y ajustar la camara
Type: AI_GENERATED
Files: level/habitacion_base.gd, level/habitacion_base.tscn, level/conexion_habitacion.gd, level/conexion_habitacion.tscn, player/follow_camera.gd, player/follow_camera.tscn, PASILLO.tscn
Change: HabitacionBase (@tool) genera con el GridMap piso, pared de fondo, paredes de extremo y colisiones segun `ancho` y `alto`. ConexionHabitacion teletransporta al jugador a otra conexion al pulsar W/flecha arriba (se enlaza de vuelta sola). PASILLO.tscn ahora usa dos habitaciones apiladas (Pasillo ancho 23, Piso2 ancho 14 alto 4) conectadas. Camara: ortografica size 16 (antes 10) y centrada en el cuerpo del jugador con target_offset (0,1,0), con snap inicial. Sin Godot en la sesion: no se ejecuto.
Commit: PENDING (lo hace el usuario manualmente)
Notes: Reemplaza el GridMap pintado a mano de PASILLO.tscn por el generado (mismo contenido: piso id 46, pared id 85). Verificar en el editor la altura de colisiones de pared y el tamano de camara. gridmap_collider.gd ya no se usa.

## AI-IAdashems-CM-000006

Timestamp: N/A
Participant: CM (Carol Mosquera)
Task: Quitar las conexiones por zona azul, mapa de 4 habitaciones y escaleras verticales
Type: AI_GENERATED
Files: level/habitacion_base.gd, level/escalera.gd, level/escalera.tscn, player/player.gd, PASILLO.tscn, level/conexion_habitacion.gd (borrado), level/conexion_habitacion.tscn (borrado)
Change: Se eliminaron las ConexionHabitacion. HabitacionBase gana `huecos_piso` (huecos en el piso, con colision partida). Nueva Escalera (Area3D @tool) con peldanos generados; el jugador la trepa con W/S estando frente a ella, la suelta con A/D arriba o abajo, o con salto (player.gd: _update_climb). PASILLO.tscn ahora tiene 4 habitaciones (Hab_1A, Hab_1B abajo; Hab_2A, Hab_2B arriba) unidas caminando, con un hueco de 3 columnas en el piso de Hab_2B y una Escalera debajo (tambien se puede subir saltando). Sin Godot en la sesion: no se ejecuto.
Commit: PENDING (lo hace el usuario manualmente)
Notes: Verificar en el editor el agarre y salida de la escalera (hover al salir por arriba) y que el hueco quede alineado con la escalera (x=9.5 local de Hab_1B). Los umbrales _CLIMB_SPEED y _LADDER_TOP_HOVER en player.gd son ajustables.
