extends Control

@onready var new_game_button: Button = $MenuCard/Menu/NewGameButton
@onready var options_button: Button = $MenuCard/Menu/OptionsButton
@onready var quit_button: Button = $MenuCard/Menu/QuitButton

const OPTIONS_SCENE := preload("res://ui/options_menu.tscn")
var _options_instance: Control = null


func _ready() -> void:
	if not new_game_button.pressed.is_connected(_on_NewGameButton_pressed):
		new_game_button.pressed.connect(_on_NewGameButton_pressed)
	if not options_button.pressed.is_connected(_on_OptionsButton_pressed):
		options_button.pressed.connect(_on_OptionsButton_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _options_instance != null and _options_instance.visible:
		_on_options_back()
		get_viewport().set_input_as_handled()


func _on_NewGameButton_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"game")
	else:
		get_tree().change_scene_to_file("res://game/game.tscn")


func _on_OptionsButton_pressed() -> void:
	$MenuCard.hide()
	if _options_instance == null:
		_options_instance = OPTIONS_SCENE.instantiate()
		_options_instance.back_requested.connect(_on_options_back)
		add_child(_options_instance)
	_options_instance.show()


func _on_options_back() -> void:
	if _options_instance != null:
		_options_instance.queue_free()
		_options_instance = null
	$MenuCard.show()


func _on_QuitButton_pressed():
	get_tree().quit()