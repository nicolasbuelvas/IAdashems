extends Control

func _input(event):
	if event.is_pressed():
		# Reemplazar con GameManager.goto("credits") cuando esté implementado
		print("Ir a créditos")
		get_tree().set_input_as_handled()
