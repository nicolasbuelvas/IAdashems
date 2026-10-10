class_name Player
extends CharacterBody3D

## Movimiento 2.5D, vida/iframes y deslizamiento. Balance desde GameConfig
## si el autoload existe; si no, fallbacks del spec.

const _FALLBACK_SPEED := 8.0
const _FALLBACK_JUMP_VELOCITY := 9.0
const _FALLBACK_MAX_HP := 3
const _FALLBACK_IFRAMES := 1.0
const _FALLBACK_SLIDE_DURATION := 0.65
const _FALLBACK_SLIDE_COOLDOWN := 0.6
const _FALLBACK_SLIDE_SPEED := 11.0
const _GROUND_ACCELERATION := 15.0
const _AIR_ACCELERATION := 14.0
const _TURNAROUND_ACCELERATION := 30.0
const _AIR_TURNAROUND_ACCELERATION := 26.0
const _GROUND_DECELERATION := 22.0
const _AIR_DECELERATION := 10.0
const _PLAYER_GRAVITY_SCALE := 2.25
const _FALL_GRAVITY_MULTIPLIER := 1.35
const _JUMP_RELEASE_GRAVITY_MULTIPLIER := 1.6
const _JUMP_APEX_GRAVITY_MULTIPLIER := 0.72
const _JUMP_APEX_VELOCITY_RATIO := 0.25
const _DASH_MIN_SPEED_RATIO := 0.72
const _DASH_CARRY_DURATION := 0.55
const _DASH_BRAKING := 9.0
const _DASH_STOP_SPEED := 0.2
const _DASH_RECOVERY_DURATION := 1.0
const _DASH_RECOVERY_SPEED_RATIO := 0.55
const _DASH_CARRY_DECELERATION := 10.0
const _DASH_EXIT_SPEED_RATIO := 0.9
const _FALLBACK_HERBICIDE_SPEED := 14.0
const _FALLBACK_HERBICIDE_COOLDOWN := 5.0
const _HERBICIDE_SCENE: PackedScene = preload("res://player/herbicide.tscn")
const _BLINK_INTERVAL := 0.08
const _SLIDE_ALPHA := 0.4
const _DASH_VISUAL_OFFSET_Y := 0.18
const HEAT_HIGH_THRESHOLD := 70.0

var move_speed: float = _FALLBACK_SPEED
var jump_velocity: float = _FALLBACK_JUMP_VELOCITY
var max_hp: int = _FALLBACK_MAX_HP
var iframe_duration: float = _FALLBACK_IFRAMES
var slide_duration: float = _FALLBACK_SLIDE_DURATION
var slide_cooldown: float = _FALLBACK_SLIDE_COOLDOWN
var slide_speed: float = _FALLBACK_SLIDE_SPEED
var herbicide_speed: float = _FALLBACK_HERBICIDE_SPEED
var herbicide_cooldown: float = _FALLBACK_HERBICIDE_COOLDOWN

var _hp: int = _FALLBACK_MAX_HP
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _jump_queued: bool = false
var _jump_started_this_frame: bool = false
var _herbicide_queued: bool = false
var _slide_queued: bool = false
var _facing: float = 1.0
var _slide_dir: float = 1.0
var _dash_active: bool = false
var _dash_recovery_left: float = 0.0
var _slide_time_left: float = 0.0
var _slide_cooldown_left: float = 0.0
var _dash_carry_time_left: float = 0.0
var _dash_carry_speed: float = 0.0
var _dash_carry_direction: float = 0.0
var _herbicide_cooldown_left: float = 0.0
var _last_aim_direction := Vector2.RIGHT
var _iframe_left: float = 0.0
var _blink_accum: float = 0.0
var _blink_on: bool = false
var _dead: bool = false
var _visual: GeometryInstance3D
var _visual_base_scale := Vector3.ONE
var _visual_tween: Tween
var _animated_sprite: AnimatedSprite3D
var _sprite_base_y := 0.0
var _heat_active := false


func _ready() -> void:
	add_to_group("player")
	axis_lock_linear_z = true
	floor_constant_speed = true
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(60.0)
	_animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	_visual = _animated_sprite
	if _animated_sprite != null:
		_sprite_base_y = _animated_sprite.position.y
	if _visual == null:
		_visual = get_node_or_null("MeshInstance3D") as GeometryInstance3D
	if _visual != null:
		_visual_base_scale = _visual.scale
	_apply_game_config()
	_hp = max_hp
	_apply_visual()
	_emit_bus("player_health_changed", [_hp, max_hp])
	_connect_heat_changed()
	_update_animation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE:
			_jump_queued = true
		elif event.physical_keycode == KEY_SHIFT:
			_slide_queued = true
		elif event.physical_keycode == KEY_E:
			_herbicide_queued = true


func _physics_process(delta: float) -> void:
	_jump_started_this_frame = false
	if _dash_recovery_left > 0.0:
		_dash_recovery_left = maxf(_dash_recovery_left - delta, 0.0)
	if not is_on_floor():
		var gravity_multiplier := 1.0
		if velocity.y < 0.0:
			gravity_multiplier = _FALL_GRAVITY_MULTIPLIER
		elif not Input.is_physical_key_pressed(KEY_SPACE):
			gravity_multiplier = _JUMP_RELEASE_GRAVITY_MULTIPLIER
		elif velocity.y < jump_velocity * _JUMP_APEX_VELOCITY_RATIO:
			gravity_multiplier = _JUMP_APEX_GRAVITY_MULTIPLIER
		velocity.y -= _gravity * _PLAYER_GRAVITY_SCALE * gravity_multiplier * delta

	if _wants_jump() and is_on_floor():
		velocity.y = jump_velocity
		_emit_bus("player_jumped", [])
		_jump_started_this_frame = true
		_animate_motion_feedback(Vector3(0.92, 1.14, 1.0))

	_update_slide(delta)
	_update_iframes(delta)
	_update_herbicide_cooldown(delta)
	_update_aim_direction()
	if _herbicide_queued:
		_herbicide_queued = false
		_fire_herbicide()

	var input_x := _horizontal_axis()
	if not is_sliding() and input_x != 0.0 and (is_zero_approx(velocity.x) or signf(velocity.x) == signf(input_x)):
		_facing = signf(input_x)

	if is_sliding():
		if _slide_time_left > 0.0:
			var slide_progress := 1.0 - _slide_time_left / slide_duration
			var deceleration := smoothstep(0.7, 1.0, slide_progress)
			var dash_exit_speed := maxf(move_speed, slide_speed * _DASH_EXIT_SPEED_RATIO)
			var current_slide_speed := lerpf(slide_speed, dash_exit_speed, deceleration)
			velocity.x = _slide_dir * current_slide_speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, _DASH_BRAKING * delta)
	elif _dash_recovery_left > 0.0:
		var recovery_speed := move_speed * _DASH_RECOVERY_SPEED_RATIO
		if input_x != 0.0:
			var acceleration := _GROUND_ACCELERATION if is_on_floor() else _AIR_ACCELERATION
			velocity.x = move_toward(velocity.x, input_x * recovery_speed, acceleration * delta)
		else:
			var deceleration := _GROUND_DECELERATION if is_on_floor() else _AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
	elif _dash_carry_time_left > 0.0:
		var carry_ratio := _dash_carry_time_left / _DASH_CARRY_DURATION
		if input_x == _dash_carry_direction:
			var carry_speed := lerpf(move_speed, _dash_carry_speed, carry_ratio)
			velocity.x = _dash_carry_direction * carry_speed
		elif input_x == 0.0:
			velocity.x = move_toward(velocity.x, 0.0, _DASH_CARRY_DECELERATION * delta)
		else:
			var turnaround_acceleration := _TURNAROUND_ACCELERATION if is_on_floor() else _AIR_TURNAROUND_ACCELERATION
			velocity.x = move_toward(velocity.x, input_x * move_speed, turnaround_acceleration * delta)
		_dash_carry_time_left = maxf(_dash_carry_time_left - delta, 0.0)
	elif input_x != 0.0:
		var acceleration := _GROUND_ACCELERATION if is_on_floor() else _AIR_ACCELERATION
		if velocity.x * input_x < 0.0:
			acceleration = _TURNAROUND_ACCELERATION
		velocity.x = move_toward(velocity.x, input_x * move_speed, acceleration * delta)
	else:
		var deceleration := _GROUND_DECELERATION if is_on_floor() else _AIR_DECELERATION
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	velocity.z = 0.0
	var was_on_floor := is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		_animate_motion_feedback(Vector3(1.12, 0.86, 1.0))
	global_position.z = 0.0
	_update_animation()


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
	return _dash_active


func is_invulnerable() -> bool:
	return _iframe_left > 0.0 or is_sliding()


func reset_to(spawn: Vector3) -> void:
	global_position = spawn
	velocity = Vector3.ZERO
	_hp = max_hp
	_dead = false
	_jump_queued = false
	_jump_started_this_frame = false
	_slide_queued = false
	_herbicide_queued = false
	_slide_time_left = 0.0
	_slide_cooldown_left = 0.0
	_dash_active = false
	_dash_recovery_left = 0.0
	_dash_carry_time_left = 0.0
	_dash_carry_speed = 0.0
	_dash_carry_direction = 0.0
	_herbicide_cooldown_left = 0.0
	_iframe_left = 0.0
	_blink_on = false
	_blink_accum = 0.0
	_apply_visual()
	_emit_bus("player_health_changed", [_hp, max_hp])


func _update_slide(delta: float) -> void:
	if _slide_queued:
		_slide_queued = false
		_try_start_slide()
	if _jump_started_this_frame and is_sliding():
		# El salto cancela el dash y conserva su impulso para el control aéreo.
		_finish_slide(true)
	if is_sliding():
		if _slide_time_left > 0.0:
			_slide_time_left = maxf(_slide_time_left - delta, 0.0)
		if _slide_time_left <= 0.0 and absf(velocity.x) <= _DASH_STOP_SPEED:
			velocity.x = 0.0
			_finish_slide(false)
	elif _slide_cooldown_left > 0.0:
		_slide_cooldown_left -= delta


func _finish_slide(cancelled_by_jump: bool) -> void:
	_slide_time_left = 0.0
	_dash_active = false
	_slide_cooldown_left = slide_cooldown
	if cancelled_by_jump:
		_dash_carry_direction = _slide_dir
		_dash_carry_speed = maxf(absf(velocity.x), move_speed)
		_dash_carry_time_left = _DASH_CARRY_DURATION
	else:
		_dash_carry_time_left = 0.0
		_dash_recovery_left = _DASH_RECOVERY_DURATION
		velocity.x = 0.0
	_emit_bus("player_slide_ended", [])
	_apply_visual()


func _try_start_slide() -> void:
	if is_sliding() or _slide_cooldown_left > 0.0 or _dash_recovery_left > 0.0 or _dead:
		return
	if not is_on_floor() or _jump_started_this_frame:
		return
	var input_x := _horizontal_axis()
	_slide_dir = signf(input_x) if input_x != 0.0 else _facing
	if _slide_dir == 0.0:
		_slide_dir = 1.0
	var minimum_dash_speed := move_speed * _DASH_MIN_SPEED_RATIO
	if velocity.x * _slide_dir < minimum_dash_speed:
		return
	_dash_active = true
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


func _animate_motion_feedback(target_scale: Vector3) -> void:
	if _visual == null:
		return
	if _visual_tween != null and _visual_tween.is_running():
		_visual_tween.kill()
	_visual.scale = _visual_base_scale * target_scale
	_visual_tween = create_tween()
	_visual_tween.tween_property(_visual, "scale", _visual_base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_visual() -> void:
	if _visual == null:
		return
	var alpha := _SLIDE_ALPHA if is_sliding() else 1.0
	if _blink_on:
		_visual.modulate = Color(1.0, 0.25, 0.25, alpha)
	elif _heat_active:
		_visual.modulate = Color(1.0, 0.48, 0.2, alpha)
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
	herbicide_speed = _cfg_float(cfg, "HERBICIDE_SPEED", herbicide_speed)
	herbicide_cooldown = _cfg_float(cfg, "HERBICIDE_COOLDOWN", herbicide_cooldown)


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


func _update_aim_direction() -> void:
	var aim_x := _horizontal_axis()
	if aim_x != 0.0:
		_last_aim_direction = Vector2(signf(aim_x), 0.0)


func _fire_herbicide() -> void:
	if _dead or _herbicide_cooldown_left > 0.0:
		return
	if is_sliding() or not is_on_floor() or _jump_started_this_frame:
		return
	var projectile := _HERBICIDE_SCENE.instantiate() as Area3D
	if projectile == null:
		return
	projectile.set("direction", Vector3(_last_aim_direction.x, _last_aim_direction.y, 0.0))
	projectile.set("speed", herbicide_speed)
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(projectile)
	projectile.global_position = global_position + Vector3(0.0, 0.9, 0.0) + projectile.direction * 0.55
	_herbicide_cooldown_left = herbicide_cooldown
	_emit_bus("herbicide_fired", [])
	_emit_bus("herbicide_cooldown_changed", [0.0])


func _update_herbicide_cooldown(delta: float) -> void:
	if _herbicide_cooldown_left <= 0.0:
		return
	_herbicide_cooldown_left = maxf(_herbicide_cooldown_left - delta, 0.0)
	var progress := 1.0 - _herbicide_cooldown_left / herbicide_cooldown
	_emit_bus("herbicide_cooldown_changed", [clampf(progress, 0.0, 1.0)])
	if _herbicide_cooldown_left == 0.0:
		_emit_bus("herbicide_ready", [])


func _on_contact_area_body_entered(body: Node3D) -> void:
	_try_player_contact(body)


func _on_contact_area_area_entered(area: Area3D) -> void:
	_try_player_contact(area)


func _try_player_contact(anomaly: Node) -> void:
	if anomaly.is_in_group("anomaly") and anomaly.has_method("on_player_contact"):
		anomaly.call("on_player_contact", self)


func _connect_heat_changed() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus == null:
		var scene_root := get_tree().current_scene
		if scene_root != null:
			bus = scene_root.find_child("EventBus", true, false)
	if bus != null and bus.has_signal("heat_changed"):
		var callback := Callable(self, "_on_heat_changed")
		if not bus.is_connected("heat_changed", callback):
			bus.connect("heat_changed", callback)


func _on_heat_changed(value: float, _max_value: float) -> void:
	_heat_active = value >= HEAT_HIGH_THRESHOLD
	_apply_visual()


func _update_animation() -> void:
	if _animated_sprite == null:
		return
	_animated_sprite.flip_h = _facing < 0.0
	if is_sliding():
		_animated_sprite.position.y = _sprite_base_y - _DASH_VISUAL_OFFSET_Y
		if _animated_sprite.animation != &"dash" or not _animated_sprite.is_playing():
			_animated_sprite.play(&"dash")
	elif is_on_floor() and absf(velocity.x) > 0.1:
		_animated_sprite.position.y = _sprite_base_y
		if _animated_sprite.animation != &"correr" or not _animated_sprite.is_playing():
			_animated_sprite.play(&"correr")
	else:
		_animated_sprite.position.y = _sprite_base_y
		if _animated_sprite.animation != &"correr" or _animated_sprite.is_playing() or _animated_sprite.frame != 5:
			_animated_sprite.animation = &"correr"
			_animated_sprite.stop()
			_animated_sprite.frame = 5
			_animated_sprite.frame_progress = 0.0
