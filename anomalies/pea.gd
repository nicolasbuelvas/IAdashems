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


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player):
		var diff_x := player.global_position.x - global_position.x
		if absf(diff_x) > 0.4:
			_facing = signf(diff_x)
			velocity.x = move_toward(velocity.x, _facing * speed, 10.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			
		# Disparo periódico si la papa está en rango de visión horizontal
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_interval
			_shoot_projectile()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func _shoot_projectile() -> void:
	var proj := PROJECTILE_SCENE.instantiate() as PeaProjectile
	if proj == null:
		return
	proj.direction = Vector3(_facing, 0.0, 0.0)
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
