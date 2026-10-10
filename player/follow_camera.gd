extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 6.0
@export var fixed_z := 12.0
## Punto que se mantiene centrado, relativo al origen del jugador (sus pies):
## sube la mira hacia el centro del cuerpo.
@export var target_offset := Vector3(0.0, 1.0, 0.0)
@export var look_ahead_distance := 1.0
@export var look_ahead_speed := 5.0
@export var look_ahead_reference_speed := 11.0

var _target: Node3D
var _look_ahead_x := 0.0


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_target = players[0] as Node3D
	position.z = fixed_z
	current = true
	if is_instance_valid(_target):
		_snap_to_target()


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var target_velocity_x := 0.0
	if _target is CharacterBody3D:
		target_velocity_x = (_target as CharacterBody3D).velocity.x
	var velocity_ratio := clampf(target_velocity_x / look_ahead_reference_speed, -1.0, 1.0)
	var desired_look_ahead := velocity_ratio * look_ahead_distance
	var look_weight := 1.0 - exp(-look_ahead_speed * delta)
	_look_ahead_x = lerpf(_look_ahead_x, desired_look_ahead, look_weight)

	var follow_weight := 1.0 - exp(-follow_speed * delta)
	var focus := _target.global_position + target_offset
	var focus_x := focus.x + _look_ahead_x
	global_position.x = lerpf(global_position.x, focus_x, follow_weight)
	global_position.y = lerpf(global_position.y, focus.y, follow_weight)
	global_position.z = fixed_z


func _snap_to_target() -> void:
	var goal := _target.global_position + target_offset
	global_position = Vector3(goal.x, goal.y, fixed_z)
