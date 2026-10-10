extends Node
## Gestor de audio global (persona D).
##
## Administra música de fondo (BGM) y efectos (SFX).
## Escucha EventBus para sincronizar audio con el estado del juego y
## conecta sonido táctil a todos los botones de la interfaz automáticamente.

const PATH_BGM_MENU := "res://audio/bgm_menu.ogg"
const PATH_BGM_GAMEPLAY := "res://audio/bgm_gameplay.ogg"
const PATH_BGM_HEAT_CRITICAL := "res://audio/bgm_heat_critical.ogg"
const PATH_BGM_VICTORY := "res://audio/bgm_victory.ogg"
const PATH_BGM_GAME_OVER := "res://audio/bgm_game_over.ogg"

const PATH_SFX_UI_HOVER := "res://audio/sfx_ui_hover.ogg"
const PATH_SFX_UI_CLICK := "res://audio/sfx_ui_click.ogg"
const PATH_SFX_UI_PAUSE := "res://audio/sfx_ui_pause.ogg"
const PATH_SFX_UI_ROUND_CARD := "res://audio/sfx_ui_round_card.ogg"
const PATH_SFX_PLAYER_JUMP := "res://audio/sfx_player_jump.ogg"
const PATH_SFX_PLAYER_SLIDE := "res://audio/sfx_player_slide.ogg"
const PATH_SFX_PLAYER_HERBICIDE := "res://audio/sfx_player_herbicide.ogg"
const PATH_SFX_PLAYER_HERBICIDE_READY := "res://audio/sfx_player_herbicide_ready.ogg"
const PATH_SFX_PLAYER_DAMAGE := "res://audio/sfx_player_damage.ogg"
const PATH_SFX_ANOMALY_CONTAINED := "res://audio/sfx_anomaly_contained.ogg"
const PATH_SFX_HEAT_STEAM := "res://audio/sfx_heat_steam.ogg"

var _cache: Dictionary = {}

var _bgm_player: AudioStreamPlayer
var _steam_player: AudioStreamPlayer
var _current_bgm_track: AudioStream = null

var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8
var _sfx_index := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_setup_players()
	_connect_event_bus()
	_hook_existing_buttons(get_tree().root)
	get_tree().node_added.connect(_on_node_added)
	call_deferred(&"_check_initial_scene_music")


func _get_stream(path: String) -> AudioStream:
	if not _cache.has(path):
		if ResourceLoader.exists(path):
			_cache[path] = load(path)
		else:
			_cache[path] = null
	return _cache[path]


func _ensure_buses() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _setup_players() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music"
	_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_bgm_player)

	_steam_player = AudioStreamPlayer.new()
	_steam_player.bus = &"SFX"
	var steam_stream := _get_stream(PATH_SFX_HEAT_STEAM)
	if steam_stream != null:
		_steam_player.stream = steam_stream
	_steam_player.volume_db = -6.0
	_steam_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_steam_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)


func play_bgm(stream_or_path: Variant, restart_if_same: bool = false) -> void:
	var stream: AudioStream = null
	var path: String = ""
	if stream_or_path is String:
		path = stream_or_path
		stream = _get_stream(path)
	elif stream_or_path is AudioStream:
		stream = stream_or_path

	if stream == null:
		_bgm_player.stop()
		_current_bgm_track = null
		return
	if _current_bgm_track == stream and not restart_if_same and _bgm_player.playing:
		return
	_current_bgm_track = stream
	_bgm_player.stream = stream
	_bgm_player.play()


func play_sfx(stream_or_path: Variant, volume_db: float = 0.0) -> void:
	if stream_or_path == null or _sfx_pool.is_empty():
		return
	var stream: AudioStream = null
	if stream_or_path is String:
		stream = _get_stream(stream_or_path)
	elif stream_or_path is AudioStream:
		stream = stream_or_path
	if stream == null:
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _connect_event_bus() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		return

	if bus.has_signal("player_jumped"):
		bus.connect("player_jumped", func(): play_sfx(PATH_SFX_PLAYER_JUMP))
	if bus.has_signal("player_slide_started"):
		bus.connect("player_slide_started", func(): play_sfx(PATH_SFX_PLAYER_SLIDE))
	if bus.has_signal("player_damaged"):
		bus.connect("player_damaged", func(_amount): play_sfx(PATH_SFX_PLAYER_DAMAGE))
	if bus.has_signal("player_died"):
		bus.connect("player_died", func(): play_bgm(PATH_BGM_GAME_OVER, true))
	if bus.has_signal("herbicide_fired"):
		bus.connect("herbicide_fired", func(): play_sfx(PATH_SFX_PLAYER_HERBICIDE))
	if bus.has_signal("herbicide_ready"):
		bus.connect("herbicide_ready", func(): play_sfx(PATH_SFX_PLAYER_HERBICIDE_READY))
	if bus.has_signal("anomaly_contained"):
		bus.connect("anomaly_contained", func(_a): play_sfx(PATH_SFX_ANOMALY_CONTAINED))
	if bus.has_signal("round_started"):
		bus.connect("round_started", func(_r, _rem):
			play_sfx(PATH_SFX_UI_ROUND_CARD)
			play_bgm(PATH_BGM_GAMEPLAY)
		)
	if bus.has_signal("round_won"):
		bus.connect("round_won", func(_r): play_bgm(PATH_BGM_VICTORY, true))
	if bus.has_signal("round_failed"):
		bus.connect("round_failed", func(_reason): play_bgm(PATH_BGM_GAME_OVER, true))
	if bus.has_signal("game_won"):
		bus.connect("game_won", func(): play_bgm(PATH_BGM_VICTORY, true))
	if bus.has_signal("pause_toggled"):
		bus.connect("pause_toggled", func(_p): play_sfx(PATH_SFX_UI_PAUSE))
	if bus.has_signal("heat_changed"):
		bus.connect("heat_changed", _on_heat_changed)


func _on_heat_changed(val: float, max_val: float) -> void:
	var ratio := val / max_val if max_val > 0.0 else 0.0
	if ratio >= 0.70:
		if _current_bgm_track == _get_stream(PATH_BGM_GAMEPLAY):
			play_bgm(PATH_BGM_HEAT_CRITICAL)
		if _steam_player.stream == null:
			_steam_player.stream = _get_stream(PATH_SFX_HEAT_STEAM)
		if _steam_player.stream != null and not _steam_player.playing:
			_steam_player.play()
	else:
		if _current_bgm_track == _get_stream(PATH_BGM_HEAT_CRITICAL):
			play_bgm(PATH_BGM_GAMEPLAY)
		if _steam_player.playing:
			_steam_player.stop()


func _check_initial_scene_music() -> void:
	var current := get_tree().current_scene
	if current != null:
		_on_scene_changed(current)


func _on_scene_changed(scene: Node) -> void:
	var sname := scene.name.to_lower()
	if sname.contains("menu") or sname.contains("options") or sname.contains("intro"):
		play_bgm(PATH_BGM_MENU)
	elif sname.contains("credits") or sname.contains("outro"):
		play_bgm(PATH_BGM_VICTORY)
	elif sname.contains("game") or sname.contains("player"):
		play_bgm(PATH_BGM_GAMEPLAY)


func _on_node_added(node: Node) -> void:
	_hook_existing_buttons(node)
	if node == get_tree().current_scene:
		_on_scene_changed(node)


func _hook_existing_buttons(node: Node) -> void:
	if node is Button:
		_hook_button(node)
	for child in node.get_children():
		_hook_existing_buttons(child)


func _hook_button(button: Button) -> void:
	if button.has_meta(&"audio_hooked"):
		return
	button.set_meta(&"audio_hooked", true)
	button.mouse_entered.connect(_on_button_hover)
	button.pressed.connect(_on_button_click)


func _on_button_hover() -> void:
	play_sfx(PATH_SFX_UI_HOVER, 0.0)


func _on_button_click() -> void:
	play_sfx(PATH_SFX_UI_CLICK, 0.0)
