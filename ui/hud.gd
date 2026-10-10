extends Control
## HUD (persona D).
##
## Regla del spec: el HUD solo escucha señales; no lee nodos de otros sistemas.
## EventBus es un autoload de C y todavía está vacío, así que mientras no exista
## el HUD queda mudo (no se conecta a nada). En cuanto aparezca con las señales
## del contrato, se engancha solo desde _ready().

## Debe coincidir con GameConfig.HEAT_HIGH_THRESHOLD (GameConfig es de C y
## todavía no existe, se duplica aquí a propósito para no depender de él).
const HEAT_HIGH_THRESHOLD := 70.0

@onready var heat_bar = $"TopBar/HeatBar"
@onready var clock_label = $"TopBar/ClockLabel"
@onready var life_icons = [
	$"BottomBar/HealthIcons/Life1",
	$"BottomBar/HealthIcons/Life2",
	$"BottomBar/HealthIcons/Life3",
]
@onready var anomalies_label = $"BottomBar/AnomaliesLabel"
@onready var herbicide_icon = $"BottomBar/HerbicideSlot/HerbicideIcon"

var _shake_tween: Tween


func _ready() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		attach_source(bus)


## Conecta las señales del contrato que existan en `source`.
## En producción eso es EventBus; en las pruebas es test_signal_emitter.gd.
func attach_source(source: Node) -> void:
	_connect_if_missing(source, &"heat_changed", _on_heat_changed)
	_connect_if_missing(source, &"player_health_changed", _on_player_health_changed)
	_connect_if_missing(source, &"round_timer_changed", _on_round_timer_changed)
	_connect_if_missing(source, &"anomalies_remaining_changed", _on_anomalies_remaining_changed)
	_connect_if_missing(source, &"herbicide_cooldown_changed", _on_herbicide_cooldown_changed)
	_connect_if_missing(source, &"herbicide_ready", _on_herbicide_ready)
	# La tarjeta de ronda va dentro del HUD y usa el mismo contrato.
	var card = get_node_or_null("RoundCard")
	if card and card.has_method("attach_source"):
		card.attach_source(source)


func _connect_if_missing(source: Node, signal_name: StringName, handler: Callable) -> void:
	if source.has_signal(signal_name) and not source.is_connected(signal_name, handler):
		source.connect(signal_name, handler)


func _on_heat_changed(value: float, max_value: float) -> void:
	heat_bar.max_value = max_value
	heat_bar.value = value
	# La barra cambia de color al pasar el umbral alto.
	heat_bar.modulate = Color(1.0, 0.35, 0.3) if value >= HEAT_HIGH_THRESHOLD else Color.WHITE


func _on_player_health_changed(current: int, max_hp: int) -> void:
	for i in range(life_icons.size()):
		life_icons[i].visible = i < current and i < max_hp


func _on_round_timer_changed(seconds_left: float) -> void:
	var total := int(seconds_left)
	clock_label.text = "%02d:%02d" % [total / 60, total % 60]


func _on_anomalies_remaining_changed(remaining: int) -> void:
	anomalies_label.text = "Anomalías: %d" % remaining


func _on_herbicide_cooldown_changed(progress: float) -> void:
	# progress: 0.0 = recién lanzado, 1.0 = listo. Se va aclarando al recargar.
	herbicide_icon.modulate = Color(1.0, 1.0, 1.0, lerpf(0.3, 1.0, progress))


func _on_herbicide_ready() -> void:
	herbicide_icon.modulate = Color.WHITE
	_shake_icon()


func _shake_icon() -> void:
	# El icono tiembla al quedar listo (GDD 9).
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var base: Vector2 = herbicide_icon.position
	_shake_tween = create_tween()
	for i in 4:
		_shake_tween.tween_property(herbicide_icon, "position", base + Vector2(4.0, 0.0), 0.05)
		_shake_tween.tween_property(herbicide_icon, "position", base + Vector2(-4.0, 0.0), 0.05)
	_shake_tween.tween_property(herbicide_icon, "position", base, 0.05)
