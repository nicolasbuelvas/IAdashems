class_name PeaAnomaly
extends Anomaly

## Anomalía Lanzaguisantes (Pisum sativum):
## Tirador táctico y francotirador. Leading shot predictivo, kiteo a distancia media y
## capacidad de usar escaleras para subir/bajar de piso buscando al jugador o escapando.
## Hace daño al contacto y con proyectiles.
## Captura: 1 impacto de herbicida (E).

const PROJECTILE_SCENE := preload("res://anomalies/pea_projectile.tscn")
## Cuadros de preparación de la animación "shoot" antes del fogonazo (cuadros 0 y 1).
const SHOOT_WINDUP_FRAMES := 2

var speed: float = 3.2
var fire_interval: float = 1.6
var projectile_speed: float = 8.0

var _fire_timer: float = 1.0
var _facing: float = 1.0
var _animated_sprite: AnimatedSprite3D
var _windup_time: float = 0.25


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("PEA_SPEED") if cfg.get("PEA_SPEED") != null else speed
		fire_interval = cfg.get("PEA_FIRE_INTERVAL") if cfg.get("PEA_FIRE_INTERVAL") != null else fire_interval
		projectile_speed = cfg.get("PEA_PROJECTILE_SPEED") if cfg.get("PEA_PROJECTILE_SPEED") != null else projectile_speed
	speed = maxf(speed, 3.0)
	fire_interval = minf(fire_interval, 1.8)
	climb_speed = 4.8

	_animated_sprite = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if _animated_sprite != null:
		_animated_sprite.play("idle")
		_animated_sprite.animation_finished.connect(_on_animation_finished)
		# El fogonazo (cuadro 2) debe coincidir con la salida del proyectil.
		var fps := _animated_sprite.sprite_frames.get_animation_speed("shoot")
		_windup_time = minf(SHOOT_WINDUP_FRAMES / maxf(fps, 1.0), fire_interval * 0.5)


func _physics_process(delta: float) -> void:
	if is_contained:
		return

	# Estado de tránsito en escalera (subiendo o bajando)
	if process_climbing(delta):
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	var player := get_player_node()
	if player != null and is_instance_valid(player):
		var all_floors := get_all_floors()
		var my_floor := get_closest_floor(all_floors, global_position.y)
		var player_floor := get_closest_floor(all_floors, player.global_position.y)
		var my_ladders := get_ladders_touching_floor(my_floor)
		var same_floor := absf(player_floor - my_floor) < 1.5
		
		var diff_x := player.global_position.x - global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		
		if dist_h > 0.2:
			_facing = signf(diff_x)

		# 1. TRÁNSITO VERTICAL SI EL JUGADOR ESTÁ EN OTRO PISO:
		# Si la papa está en otro nivel, buscar escalera para cambiar de piso hacia ella
		if not same_floor and _post_climb_cooldown <= 0.0 and not my_ladders.is_empty():
			var best_ladder: Node3D = null
			var min_dist := INF
			for lad in my_ladders:
				var dest_y := get_ladder_dest_y(lad, my_floor)
				var towards_player := (player_floor > my_floor and dest_y > my_floor) or (player_floor < my_floor and dest_y < my_floor)
				if towards_player:
					var d := absf(lad.global_position.x - global_position.x)
					if d < min_dist:
						min_dist = d
						best_ladder = lad
			
			if best_ladder != null:
				var diff_lad := best_ladder.global_position.x - global_position.x
				if absf(diff_lad) > 0.5:
					velocity.x = move_toward(velocity.x, signf(diff_lad) * speed, 20.0 * delta)
				else:
					var dest_y := get_ladder_dest_y(best_ladder, my_floor)
					climb_ladder_safely(best_ladder, dest_y)
					return
			else:
				# Si no hay escalera hacia el jugador, patrullar buscando ángulo
				velocity.x = move_toward(velocity.x, _facing * (speed * 0.6), 12.0 * delta)

		# 2. ESCAPE VERTICAL SI EL JUGADOR ESTÁ MUY CERCA EN EL MISMO PISO:
		elif same_floor and dist_h < 2.8 and _post_climb_cooldown <= 0.0 and not my_ladders.is_empty():
			var escape_ladder: Node3D = null
			var min_dist := INF
			for lad in my_ladders:
				var d := absf(lad.global_position.x - global_position.x)
				if d < min_dist:
					min_dist = d
					escape_ladder = lad
					
			if escape_ladder != null:
				var diff_lad := escape_ladder.global_position.x - global_position.x
				if absf(diff_lad) <= 0.6:
					var dest_y := get_ladder_dest_y(escape_ladder, my_floor)
					climb_ladder_safely(escape_ladder, dest_y)
					return
				else:
					# Retirada hacia la escalera
					velocity.x = move_toward(velocity.x, signf(diff_lad) * speed, 18.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, -_facing * speed, 16.0 * delta)

		# 3. KITEO HORIZONTAL Y DISPARO NORMAL:
		else:
			if dist_h < 4.5 and same_floor:
				# Retirada para mantener distancia
				var retreat_dir := -signf(diff_x)
				velocity.x = move_toward(velocity.x, retreat_dir * speed, 16.0 * delta)
			elif dist_h > 5.5 and same_floor:
				# Acercarse para estar en rango de tiro
				velocity.x = move_toward(velocity.x, _facing * (speed * 0.8), 12.0 * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
			
			# Disparo si está en rango vertical
			if dist_v < 2.5:
				_fire_timer -= delta
				if _fire_timer <= 0.0:
					_fire_timer = fire_interval
					_shoot_projectile(player)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		
	_update_sprite()
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


func _start_shoot_animation() -> void:
	if _animated_sprite != null and _animated_sprite.animation != &"shoot":
		_animated_sprite.play("shoot")


func _on_animation_finished() -> void:
	if _animated_sprite != null and _animated_sprite.animation == &"shoot":
		_animated_sprite.play("idle")


## El sprite original mira a la derecha: se voltea según la dirección de movimiento
## (o de disparo mientras dispara). Sin disparar usa el cuadro 0 ("idle").
func _update_sprite() -> void:
	if _animated_sprite == null:
		return
	if _animated_sprite.animation == &"shoot":
		_animated_sprite.flip_h = _facing < 0.0
	elif absf(velocity.x) > 0.05:
		_animated_sprite.flip_h = velocity.x < 0.0


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

	# Garantiza que el fogonazo se vea aunque la preparación no haya arrancado.
	if _animated_sprite != null and _animated_sprite.animation != &"shoot":
		_animated_sprite.play("shoot")
		_animated_sprite.frame = SHOOT_WINDUP_FRAMES
	_animated_sprite.flip_h = _facing < 0.0 if _animated_sprite != null else false

	proj.direction = shoot_dir
	proj.speed = projectile_speed
	
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	scene_root.add_child(proj)
	proj.global_position = global_position + Vector3(_facing * 1, 1.1, 0.0)

	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_pea_shoot.wav", -2.0)


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
