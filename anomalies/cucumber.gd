class_name CucumberAnomaly
extends Anomaly

## Anomalía Pepino (Cucumis sativus):
## Evasiva y altamente táctica (Pac-Man AI).
## Sabe que subir/bajar escaleras es una acción no cancelable.
## Busca activamente escaleras para descender, usa escudos y se dispersa para no acorralarse.
## Captura: Tocarla directamente (inofensiva).

var speed: float = 6.0
var stairs_mult: float = 0.5

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 4.0
var _climb_ladder_x: float = 0.0

var _post_climb_cooldown: float = 0.0
var _patrol_dir: float = 1.0
var _wall_escape_timer: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult
	speed = maxf(speed, 6.0)
	_patrol_dir = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	# Animación y traslación vertical no cancelable
	if is_climbing:
		global_position.x = move_toward(global_position.x, _climb_ladder_x, 10.0 * delta)
		global_position.y = move_toward(global_position.y, climb_target_y, climb_speed * delta)
		global_position.z = 0.0
		velocity = Vector3.ZERO
		if is_equal_approx(global_position.y, climb_target_y):
			is_climbing = false
			global_position.x = climb_exit_x
			velocity = Vector3.ZERO
			_post_climb_cooldown = 2.0
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	if _post_climb_cooldown > 0.0:
		_post_climb_cooldown -= delta
	if _wall_escape_timer > 0.0:
		_wall_escape_timer -= delta

	var player := get_player_node()
	var move_x := 0.0
	
	if player != null and is_instance_valid(player):
		var diff_x := global_position.x - player.global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		var player_is_climbing: bool = bool(player.get("is_climbing") == true)
		
		# SI EL JUGADOR ESTÁ EN LA ESCALERA (acción bloqueada):
		if player_is_climbing:
			# El jugador no se puede mover ni cancelar. Alejarse de su destino
			var player_target_y: float = float(player.get("climb_target_y") if player.get("climb_target_y") != null else 0.0)
			var target_is_my_floor := absf(global_position.y - player_target_y) < 1.5
			if target_is_my_floor:
				# La papa va a emerger en mi piso: alejarse hacia el extremo opuesto
				move_x = signf(global_position.x - player.global_position.x)
			else:
				move_x = _patrol_dir
				
		# SI EL JUGADOR ESTÁ EN EL MISMO PISO (< 2.2m vertical):
		elif dist_v < 2.2:
			# 1. TÁCTICA DE ESCUDO HUMANO (Buscar aliada Lechuga o Guisante):
			var shield_found := false
			var allies := get_allies()
			var best_shield: Anomaly = null
			var min_s_dist := INF
			for ally in allies:
				if (ally is LettuceAnomaly or ally is PeaAnomaly) and absf(ally.global_position.y - global_position.y) < 1.5:
					var d := global_position.distance_to(ally.global_position)
					if d < min_s_dist and d < 9.0:
						min_s_dist = d
						best_shield = ally
						
			if best_shield != null:
				shield_found = true
				var p_to_shield := best_shield.global_position.x - player.global_position.x
				var target_x := best_shield.global_position.x + signf(p_to_shield) * 2.2
				var diff_s := target_x - global_position.x
				move_x = signf(diff_s) if absf(diff_s) > 0.3 else signf(p_to_shield)

			if not shield_found:
				# 2. PRIORIDAD TÁCTICA: Buscar activamente bajar escaleras para escapar
				var best_ladder: Node3D = null
				var best_ladder_dist := INF
				var ladders := get_tree().get_nodes_in_group("ladder")
				
				for lad in ladders:
					if lad is Node3D:
						var lad_node := lad as Node3D
						var lad_top_y: float = float(lad_node.get("top_y") if lad_node.get("top_y") != null else 0.0)
						var lad_bot_y: float = float(lad_node.get("bottom_y") if lad_node.get("bottom_y") != null else 0.0)
						
						# Verificar si es una escalera que desciende desde mi piso
						var is_descending_ladder := absf(global_position.y - lad_top_y) < 1.6
						if is_descending_ladder:
							var lad_x := lad_node.global_position.x
							# Verificar que el jugador no esté entre el pepino y la escalera
							var player_between := (player.global_position.x > minf(global_position.x, lad_x)) and (player.global_position.x < maxf(global_position.x, lad_x))
							var d := absf(lad_x - global_position.x)
							if not player_between and d < best_ladder_dist:
								best_ladder_dist = d
								best_ladder = lad_node
				
				if best_ladder != null and _post_climb_cooldown <= 0.0:
					# Dirigirse con determinación a la escalera de escape
					var d_to_lad := best_ladder.global_position.x - global_position.x
					move_x = signf(d_to_lad)
				else:
					# Huida estándar alejándose del jugador
					move_x = signf(diff_x)
					if move_x == 0.0:
						move_x = 1.0
						
		# SI EL JUGADOR ESTÁ EN OTRO PISO:
		else:
			# Patrullar y buscar escaleras para descender si está en piso alto
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

	# 3. DISPERSIÓN ENTRE PEPINOS (No agruparse en manadas):
	for ally in get_allies():
		if ally is CucumberAnomaly:
			var d_ally := absf(global_position.x - ally.global_position.x)
			var same_floor := absf(global_position.y - ally.global_position.y) < 1.5
			if same_floor and d_ally < 3.2:
				var repel := signf(global_position.x - ally.global_position.x)
				if repel != 0.0:
					move_x = repel

	# 4. EVITAR ACORRALARSE EN PAREDES DEL MAPA (X = ±13):
	var near_right_wall := global_position.x > 11.5
	var near_left_wall := global_position.x < -11.5
	
	if (near_right_wall and move_x > 0.0) or (near_left_wall and move_x < 0.0):
		# En vez de seguir empujando contra la pared, dar media vuelta inmediata
		move_x = -move_x
		_patrol_dir = move_x
		_wall_escape_timer = 1.2
	elif is_on_wall():
		var wall_norm := get_wall_normal()
		if wall_norm.x != 0.0:
			move_x = signf(wall_norm.x)
			_patrol_dir = move_x
			_wall_escape_timer = 1.0

	var current_speed := speed * (stairs_mult if in_stairs else 1.0)
	
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 28.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, _patrol_dir * current_speed, 18.0 * delta)
		
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
