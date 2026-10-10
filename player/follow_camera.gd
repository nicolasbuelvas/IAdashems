extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 6.0
@export var fixed_z := 13.0
@export var y_offset := 1.2
@export var pitch_deg := -6.5
@export var yaw_deg := -3.5
@export var look_ahead_distance := 1.0
@export var look_ahead_speed := 5.0
@export var look_ahead_reference_speed := 11.0
@export var max_bank_deg := 2.0
@export var bank_speed := 3.5

var _target: Node3D
var _look_ahead_x := 0.0
var _bank_deg := 0.0


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_target = players[0] as Node3D
	position.z = fixed_z
	rotation_degrees.x = pitch_deg
	rotation_degrees.y = yaw_deg
	current = true


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
	var desired_bank := -velocity_ratio * max_bank_deg
	var bank_weight := 1.0 - exp(-bank_speed * delta)
	_bank_deg = lerpf(_bank_deg, desired_bank, bank_weight)
	rotation_degrees.z = _bank_deg

	var follow_weight := 1.0 - exp(-follow_speed * delta)
	var focus_x := _target.global_position.x + _look_ahead_x
	global_position.x = lerpf(global_position.x, focus_x, follow_weight)
	global_position.y = lerpf(global_position.y, _target.global_position.y + y_offset, follow_weight)
	global_position.z = fixed_z
