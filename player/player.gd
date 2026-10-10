class_name Player
extends CharacterBody3D

## Movimiento 2.5D (X/Y) de la papa. Velocidad y salto salen de GameConfig
## si el autoload existe; si no, se usan los fallbacks del spec.

const _FALLBACK_SPEED := 6.0
const _FALLBACK_JUMP_VELOCITY := 9.0

var move_speed: float = _FALLBACK_SPEED
var jump_velocity: float = _FALLBACK_JUMP_VELOCITY

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_queued: bool = false


func _ready() -> void:
	add_to_group("player")
	axis_lock_linear_z = true
	floor_constant_speed = true
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(60.0)
	_apply_game_config()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		if event.pressed and not event.echo:
			_jump_queued = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _wants_jump() and is_on_floor():
		velocity.y = jump_velocity

	var input_x := _horizontal_axis()
	if input_x != 0.0:
		velocity.x = input_x * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)

	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func _apply_game_config() -> void:
	var cfg := get_node_or_null("/root/GameConfig")
	if cfg == null:
		return
	var speed: Variant = cfg.get("PLAYER_SPEED")
	if speed is float or speed is int:
		move_speed = float(speed)
	var jump: Variant = cfg.get("PLAYER_JUMP_VELOCITY")
	if jump is float or jump is int:
		jump_velocity = float(jump)


func _horizontal_axis() -> float:
	var axis := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		axis -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		axis += 1.0
	return axis


func _wants_jump() -> bool:
	if _jump_queued:
		_jump_queued = false
		return true
	return false
