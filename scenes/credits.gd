extends Control

func _on_BackButton_pressed():
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"menu")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
