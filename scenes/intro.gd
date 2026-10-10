extends Control

func _input(event):
	if event.is_pressed():
		# Reemplazar con GameManager.goto("game") cuando esté implementado
		print("Ir al juego")
		get_tree().set_input_as_handled()