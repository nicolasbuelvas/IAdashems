extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 6.0
@export var fixed_z := 13.0
@export var y_offset := 1.2
@export var pitch_deg := -11.0
@export var yaw_deg := -12.0
@export var look_ahead_distance := 1.0
@export var look_ahead_speed := 5.0
@export var look_ahead_reference_speed := 11.0
@export var heat_shake_max_offset := Vector2(0.045, 0.028)
@export var heat_response_speed := 2.8

const _REFERENCE_PITCH_DEG := -6.5
const _REFERENCE_YAW_DEG := -3.5

var _target: Node3D
var _look_ahead_x := 0.0
var _follow_position := Vector3.ZERO
var _heat_intensity := 0.0
var _heat_target_intensity := 0.0
var _shake_time := 0.0


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
	_follow_position = global_position
	var event_bus := get_node_or_null("/root/EventBus")
	if event_bus != null and event_bus.has_signal("heat_changed"):
		var callback := Callable(self, "_on_heat_changed")
		if not event_bus.is_connected("heat_changed", callback):
			event_bus.connect("heat_changed", callback)
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

	var follow_weight := 1.0 - exp(-follow_speed * delta)
	var focus_x := _target.global_position.x + _look_ahead_x
	# Compensa el cambio angular para que el jugador mantenga el encuadre al revelar profundidad.
	var yaw_frame_offset := fixed_z * (tan(deg_to_rad(-yaw_deg)) - tan(deg_to_rad(-_REFERENCE_YAW_DEG)))
	var pitch_frame_offset := fixed_z * (tan(deg_to_rad(-pitch_deg)) - tan(deg_to_rad(-_REFERENCE_PITCH_DEG)))
	_follow_position.x = lerpf(_follow_position.x, focus_x - yaw_frame_offset, follow_weight)
	_follow_position.y = lerpf(_follow_position.y, _target.global_position.y + y_offset + pitch_frame_offset, follow_weight)
	_follow_position.z = fixed_z
	_heat_intensity = lerpf(_heat_intensity, _heat_target_intensity, 1.0 - exp(-heat_response_speed * delta))
	_shake_time += delta
	var shake := Vector3(
		sin(_shake_time * 17.0) * heat_shake_max_offset.x,
		sin(_shake_time * 23.7 + 1.4) * heat_shake_max_offset.y,
		0.0
	) * _heat_intensity
	global_position = _follow_position + shake


func _on_heat_changed(value: float, max_value: float) -> void:
	var threshold := float(GameConfig.HEAT_HIGH_THRESHOLD)
	if max_value <= threshold:
		_heat_target_intensity = 0.0
		return
	_heat_target_intensity = smoothstep(0.0, 1.0, clampf((value - threshold) / (max_value - threshold), 0.0, 1.0))
