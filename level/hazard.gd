# level/hazard.gd
# Area3D de peligro del escenario. Persona C (c-nivel). Spec 2.5 (capa 7, grupo hazard).
# Capa 7 (hazard) y mascara capa 2 (player) se fijan en cada escena de level/ y level/hazards/.
#
# Modos:
#   STATIC  : siempre dania (pinchos / grapas).
#   CYCLE   : WARN (aviso) -> ON (dania) -> OFF, en bucle (vapor, cable pelado).
#   PATROL  : siempre dania y se mueve de ida y vuelta en X (silla rodante).
#   TRIGGER : un Area3D hijo "Trigger" detecta a la papa -> WARN -> ON -> OFF (rearme). Plafon suelto.
#
# Nodos visuales opcionales (por nombre): "Warn" se ve en WARN, "On" se ve en ON, "Off" se ve fuera de ON.
# "Dropper" (TRIGGER) solo se ve en ON: cae desde drop_height hasta 0 y vuelve arriba al salir.
#
# Dano: mientras la papa este dentro y la trampa en ON, intenta un golpe de GameConfig.HAZARD_DAMAGE
# en cada tick. La papa filtra sus iframes en take_damage. Si hurts_while_sliding es false, el slide
# protege (GDD 8). Si es true (trampas aereas), el golpe atraviesa el slide.
#
# Escalado por ronda: escucha EventBus.round_started. Antes de active_from_round la trampa
# se oculta y no dania. tempo_by_round[n - 1] divide los tiempos del ciclo y multiplica la velocidad de patrulla.
class_name Hazard
extends Area3D

enum Mode { STATIC, CYCLE, PATROL, TRIGGER }
enum State { OFF, WARN, ON }

@export var mode: Mode = Mode.STATIC
## Primera ronda en la que la trampa existe. Antes se oculta y no dania.
@export_range(1, 6) var active_from_round: int = 1
## Si es true, el golpe atraviesa el slide (vapor, plafones). Los pinchos del suelo lo dejan en false.
@export var hurts_while_sliding: bool = false

@export_group("Ciclo")
@export var cycle_on: float = 1.2
@export var cycle_off: float = 2.0
@export var warn_time: float = 0.6
## Desfase inicial del ciclo, en segundos, para que dos trampas iguales no vayan sincronizadas.
@export var phase_offset: float = 0.0
## Multiplicador de ritmo por ronda (indice = ronda - 1). Vacio o sin indice = 1.0.
@export var tempo_by_round: PackedFloat32Array = PackedFloat32Array()

@export_group("Patrulla")
## Distancia a cada lado del punto inicial (PATROL).
@export var patrol_distance: float = 3.0
@export var patrol_speed: float = 2.0

@export_group("Caida")
## Altura desde la que cae "Dropper" (TRIGGER).
@export var drop_height: float = 3.0

var state: State = State.OFF
var enabled: bool = true

var _round: int = 1
var _state_left: float = 0.0
var _origin_x: float = 0.0
var _patrol_dir: float = 1.0
## Cuerpos de la papa que estan dentro del area.
var _inside: Array[Node] = []


func _ready() -> void:
	add_to_group(&"hazard")
	_origin_x = position.x
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var trigger := get_node_or_null(^"Trigger") as Area3D
	if trigger != null:
		trigger.body_entered.connect(_on_trigger_body_entered)
	var bus := get_node_or_null(^"/root/EventBus")
	if bus != null and bus.has_signal(&"round_started"):
		bus.connect(&"round_started", _on_round_started)
	_apply_round()


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_update_state(delta)
	if mode == Mode.PATROL:
		_update_patrol(delta)
	if state != State.ON:
		return
	for body in _inside.duplicate():
		if not is_instance_valid(body):
			_inside.erase(body)
			continue
		_try_hit(body)


## Ritmo de la ronda actual (1.0 si no hay dato).
func get_tempo() -> float:
	if _round - 1 < tempo_by_round.size() and tempo_by_round[_round - 1] > 0.0:
		return tempo_by_round[_round - 1]
	return 1.0


func _on_round_started(round_number: int, _remaining: int) -> void:
	_round = round_number
	_apply_round()


## Activa u oculta la trampa segun la ronda y reinicia su ciclo.
func _apply_round() -> void:
	enabled = _round >= active_from_round
	visible = enabled
	set_deferred(&"monitoring", enabled)
	position.x = _origin_x
	_patrol_dir = 1.0
	match mode:
		Mode.STATIC, Mode.PATROL:
			_set_state(State.ON)
		Mode.CYCLE:
			_set_state(State.OFF)
			_state_left = phase_offset / get_tempo()
		Mode.TRIGGER:
			_set_state(State.OFF)
			_state_left = 0.0


func _update_state(delta: float) -> void:
	if mode == Mode.STATIC or mode == Mode.PATROL:
		return
	if _state_left > 0.0:
		_state_left -= delta
		if _state_left > 0.0:
			return
	var tempo := get_tempo()
	match state:
		State.OFF:
			# TRIGGER espera a la papa; CYCLE avisa en cuanto termina el OFF.
			if mode == Mode.CYCLE:
				_set_state(State.WARN)
				_state_left = warn_time
		State.WARN:
			_set_state(State.ON)
			_state_left = cycle_on / tempo
		State.ON:
			_set_state(State.OFF)
			_state_left = cycle_off / tempo


func _update_patrol(delta: float) -> void:
	position.x += _patrol_dir * patrol_speed * get_tempo() * delta
	if position.x >= _origin_x + patrol_distance:
		position.x = _origin_x + patrol_distance
		_patrol_dir = -1.0
	elif position.x <= _origin_x - patrol_distance:
		position.x = _origin_x - patrol_distance
		_patrol_dir = 1.0


func _set_state(new_state: State) -> void:
	state = new_state
	var warn := get_node_or_null(^"Warn") as Node3D
	if warn != null:
		warn.visible = new_state == State.WARN
	var on := get_node_or_null(^"On") as Node3D
	if on != null:
		on.visible = new_state == State.ON
	var off := get_node_or_null(^"Off") as Node3D
	if off != null:
		off.visible = new_state != State.ON
	var dropper := get_node_or_null(^"Dropper") as Node3D
	if dropper != null:
		dropper.visible = new_state == State.ON
		if new_state == State.ON:
			dropper.position.y = drop_height
			create_tween().tween_property(dropper, ^"position:y", 0.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		else:
			dropper.position.y = drop_height


func _on_trigger_body_entered(body: Node) -> void:
	if not enabled or mode != Mode.TRIGGER or state != State.OFF or _state_left > 0.0:
		return
	if _is_player(body):
		_set_state(State.WARN)
		_state_left = warn_time


func _on_body_entered(body: Node) -> void:
	if _is_player(body) and not _inside.has(body):
		_inside.append(body)


func _on_body_exited(body: Node) -> void:
	_inside.erase(body)


## La papa decide si el golpe entra (iframes). Aqui solo se filtra el slide para las trampas de suelo.
func _try_hit(body: Node) -> void:
	if not hurts_while_sliding:
		if body.has_method(&"is_invulnerable") and body.is_invulnerable():
			return
		if body.has_method(&"is_sliding") and body.is_sliding():
			return
		body.take_damage(GameConfig.HAZARD_DAMAGE)
		return
	if Callable(body, &"take_damage").get_argument_count() >= 2:
		body.take_damage(GameConfig.HAZARD_DAMAGE, true)
	elif not (body.has_method(&"is_invulnerable") and body.is_invulnerable()):
		body.take_damage(GameConfig.HAZARD_DAMAGE)


func _is_player(body: Node) -> bool:
	return body.is_in_group(&"player") and body.has_method(&"take_damage")
