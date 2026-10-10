extends Camera3D
## Cámara fija de lado que sigue al jugador a lo largo de un eje del mundo,
## sin salirse de [min_x, max_x] (medido sobre ese eje).

@export var target: Node3D
@export var follow_axis: Vector3 = Vector3.RIGHT
@export var min_x: float = -5.0
@export var max_x: float = 5.0
@export var smoothing: float = 6.0


func _process(delta: float) -> void:
	if target == null:
		return
	var axis := follow_axis.normalized()
	var current := global_position.dot(axis)
	var goal := clampf(target.global_position.dot(axis), min_x, max_x)
	global_position += axis * (lerpf(current, goal, clampf(smoothing * delta, 0.0, 1.0)) - current)
