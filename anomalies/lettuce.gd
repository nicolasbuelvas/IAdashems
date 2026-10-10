class_name LettuceAnomaly
extends Anomaly

## Anomalía Lechuga (Lactuca sativa):
## Rebota continuamente por el escenario en 2D (suelo y techo).
## Siempre en máxima condición: esquiva slides saltando al techo y castiga al terminar el dash.
## Causa daño al contacto, EXCEPTO cuando la papa se desliza con Shift.
## Captura: Deslizarse a través de ella.

var speed: float = 5.2
var _dir_x: float = 1.0
var bounce_force_y: float = 7.2
var _was_player_sliding: bool = false
var _erratic_timer: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("LETTUCE_SPEED") if cfg.get("LETTUCE_SPEED") != null else speed
	speed = maxf(speed, 5.0)
	_dir_x = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	var player := get_player_node()
	var player_sliding := false
	if player != null and is_instance_valid(player) and player.has_method("is_sliding"):
		player_sliding = player.call("is_sliding")
	
	velocity.y -= _gravity * delta
	
	# REBOTE EN TECHO SÓLIDO:
	if is_on_ceiling():
		velocity.y = -absf(bounce_force_y)
		if randf() < 0.35:
			_dir_x = 1.0 if randf() > 0.5 else -1.0
			
	# REBOTE EN SUELO:
	if is_on_floor():
		velocity.y = bounce_force_y * (1.0 + randf_range(-0.1, 0.1))

	# REBOTE EN PAREDES:
	if is_on_wall():
		var norm := get_wall_normal()
		if norm.x != 0.0:
			_dir_x = signf(norm.x)
			velocity.y += randf_range(-1.0, 2.0)

	# ESTRATEGIA CONTRA EL SLIDE DEL JUGADOR:
	if player != null and is_instance_valid(player):
		var dist_to_player := global_position.distance_to(player.global_position)
		
		# 1. Si el jugador hace slide hacia la lechuga, esquivar saltando al techo
		if player_sliding and dist_to_player < 5.0:
			velocity.y = bounce_force_y * 1.35
		
		# 2. Si el jugador acaba de fallar/terminar el slide, picada hacia la papa vulnerable
		if _was_player_sliding and not player_sliding and dist_to_player < 6.5:
			var attack_dir_x := signf(player.global_position.x - global_position.x)
			if attack_dir_x != 0.0:
				_dir_x = attack_dir_x
			velocity.y = -4.0

	_was_player_sliding = player_sliding

	# Rebote horizontal errático e impredecible:
	_erratic_timer -= delta
	if _erratic_timer <= 0.0:
		_erratic_timer = randf_range(1.8, 3.5)
		if randf() < 0.35:
			_dir_x *= -1.0

	velocity.x = _dir_x * speed
	velocity.z = 0.0
	
	move_and_slide()
	global_position.z = 0.0


## Contrato de contacto con el jugador:
func on_player_contact(player_node: Node) -> void:
	if is_contained or player_node == null:
		return
		
	var sliding := false
	if player_node.has_method("is_sliding"):
		sliding = player_node.call("is_sliding")
		
	if sliding:
		contain()
	else:
		if player_node.has_method("take_damage"):
			player_node.call("take_damage", 1)
