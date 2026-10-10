class_name Player
extends CharacterBody3D

## Movimiento 2.5D, vida/iframes y deslizamiento. Balance desde GameConfig
## si el autoload existe; si no, fallbacks del spec.

const _FALLBACK_SPEED := 6.0
const _FALLBACK_JUMP_VELOCITY := 9.0
const _FALLBACK_MAX_HP := 3
const _FALLBACK_IFRAMES := 1.0
const _FALLBACK_SLIDE_DURATION := 0.5
const _FALLBACK_SLIDE_COOLDOWN := 0.6
const _FALLBACK_SLIDE_SPEED := 11.0
const _BLINK_INTERVAL := 0.08
const _SLIDE_ALPHA := 0.4

var move_speed: float = _FALLBACK_SPEED
var jump_velocity: float = _FALLBACK_JUMP_VELOCITY
var max_hp: int = _FALLBACK_MAX_HP
var iframe_duration: float = _FALLBACK_IFRAMES
var slide_duration: float = _FALLBACK_SLIDE_DURATION
var slide_cooldown: float = _FALLBACK_SLIDE_COOLDOWN
var slide_speed: float = _FALLBACK_SLIDE_SPEED

var _hp: int = _FALLBACK_MAX_HP
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_queued: bool = false
var _slide_queued: bool = false
var _facing: float = 1.0
var _slide_dir: float = 1.0
var _slide_time_left: float = 0.0
var _slide_cooldown_left: float = 0.0
var _iframe_left: float = 0.0
var _blink_accum: float = 0.0
var _blink_on: bool = false
var _dead: bool = false
var _visual: GeometryInstance3D


func _ready() -> void:
	add_to_group("player")
	axis_lock_linear_z = true
	floor_constant_speed = true
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(60.0)
	_visual = get_node_or_null("AnimatedSprite3D") as GeometryInstance3D
	if _visual == null:
		_visual = get_node_or_null("MeshInstance3D") as GeometryInstance3D
	_apply_game_config()
	_hp = max_hp
	_apply_visual()
	_emit_bus("player_health_changed", [_hp, max_hp])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			_jump_queued = true
		elif event.physical_keycode == KEY_SHIFT:
			_slide_queued = true


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if _wants_jump() and is_on_floor():
		velocity.y = jump_velocity

	_update_slide(delta)
	_update_iframes(delta)

	var input_x := _horizontal_axis()
	if input_x != 0.0:
		_facing = signf(input_x)

	if is_sliding():
		velocity.x = _slide_dir * slide_speed
	elif input_x != 0.0:
		velocity.x = input_x * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)

	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func take_damage(amount: int) -> void:
	if amount <= 0 or _dead:
		return
	if is_sliding() or is_invulnerable():
		return
	_hp = maxi(_hp - amount, 0)
	_emit_bus("player_damaged", [amount])
	_emit_bus("player_health_changed", [_hp, max_hp])
	_iframe_left = iframe_duration
	_blink_accum = 0.0
	_blink_on = true
	_apply_visual()
	if _hp <= 0:
		_dead = true
		_emit_bus("player_died", [])


func is_sliding() -> bool:
	return _slide_time_left > 0.0


func is_invulnerable() -> bool:
	return _iframe_left > 0.0 or is_sliding()


func reset_to(spawn: Vector3) -> void:
	global_position = spawn
	velocity = Vector3.ZERO
	_hp = max_hp
	_dead = false
	_jump_queued = false
	_slide_queued = false
	_slide_time_left = 0.0
	_slide_cooldown_left = 0.0
	_iframe_left = 0.0
	_blink_on = false
	_blink_accum = 0.0
	_apply_visual()
	_emit_bus("player_health_changed", [_hp, max_hp])


func _update_slide(delta: float) -> void:
	if _slide_queued:
		_slide_queued = false
		_try_start_slide()
	if _slide_time_left > 0.0:
		_slide_time_left -= delta
		if _slide_time_left <= 0.0:
			_slide_time_left = 0.0
			_slide_cooldown_left = slide_cooldown
			_emit_bus("player_slide_ended", [])
			_apply_visual()
	elif _slide_cooldown_left > 0.0:
		_slide_cooldown_left -= delta


func _try_start_slide() -> void:
	if is_sliding() or _slide_cooldown_left > 0.0 or _dead:
		return
	var input_x := _horizontal_axis()
	_slide_dir = signf(input_x) if input_x != 0.0 else _facing
	if _slide_dir == 0.0:
		_slide_dir = 1.0
	_slide_time_left = slide_duration
	_emit_bus("player_slide_started", [])
	_apply_visual()


func _update_iframes(delta: float) -> void:
	if _iframe_left <= 0.0:
		return
	_iframe_left -= delta
	_blink_accum += delta
	if _blink_accum >= _BLINK_INTERVAL:
		_blink_accum = 0.0
		_blink_on = not _blink_on
	if _iframe_left <= 0.0:
		_iframe_left = 0.0
		_blink_on = false
	_apply_visual()


func _apply_visual() -> void:
	if _visual == null:
		return
	var alpha := _SLIDE_ALPHA if is_sliding() else 1.0
	if _blink_on:
		_visual.modulate = Color(1.0, 0.25, 0.25, alpha)
	else:
		_visual.modulate = Color(1.0, 1.0, 1.0, alpha)


func _apply_game_config() -> void:
	var cfg := get_node_or_null("/root/GameConfig")
	if cfg == null:
		return
	move_speed = _cfg_float(cfg, "PLAYER_SPEED", move_speed)
	jump_velocity = _cfg_float(cfg, "PLAYER_JUMP_VELOCITY", jump_velocity)
	max_hp = int(_cfg_float(cfg, "PLAYER_MAX_HP", float(max_hp)))
	iframe_duration = _cfg_float(cfg, "PLAYER_IFRAMES", iframe_duration)
	slide_duration = _cfg_float(cfg, "SLIDE_DURATION", slide_duration)
	slide_cooldown = _cfg_float(cfg, "SLIDE_COOLDOWN", slide_cooldown)
	slide_speed = _cfg_float(cfg, "SLIDE_SPEED", slide_speed)


func _cfg_float(cfg: Node, property: String, fallback: float) -> float:
	var value: Variant = cfg.get(property)
	if value is float or value is int:
		return float(value)
	return fallback


func _emit_bus(signal_name: StringName, args: Array) -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null or not bus.has_signal(signal_name):
		return
	match args.size():
		0:
			bus.emit_signal(signal_name)
		1:
			bus.emit_signal(signal_name, args[0])
		2:
			bus.emit_signal(signal_name, args[0], args[1])
		_:
			bus.callv("emit_signal", [signal_name] + args)


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
