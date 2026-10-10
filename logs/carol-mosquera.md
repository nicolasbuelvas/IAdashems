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
