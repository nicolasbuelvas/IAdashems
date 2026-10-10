extends Control
## HUD renovado (anti-AI-slop, profesional y con iconografía técnica).

signal retry_requested
signal restart_game_requested
signal main_menu_requested

const HEAT_HIGH_THRESHOLD := 70.0

@onready var heat_bar = $"TopBar/HeatPanel/HeatRow/HeatBar"
@onready var clock_label = $"TopBar/ClockPanel/ClockLabel"
@onready var anomalies_count = $"TopBar/AnomaliesPanel/AnomaliesRow/AnomaliesCount"
@onready var herbicide_icon = $"BottomBar/HerbicideSlot/HerbicideRow/IconSlot/HerbicideIcon"
@onready var btn_pause = $"TopBar/PausePanel/BtnPause"

@onready var dash_icon = get_node_or_null("BottomBar/DashSlot/DashRow/DashIcon") as Label
@onready var dash_badge = get_node_or_null("BottomBar/DashSlot/DashRow/DashStateBadge") as Label
@onready var game_over_modal = get_node_or_null("GameOverUI") as CanvasLayer

var _dash_ready: bool = true
var _dash_speed_reached: bool = false

@onready var life_icons = [
	$"BottomBar/LivesPanel/LivesRow/Slot1/Life1",
	$"BottomBar/LivesPanel/LivesRow/Slot2/Life2",
	$"BottomBar/LivesPanel/LivesRow/Slot3/Life3",
]

var _shake_tween: Tween
var _banner_tween: Tween
var _draining_hearts: bool = false


func _ready() -> void:
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		attach_source(bus)
	if btn_pause:
		btn_pause.pressed.connect(_on_pause_button_pressed)
	
	var btn_ret = get_node_or_null("GameOverUI/Center/Card/Rows/BtnRetry") as Button
	if btn_ret:
		btn_ret.pressed.connect(_on_btn_retry_pressed)
	var btn_res = get_node_or_null("GameOverUI/Center/Card/Rows/BtnRestartGame") as Button
	if btn_res:
		btn_res.pressed.connect(_on_btn_restart_game_pressed)
	var btn_menu = get_node_or_null("GameOverUI/Center/Card/Rows/BtnMainMenu") as Button
	if btn_menu:
		btn_menu.pressed.connect(_on_btn_main_menu_pressed)

	_update_dash_ui()


func attach_source(source: Node) -> void:
	_connect_if_missing(source, &"heat_changed", _on_heat_changed)
	_connect_if_missing(source, &"heat_maxed", _on_heat_maxed)
	_connect_if_missing(source, &"lives_sacrificed_for_heat", _on_lives_sacrificed_for_heat)
	_connect_if_missing(source, &"holders_shattered", _on_holders_shattered)
	_connect_if_missing(source, &"player_health_changed", _on_player_health_changed)
	_connect_if_missing(source, &"round_timer_changed", _on_round_timer_changed)
	_connect_if_missing(source, &"anomalies_remaining_changed", _on_anomalies_remaining_changed)
	_connect_if_missing(source, &"herbicide_cooldown_changed", _on_herbicide_cooldown_changed)
	_connect_if_missing(source, &"herbicide_ready", _on_herbicide_ready)
	_connect_if_missing(source, &"dash_cooldown_changed", _on_dash_cooldown_changed)
	_connect_if_missing(source, &"dash_speed_threshold_changed", _on_dash_speed_threshold_changed)
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
	if _draining_hearts:
		return
	for i in range(life_icons.size()):
		var active: bool = (i < current and i < max_hp)
		life_icons[i].visible = active
	if current > 0:
		_reset_holders()


func _on_lives_sacrificed_for_heat(_heat_added: float) -> void:
	_reset_holders()
	
	# 1. Recuperar los 3 corazones de papa uno a uno con rebote elástico
	for i in range(life_icons.size()):
		life_icons[i].visible = true
		life_icons[i].modulate = Color.WHITE
		life_icons[i].scale = Vector2(0.1, 0.1)
		var pt = create_tween()
		pt.tween_interval(i * 0.12)
		pt.tween_property(life_icons[i], "scale", Vector2(1.25, 1.25), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pt.tween_property(life_icons[i], "scale", Vector2.ONE, 0.08)
	
	# 2. Orden lógico: una vez aterrizan las vidas, suena el vapor y sube el calor
	await get_tree().create_timer(0.42).timeout
	
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_heat_steam.ogg")
	
	# Icono flotante minimalista: ♨ +30%
	var banner = get_node_or_null("SacrificeBanner")
	var lbl = get_node_or_null("SacrificeBanner/BannerLabel") as Label
	if banner and lbl:
		lbl.text = "♨  +30%"
		if _banner_tween and _banner_tween.is_valid():
			_banner_tween.kill()
		_banner_tween = create_tween()
		banner.modulate.a = 0.0
		banner.position.y = 86.0
		_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
		_banner_tween.parallel().tween_property(banner, "position:y", 68.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_banner_tween.tween_interval(1.2)
		_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.3)
	
	# Pulso y destello intenso en el medidor de temperatura
	var hp = get_node_or_null("TopBar/HeatPanel")
	if hp:
		var ht = create_tween()
		ht.tween_property(hp, "modulate", Color(2.5, 0.6, 0.2, 1.0), 0.14)
		ht.tween_property(hp, "modulate", Color.WHITE, 0.35)


func _on_heat_maxed() -> void:
	if _draining_hearts:
		return
	_draining_hearts = true
	# Pérdida suave una por una de derecha a izquierda si aún tiene vidas
	for i in range(life_icons.size() - 1, -1, -1):
		if life_icons[i].visible:
			var dt = create_tween()
			dt.tween_property(life_icons[i], "modulate", Color(2.5, 0.2, 0.1, 1.0), 0.14)
			dt.tween_property(life_icons[i], "scale", Vector2(0.1, 0.1), 0.16)
			var audio = get_node_or_null("/root/AudioManager")
			if audio and audio.has_method("play_sfx"):
				audio.call("play_sfx", "res://audio/sfx_potato_explode.wav")
			await get_tree().create_timer(0.28).timeout
			life_icons[i].visible = false
			life_icons[i].scale = Vector2.ONE
	
	# Rotura física de los holders
	_shatter_holders()
	_draining_hearts = false


func _shatter_holders() -> void:
	for i in range(1, 4):
		var crack = get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot%d/Cracked%d" % [i, i])
		if crack:
			crack.visible = true
	var audio = get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_holder_crack.wav")
	
	var lp = get_node_or_null("BottomBar/LivesPanel")
	if lp:
		var st = create_tween()
		var base_x: float = lp.position.x
		for k in 6:
			st.tween_property(lp, "position:x", base_x + randf_range(-6.0, 6.0), 0.04)
		st.tween_property(lp, "position:x", base_x, 0.04)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("holders_shattered"):
		bus.emit_signal("holders_shattered")
	
	# Forzar muerte de la papa para detonar la explosión en papas fritas
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("kill"):
			p.call("kill")
	
	# Sonar tema de Game Over y desplegar el modal tras delay
	if audio and audio.has_method("play_music"):
		audio.call("play_music", "res://audio/bgm_game_over.ogg")
	
	await get_tree().create_timer(1.2).timeout
	if game_over_modal:
		game_over_modal.visible = true
		get_tree().paused = true


func _on_holders_shattered() -> void:
	for i in range(1, 4):
		var crack = get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot%d/Cracked%d" % [i, i])
		if crack:
			crack.visible = true


func _reset_holders() -> void:
	for i in range(1, 4):
		var crack = get_node_or_null("BottomBar/LivesPanel/LivesRow/Slot%d/Cracked%d" % [i, i])
		if crack:
			crack.visible = false
	for icon in life_icons:
		icon.modulate = Color.WHITE
		icon.scale = Vector2.ONE


func _on_btn_retry_pressed() -> void:
	if game_over_modal:
		game_over_modal.visible = false
	get_tree().paused = false
	_reset_holders()
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.state == GameManager.PAUSED:
		gm.state = GameManager.PLAYING
	retry_requested.emit()


func _on_btn_restart_game_pressed() -> void:
	if game_over_modal:
		game_over_modal.visible = false
	get_tree().paused = false
	_reset_holders()
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		gm.current_round = 1
		gm.state = GameManager.PLAYING
	restart_game_requested.emit()


func _on_btn_main_menu_pressed() -> void:
	if game_over_modal:
		game_over_modal.visible = false
	get_tree().paused = false
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"menu")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	main_menu_requested.emit()


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


func _on_dash_cooldown_changed(progress: float) -> void:
	if progress < 1.0:
		_dash_ready = false
		if dash_icon:
			dash_icon.modulate = Color(1.0, 1.0, 1.0, lerpf(0.25, 0.6, progress))
		if dash_badge:
			dash_badge.text = "%d%%" % int(progress * 100.0)
			dash_badge.modulate = Color(0.65, 0.6, 0.55, 0.7)
	else:
		_dash_ready = true
		_update_dash_ui()


func _on_dash_speed_threshold_changed(speed_reached: bool) -> void:
	_dash_speed_reached = speed_reached
	_update_dash_ui()


func _update_dash_ui() -> void:
	if not _dash_ready:
		return
	if _dash_speed_reached:
		if dash_icon:
			dash_icon.modulate = Color(1.0, 0.92, 0.22, 1.0)
		if dash_badge:
			dash_badge.text = "¡LISTO!"
			dash_badge.modulate = Color(0.96, 0.85, 0.22, 1.0)
	else:
		if dash_icon:
			dash_icon.modulate = Color(0.85, 0.72, 0.45, 0.7)
		if dash_badge:
			dash_badge.text = "CORRE"
			dash_badge.modulate = Color(0.75, 0.68, 0.55, 0.7)
