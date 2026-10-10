extends Control
## Menú de pausa (persona D).
##
## Mientras C no tenga GameManager, el menú conmuta la pausa él mismo.
## Cuando EventBus exista con pause_toggled, Esc lo maneja GameManager (C) y
## este menú solo escucha la señal (así no se duplica el toggle).

var _event_bus: Node = null


func _ready() -> void:
	hide()
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("pause_toggled"):
		_event_bus = bus
		_event_bus.connect("pause_toggled", _on_pause_toggled)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


## Pausa/reanuda. Sin EventBus lo hace él mismo; con EventBus emite la señal
## de contrato y aplica el resultado (idempotente, sin importar quién más
## escuche pause_toggled).
func toggle_pause() -> void:
	if _event_bus:
		_event_bus.emit_signal("pause_toggled", not get_tree().paused)
	else:
		_set_paused(not get_tree().paused)


func _on_pause_toggled(paused: bool) -> void:
	_set_paused(paused)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused


func _on_ResumeButton_pressed() -> void:
	if _event_bus:
		_event_bus.emit_signal("pause_toggled", false)
	else:
		_set_paused(false)


func _on_OptionsButton_pressed() -> void:
	# Pendiente: GameManager.goto(&"options") — GameManager es de C y está vacío.
	print("Ir a opciones")


func _on_QuitButton_pressed() -> void:
	# Pendiente: GameManager.goto(&"menu") — GameManager es de C y está vacío.
	print("Salir al menú principal")
