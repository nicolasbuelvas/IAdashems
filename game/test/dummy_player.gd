extends CharacterBody3D
## Dummy de la papa mientras A no entrega player/player.tscn. Es un cubo con color, sin arte.
## Cumple la interfaz de docs/spec-mvp-reparto.md 2.6 y emite las señales de A (sección 5).
## Sin class_name, para no chocar con Player de A. Solo usa constantes de GameConfig.

var hp: int = GameConfig.PLAYER_MAX_HP

var _facing: float = 1.0
var _iframes_left: float = 0.0
var _slide_left: float = 0.0
var _slide_cooldown_left: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _contact_area: Area3D = $ContactArea


func _ready() -> void:
	_contact_area.body_entered.connect(_on_contact_body_entered)


func _physics_process(delta: float) -> void:
	_iframes_left = maxf(_iframes_left - delta, 0.0)
	_slide_cooldown_left = maxf(_slide_cooldown_left - delta, 0.0)

	var dir := _read_axis()
	if dir != 0.0:
		_facing = signf(dir)

	if _slide_left > 0.0:
		_slide_left -= delta
		if _slide_left <= 0.0:
			_end_slide()
	elif Input.is_physical_key_pressed(KEY_SHIFT) and _slide_cooldown_left <= 0.0:
		_start_slide()

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_physical_key_pressed(KEY_SPACE):
		velocity.y = GameConfig.PLAYER_JUMP_VELOCITY

	if is_sliding():
		velocity.x = _facing * GameConfig.SLIDE_SPEED
	else:
		velocity.x = dir * GameConfig.PLAYER_SPEED
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func take_damage(amount: int) -> void:
	if hp <= 0 or is_invulnerable() or is_sliding():
		return
	hp = maxi(hp - amount, 0)
	_iframes_left = GameConfig.PLAYER_IFRAMES
	EventBus.player_damaged.emit(amount)
	EventBus.player_health_changed.emit(hp, GameConfig.PLAYER_MAX_HP)
	if hp == 0:
		EventBus.player_died.emit()


func is_sliding() -> bool:
	return _slide_left > 0.0


func is_invulnerable() -> bool:
	return _iframes_left > 0.0


func reset_to(spawn: Vector3) -> void:
	hp = GameConfig.PLAYER_MAX_HP
	_iframes_left = 0.0
	_slide_cooldown_left = 0.0
	if is_sliding():
		_slide_left = 0.0
		EventBus.player_slide_ended.emit()
	velocity = Vector3.ZERO
	global_position = spawn
	EventBus.player_health_changed.emit(hp, GameConfig.PLAYER_MAX_HP)


func _read_axis() -> float:
	var axis := Input.get_axis(&"ui_left", &"ui_right")
	if Input.is_physical_key_pressed(KEY_D):
		axis += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		axis -= 1.0
	return clampf(axis, -1.0, 1.0)


func _start_slide() -> void:
	_slide_left = GameConfig.SLIDE_DURATION
	EventBus.player_slide_started.emit()


func _end_slide() -> void:
	_slide_left = 0.0
	_slide_cooldown_left = GameConfig.SLIDE_COOLDOWN
	EventBus.player_slide_ended.emit()


func _on_contact_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"anomaly") and body.has_method(&"on_player_contact"):
		body.call(&"on_player_contact", self)
