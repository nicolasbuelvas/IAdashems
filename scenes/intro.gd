extends Control

@onready var continue_hint = $"Center/Rows/ContinueHint"


func _process(_delta: float) -> void:
	# La pista late suavemente para invitar a continuar.
	continue_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 320.0)


func _input(event):
	if event.is_pressed():
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.has_method("goto"):
			gm.goto(&"game")
		else:
			get_tree().change_scene_to_file("res://player/test_player.tscn")
		get_tree().set_input_as_handled()
