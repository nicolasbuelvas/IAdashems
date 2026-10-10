class_name PeaAnomaly
extends Anomaly

## Anomalía Lanzaguisantes (Pisum sativum):
## Lenta. Sigue a la papa en X y le dispara un proyectil cada 2.5 s.
## Hace daño al contacto.
## Captura: 1 impacto de herbicida (E).

const PROJECTILE_SCENE := preload("res://anomalies/pea_projectile.tscn")

var speed: float = 1.5
var fire_interval: float = 2.5
var projectile_speed: float = 7.0

var _fire_timer: float = 1.2
var _facing: float = 1.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("PEA_SPEED") if cfg.get("PEA_SPEED") != null else speed
		fire_interval = cfg.get("PEA_FIRE_INTERVAL") if cfg.get("PEA_FIRE_INTERVAL") != null else fire_interval
		projectile_speed = cfg.get("PEA_PROJECTILE_SPEED") if cfg.get("PEA_PROJECTILE_SPEED") != null else projectile_speed
	
	if difficulty >= 5:
		speed = 2.4
		fire_interval = 1.6
	elif difficulty >= 3:
		speed = 2.0
		fire_interval = 2.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	var player := get_player_node()
	if player != null and is_instance_valid(player):
		var diff_x := player.global_position.x - global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		
		# Mantener orientación hacia el jugador
		if dist_h > 0.2:
			_facing = signf(diff_x)
			
		# ESTRATEGIA DE KITEO / CONTROL DE DISTANCIA (Dificultad >= 4):
		# Si la papa está en el mismo piso y se acerca a menos de 4.0m, el tirador retrocede disparando
		if difficulty >= 4 and dist_h < 4.0 and dist_v < 1.8:
			var retreat_dir := -signf(diff_x)
			velocity.x = move_toward(velocity.x, retreat_dir * speed, 14.0 * delta)
		elif dist_h > 3.5:
			# Si está lejos, avanza gradualmente para no perder rango
			velocity.x = move_toward(velocity.x, _facing * (speed * 0.7), 10.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			
		# DISPARO TÁCTICO:
		# Dispara si está en la misma línea visual o si domina el área
		if dist_v < 2.5 or (difficulty >= 5 and dist_v < 4.5):
			_fire_timer -= delta
			if _fire_timer <= 0.0:
				_fire_timer = fire_interval
				_shoot_projectile(player)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func _shoot_projectile(target_player: Node3D = null) -> void:
	var proj := PROJECTILE_SCENE.instantiate() as PeaProjectile
	if proj == null:
		return
		
	var shoot_dir := Vector3(_facing, 0.0, 0.0)
	
	# PREDICCIÓN DE DISPARO (LEADING SHOT - Dificultad >= 5):
	if difficulty >= 5 and target_player != null and target_player is CharacterBody3D:
		var p_vel_x: float = (target_player as CharacterBody3D).velocity.x
		var dist_x := absf(target_player.global_position.x - global_position.x)
		var time_to_hit := dist_x / maxf(projectile_speed, 1.0)
		var predicted_player_x := target_player.global_position.x + p_vel_x * time_to_hit * 0.75
		var predicted_diff := predicted_player_x - global_position.x
		if absf(predicted_diff) > 0.3:
			shoot_dir.x = signf(predicted_diff)
			_facing = shoot_dir.x

	proj.direction = shoot_dir
	proj.speed = projectile_speed
	
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	scene_root.add_child(proj)
	proj.global_position = global_position + Vector3(_facing * 0.7, 0.4, 0.0)


## Contrato de impacto de herbicida:
func on_herbicide_hit() -> void:
	if not is_contained:
		contain()


## Contrato de contacto con el jugador:
func on_player_contact(player_node: Node) -> void:
	if is_contained or player_node == null:
		return
	if player_node.has_method("take_damage"):
		player_node.call("take_damage", 1)
