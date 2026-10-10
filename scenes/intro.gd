extends Control

@onready var continue_hint = $"Center/Rows/ContinueHint"


func _process(_delta: float) -> void:
	# La pista late suavemente para invitar a continuar.
	continue_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 320.0)


func _input(event):
	if event.is_pressed():
		# Pendiente: GameManager.goto(&"game") — GameManager es de C y está vacío.
		print("Ir al juego")
		get_tree().set_input_as_handled()
