class_name PeaAnomaly
extends Anomaly

## Anomalía Lanzaguisantes (Pisum sativum):
## Tirador táctico. Siempre en máxima condición: leading shot predictivo y kiteo a distancia media.
## Hace daño al contacto y con proyectiles.
## Captura: 1 impacto de herbicida (E).

const PROJECTILE_SCENE := preload("res://anomalies/pea_projectile.tscn")

var speed: float = 2.4
var fire_interval: float = 1.6
var projectile_speed: float = 7.5

var _fire_timer: float = 1.0
var _facing: float = 1.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("PEA_SPEED") if cfg.get("PEA_SPEED") != null else speed
		fire_interval = cfg.get("PEA_FIRE_INTERVAL") if cfg.get("PEA_FIRE_INTERVAL") != null else fire_interval
		projectile_speed = cfg.get("PEA_PROJECTILE_SPEED") if cfg.get("PEA_PROJECTILE_SPEED") != null else projectile_speed
	speed = maxf(speed, 2.2)
	fire_interval = minf(fire_interval, 1.8)


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
		
		if dist_h > 0.2:
			_facing = signf(diff_x)
			
		# Kiteo / Control de distancia táctica:
		if dist_h < 4.2 and dist_v < 2.0:
			var retreat_dir := -signf(diff_x)
			velocity.x = move_toward(velocity.x, retreat_dir * speed, 16.0 * delta)
		elif dist_h > 3.6:
			velocity.x = move_toward(velocity.x, _facing * (speed * 0.75), 12.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			
		# Disparo periódico si la papa está en rango vertical
		if dist_v < 3.2:
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
	
	# Disparo predictivo (Leading shot):
	if target_player != null and target_player is CharacterBody3D:
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
