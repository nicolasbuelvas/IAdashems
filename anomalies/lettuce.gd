class_name LettuceAnomaly
extends Anomaly

## Anomalía Lechuga (Lactuca sativa):
## Rebota continuamente por el escenario.
## Causa daño al contacto, EXCEPTO cuando la papa se desliza con Shift.
## Captura: Deslizarse a través de ella.

var speed: float = 4.0
var _dir_x: float = 1.0
var bounce_force_y: float = 6.2
var _was_player_sliding: bool = false
var _erratic_timer: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("LETTUCE_SPEED") if cfg.get("LETTUCE_SPEED") != null else speed
	_dir_x = 1.0 if (randf() > 0.5) else -1.0
	
	if difficulty >= 5:
		speed = 5.4
		bounce_force_y = 7.5
	elif difficulty >= 3:
		speed = 4.6
		bounce_force_y = 6.8


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	var player := get_player_node()
	var player_sliding := false
	if player != null and is_instance_valid(player) and player.has_method("is_sliding"):
		player_sliding = player.call("is_sliding")
	
	# Gravedad estándar si no está rebotando en el techo
	velocity.y -= _gravity * delta
	
	# REBOTE EN TECHO (Dificultad >= 3):
	if is_on_ceiling() and difficulty >= 3:
		# Rebota hacia abajo con fuerza y ángulo impredecible
		velocity.y = -absf(bounce_force_y)
		if difficulty >= 4:
			_dir_x = 1.0 if randf() > 0.5 else -1.0
			
	# REBOTE EN SUELO:
	if is_on_floor():
		if difficulty >= 3:
			velocity.y = bounce_force_y * (1.0 + randf_range(-0.15, 0.15))
		else:
			# Dificultad básica: pequeños saltos en el suelo
			velocity.y = 3.5

	# REBOTE EN PAREDES:
	if is_on_wall():
		var norm := get_wall_normal()
		if norm.x != 0.0:
			_dir_x = signf(norm.x)
			# En dificultad media-alta añade variación errática de velocidad
			if difficulty >= 4:
				velocity.y += randf_range(-1.5, 2.5)

	# ESTRATEGIA CONTRA EL SLIDE DEL JUGADOR (Dificultad >= 4):
	if player != null and is_instance_valid(player):
		var dist_to_player := global_position.distance_to(player.global_position)
		
		# 1. Si el jugador hace slide hacia la lechuga, la lechuga salta hacia el techo para esquivarlo
		if player_sliding and dist_to_player < 5.0 and difficulty >= 4:
			velocity.y = bounce_force_y * 1.3
		
		# 2. Si el jugador falló o acaba de terminar el slide, abalanzarse hacia él (castigo de fallo)
		if _was_player_sliding and not player_sliding and dist_to_player < 6.0 and difficulty >= 4:
			var attack_dir_x := signf(player.global_position.x - global_position.x)
			if attack_dir_x != 0.0:
				_dir_x = attack_dir_x
			velocity.y = -3.0 # Picada hacia la papa vulnerable

	_was_player_sliding = player_sliding

	# Rebote de izquierda a derecha menos predecible (Dificultad >= 5):
	_erratic_timer -= delta
	if _erratic_timer <= 0.0 and difficulty >= 5:
		_erratic_timer = randf_range(1.5, 3.0)
		if randf() < 0.4:
			_dir_x *= -1.0 # Cambio súbito de dirección en el aire

	velocity.x = _dir_x * speed
	velocity.z = 0.0
	
	move_and_slide()
	global_position.z = 0.0


## Contrato de contacto con el jugador:
func on_player_contact(player_node: Node) -> void:
	if is_contained or player_node == null:
		return
		
	# Si la papa se está deslizando (Dash / Shift), la lechuga queda contenida
	var sliding := false
	if player_node.has_method("is_sliding"):
		sliding = player_node.call("is_sliding")
		
	if sliding:
		contain()
	else:
		if player_node.has_method("take_damage"):
			player_node.call("take_damage", 1)
