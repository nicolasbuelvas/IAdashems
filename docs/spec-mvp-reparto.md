# Phytophthora infestans: SPEC del MVP y reparto de trabajo

Equipo: 4 personas, todas programan
Plazo: 5 horas, con apoyo de IA
Alcance: juego completo (6 rondas, 3 pisos, 3 anomalías, intro y final)
Motor: Godot 4.x con GDScript. Todos usan exactamente la misma versión.
Documento base: `gdd-phytophthora-infestans.md`

---

## 0. Advertencia de alcance

El juego completo en 5 horas es muy ajustado. Para que funcione, se necesitan tres cosas:

1. **Contratos fijos desde el minuto 30.** Nadie cambia una señal, un nombre de grupo o una firma de función sin avisar a todo el equipo.
2. **Placeholders primero, arte después.** Cubos y cápsulas con color hasta la hora 2:30.
3. **Lista de recortes acordada de antemano** (sección 9). Si a la hora 3:30 algo va atrasado, se recorta sin discutir.

---

## 1. Decisiones asumidas para el MVP

El GDD no definía estos puntos. Se asumen así para poder construir. Cualquiera puede vetarlos en la reunión inicial.

| Tema | Decisión para el MVP |
|---|---|
| Calor al iniciar una ronda | Se reinicia a 0 |
| Vida al iniciar una ronda o reintentar | Se reinicia a 3 |
| Invulnerabilidad tras un golpe | 1 s, con parpadeo |
| Reloj al contener una anomalía | Resta 15 s, con un mínimo de 10 s restantes |
| Duración del deslizamiento | 0,5 s, con 0,6 s de cooldown |
| Captura de la lechuga | Cualquier contacto mientras la papa se desliza |
| Disparo del guisante | 1 proyectil cada 2,5 s, 1 de daño |
| Velocidad del pepino en escaleras | 50 % al subir |
| Peligros del escenario | Un solo tipo (pinchos), 1 de daño |
| Expansión de piso | El piso nuevo se abre al empezar la ronda 3 (piso 2) y la ronda 6 (piso 3) |
| Cámara | Camera3D lateral que sigue a la papa en X e Y |

---

## 2. Arquitectura compartida

### 2.1 Estructura de carpetas y dueños

Cada persona solo edita sus carpetas. Así se evitan conflictos en los `.tscn`, que Git no fusiona bien.

```
res://
  autoload/          C   (event_bus.gd, game_config.gd, game_manager.gd)
  player/            A
  anomalies/         B
  level/             C   (building.tscn, stairs, hazards, spawn points)
  systems/           C   (heat_system.gd, round_manager.gd)
  ui/                D   (hud, menús, pausa, opciones)
  scenes/            D   (main_menu, intro, outro, credits)
  audio/             D
  game/              C   (game.tscn: escena principal de juego)
  art/<dueño>/       cada uno sus sprites
```

**Regla:** cada `.tscn` tiene un solo dueño. Si necesitas algo en una escena ajena, se lo pides a su dueño o lo instancias por código.

### 2.2 Autoloads (los crea C en la hora 0)

| Autoload | Archivo | Propósito |
|---|---|---|
| `EventBus` | `autoload/event_bus.gd` | Todas las señales globales |
| `GameConfig` | `autoload/game_config.gd` | Todos los valores de balance |
| `GameManager` | `autoload/game_manager.gd` | Estado del juego y cambio de escenas |

### 2.3 EventBus: el contrato principal

Nadie se llama directamente entre sistemas. Todo pasa por estas señales.

```gdscript
# autoload/event_bus.gd
extends Node

# Jugador (emite A)
signal player_health_changed(current: int, max_hp: int)
signal player_damaged(amount: int)
signal player_died()
signal player_slide_started()
signal player_slide_ended()
signal herbicide_fired()
signal herbicide_cooldown_changed(progress: float)  # 0.0 = recién lanzado, 1.0 = listo
signal herbicide_ready()

# Anomalías (emite B)
signal anomaly_spawned(anomaly: Node)
signal anomaly_contained(anomaly: Node)

# Sistemas (emite C)
signal heat_changed(value: float, max_value: float)
signal heat_maxed()
signal round_started(round_number: int, remaining: int)
signal round_timer_changed(seconds_left: float)
signal round_timer_expired()
signal anomalies_remaining_changed(remaining: int)
signal round_won(round_number: int)
signal round_failed(reason: StringName)   # &"heat" o &"health"
signal floor_unlocked(floor_number: int)
signal game_won()

# Flujo (emite D o GameManager)
signal pause_toggled(paused: bool)
```

### 2.4 GameConfig: valores de balance

Son valores iniciales. Se ajustan solo aquí, nunca dentro del código de cada sistema.

```gdscript
# autoload/game_config.gd
extends Node

# Calor (0 a 100)
const HEAT_MAX := 100.0
const HEAT_PER_SEC_TIME := 1.11          # unos 90 s hasta el máximo sin otros factores
const HEAT_PER_SEC_PER_ANOMALY := 0.3
const HEAT_PER_HIT := 10.0
const HEAT_EXPIRED_MULTIPLIER := 3.0
const HEAT_COOL_PER_CONTAIN := 20.0       # enfriamiento total por captura
const HEAT_COOL_RATE := 8.0               # velocidad del enfriamiento gradual, por segundo
const HEAT_HIGH_THRESHOLD := 70.0         # desde aquí sale humo

# Reloj
const ROUND_BASE_TIME := 90.0
const ROUND_TIME_PER_ANOMALY := 15.0
const ROUND_MIN_TIME_LEFT := 10.0

# Jugador
const PLAYER_MAX_HP := 3
const PLAYER_SPEED := 6.0
const PLAYER_JUMP_VELOCITY := 9.0
const PLAYER_IFRAMES := 1.0
const SLIDE_DURATION := 0.5
const SLIDE_COOLDOWN := 0.6
const SLIDE_SPEED := 11.0
const HERBICIDE_COOLDOWN := 5.0
const HERBICIDE_SPEED := 14.0

# Anomalías
const CUCUMBER_SPEED := 5.0
const CUCUMBER_FLEE_DISTANCE := 6.0
const CUCUMBER_STAIRS_MULT := 0.5
const LETTUCE_SPEED := 4.0
const PEA_SPEED := 1.5
const PEA_FIRE_INTERVAL := 2.5
const PEA_PROJECTILE_SPEED := 7.0
```

### 2.5 Física, capas y grupos

Todo es 3D con el eje Z bloqueado (`axis_lock_linear_z = true` en los CharacterBody3D). Los sprites son `AnimatedSprite3D`.

| Capa | Nombre | Quién la usa |
|---|---|---|
| 1 | world | Suelos, paredes, escaleras |
| 2 | player | Papa |
| 3 | anomaly | Anomalías |
| 4 | player_projectile | Herbicida |
| 5 | enemy_projectile | Guisantes |
| 6 | stairs_zone | Área de escaleras |
| 7 | hazard | Pinchos |

| Grupo | Nodo | Dueño |
|---|---|---|
| `player` | Papa | A |
| `anomaly` | Cada anomalía | B |
| `stairs` | Area3D de cada escalera | C |
| `hazard` | Pinchos | C |
| `container` | Marker3D del contenedor de cada piso | C |

### 2.6 Interfaces entre nodos

Estas son las únicas llamadas directas permitidas.

```gdscript
# Papa (A): player/player.gd
class_name Player extends CharacterBody3D
func take_damage(amount: int) -> void      # ignora si está en iframes o deslizándose
func is_sliding() -> bool
func is_invulnerable() -> bool
func reset_to(spawn: Vector3) -> void      # vida llena, sin estados

# Anomalía base (B): anomalies/anomaly.gd
class_name Anomaly extends CharacterBody3D
enum Kind { CUCUMBER, LETTUCE, PEA }
var kind: Kind
var spawn_id: StringName                   # lo asigna RoundManager al instanciar
func on_player_contact(player: Player) -> void  # B decide si se captura o hace daño
func on_herbicide_hit() -> void
func contain() -> void                     # animación, viaja al contenedor, emite anomaly_contained, se libera
```

**Regla de detección:** la papa tiene un `Area3D` llamado `ContactArea`. Cuando toca un cuerpo del grupo `anomaly`, llama a `anomaly.on_player_contact(self)`. El herbicida llama a `on_herbicide_hit()` al impactar. Las reglas de captura y daño viven solo en B.

| Anomalía | `on_player_contact` | `on_herbicide_hit` |
|---|---|---|
| Pepino (*Cucumis sativus*) | `contain()` | Nada |
| Lechuga (*Lactuca sativa*) | Si `player.is_sliding()`: `contain()`. Si no: `player.take_damage(1)` | Nada |
| Guisante (*Pisum sativum*) | `player.take_damage(1)` | `contain()` |

---

## 3. Datos de las rondas (los implementa C)

Los spawn points son `Marker3D` dentro de `building.tscn`, con nombres como `F1_A`. C coloca al menos 4 por piso, de A a D.

| Ronda | Piso habilitado | Anomalías (tipo@spawn) | Total |
|---|---|---|---|
| 1 | 1 | Pepino@F1_A | 1 |
| 2 | 1 | Pepino@F1_A, Lechuga@F1_B | 2 |
| 3 | 1-2 (abre el 2) | Pepino@F1_C, Lechuga@F2_A, Guisante@F2_B | 3 |
| 4 | 1-2 | Pepino@F1_A, Pepino@F2_C, Lechuga@F1_B, Guisante@F2_D | 4 |
| 5 | 1-2 | Pepino@F1_C, Pepino@F2_A, Lechuga@F1_D, Lechuga@F2_B, Guisante@F2_C | 5 |
| 6 | 1-3 (abre el 3) | Pepino@F1_A, Pepino@F3_A, Lechuga@F2_A, Lechuga@F3_B, Guisante@F2_C, Guisante@F3_C | 6 |

Total del juego: 21 anomalías.

**Reintento con progreso:** RoundManager guarda los `spawn_id` contenidos en la ronda actual. Al reintentar, recarga la ronda e instancia solo las anomalías que faltan. El reloj vuelve a `90 + 15 × restantes`.

---

## 4. Flujo de estados (GameManager, de C)

```
MENU -> INTRO -> ROUND_INTRO -> PLAYING -> ROUND_WON -> ROUND_INTRO (siguiente)
                                   |                \
                                   |                 -> (ronda 6) OUTRO -> CREDITS -> MENU
                                   -> ROUND_FAILED -> ROUND_INTRO (misma ronda, con progreso)
PLAYING <-> PAUSED
```

| Escena | Archivo | Dueño |
|---|---|---|
| Menú principal | `scenes/main_menu.tscn` | D |
| Intro | `scenes/intro.tscn` | D |
| Juego | `game/game.tscn` | C (instancia la papa de A, el edificio de C y el HUD de D) |
| Final | `scenes/outro.tscn` | D |
| Créditos | `scenes/credits.tscn` | D |

GameManager expone `goto(scene_key: StringName)`. D llama a `GameManager.goto(&"game")` desde el menú y a `GameManager.goto(&"credits")` al terminar el outro.

---

## 5. Reparto por persona

### Persona A: Jugador (Potato Sans)

**Entregables**
- `player/player.tscn` y `player/player.gd`
- `player/herbicide.tscn` (proyectil)
- Cámara lateral `player/follow_camera.tscn`, que C instancia en `game.tscn`
- Sprites de la papa: idle, correr, saltar, deslizar, golpe y versión con humo

**Funcionalidad**
- Movimiento con WASD (A y D en X), salto con Espacio y gravedad.
- Subir escaleras: las escaleras son rampas físicas. La papa camina sobre ellas sin frenarse.
- Deslizamiento con Shift: dura 0,5 s, aumenta la velocidad y hace a la papa translúcida e invulnerable. Cooldown de 0,6 s. Emite `player_slide_started` y `player_slide_ended`.
- Herbicida con E: se lanza en la dirección del último input (8 direcciones; si está quieta, hacia donde mira). Cooldown de 5 s. Emite `herbicide_fired`, `herbicide_cooldown_changed` cada frame durante el cooldown y `herbicide_ready`.
- Vida: 3 golpes, 1 s de iframes con parpadeo rojo. Emite `player_damaged`, `player_health_changed` y `player_died`.
- Humo y vapor (GPUParticles3D) cuando el calor pasa `HEAT_HIGH_THRESHOLD`. Escucha `heat_changed`.
- `ContactArea` que llama a `on_player_contact` en las anomalías.

**Criterios de aceptación**
- [ ] La papa se mueve, salta, se desliza y sube escaleras en una escena de prueba propia.
- [ ] El herbicida respeta el cooldown y sale en la dirección correcta.
- [ ] Los golpes durante el deslizamiento o los iframes no quitan vida.
- [ ] Todas las señales de A se emiten. Se verifica con prints o con un HUD de debug.

---

### Persona B: Anomalías

**Entregables**
- `anomalies/anomaly.gd` (clase base) y `anomalies/anomaly_base.tscn`
- `anomalies/cucumber.tscn`, `anomalies/lettuce.tscn` y `anomalies/pea.tscn`
- `anomalies/pea_projectile.tscn`
- Animación de contención (encoger y viajar en tween al `container` más cercano del mismo piso)
- Sprites de las 3 anomalías y del proyectil de guisante

**Funcionalidad**
- **Pepino:** si la papa está a menos de `CUCUMBER_FLEE_DISTANCE`, huye en X en dirección contraria. Si tiene una escalera cerca, puede usarla para escapar, y dentro de un área del grupo `stairs` subiendo va al 50 %. Si queda contra una pared, se queda quieto (es la forma de arrinconarlo). Inofensivo.
- **Lechuga:** se mueve a velocidad constante y rebota en suelos y paredes (`velocity.bounce(normal)`). Hace daño al contacto salvo que la papa se deslice.
- **Guisante:** avanza lento en X hacia la papa y le dispara un proyectil cada 2,5 s. El proyectil hace 1 de daño, desaparece al chocar con `world` y se ignora si la papa es invulnerable. Hace daño al contacto. Se contiene con 1 impacto de herbicida.
- `contain()` desactiva colisiones, hace el tween al contenedor, emite `anomaly_contained(self)` y luego `queue_free()`.
- Emite `anomaly_spawned(self)` en `_ready()`.

**Criterios de aceptación**
- [ ] Cada anomalía funciona en una escena de prueba con un dummy de la papa (un CharacterBody3D en el grupo `player` con métodos stub).
- [ ] Las reglas de la tabla de la sección 2.6 se cumplen.
- [ ] El pepino se frena visiblemente en las escaleras.
- [ ] La contención siempre emite `anomaly_contained` una sola vez.

---

### Persona C: GameManager, sistemas y nivel (integrador)

**Entregables**
- Repo, `.gitignore` (excluye `.godot/`), estructura de carpetas, autoloads con stubs (hora 0 a 0:30)
- `autoload/game_manager.gd` (estados y cambio de escenas)
- `systems/heat_system.gd`
- `systems/round_manager.gd` (datos de rondas, spawn, reloj, victoria, derrota, reintento)
- `level/building.tscn`: 3 pisos, escaleras-rampa con su Area3D `stairs`, paredes que bloquean los pisos 2 y 3, spawn points, un `container` por piso, spawn de la papa y pinchos
- `game/game.tscn`: instancia el edificio, la papa, la cámara, el HUD y los sistemas
- Integración en las horas 2:30 y 4:00

**Funcionalidad**
- **HeatSystem:** cada frame suma `tiempo + anomalías activas × factor`, multiplicado por 3 si el reloj expiró. Suma `HEAT_PER_HIT` con `player_damaged`. Al recibir `anomaly_contained`, agrega 20 de enfriamiento pendiente que se descuenta a 8 por segundo. Emite `heat_changed` y, al llegar a 100, `heat_maxed`.
- **RoundManager:** al iniciar la ronda, habilita pisos (emite `floor_unlocked` en las rondas 3 y 6 y quita la pared), instancia las anomalías faltantes y arranca el reloj. Al contener, resta 15 s (mínimo 10 s) y emite `anomalies_remaining_changed`. Al llegar a 0 restantes, emite `round_won` y, en la ronda 6, `game_won`. Con `heat_maxed` o `player_died`, emite `round_failed` y reintenta con progreso.
- **Pinchos:** Area3D en el grupo `hazard` que llama a `take_damage(1)` a la papa.
- **GameManager:** maneja la pausa con Esc (`get_tree().paused`) y emite `pause_toggled`. Los nodos de UI usan `process_mode = ALWAYS`.

**Criterios de aceptación**
- [ ] Se pueden jugar las 6 rondas seguidas con placeholders.
- [ ] El reintento conserva las anomalías contenidas.
- [ ] Los pisos 2 y 3 se abren en las rondas correctas.
- [ ] El calor sube, baja y triplica su velocidad al expirar el reloj, según GameConfig.

---

### Persona D: UI, flujo de escenas y audio

**Entregables**
- `ui/hud.tscn`: medidor de calor, reloj, vida (3 iconos), anomalías restantes, icono del herbicida
- `ui/pause_menu.tscn`: reanudar, opciones, salir al menú
- `ui/options_menu.tscn`: volumen de música y efectos (buses de audio `Music` y `SFX`), pantalla completa o ventana, resolución
- `ui/round_card.tscn`: tarjeta "Turno N" de 2 s y aviso "Nuevo piso habilitado"
- `scenes/main_menu.tscn`: Nueva partida, Opciones, Salir
- `scenes/intro.tscn`: la papa dormida en su escritorio despierta. Texto de Grupo Tubérculo S.A.S.
- `scenes/outro.tscn`: explosión del edificio (sacudida, destello, partículas, fundido a blanco) y texto de cierre
- `scenes/credits.tscn`
- `audio/`: música corporativa, efectos de oficina y cartoon, y un `AudioManager` dentro de `ui/` que escucha el EventBus

**Funcionalidad**
- El HUD solo escucha señales. No lee nodos de otros.
- El icono del herbicida se oscurece según `herbicide_cooldown_changed` y tiembla con `herbicide_ready`.
- La barra de calor cambia de color al pasar el umbral alto.
- El AudioManager reproduce: golpe (`player_damaged`), captura (`anomaly_contained`), lanzamiento (`herbicide_fired`), alarma (`round_timer_expired`), fanfarria (`round_won`) y explosión (`game_won`).

**Criterios de aceptación**
- [ ] El HUD reacciona a todas las señales usando un script de prueba que las emite.
- [ ] El menú lleva al intro, el intro al juego y el outro a los créditos y al menú.
- [ ] La pausa congela el juego y el menú de pausa sigue funcionando.
- [ ] Las opciones cambian el volumen y la pantalla.

---

## 6. Cronograma de 5 horas

| Hora | Todos | A | B | C | D |
|---|---|---|---|---|---|
| 0:00-0:30 | Leer el GDD y este documento. Reunión de 10 min para vetar decisiones | Escena de prueba | Escena de prueba con dummy | Repo, autoloads con stubs y GameConfig | Esqueleto de escenas y menús |
| 0:30-2:30 | Trabajo en paralelo con placeholders | Movimiento, deslizamiento, herbicida y vida | Base y 3 anomalías | Edificio, HeatSystem y RoundManager | HUD, pausa, opciones y tarjeta de ronda |
| **2:30** | **Integración 1** (C fusiona y todos prueban la ronda 1-3) | | | | |
| 2:30-4:00 | Arte con IA y contenido | Sprites y humo de la papa | Sprites, contención y pulido de IA | Rondas 4-6 y pinchos | Intro, outro, créditos y audio |
| **4:00** | **Integración 2** (partida completa de las 6 rondas) | | | | |
| 4:00-4:40 | Bugs y balance en GameConfig | Bugs propios | Bugs propios | Balance de calor y reloj | Bugs de UI y audio |
| 4:40-5:00 | Exportar build para Windows y una partida final | | | Exporta | |

---

## 7. Git y trabajo con IA

**Git**
- Una rama por persona (`a-player`, `b-anomalies`, `c-systems`, `d-ui`). C fusiona a `main` en cada integración.
- Nadie edita carpetas ajenas ni `project.godot`, excepto C.
- Commits pequeños y frecuentes.

**IA**
- A cada asistente de IA le dan: el GDD, las secciones 2 y 3 de este documento, y su sección de rol. Así el código generado respeta los nombres de señales y grupos.
- La IA nunca renombra señales, grupos ni capas.
- Para el arte, todos usan el mismo prompt base de estilo, por ejemplo: "cartoon 2D sprite, flat colors, thick dark outline, minimal, side view, transparent background". Así los sprites de los 4 combinan.
- Para el audio, librerías libres: Kenney (efectos), Pixabay Music y Freesound. D verifica las licencias.

---

## 8. Definición de terminado del MVP

- [ ] Se juega de principio a fin: menú, intro, 6 rondas, explosión, créditos y menú.
- [ ] Las 3 anomalías funcionan con sus reglas de captura y daño.
- [ ] Calor, vida y reloj funcionan según el GDD, con derrota y reintento con progreso.
- [ ] El HUD muestra los 5 elementos.
- [ ] Pausa y opciones funcionan.
- [ ] Hay una build de Windows que corre en otra máquina.

---

## 9. Recortes en orden (si a la hora 3:30 van atrasados)

1. Opción de resolución (se deja solo pantalla completa o ventana).
2. Partículas de humo (se usa un tinte rojo sobre el sprite).
3. Intro animada (se usa una imagen fija con texto).
4. Pinchos del escenario.
5. Pepino usando escaleras (se queda en su piso y se arrincona contra las paredes).
6. Outro elaborado (se usa sacudida, fundido a blanco y texto).

No se recorta nunca: el sistema de calor, las 3 anomalías, el reintento con progreso y la ronda 6 con su final.

---

## 10. Riesgos de integración

| Riesgo | Mitigación |
|---|---|
| Conflictos en `.tscn` | Un dueño por escena (sección 2.1) |
| Señales con nombres distintos | Solo se usa `event_bus.gd`. C lo congela a la hora 0:30 |
| Pepino imposible de atrapar | Prueba a la hora 2:30. Si falla, se aplica el recorte 5 |
| Ronda 6 injusta por el guisante | Se ajusta `PEA_FIRE_INTERVAL` en GameConfig durante el balance |
| Reloj que resta tiempo al capturar se siente raro | Se prueba en la integración 1. Si confunde, se pone `ROUND_TIME_PER_ANOMALY` en 0 al contener |
| La IA genera código para Godot 3 | Se pide explícitamente "Godot 4, GDScript 2.0" en cada prompt |
