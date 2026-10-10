extends Control
## HUD renovado anti-AI-slop con iconografía técnica pura.
## Mecánicas principales:
## 1) Temperatura como tensión principal.
## 2) Corazones con silueta de papa y holder negro inferior (apariencia de borde negro).
## 3) Secuencia de revivir: al llegar a 0 vidas, se recuperan 3 corazones a cambio de subida de temperatura (+30%).
## 4) Secuencia de sobrecalentamiento crítico: evaporación secuencial de corazones, fractura de holders y Game Over (3 opciones).

const HEAT_HIGH_THRESHOLD := 70.0
const REVIVE_HEAT_PENALTY := 30.0

signal revive_completed(penalty_amount: float)
signal breakdown_completed()

@onready var heat_bar: ProgressBar = $"TopBar/HeatPanel/HeatRow/HeatBar"
@onready var clock_label: Label = $"TopBar/ClockPanel/ClockLabel"
@onready var anomalies_count: Label = $"TopBar/AnomaliesPanel/AnomaliesRow/AnomaliesCount"
@onready var herbicide_icon: Control = $"BottomBar/HerbicideSlot/HerbicideRow/IconSlot/HerbicideIcon"
@onready var btn_pause: Button = $"TopBar/PausePanel/BtnPause"
@onready var game_over_modal: GameOverModal = get_node_or_null("GameOverModal")

# Corazones superiores (Papa sprite + silueta negra underneath)
@onready var top_holders = [
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot1/Holder1"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot2/Holder2"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot3/Holder3"),
]
@onready var top_cracks = [
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot1/Crack1"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot2/Crack2"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot3/Crack3"),
]
@onready var top_lives = [
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot1/Life1"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot2/Life2"),
	get_node_or_null("TopBar/LivesPanel/LivesRow/Slot3/Life3"),
]

# Nodos de compatibilidad para herramientas de verificación automática
@onready var life_icons = [
	get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot1/Life1"),
	get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot2/Life2"),
	get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot3/Life3"),
]

var _current_hp: int = 3
var _max_hp: int = 3
var _is_reviving: bool = false
var _is_breaking_down: bool = false
var _shake_tween: Tween
var _source_node: Node = null


func _ready() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		attach_source(bus)
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_button_pressed)
	if game_over_modal:
		game_over_modal.retry_pressed.connect(_on_game_over_retry)
		game_over_modal.restart_game_pressed.connect(_on_game_over_restart_game)
		game_over_modal.main_menu_pressed.connect(_on_game_over_main_menu)


func attach_source(source: Node) -> void:
	_source_node = source
	_connect_if_missing(source, &"heat_changed", _on_heat_changed)
	_connect_if_missing(source, &"heat_maxed", _on_heat_maxed)
	_connect_if_missing(source, &"player_health_changed", _on_player_health_changed)
	_connect_if_missing(source, &"player_died", _on_player_died)
	_connect_if_missing(source, &"round_started", _on_round_started)
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
	if gm:
		if gm.state != GameManager.PLAYING and gm.state != GameManager.PAUSED:
			gm.state = GameManager.PLAYING
		gm.set_paused(true)
	else:
		var bus := get_node_or_null("/root/EventBus")
		if bus and bus.has_signal("pause_toggled"):
			bus.emit_signal("pause_toggled", true)
		else:
			get_tree().paused = true


func _on_round_started(_n: int, _rem: int) -> void:
	_is_breaking_down = false
	_is_reviving = false
	if game_over_modal:
		game_over_modal.hide_modal()
	_restore_holders_state()


func _restore_holders_state() -> void:
	for i in range(3):
		if i < top_holders.size() and top_holders[i] != null:
			top_holders[i].visible = true
			top_holders[i].modulate = Color(0.08, 0.08, 0.08, 1.0)
			top_holders[i].scale = Vector2.ONE
		if i < top_cracks.size() and top_cracks[i] != null:
			top_cracks[i].visible = false
			top_cracks[i].modulate.a = 0.0
		if i < top_lives.size() and top_lives[i] != null:
			top_lives[i].visible = true
			top_lives[i].scale = Vector2.ONE
			top_lives[i].modulate = Color.WHITE
		if i < life_icons.size() and life_icons[i] != null:
			life_icons[i].visible = true
	_current_hp = 3


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
	_current_hp = current
	_max_hp = max_hp
	for i in range(top_lives.size()):
		if top_lives[i] != null:
			top_lives[i].visible = (i < current and i < max_hp)
	for i in range(life_icons.size()):
		if life_icons[i] != null:
			life_icons[i].visible = (i < current and i < max_hp)
	
	if current <= 0 and not _is_reviving and not _is_breaking_down:
		call_deferred(&"_play_revive_sequence")


func _on_player_died() -> void:
	if not _is_reviving and not _is_breaking_down:
		call_deferred(&"_play_revive_sequence")


func _play_revive_sequence() -> void:
	if _is_reviving or _is_breaking_down:
		return
	_is_reviving = true

	# Pausa para que se desarrolle la explosión de la papa
	await get_tree().create_timer(0.75).timeout
	if _is_breaking_down or not is_inside_tree():
		_is_reviving = false
		return

	# Secuencia de recuperación de corazones 1 a 1 en sus siluetas negras
	for i in range(3):
		if i < top_lives.size() and top_lives[i] != null:
			var life: Control = top_lives[i]
			life.visible = true
			life.scale = Vector2(0.1, 0.1)
			life.modulate = Color.WHITE
			var tw := create_tween()
			if tw:
				tw.tween_property(life, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(life, "scale", Vector2.ONE, 0.08)
			var audio := get_node_or_null("/root/AudioManager")
			if audio and audio.has_method("play_sfx"):
				audio.call("play_sfx", "res://audio/sfx_ui_hover.ogg")
			await get_tree().create_timer(0.18).timeout

	# Justo al encajar el 3er corazón: vapor alarmante y subida de temperatura
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_heat_steam.ogg")

	_pulse_heat_bar()
	_show_heat_penalty_badge()

	# Incrementar la temperatura en el sistema
	if _source_node and _source_node.has_signal("heat_penalty_requested"):
		_source_node.emit_signal("heat_penalty_requested", REVIVE_HEAT_PENALTY)
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus != _source_node and bus.has_signal("heat_penalty_requested"):
		bus.emit_signal("heat_penalty_requested", REVIVE_HEAT_PENALTY)

	_current_hp = 3
	for i in range(life_icons.size()):
		if life_icons[i] != null:
			life_icons[i].visible = true
	_is_reviving = false
	revive_completed.emit(REVIVE_HEAT_PENALTY)


func _pulse_heat_bar() -> void:
	if heat_bar == null:
		return
	var tw := create_tween()
	tw.tween_property(heat_bar, "modulate", Color(2.5, 0.35, 0.15, 1.0), 0.12)
	tw.tween_property(heat_bar, "modulate", Color.WHITE, 0.5)


func _show_heat_penalty_badge() -> void:
	var badge := Label.new()
	badge.text = "♨ +30%"
	badge.theme_type_variation = "TitleMd"
	badge.add_theme_color_override("font_color", Color(1.0, 0.38, 0.15, 1.0))
	add_child(badge)
	var lives_panel := get_node_or_null("TopBar/LivesPanel") as Control
	if lives_panel:
		badge.global_position = lives_panel.global_position + Vector2(25, -12)
	else:
		badge.global_position = Vector2(420, 35)
	var tw := create_tween()
	tw.parallel().tween_property(badge, "position:y", badge.position.y - 36.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(badge, "modulate:a", 0.0, 0.75)
	tw.tween_callback(badge.queue_free)


func _on_heat_maxed() -> void:
	call_deferred(&"_play_heat_critical_breakdown")


func _play_heat_critical_breakdown() -> void:
	if _is_breaking_down:
		return
	_is_breaking_down = true

	# 1. Perder suavemente los corazones restantes uno por uno de derecha a izquierda
	for i in range(2, -1, -1):
		if i < top_lives.size() and top_lives[i] != null:
			var life: Control = top_lives[i]
			if life.visible and life.scale.x > 0.1:
				var tw := create_tween()
				tw.parallel().tween_property(life, "modulate", Color(2.5, 0.2, 0.15, 1.0), 0.08)
				tw.parallel().tween_property(life, "scale", Vector2.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(life, "modulate:a", 0.0, 0.22)
				var audio := get_node_or_null("/root/AudioManager")
				if audio and audio.has_method("play_sfx"):
					audio.call("play_sfx", "res://audio/sfx_potato_explode.wav")
				await get_tree().create_timer(0.25).timeout
				life.visible = false
				if i < life_icons.size() and life_icons[i] != null:
					life_icons[i].visible = false

	# 2. Romper los HOLDERS (fractura con grietas y estallido)
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_comic_explosion.wav")

	# Mostrar grietas rojas/blancas sobre las siluetas
	for i in range(3):
		if i < top_cracks.size() and top_cracks[i] != null:
			top_cracks[i].visible = true
			top_cracks[i].modulate = Color(2.2, 1.0, 1.0, 1.0)

	var lives_row := get_node_or_null("TopBar/LivesPanel/LivesRow") as Control
	if lives_row:
		var base_x := lives_row.position.x
		var tw_shake := create_tween()
		for k in 6:
			tw_shake.tween_property(lives_row, "position:x", base_x + randf_range(-7.0, 7.0), 0.04)
		tw_shake.tween_property(lives_row, "position:x", base_x, 0.04)
		await tw_shake.finished

	# Desvanecer y romper los holders
	for i in range(3):
		if i < top_holders.size() and top_holders[i] != null:
			var holder: Control = top_holders[i]
			var tw_break := create_tween()
			tw_break.parallel().tween_property(holder, "scale", Vector2.ZERO, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tw_break.parallel().tween_property(holder, "modulate:a", 0.0, 0.24)
	await get_tree().create_timer(0.3).timeout

	# 3. Eliminar a la papa definitivamente y mostrar pantalla GameOver
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("kill"):
		player.call("kill")

	await get_tree().create_timer(1.3).timeout
	if game_over_modal:
		game_over_modal.show_modal()
	breakdown_completed.emit()


func _on_game_over_retry() -> void:
	_restore_holders_state()
	var arena := get_tree().current_scene
	if arena and arena.has_method("_on_btn_retry_pressed"):
		arena.call("_on_btn_retry_pressed")
	elif arena and arena.has_method("_respawn_simulation"):
		arena.call("_respawn_simulation")
	else:
		var gm := get_node_or_null("/root/GameManager")
		var rm := get_tree().get_first_node_in_group("round_manager")
		if rm == null:
			rm = get_node_or_null("/root/Game/RoundManager")
		if rm and gm:
			rm.call("start_round", gm.current_round)
		else:
			get_tree().reload_current_scene()


func _on_game_over_restart_game() -> void:
	_restore_holders_state()
	var arena := get_tree().current_scene
	if arena and arena.has_method("_on_btn_restart_game_pressed"):
		arena.call("_on_btn_restart_game_pressed")
	else:
		var gm := get_node_or_null("/root/GameManager")
		if gm:
			gm.current_round = 1
		var rm := get_tree().get_first_node_in_group("round_manager")
		if rm == null:
			rm = get_node_or_null("/root/Game/RoundManager")
		if rm:
			rm.call("start_round", 1)
		else:
			get_tree().reload_current_scene()


func _on_game_over_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_round_timer_changed(seconds_left: float) -> void:
	var total := int(seconds_left)
	clock_label.text = "%02d:%02d" % [total / 60, total % 60]


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
