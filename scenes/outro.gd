extends Control

## Tiempo mínimo en pantalla antes de aceptar una tecla: evita que la tecla con la que se capturó
## la última anomalía (o una que siga sostenida) salte el outro sin leerlo.
const MIN_SHOW_TIME := 1.0

@onready var continue_hint = $"Center/Rows/ContinueHint"

var _shown_for: float = 0.0
var _leaving: bool = false


func _process(delta: float) -> void:
	_shown_for += delta
	continue_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 320.0)


func _input(event: InputEvent) -> void:
	if _leaving or _shown_for < MIN_SHOW_TIME or not _is_fresh_press(event):
		return
	_leaving = true
	# Antes del cambio de escena: después, este nodo ya no está en el árbol y get_viewport() es null.
	get_viewport().set_input_as_handled()
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("goto"):
		gm.goto(&"credits")
	else:
		get_tree().change_scene_to_file("res://scenes/credits.tscn")


## Solo cuenta una pulsación nueva de tecla, botón del ratón o mando (no eco ni movimiento del ratón).
func _is_fresh_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	return (event is InputEventMouseButton or event is InputEventJoypadButton) and event.pressed
