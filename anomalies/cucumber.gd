class_name CucumberAnomaly
extends Anomaly

## Anomalía Pepino (Cucumis sativus):
## Algoritmo de evasión táctica de alta supervivencia:
## - Lectura de proximidad y pisos.
## - Salto evasivo si la papa se desliza con Shift (Dash).
## - Búsqueda activa de escaleras libres para descender.
## - Dispersión espacial para evitar acorralarse juntas.
## - Evasión anticipada de muros (X = ±11.5).

var speed: float = 6.2
var stairs_mult: float = 0.55

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 4.2
var _climb_ladder_x: float = 0.0

var _post_climb_cooldown: float = 0.0
var _patrol_dir: float = 1.0
var _wall_escape_timer: float = 0.0
var _jump_cooldown: float = 0.0
var _alive_time: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult
	speed = maxf(speed, 6.2)
	_patrol_dir = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	_alive_time += delta
	if _jump_cooldown > 0.0:
		_jump_cooldown -= delta
	if _post_climb_cooldown > 0.0:
		_post_climb_cooldown -= delta
	if _wall_escape_timer > 0.0:
		_wall_escape_timer -= delta

	# Estado de escalada vertical (acción bloqueada y no cancelable)
	if is_climbing:
		global_position.x = move_toward(global_position.x, _climb_ladder_x, 10.0 * delta)
		global_position.y = move_toward(global_position.y, climb_target_y, climb_speed * delta)
		global_position.z = 0.0
		velocity = Vector3.ZERO
		if is_equal_approx(global_position.y, climb_target_y):
			is_climbing = false
			global_position.x = climb_exit_x
			velocity = Vector3.ZERO
			_post_climb_cooldown = 2.2
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var player := get_player_node()
	var move_x := 0.0
	
	if player != null and is_instance_valid(player):
		var diff_x := global_position.x - player.global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		var player_is_climbing: bool = bool(player.get("is_climbing") == true)
		var player_is_sliding: bool = bool(player.has_method("is_sliding") and player.call("is_sliding"))
		
		# 1. EVASIÓN DE DASH/SLIDE DEL JUGADOR:
		# Si la papa viene a toda velocidad con slide hacia el pepino, dar salto evasivo por encima
		if player_is_sliding and dist_h < 4.5 and dist_v < 1.6 and is_on_floor() and _jump_cooldown <= 0.0:
			velocity.y = 8.5
			_jump_cooldown = 1.2
			# Al saltar, cambiar el vector para cruzar al lado opuesto
			move_x = -signf(diff_x)
		
		# 2. SI EL JUGADOR ESTÁ EN LA ESCALERA (acción bloqueada):
		elif player_is_climbing:
			var player_target_y: float = float(player.get("climb_target_y") if player.get("climb_target_y") != null else 0.0)
			var target_is_my_floor := absf(global_position.y - player_target_y) < 1.5
			if target_is_my_floor:
				# La papa saldrá en mi piso: alejarse del punto de salida
				move_x = signf(global_position.x - player.global_position.x)
			else:
				move_x = _patrol_dir

		# 3. SI EL JUGADOR ESTÁ EN EL MISMO PISO (< 2.2m vertical):
		elif dist_v < 2.2:
			# Prioridad: Buscar escalera de descenso segura para cambiar de nivel
			var best_ladder: Node3D = null
			var best_ladder_dist := INF
			var ladders := get_tree().get_nodes_in_group("ladder")
			
			for lad in ladders:
				if lad is Node3D:
					var lad_node := lad as Node3D
					var lad_top_y: float = float(lad_node.get("top_y") if lad_node.get("top_y") != null else 0.0)
					var is_descending := absf(global_position.y - lad_top_y) < 1.6
					if is_descending:
						var lad_x := lad_node.global_position.x
						# Comprobar que el jugador no bloquee el paso a esta escalera
						var player_between := (player.global_position.x > minf(global_position.x, lad_x)) and (player.global_position.x < maxf(global_position.x, lad_x))
						var d := absf(lad_x - global_position.x)
						if not player_between and d < best_ladder_dist:
							best_ladder_dist = d
							best_ladder = lad_node
			
			if best_ladder != null and _post_climb_cooldown <= 0.0:
				move_x = signf(best_ladder.global_position.x - global_position.x)
			else:
				# Huida horizontal normal
				move_x = signf(diff_x)
				if move_x == 0.0:
					move_x = 1.0

		# 4. SI EL JUGADOR ESTÁ EN OTRO PISO:
		else:
			# Si está en piso alto, buscar escaleras para descender
			if global_position.y > 0.0 and _post_climb_cooldown <= 0.0:
				var ladders := get_tree().get_nodes_in_group("ladder")
				for lad in ladders:
					if lad is Node3D:
						var lad_top_y: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
						if absf(global_position.y - lad_top_y) < 1.6:
							var lad_x := (lad as Node3D).global_position.x
							if absf(lad_x - global_position.x) < 8.0:
								move_x = signf(lad_x - global_position.x)
								break
			if move_x == 0.0:
				move_x = _patrol_dir
	else:
		move_x = _patrol_dir

	# 5. DISPERSIÓN ENTRE PEPINOS (No apelotonarse en el mismo rincón):
	for ally in get_allies():
		if ally is CucumberAnomaly:
			var d_ally := absf(global_position.x - ally.global_position.x)
			var same_floor := absf(global_position.y - ally.global_position.y) < 1.5
			if same_floor and d_ally < 3.2:
				var repel := signf(global_position.x - ally.global_position.x)
				if repel != 0.0:
					move_x = repel

	# 6. ANTICIPACIÓN DE MUROS (No esperar a chocar con X = ±13):
	if global_position.x > 11.0 and move_x > 0.0:
		move_x = -1.0
		_patrol_dir = -1.0
		_wall_escape_timer = 1.4
	elif global_position.x < -11.0 and move_x < 0.0:
		move_x = 1.0
		_patrol_dir = 1.0
		_wall_escape_timer = 1.4
	elif is_on_wall():
		var wall_norm := get_wall_normal()
		if wall_norm.x != 0.0:
			move_x = signf(wall_norm.x)
			_patrol_dir = move_x
			_wall_escape_timer = 1.2

	var current_speed := speed * (stairs_mult if in_stairs else 1.0)
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 30.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, _patrol_dir * current_speed, 20.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func on_player_contact(_player: Node) -> void:
	if not is_contained:
		print("[Cucumber] Capturado tras sobrevivir %.2f segundos" % _alive_time)
		contain()


func start_climb(target_y: float, exit_x: float, ladder_x: float) -> void:
	if is_climbing or is_contained:
		return
	is_climbing = true
	velocity = Vector3.ZERO
	_climb_ladder_x = ladder_x
	climb_target_y = target_y
	climb_exit_x = exit_x
	global_position.x = ladder_x
	global_position.z = 0.0
