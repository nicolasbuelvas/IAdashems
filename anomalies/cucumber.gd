class_name CucumberAnomaly
extends Anomaly

## Anomalía Pepino (Cucumis sativus) - Entidad de Correr:
## Reglas maestras de comportamiento y evasión:
## 1) Siempre estar e ir a un piso diferente (por arriba o abajo) del jugador.
## 2) Cuando el jugador sube o baja una escalera, ir a la contraria para cumplir la primera.
## 3) Evitar a toda costa ir más allá a la izquierda o derecha de la escalera (evitando acorralarse a sí misma).
## Captura: Tocarla directamente (inofensiva).

var speed: float = 9.2
var stairs_mult: float = 0.75

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 6.2
var _climb_ladder_x: float = 0.0

var _post_climb_cooldown: float = 0.0
var _patrol_dir: float = 1.0
var _dodge_jump_cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult
	speed = maxf(speed, 9.2)
	_patrol_dir = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	# Estado de escalada vertical (transición no cancelable)
	if is_climbing:
		global_position.x = move_toward(global_position.x, _climb_ladder_x, 12.0 * delta)
		global_position.y = move_toward(global_position.y, climb_target_y, climb_speed * delta)
		global_position.z = 0.0
		velocity = Vector3.ZERO
		if is_equal_approx(global_position.y, climb_target_y):
			is_climbing = false
			global_position.x = climb_exit_x
			velocity = Vector3.ZERO
			_post_climb_cooldown = 0.6
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	if _post_climb_cooldown > 0.0:
		_post_climb_cooldown -= delta
	if _dodge_jump_cooldown > 0.0:
		_dodge_jump_cooldown -= delta

	# Reconocimiento dinámico de niveles y escaleras
	var all_floors := _get_all_floors()
	var my_floor := _get_closest_floor(all_floors, global_position.y)
	var my_ladders := _get_ladders_touching_floor(my_floor)
	var safe_bounds := _get_safe_x_range(my_ladders)

	var player := get_player_node()
	var move_x := 0.0
	var speed_multiplier := 1.0

	if player != null and is_instance_valid(player):
		var player_floor := _get_closest_floor(all_floors, player.global_position.y)
		var same_floor := absf(player_floor - my_floor) < 1.5
		var player_is_climbing: bool = bool(player.get("is_climbing") == true)
		var player_ladder_x: float = float(player.get("_climb_ladder_x") if player.get("_climb_ladder_x") != null else player.global_position.x)
		var player_target_y: float = float(player.get("climb_target_y") if player.get("climb_target_y") != null else player.global_position.y)
		var player_dest_floor := _get_closest_floor(all_floors, player_target_y)
		var player_sliding := bool(player.has_method("is_sliding") and player.call("is_sliding"))
		var dist_to_player := absf(global_position.x - player.global_position.x)

		# REACCIÓN A SLIDE / DASH DEL JUGADOR:
		# Si la papa viene a toda velocidad con slide en el mismo piso, sprint de adrenalina y salto evasivo
		if same_floor and player_sliding and dist_to_player < 9.0:
			speed_multiplier = 1.35
			if dist_to_player < 3.5 and is_on_floor() and _dodge_jump_cooldown <= 0.0:
				velocity.y = 8.0
				_dodge_jump_cooldown = 1.0

		# REGLA 2: Cuando el jugador sube o baja una escalera,
		# ir inmediatamente a la escalera CONTRARIA para cumplir la primera regla.
		if player_is_climbing:
			var opposite_ladder := _get_opposite_ladder(my_ladders, player_ladder_x)
			if opposite_ladder != null:
				var dist_to_opp := opposite_ladder.global_position.x - global_position.x
				if absf(dist_to_opp) > 0.5:
					# Correr a toda prisa hacia la escalera contraria
					move_x = signf(dist_to_opp)
				else:
					# Ya en la escalera contraria:
					# Si el jugador viene hacia mi piso, usar la escalera contraria para cambiar de piso
					var player_coming_to_my_floor := absf(player_dest_floor - my_floor) < 1.5
					if player_coming_to_my_floor and _post_climb_cooldown <= 0.0:
						var dest_y := _get_ladder_dest_y(opposite_ladder, my_floor)
						_climb_ladder(opposite_ladder, dest_y)
					else:
						# Alejarse del punto donde está emergiendo el jugador
						move_x = -signf(player_ladder_x - global_position.x)
			else:
				move_x = -signf(player_ladder_x - global_position.x)

		# REGLA 1: Si el jugador está en el MISMO piso:
		# PRIORIDAD ABSOLUTA: Ir a una escalera para cambiar de piso (arriba o abajo).
		elif same_floor:
			var escape_ladder := _select_best_escape_ladder(my_ladders, player)
			if escape_ladder != null:
				var dist_to_ladder := escape_ladder.global_position.x - global_position.x
				if absf(dist_to_ladder) > 0.5:
					# Correr hacia la escalera de escape
					move_x = signf(dist_to_ladder)
				else:
					# En la escalera: iniciar cambio de piso
					if _post_climb_cooldown <= 0.0:
						var dest_y := _get_ladder_dest_y(escape_ladder, my_floor)
						_climb_ladder(escape_ladder, dest_y)
			else:
				# Si no hay escalera disponible en este piso, huir en dirección opuesta al jugador
				move_x = signf(global_position.x - player.global_position.x)
				if move_x == 0.0:
					move_x = 1.0

		# Si el jugador está en un piso DIFERENTE:
		# REGLA 1 satisfecha: Mantenerse en un piso diferente patrullando entre las escaleras
		else:
			move_x = _patrol_dir

	else:
		move_x = _patrol_dir

	# Dispersión entre pepinos (no apiñarse en el mismo sitio)
	for ally in get_allies():
		if ally is CucumberAnomaly and is_instance_valid(ally):
			var same_lvl := absf(global_position.y - ally.global_position.y) < 1.5
			var dist_ally := absf(global_position.x - ally.global_position.x)
			if same_lvl and dist_ally < 2.5:
				var repel := signf(global_position.x - ally.global_position.x)
				if repel != 0.0:
					move_x = repel

	# REGLA 3: Evitar a toda costa ir más allá a la izquierda o derecha de la escalera.
	# La entidad NUNCA se mueve más allá de los extremos de las escaleras (evita acorralarse).
	if global_position.x <= safe_bounds.x + 0.15 and move_x < 0.0:
		move_x = 1.0
		_patrol_dir = 1.0
		global_position.x = maxf(global_position.x, safe_bounds.x)
	elif global_position.x >= safe_bounds.y - 0.15 and move_x > 0.0:
		move_x = -1.0
		_patrol_dir = -1.0
		global_position.x = minf(global_position.x, safe_bounds.y)

	# Delimitación horizontal estricta (no salir jamás del corredor entre escaleras)
	global_position.x = clampf(global_position.x, safe_bounds.x, safe_bounds.y)

	var current_speed := speed * speed_multiplier * (stairs_mult if in_stairs else 1.0)
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 50.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, _patrol_dir * current_speed, 25.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0

	# Re-clamp preventivo tras resolver física
	global_position.x = clampf(global_position.x, safe_bounds.x, safe_bounds.y)


func _get_all_floors() -> Array[float]:
	var floors: Array[float] = []
	for lad in get_tree().get_nodes_in_group("ladder"):
		if lad is Node3D:
			var bot: float = float(lad.get("bottom_y") if lad.get("bottom_y") != null else 0.0)
			var top: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
			if not _has_approx_floor(floors, bot):
				floors.append(bot)
			if not _has_approx_floor(floors, top):
				floors.append(top)
	floors.sort()
	if floors.is_empty():
		floors.append(global_position.y)
	return floors


func _has_approx_floor(floors: Array[float], val: float) -> bool:
	for f in floors:
		if absf(f - val) < 0.8:
			return true
	return false


func _get_closest_floor(floors: Array[float], y: float) -> float:
	var closest := y
	var min_d := INF
	for f in floors:
		var d := absf(f - y)
		if d < min_d:
			min_d = d
			closest = f
	return closest


func _get_ladders_touching_floor(floor_y: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for lad in get_tree().get_nodes_in_group("ladder"):
		if lad is Node3D:
			var bot: float = float(lad.get("bottom_y") if lad.get("bottom_y") != null else 0.0)
			var top: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
			if absf(floor_y - bot) < 1.6 or absf(floor_y - top) < 1.6:
				result.append(lad as Node3D)
	return result


func _get_safe_x_range(ladders: Array[Node3D]) -> Vector2:
	if ladders.is_empty():
		return Vector2(-19.0, 19.0)
	var min_x := INF
	var max_x := -INF
	for lad in ladders:
		min_x = minf(min_x, lad.global_position.x)
		max_x = maxf(max_x, lad.global_position.x)
	if min_x >= max_x - 1.0:
		return Vector2(min_x - 4.5, min_x + 4.5)
	return Vector2(min_x, max_x)


func _get_safe_exit_x(ladder: Node3D, dest_floor_y: float) -> float:
	var dest_ladders := _get_ladders_touching_floor(dest_floor_y)
	var bounds := _get_safe_x_range(dest_ladders)
	var lad_x := ladder.global_position.x
	var margin := 1.2
	
	if lad_x <= bounds.x + 0.5:
		return clampf(lad_x + margin, bounds.x, bounds.y)
	elif lad_x >= bounds.y - 0.5:
		return clampf(lad_x - margin, bounds.x, bounds.y)
	else:
		var dist_to_left := lad_x - bounds.x
		var dist_to_right := bounds.y - lad_x
		if dist_to_left < dist_to_right:
			return clampf(lad_x + margin, bounds.x, bounds.y)
		else:
			return clampf(lad_x - margin, bounds.x, bounds.y)


func _get_ladder_dest_y(lad: Node3D, current_floor_y: float) -> float:
	var bot: float = float(lad.get("bottom_y") if lad.get("bottom_y") != null else 0.0)
	var top: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
	if absf(current_floor_y - bot) < 1.5:
		return top
	elif absf(current_floor_y - top) < 1.5:
		return bot
	if global_position.y >= (bot + top) * 0.5:
		return bot
	return top


func _get_opposite_ladder(ladders: Array[Node3D], ref_x: float) -> Node3D:
	if ladders.is_empty():
		return null
	var best: Node3D = null
	var max_dist := -1.0
	for lad in ladders:
		var d := absf(lad.global_position.x - ref_x)
		if d > max_dist:
			max_dist = d
			best = lad
	return best


func _select_best_escape_ladder(ladders: Array[Node3D], player: Node3D) -> Node3D:
	if ladders.is_empty():
		return null
	var p_x := player.global_position.x
	var best: Node3D = null
	var min_cost := INF
	
	for lad in ladders:
		var lad_x := lad.global_position.x
		var blocked := (p_x > minf(global_position.x, lad_x)) and (p_x < maxf(global_position.x, lad_x))
		if blocked:
			continue
			
		var dist_to_lad := absf(lad_x - global_position.x)
		var dist_from_player := absf(lad_x - p_x)
		var cost := dist_to_lad - dist_from_player * 0.3
		if cost < min_cost:
			min_cost = cost
			best = lad
			
	if best == null:
		best = _get_opposite_ladder(ladders, p_x)
	return best


func _climb_ladder(ladder: Node3D, dest_y: float) -> void:
	if is_climbing or _post_climb_cooldown > 0.0 or is_contained:
		return
	var safe_exit_x := _get_safe_exit_x(ladder, dest_y)
	start_climb(dest_y, safe_exit_x, ladder.global_position.x)


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


func on_player_contact(_player: Node) -> void:
	if not is_contained:
		contain()
