extends Control
## Menú de pausa (persona D).
##
## Mientras C no tenga GameManager, el menú conmuta la pausa él mismo.
## Cuando EventBus exista con pause_toggled, Esc lo maneja GameManager (C) y
## este menú solo escucha la señal (así no se duplica el toggle).

var _event_bus: Node = null
const OPTIONS_SCENE := preload("res://ui/options_menu.tscn")
var _options_instance: Control = null


func _ready() -> void:
	hide()
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("pause_toggled"):
		_event_bus = bus
		_event_bus.connect("pause_toggled", _on_pause_toggled)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if _options_instance != null and _options_instance.visible:
			_on_options_back()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()


## Pausa/reanuda. Sin EventBus lo hace él mismo; con EventBus emite la señal
## de contrato y aplica el resultado (idempotente, sin importar quién más
## escuche pause_toggled).
func toggle_pause() -> void:
	if _event_bus:
		_event_bus.emit_signal("pause_toggled", not get_tree().paused)
	else:
		_set_paused(not get_tree().paused)


func _on_pause_toggled(paused: bool) -> void:
	_set_paused(paused)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if not paused and _options_instance != null and _options_instance.visible:
		_options_instance.queue_free()
		_options_instance = null
		$Center.show()


func _on_ResumeButton_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("set_paused"):
		gm.set_paused(false)
	elif _event_bus:
		_event_bus.emit_signal("pause_toggled", false)
	else:
		_set_paused(false)


func _on_OptionsButton_pressed() -> void:
	$Center.hide()
	if _options_instance == null:
		_options_instance = OPTIONS_SCENE.instantiate()
		_options_instance.back_requested.connect(_on_options_back)
		add_child(_options_instance)
	_options_instance.show()


func _on_options_back() -> void:
	if _options_instance != null:
		_options_instance.queue_free()
		_options_instance = null
	$Center.show()


func _on_QuitButton_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"menu")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
