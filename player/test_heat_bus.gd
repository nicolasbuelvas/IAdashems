extends Node

signal heat_changed(value: float, max_value: float)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		heat_changed.emit(80.0, 100.0)
		print("Test EventBus: heat_changed(80, 100)")
