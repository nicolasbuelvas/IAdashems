extends Control

@onready var new_game_button: Button = $MenuCard/Menu/NewGameButton
@onready var options_button: Button = $MenuCard/Menu/OptionsButton
@onready var quit_button: Button = $MenuCard/Menu/QuitButton


func _ready() -> void:
	if not new_game_button.pressed.is_connected(_on_NewGameButton_pressed):
		new_game_button.pressed.connect(_on_NewGameButton_pressed)
	if not options_button.pressed.is_connected(_on_OptionsButton_pressed):
		options_button.pressed.connect(_on_OptionsButton_pressed)


func _on_NewGameButton_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"game")
	else:
		get_tree().change_scene_to_file("res://player/test_player.tscn")


func _on_OptionsButton_pressed() -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"options")
	else:
		get_tree().change_scene_to_file("res://ui/options_menu.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()