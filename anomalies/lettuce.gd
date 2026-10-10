class_name LettuceAnomaly
extends Anomaly

## Anomalía Lechuga (Lactuca sativa):
## Rebota continuamente por el escenario mediante balística y física realista.
## Calcula la relación inversa entre altura y distancia horizontal:
## - Salto largo: Menor altura vertical, gran velocidad horizontal (escapar ante slide lejano).
## - Salto alto: Mayor altura vertical, menor distancia horizontal (esquivar por arriba ante slide cercano).
## Castigo: Si el jugador termina su slide y queda en recuperación, arremete velozmente en picada rasante.
## Captura: Deslizarse con Shift a través de ella.

var base_speed: float = 6.0
var _dir_x: float = 1.0

var _was_player_sliding: bool = false
var _erratic_timer: float = 0.0

const RESTITUTION_CEILING: float = 0.8
const RESTITUTION_WALL: float = 0.85


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		base_speed = cfg.get("LETTUCE_SPEED") if cfg.get("LETTUCE_SPEED") != null else base_speed
	base_speed = maxf(base_speed, 5.5)
	_dir_x = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	var player := get_player_node()
	var player_sliding := false
	if player != null and is_instance_valid(player) and player.has_method("is_sliding"):
		player_sliding = player.call("is_sliding")

	# 1. GRAVEDAD REAL CONTINUA EN EL AIRE:
	if not is_on_floor():
		velocity.y -= _gravity * delta
		# Resistencia aerodinámica suave
		velocity.x = move_toward(velocity.x, _dir_x * 4.0, 1.8 * delta)

	# 2. REBOTE FÍSICO EN TECHO SÓLIDO (NUNCA flotar ni quedarse pegada):
	if is_on_ceiling():
		if velocity.y > 0.0:
			velocity.y = -maxf(absf(velocity.y) * RESTITUTION_CEILING, 3.5)
		if randf() < 0.25:
			_dir_x = 1.0 if randf() > 0.5 else -1.0

	# 3. REBOTE FÍSICO EN PAREDES:
	if is_on_wall():
		var norm := get_wall_normal()
		if norm.x != 0.0:
			_dir_x = signf(norm.x)
			velocity.x = _dir_x * maxf(absf(velocity.x) * RESTITUTION_WALL, 4.5)

	# 4. CÁLCULO BALÍSTICO DE SALTO AL TOCAR EL SUELO:
	if is_on_floor():
		_calculate_ground_bounce(player, player_sliding)

	# Variación errática periódica de dirección horizontal
	_erratic_timer -= delta
	if _erratic_timer <= 0.0:
		_erratic_timer = randf_range(2.0, 4.0)
		if randf() < 0.3:
			_dir_x *= -1.0

	_was_player_sliding = player_sliding

	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func _calculate_ground_bounce(player: Node3D, player_sliding: bool) -> void:
	var launch_vy := 6.2
	var launch_vx := 5.5

	if player != null and is_instance_valid(player):
		var same_floor := absf(player.global_position.y - global_position.y) < 2.0
		var dist_x := absf(player.global_position.x - global_position.x)
		var dir_away := signf(global_position.x - player.global_position.x)
		if dir_away == 0.0:
			dir_away = 1.0

		# CASO 1: Jugador en slide (Shift)
		if same_floor and player_sliding:
			# A) Muy cerca (< 3.8m): SALTO ALTO (gran altura para esquivar por arriba, poca distancia)
			if dist_x < 3.8:
				launch_vy = 8.6
				launch_vx = 3.0
				_dir_x = dir_away

			# B) Distancia media (3.8m a 8.5m): SALTO LARGO (poca altura, gran velocidad horizontal de escape)
			else:
				launch_vy = 4.6
				launch_vx = 9.8
				_dir_x = dir_away

		# CASO 2: Jugador termina o falla el slide (Vulnerabilidad)
		elif same_floor and _was_player_sliding and not player_sliding and dist_x < 7.0:
			# Embestida rasante en picada hacia la papa vulnerable
			var dir_to_player := signf(player.global_position.x - global_position.x)
			if dir_to_player != 0.0:
				_dir_x = dir_to_player
			launch_vy = 4.2
			launch_vx = 8.8

		# CASO 3: Patrulla normal con balance balístico
		else:
			var roll := randf()
			if roll < 0.45:
				# Salto largo estándar
				launch_vy = 5.0
				launch_vx = 7.2
			elif roll < 0.8:
				# Salto equilibrado
				launch_vy = 6.4
				launch_vx = 5.2
			else:
				# Salto alto contemplativo
				launch_vy = 8.2
				launch_vx = 3.2

	else:
		if randf() < 0.5:
			launch_vy = 5.2
			launch_vx = 6.8
		else:
			launch_vy = 7.5
			launch_vx = 3.8

	velocity.y = launch_vy
	velocity.x = _dir_x * launch_vx


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
