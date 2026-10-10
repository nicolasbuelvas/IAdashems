extends Control
## Menú de opciones (persona D).
##
## Los buses de audio Music y SFX los crea D en tiempo de ejecución si faltan:
## el layout de audio vive en project.godot, que solo lo edita C.

signal back_requested()

const DB_FLOOR := -80.0  # volumen mínimo de cada bus

@onready var music_slider = $"Center/Card/Rows/MusicRow/MusicSlider"
@onready var sfx_slider = $"Center/Card/Rows/SfxRow/SfxSlider"
@onready var fullscreen_check = $"Center/Card/Rows/FullscreenCheck"
@onready var resolution_option = $"Center/Card/Rows/ResolutionRow/ResolutionOption"


func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music_slider.value = _db_to_value(_get_bus_db("Music"))
	sfx_slider.value = _db_to_value(_get_bus_db("SFX"))
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_populate_resolutions()
	_select_current_resolution()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _get_bus_db(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_db(idx) if idx >= 0 else 0.0


func _set_bus_db(bus_name: String, db: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)


# Slider 0-100 <-> decibelios (100 = 0 dB, sin ganancia; 0 = silencio)
func _db_to_value(db: float) -> float:
	if db <= DB_FLOOR:
		return 0.0
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)


func _value_to_db(value: float) -> float:
	if value <= 0.0:
		return DB_FLOOR
	return maxf(linear_to_db(value / 100.0), DB_FLOOR)


func _populate_resolutions() -> void:
	resolution_option.clear()
	resolution_option.add_item("1920x1080 (Full HD)")
	resolution_option.set_item_metadata(0, Vector2i(1920, 1080))
	resolution_option.add_item("1280x720 (HD)")
	resolution_option.set_item_metadata(1, Vector2i(1280, 720))
	resolution_option.add_item("960x540 (qHD)")
	resolution_option.set_item_metadata(2, Vector2i(960, 540))


func _select_current_resolution() -> void:
	var current_size := DisplayServer.window_get_size()
	for i in range(resolution_option.item_count):
		if resolution_option.get_item_metadata(i) == current_size:
			resolution_option.select(i)
			return
	# Si no se encuentra, se añade la resolución actual al final
	resolution_option.add_item("%dx%d (Actual)" % [current_size.x, current_size.y])
	resolution_option.set_item_metadata(resolution_option.item_count - 1, current_size)
	resolution_option.select(resolution_option.item_count - 1)


func _on_MusicSlider_value_changed(value: float) -> void:
	_set_bus_db("Music", _value_to_db(value))


func _on_SfxSlider_value_changed(value: float) -> void:
	_set_bus_db("SFX", _value_to_db(value))


func _on_FullscreenCheck_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_select_current_resolution()


func _on_ResolutionOption_item_selected(index: int) -> void:
	var target_size: Vector2i = resolution_option.get_item_metadata(index)
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_check.set_pressed_no_signal(false)
	DisplayServer.window_set_size(target_size)
	var screen_size := DisplayServer.screen_get_size()
	DisplayServer.window_set_position((screen_size - target_size) / 2)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_BackButton_pressed()
		get_viewport().set_input_as_handled()


func _on_BackButton_pressed() -> void:
	back_requested.emit()
	if get_tree().current_scene == self:
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.has_method("goto"):
			gm.goto(&"menu")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
