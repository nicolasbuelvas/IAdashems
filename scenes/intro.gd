extends Control

@onready var continue_hint = $"Center/Rows/ContinueHint"

var _accum: float = 0.0


func _process(delta: float) -> void:
	_accum += delta
	continue_hint.modulate.a = 0.55 + 0.45 * sin(_accum * 6.0)


func _input(event):
	if event.is_pressed():
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.has_method("goto"):
			gm.goto(&"game")
		else:
			get_tree().change_scene_to_file("res://player/test_player.tscn")
		get_tree().set_input_as_handled()
