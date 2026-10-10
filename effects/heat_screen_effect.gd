extends CanvasLayer

@export var heat_response_speed := 2.8

@onready var _overlay: ColorRect = $ColorRect

var _heat_intensity := 0.0
var _target_intensity := 0.0


func _ready() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("heat_changed"):
		var callback := Callable(self, "_on_heat_changed")
		if not event_bus.is_connected("heat_changed", callback):
			event_bus.connect("heat_changed", callback)
	_update_target_intensity(0.0, GameConfig.HEAT_MAX, GameConfig.HEAT_HIGH_THRESHOLD)


func _process(delta: float) -> void:
	_heat_intensity = lerpf(_heat_intensity, _target_intensity, 1.0 - exp(-heat_response_speed * delta))
	var material := _overlay.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("heat_intensity", _heat_intensity)


func _on_heat_changed(value: float, max_value: float) -> void:
	_update_target_intensity(value, max_value, GameConfig.HEAT_HIGH_THRESHOLD)


func _update_target_intensity(value: float, max_value: float, threshold: float) -> void:
	if max_value <= threshold:
		_target_intensity = 0.0
		return
	_target_intensity = smoothstep(0.0, 1.0, clampf((value - threshold) / (max_value - threshold), 0.0, 1.0))
