extends Control

## Tiempo mínimo en pantalla antes de aceptar una tecla: evita que el clic o Enter de "Nueva partida" salte la intro.
const MIN_SHOW_TIME := 0.5

@onready var continue_hint = $"Center/Rows/ContinueHint"

var _accum: float = 0.0
var _leaving: bool = false


func _process(delta: float) -> void:
	_accum += delta
	continue_hint.modulate.a = 0.55 + 0.45 * sin(_accum * 6.0)


func _input(event: InputEvent) -> void:
	if _leaving or _accum < MIN_SHOW_TIME or not _is_fresh_press(event):
		return
	_leaving = true
	# Antes del cambio de escena: después, este nodo ya no está en el árbol y get_viewport() es null.
	get_viewport().set_input_as_handled()
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"game")
	else:
		get_tree().change_scene_to_file("res://game/game.tscn")


## Solo cuenta una pulsación nueva de tecla, botón del ratón o mando (no eco ni movimiento del ratón).
func _is_fresh_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	return (event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed
