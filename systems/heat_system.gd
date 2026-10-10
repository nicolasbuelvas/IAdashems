# systems/heat_system.gd
# Persona C. Calor de la papa (0 a HEAT_MAX). Nodo de escena, no autoload.
# Todos los valores de balance salen de GameConfig.
#
# Conteo de anomalías activas:
#   - _active_ids guarda el instance_id de cada anomalía spawneada en el intento actual.
#   - anomaly_spawned añade el id (si ya estaba, no hace nada).
#   - anomaly_contained quita el id. Solo si estaba en el conjunto da enfriamiento,
#     así una captura no se cuenta ni enfría dos veces.
#   - tree_exiting de cada anomalía quita su id si sale del árbol sin captura (reload).
#   - round_started vacía el conjunto: el reintento empieza en 0 y solo cuenta lo que se spawnee después.
#   - active_anomalies siempre es _active_ids.size().
class_name HeatSystem
extends Node

var heat: float = 0.0
var active: bool = false
var active_anomalies: int = 0
var timer_expired: bool = false
var pending_cool: float = 0.0
var maxed_emitted: bool = false

# instance_id (int) -> true. Conjunto de anomalías vivas contadas en este intento.
var _active_ids: Dictionary = {}


func _ready() -> void:
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_won.connect(_on_round_won)
	EventBus.round_failed.connect(_on_round_failed)
	EventBus.anomaly_spawned.connect(_on_anomaly_spawned)
	EventBus.anomaly_contained.connect(_on_anomaly_contained)
	EventBus.round_timer_expired.connect(_on_round_timer_expired)
	EventBus.player_damaged.connect(_on_player_damaged)
	if EventBus.has_signal("heat_penalty_requested"):
		EventBus.heat_penalty_requested.connect(_on_heat_penalty_requested)


func _process(delta: float) -> void:
	if not active:
		return

	var rate: float = GameConfig.HEAT_PER_SEC_TIME + float(active_anomalies) * GameConfig.HEAT_PER_SEC_PER_ANOMALY
	if timer_expired:
		rate *= GameConfig.HEAT_EXPIRED_MULTIPLIER

	heat += rate * delta

	var cool: float = minf(pending_cool, GameConfig.HEAT_COOL_RATE * delta)
	heat -= cool
	pending_cool -= cool

	_publish()


# Método público de debug. Lo usa la escena de prueba de c-integracion (tecla de debug).
func debug_add_heat(amount: float) -> void:
	if not active:
		push_warning("HeatSystem: debug_add_heat ignorado, no hay ronda activa.")
		return
	heat += amount
	_publish()


# Clamp, emisión de heat_changed y heat_maxed una sola vez por intento.
func _publish() -> void:
	heat = clampf(heat, 0.0, GameConfig.HEAT_MAX)
	EventBus.heat_changed.emit(heat, GameConfig.HEAT_MAX)
	if heat >= GameConfig.HEAT_MAX and not maxed_emitted:
		maxed_emitted = true
		EventBus.heat_maxed.emit()


func _sync_count() -> void:
	active_anomalies = _active_ids.size()


func _on_round_started(_round_number: int, _remaining: int) -> void:
	active = true
	heat = 0.0
	timer_expired = false
	pending_cool = 0.0
	maxed_emitted = false
	_active_ids.clear()
	_sync_count()
	EventBus.heat_changed.emit(0.0, GameConfig.HEAT_MAX)


func _on_round_won(_round_number: int) -> void:
	active = false


func _on_round_failed(_reason: StringName) -> void:
	active = false


func _on_round_timer_expired() -> void:
	timer_expired = true


func _on_player_damaged(_amount: int) -> void:
	if not active:
		return
	heat += GameConfig.HEAT_PER_HIT
	_publish()


func _on_heat_penalty_requested(amount: float) -> void:
	if not active:
		return
	heat += amount
	_publish()


func _on_anomaly_spawned(anomaly: Node) -> void:
	if not is_instance_valid(anomaly):
		return
	var id: int = anomaly.get_instance_id()
	if _active_ids.has(id):
		return
	_active_ids[id] = true
	anomaly.tree_exiting.connect(_on_anomaly_exiting.bind(id))
	_sync_count()


func _on_anomaly_contained(anomaly: Node) -> void:
	if not is_instance_valid(anomaly):
		return
	var id: int = anomaly.get_instance_id()
	if not _active_ids.erase(id):
		push_warning("HeatSystem: anomaly_contained de una anomalía no contada en este intento (duplicada o sin spawn). Se ignora.")
		return
	pending_cool += GameConfig.HEAT_COOL_PER_CONTAIN
	_sync_count()


func _on_anomaly_exiting(instance_id: int) -> void:
	_active_ids.erase(instance_id)
	_sync_count()
