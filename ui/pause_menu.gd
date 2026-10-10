extends Control

func _ready():
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Asumiendo "Esc" mapeado a ui_cancel
		toggle_pause()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused

func _on_ResumeButton_pressed():
	toggle_pause()

func _on_OptionsButton_pressed():
	# Reemplazar con GameManager.goto("options_menu") cuando esté implementado
	print("Ir a opciones")
	get_tree().set_input_as_handled()

func _on_QuitButton_pressed():
	# Reemplazar con GameManager.goto("main_menu") cuando esté implementado
	print("Salir al menú principal")
	get_tree().set_input_as_handled()