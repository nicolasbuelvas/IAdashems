class_name RoundManager
extends Node
## Dueño del progreso de las rondas: datos de las 6 rondas, spawn de anomalías,
## reloj, victoria, derrota y reintento con progreso.
## Contrato: docs/spec-mvp-reparto.md (2.3, 2.4, 3 y 5) y docs/flujo-subagentes-persona-C.md (sección 2).
## Habla con Building solo por la interfaz congelada, llamando por nombre.

const SCENES := {
	"cucumber": "res://anomalies/cucumber.tscn",
	"lettuce": "res://anomalies/lettuce.tscn",
	"pea": "res://anomalies/pea.tscn",
}

## Tabla 3 del spec. Total: 1 + 2 + 3 + 4 + 5 + 6 = 21 anomalías.
const ROUNDS := [
	{"floors": [1], "anomalies": [["cucumber", &"F1_A"]]},
	{"floors": [1], "anomalies": [["cucumber", &"F1_A"], ["lettuce", &"F1_B"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", &"F1_C"], ["lettuce", &"F2_A"], ["pea", &"F2_B"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", &"F1_A"], ["cucumber", &"F2_C"], ["lettuce", &"F1_B"], ["pea", &"F2_D"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", &"F1_C"], ["cucumber", &"F2_A"], ["lettuce", &"F1_D"], ["lettuce", &"F2_B"], ["pea", &"F2_C"]]},
	{"floors": [1, 2, 3], "anomalies": [["cucumber", &"F1_A"], ["cucumber", &"F3_A"], ["lettuce", &"F2_A"], ["lettuce", &"F3_B"], ["pea", &"F2_C"], ["pea", &"F3_C"]]},
]

@export var building: Node3D
@export var anomalies_root: Node3D
@export var player: Node3D
## Rutas por tipo. game/test/test_game.tscn las cambia por los dummies. Siempre se usa esta variable, nunca SCENES.
@export var anomaly_scenes: Dictionary = SCENES
@export var enable_timer_limit: bool = true

var current_round: int = 0
var active: bool = false
var remaining: int = 0
var time_left: float = 0.0
var max_floor_unlocked: int = 1
var contained_ids: Array[StringName] = []
var expired_emitted: bool = false
## Reloj guardado al morir (vida o calor): el reintento lo retoma en vez de recalcularlo. -1 = no hay.
var _resume_time: float = -1.0

## Anomalías instanciadas por esta clase y todavía sin contener: spawn_id -> nodo.
var _live: Dictionary = {}


func _ready() -> void:
	EventBus.heat_maxed.connect(_on_heat_maxed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.anomaly_contained.connect(_on_anomaly_contained)


func _process(delta: float) -> void:
	if not active:
		return
	if enable_timer_limit:
		time_left -= delta
		EventBus.round_timer_changed.emit(maxf(time_left, 0.0))
		if time_left <= 0.0 and not expired_emitted:
			expired_emitted = true
			EventBus.round_timer_expired.emit()
			# Reloj agotado = game over definitivo del turno: la ronda se reinicia completa.
			_fail(&"time")


## Inicia la ronda n (1 a 6) o la reintenta. Si n es la ronda actual, conserva contained_ids
## (tras morir siguen ahí; tras agotar el reloj _fail ya los borró).
func start_round(n: int) -> void:
	_penalty_in_progress = false
	if n < 1 or n > ROUNDS.size():
		push_error("RoundManager: la ronda %d no existe" % n)
		return
	if not is_instance_valid(building) or not is_instance_valid(anomalies_root):
		push_error("RoundManager: faltan los exports building o anomalies_root")
		return

	var data: Dictionary = ROUNDS[n - 1]

	# 1. Progreso: solo se vacía al cambiar de ronda.
	if n != current_round:
		_free_live()
		contained_ids.clear()
		_resume_time = -1.0
	current_round = n

	# 2. Anomalías que faltan.
	remaining = 0
	for entry in data["anomalies"]:
		if not contained_ids.has(entry[1]):
			remaining += 1

	# 3. Antes de instanciar nada: HeatSystem reinicia el calor en esta señal.
	EventBus.round_started.emit(n, remaining)

	# 4. Reposicionar la papa. Sin jugador válido se avisa una vez por inicio de ronda y se sigue.
	if is_instance_valid(player) and player.has_method("reset_to"):
		player.call("reset_to", building.call(&"get_player_spawn"))
	else:
		push_warning("RoundManager: player no existe o no tiene reset_to; la papa no se reposiciona")

	# 5. Pisos: solo se abren los que superan el máximo ya desbloqueado.
	for f in data["floors"]:
		var floor_number: int = f
		if floor_number > max_floor_unlocked:
			building.call(&"unlock_floor", floor_number)
			max_floor_unlocked = floor_number
			EventBus.floor_unlocked.emit(floor_number)

	# 6. Instanciar solo las anomalías faltantes.
	for entry in data["anomalies"]:
		var spawn_id: StringName = entry[1]
		if contained_ids.has(spawn_id) or _is_live(spawn_id):
			continue
		_spawn_anomaly(entry[0], spawn_id)

	# 7. Reloj: 90 + 15 x restantes. Si la papa murió, sigue donde iba.
	if _resume_time > 0.0:
		time_left = _resume_time
	else:
		time_left = GameConfig.ROUND_BASE_TIME + GameConfig.ROUND_TIME_PER_ANOMALY * remaining
	_resume_time = -1.0
	expired_emitted = false
	active = true
	if remaining == 0:
		push_warning("RoundManager: la ronda %d arranca sin anomalías pendientes" % n)

	# 8. HUD: contador y reloj arrancan con su valor real, sin esperar al primer _process. Va al final.
	EventBus.anomalies_remaining_changed.emit(remaining)
	EventBus.round_timer_changed.emit(time_left)


func _spawn_anomaly(kind: String, spawn_id: StringName) -> void:
	# Se resuelve el destino antes de instanciar para no dejar nodos huérfanos.
	var marker := building.call(&"get_spawn", spawn_id) as Node3D
	if marker == null:
		push_error("RoundManager: Building no tiene el spawn '%s'" % spawn_id)
		return

	var path: String = anomaly_scenes.get(kind, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("RoundManager: no existe la escena de '%s' (%s)" % [kind, path])
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("RoundManager: no se pudo cargar '%s' como PackedScene" % path)
		return

	var instance := packed.instantiate()
	var anomaly := instance as Node3D
	if anomaly == null:
		push_error("RoundManager: '%s' no es un Node3D" % path)
		instance.free()
		return

	# spawn_id y posición se fijan antes de add_child: _ready() de la anomalía emite anomaly_spawned
	# y ya debe verlos. La posición va en local porque anomalies_root es el padre.
	anomaly.set(&"spawn_id", spawn_id)
	if anomaly.get(&"spawn_id") != spawn_id:
		push_error("RoundManager: '%s' no declara la variable spawn_id" % path)
		anomaly.free()
		return
	anomaly.position = anomalies_root.to_local(marker.global_position)
	# Se registra antes de add_child por si una señal síncrona en _ready() pide su captura.
	_live[spawn_id] = anomaly
	anomalies_root.add_child(anomaly)


func _is_live(spawn_id: StringName) -> bool:
	if not _live.has(spawn_id):
		return false
	if is_instance_valid(_live[spawn_id]):
		return true
	_live.erase(spawn_id)
	return false


## spawn_id puede llegar como StringName o como String; se normaliza a StringName. Vacío si no hay.
func _spawn_id_of(anomaly: Node) -> StringName:
	var raw: Variant = anomaly.get(&"spawn_id")
	if typeof(raw) == TYPE_STRING_NAME:
		return raw
	if typeof(raw) == TYPE_STRING:
		var text: String = raw
		return StringName(text)
	return &""


## Solo cuenta una anomalía que esta ronda instanció, que sigue viva y que aún no está contenida.
## Las ajenas, las que no tienen spawn_id, las repetidas y las que llegan fuera de ronda se descartan con push_warning.
func _on_anomaly_contained(anomaly: Node) -> void:
	if not active:
		push_warning("RoundManager: captura fuera de ronda descartada")
		return
	if not is_instance_valid(anomaly):
		push_warning("RoundManager: captura de una anomalía inválida descartada")
		return
	var sid := _spawn_id_of(anomaly)
	if sid == &"":
		push_warning("RoundManager: anomalía sin spawn_id descartada (%s)" % anomaly.name)
		return
	if contained_ids.has(sid) or not _is_live(sid) or _live[sid] != anomaly:
		push_warning("RoundManager: captura de '%s' descartada (repetida o de otro intento)" % sid)
		return

	_live.erase(sid)
	contained_ids.append(sid)
	remaining -= 1
	# Nunca sube el reloj: resta 15 s con mínimo 10 s restantes (interpretación en Riesgos).
	time_left = maxf(time_left - GameConfig.ROUND_TIME_PER_ANOMALY, minf(time_left, GameConfig.ROUND_MIN_TIME_LEFT))
	EventBus.anomalies_remaining_changed.emit(remaining)
	if remaining == 0:
		_win()


func _win() -> void:
	_penalty_in_progress = false
	active = false
	EventBus.round_won.emit(current_round)
	if current_round == ROUNDS.size():
		EventBus.game_won.emit()


## Derrota: corta el reloj, libera las anomalías vivas y avisa. No reinicia la ronda:
## game.gd pide start_round(current_round). El calor y la vida se reinician con round_started y reset_to.
## Decisión de SV (2026-10-10):
##   - &"health" o &"heat" (la papa muere): conserva las anomalías contenidas y el reloj sigue donde iba.
##   - &"time" (reloj agotado): game over definitivo del turno. Borra el progreso y el reintento
##     trae todas las anomalías con el reloj completo.
var _penalty_in_progress: bool = false


func _fail(reason: StringName) -> void:
	if not active:
		return
	active = false
	_free_live()
	if reason == &"time" or reason == &"heat":
		contained_ids.clear()
		_resume_time = -1.0
	else:
		_resume_time = time_left
	EventBus.round_failed.emit(reason)


func _free_live() -> void:
	for node in _live.values():
		if is_instance_valid(node):
			node.queue_free()
	_live.clear()


func _on_heat_maxed() -> void:
	_fail(&"heat")


func _on_player_died() -> void:
	_apply_death_penalty()


func _apply_death_penalty() -> void:
	if not active:
		return
	time_left = maxf(time_left - 15.0, 10.0)
	EventBus.round_timer_changed.emit(time_left)
