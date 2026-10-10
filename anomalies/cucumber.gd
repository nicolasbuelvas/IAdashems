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


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("CUCUMBER_SPEED") if cfg.get("CUCUMBER_SPEED") != null else speed
		flee_distance = cfg.get("CUCUMBER_FLEE_DISTANCE") if cfg.get("CUCUMBER_FLEE_DISTANCE") != null else flee_distance
		stairs_mult = cfg.get("CUCUMBER_STAIRS_MULT") if cfg.get("CUCUMBER_STAIRS_MULT") != null else stairs_mult


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
	
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var move_x := 0.0
	
	if player != null and is_instance_valid(player):
		var diff_x := global_position.x - player.global_position.x
		var dist_h := absf(diff_x)
		var dist_v := absf(global_position.y - player.global_position.y)
		
		# Si la papa está cerca en el mismo piso o aproximándose
		if dist_h < flee_distance and dist_v < 3.5:
			move_x = signf(diff_x)
			if move_x == 0.0:
				move_x = 1.0
	
	var current_speed := speed * (stairs_mult if in_stairs else 1.0)
	
	# Si está contra la pared en la dirección en la que intenta huir, se frena (queda arrinconado)
	if is_on_wall() and move_x != 0.0:
		var wall_normal := get_wall_normal()
		if signf(wall_normal.x) != signf(move_x):
			move_x = 0.0
	
	if move_x != 0.0:
		velocity.x = move_toward(velocity.x, move_x * current_speed, 18.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		
	velocity.z = 0.0
	move_and_slide()
	global_position.z = 0.0


## Contrato de contacto con el jugador:
func on_player_contact(_player: Node) -> void:
	if not is_contained:
		contain()
