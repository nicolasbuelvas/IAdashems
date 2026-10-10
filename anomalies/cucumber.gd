class_name CucumberAnomaly
extends Anomaly

## Anomalía Pepino (Cucumis sativus):
## Evasiva. Huye de la papa a toda costa en el eje X.
## Se frena al 50% al subir/bajar escaleras.
## Si queda arrinconada contra una pared, se frena.
## Captura: Tocarla directamente (inofensiva).

var speed: float = 5.0
var flee_distance: float = 6.0
var stairs_mult: float = 0.5

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 3.5
var _climb_ladder_x: float = 0.0

var _tactical_timer: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		flee_distance = cfg.get("CUCUMBER_FLEE_DISTANCE") if cfg.get("CUCUMBER_FLEE_DISTANCE") != null else flee_distance
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult
	
	# Ajustes según dificultad (1-6)
	if difficulty >= 5:
		speed = 6.0
		flee_distance = 999.0 # Omnisciente: sabe dónde está el jugador en todo momento
	elif difficulty >= 3:
		speed = 5.2
		flee_distance = 12.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	if is_climbing:
		global_position.x = move_toward(global_position.x, _climb_ladder_x, 8.0 * delta)
		global_position.y = move_toward(global_position.y, climb_target_y, climb_speed * delta)
		global_position.z = 0.0
		velocity = Vector3.ZERO
		if is_equal_approx(global_position.y, climb_target_y):
			is_climbing = false
			global_position.x = climb_exit_x
			velocity = Vector3.ZERO
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
	
	var player := get_player_node()
	var move_x := 0.0
	
	if player != null and is_instance_valid(player):
		var diff_x := global_position.x - player.global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		
		# En dificultad avanzada sabe en todo momento dónde está la papa
		var aware_of_player := (difficulty >= 5) or (dist_h < flee_distance and dist_v < 4.0)
		
		if aware_of_player:
			# Estrategia Pac-Man: Buscar bots de apoyo como escudo
			var shield_found := false
			if difficulty >= 4 and dist_v < 2.0:
				var allies := get_allies()
				var best_shield: Anomaly = null
				var min_shield_dist := INF
				for ally in allies:
					# Si el aliado está en el mismo piso
					if absf(ally.global_position.y - global_position.y) < 1.5:
						var d := global_position.distance_to(ally.global_position)
						if d < min_shield_dist and d < 9.0:
							min_shield_dist = d
							best_shield = ally
				
				if best_shield != null:
					shield_found = true
					# Posicionarse detrás del aliado respecto al jugador:
					# Si player está a la izquierda del aliado, pepino se coloca a la derecha del aliado (a ~2.2m)
					var player_to_shield := best_shield.global_position.x - player.global_position.x
					var target_behind_shield_x := best_shield.global_position.x + signf(player_to_shield) * 2.2
					var diff_shield := target_behind_shield_x - global_position.x
					if absf(diff_shield) > 0.3:
						move_x = signf(diff_shield)
					else:
						# Ya está resguardado detrás del escudo
						move_x = 0.0

			if not shield_found:
				# Huida habitual en X
				move_x = signf(diff_x)
				if move_x == 0.0:
					move_x = 1.0
				
				# Táctica avanzada: Si el jugador se acerca mucho en el mismo piso, busca escapar por escalera
				if difficulty >= 3 and dist_h < 4.5 and dist_v < 1.8:
					var ladders := get_tree().get_nodes_in_group("ladder")
					for lad in ladders:
						if lad is Node3D and absf(lad.global_position.y - global_position.y) < 1.5:
							var lad_diff: float = (lad as Node3D).global_position.x - global_position.x
							if absf(lad_diff) < 5.0 and signf(lad_diff) == move_x:
								# Avanza con determinación hacia la escalera
								move_x = signf(lad_diff)
								break
	
	var current_speed := speed * (stairs_mult if in_stairs else 1.0)
	
	# Si está contra la pared en la dirección en la que intenta huir, se frena (queda arrinconado)
	if is_on_wall() and move_x != 0.0:
		var wall_normal := get_wall_normal()
		if signf(wall_normal.x) != signf(move_x):
			move_x = 0.0
	
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 22.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


## Contrato de contacto con el jugador:
func on_player_contact(_player: Node) -> void:
	if not is_contained:
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
