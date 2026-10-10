extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 6.0
@export var fixed_z := 12.0

var _target: Node3D


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			_target = players[0] as Node3D
	position.z = fixed_z
	current = true


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position.x = lerpf(global_position.x, _target.global_position.x, weight)
	global_position.y = lerpf(global_position.y, _target.global_position.y, weight)
	global_position.z = fixed_z
