class_name CucumberAnomaly
extends Anomaly

## Anomalía Pepino (Cucumis sativus):
## Evasiva y ágil. Siempre en máxima condición táctica (Pac-Man).
## Corre activamente, usa aliados como escudo, escapa por escaleras y no se congela en paredes.
## Captura: Tocarla directamente (inofensiva).

var speed: float = 5.8
var stairs_mult: float = 0.5

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 3.8
var _climb_ladder_x: float = 0.0

var _patrol_dir: float = 1.0
var _wall_turnaround_cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult
	speed = maxf(speed, 5.8)
	_patrol_dir = 1.0 if randf() > 0.5 else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	# Estado de escalada vertical (no cancelable)
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
		
	if _wall_turnaround_cooldown > 0.0:
		_wall_turnaround_cooldown -= delta
	
	var player := get_player_node()
	var move_x := 0.0
	
	if player != null and is_instance_valid(player):
		var diff_x := global_position.x - player.global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		
		# 1. Si la papa está en el mismo piso o cerca verticalmente (< 3.0m)
		if dist_v < 3.0:
			# Táctica Pac-Man: Buscar aliado para usar como escudo humano
			var shield_found := false
			var allies := get_allies()
			var best_shield: Anomaly = null
			var min_shield_dist := INF
			for ally in allies:
				if absf(ally.global_position.y - global_position.y) < 1.8:
					var d := global_position.distance_to(ally.global_position)
					if d < min_shield_dist and d < 10.0:
						min_shield_dist = d
						best_shield = ally
			
			if best_shield != null:
				shield_found = true
				var player_to_shield := best_shield.global_position.x - player.global_position.x
				var target_behind_shield_x := best_shield.global_position.x + signf(player_to_shield) * 2.2
				var diff_shield := target_behind_shield_x - global_position.x
				if absf(diff_shield) > 0.3:
					move_x = signf(diff_shield)
				else:
					move_x = signf(player_to_shield)
					
			if not shield_found:
				# Huida activa en dirección opuesta al jugador
				move_x = signf(diff_x)
				if move_x == 0.0:
					move_x = 1.0
					
				# Si el jugador se aproxima a menos de 5.5m, buscar escalera cercana para escapar de piso
				if dist_h < 5.5:
					var ladders := get_tree().get_nodes_in_group("ladder")
					for lad in ladders:
						if lad is Node3D and absf((lad as Node3D).global_position.y - global_position.y) < 1.5:
							var lad_diff: float = (lad as Node3D).global_position.x - global_position.x
							if absf(lad_diff) < 6.0 and signf(lad_diff) == move_x:
								move_x = signf(lad_diff)
								break
		else:
			# Si el jugador está en otro piso (ej. sótano), el pepino patrulla y corre activamente
			move_x = _patrol_dir
	else:
		move_x = _patrol_dir

	# Si choca contra la pared: no se queda quieto, cambia de dirección o busca escapar
	if is_on_wall():
		var wall_normal := get_wall_normal()
		if wall_normal.x != 0.0 and _wall_turnaround_cooldown <= 0.0:
			_wall_turnaround_cooldown = 0.4
			_patrol_dir = signf(wall_normal.x)
			# Si la huida lo empujaba hacia la pared, intentar voltearse para no ser presa fácil
			move_x = _patrol_dir

	var current_speed := speed * (stairs_mult if in_stairs else 1.0)
	
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 24.0 * delta)
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
