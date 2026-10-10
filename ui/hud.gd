extends Control
## HUD renovado (anti-AI-slop, profesional y con iconografía técnica).

const HEAT_HIGH_THRESHOLD := 70.0

@onready var heat_bar = $"TopBar/HeatPanel/HeatRow/HeatBar"
@onready var clock_label = $"TopBar/ClockPanel/ClockLabel"
@onready var anomalies_count = $"TopBar/AnomaliesPanel/AnomaliesRow/AnomaliesCount"
@onready var herbicide_icon = $"BottomBar/HerbicideSlot/HerbicideRow/IconSlot/HerbicideIcon"
@onready var btn_pause = $"TopBar/PausePanel/BtnPause"

@onready var life_icons = [
	$"BottomBar/LivesPanel/LivesRow/Slot1/Life1",
	$"BottomBar/LivesPanel/LivesRow/Slot2/Life2",
	$"BottomBar/LivesPanel/LivesRow/Slot3/Life3",
]

var _shake_tween: Tween


func _ready() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		attach_source(bus)
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_button_pressed)


func attach_source(source: Node) -> void:
	_connect_if_missing(source, &"heat_changed", _on_heat_changed)
	_connect_if_missing(source, &"player_health_changed", _on_player_health_changed)
	_connect_if_missing(source, &"round_timer_changed", _on_round_timer_changed)
	_connect_if_missing(source, &"anomalies_remaining_changed", _on_anomalies_remaining_changed)
	_connect_if_missing(source, &"herbicide_cooldown_changed", _on_herbicide_cooldown_changed)
	_connect_if_missing(source, &"herbicide_ready", _on_herbicide_ready)
	var card = get_node_or_null("RoundCard")
	if card and card.has_method("attach_source"):
		card.attach_source(source)


func _connect_if_missing(source: Node, signal_name: StringName, handler: Callable) -> void:
	if source.has_signal(signal_name) and not source.is_connected(signal_name, handler):
		source.connect(signal_name, handler)


func _on_pause_button_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("set_paused"):
		gm.set_paused(true)
	else:
		var bus := get_node_or_null("/root/EventBus")
		if bus and bus.has_signal("pause_toggled"):
			bus.emit_signal("pause_toggled", true)
		else:
			get_tree().paused = true


func _on_heat_changed(value: float, max_value: float) -> void:
	heat_bar.max_value = max_value
	heat_bar.value = value
	var heat_pct := int((value / max_value) * 100.0) if max_value > 0.0 else 0
	var lbl = get_node_or_null("TopBar/HeatPanel/HeatRow/HeatLabel") as Label
	if lbl:
		lbl.text = "%d%%" % heat_pct
	if value >= HEAT_HIGH_THRESHOLD:
		heat_bar.modulate = Color(1.0, 0.32, 0.22)
	else:
		heat_bar.modulate = Color.WHITE


func _on_player_health_changed(current: int, max_hp: int) -> void:
	for i in range(life_icons.size()):
		life_icons[i].visible = i < current and i < max_hp


func _on_round_timer_changed(seconds_left: float) -> void:
	var total := int(seconds_left)
	clock_label.text = "%02d:%02d" % [total / 60, total % 60]
	if seconds_left < 15.0:
		clock_label.modulate = Color(1.0, 0.35, 0.25)
	else:
		clock_label.modulate = Color.WHITE


func _on_anomalies_remaining_changed(remaining: int) -> void:
	anomalies_count.text = str(remaining)


func _on_herbicide_cooldown_changed(progress: float) -> void:
	herbicide_icon.modulate = Color(1.0, 1.0, 1.0, lerpf(0.3, 1.0, progress))


func _on_herbicide_ready() -> void:
	herbicide_icon.modulate = Color.WHITE
	_shake_icon()


func _shake_icon() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var base: Vector2 = herbicide_icon.position
	_shake_tween = create_tween()
	for i in 4:
		_shake_tween.tween_property(herbicide_icon, "position", base + Vector2(4.0, 0.0), 0.05)
		_shake_tween.tween_property(herbicide_icon, "position", base + Vector2(-4.0, 0.0), 0.05)
	_shake_tween.tween_property(herbicide_icon, "position", base, 0.05)
