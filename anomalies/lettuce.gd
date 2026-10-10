class_name LettuceAnomaly
extends Anomaly

## Anomalía Lechuga (Lactuca sativa):
## Rebota continuamente por el escenario.
## Causa daño al contacto, EXCEPTO cuando la papa se desliza con Shift.
## Captura: Deslizarse a través de ella.

var speed: float = 4.0
var _dir_x: float = 1.0


func _ready() -> void:
	super._ready()
	var cfg = get_node_or_null("/root/GameConfig")
	if cfg:
		speed = cfg.get("LETTUCE_SPEED") if cfg.get("LETTUCE_SPEED") != null else speed
	_dir_x = 1.0 if (randf() > 0.5) else -1.0


func _physics_process(delta: float) -> void:
	if is_contained:
		return
		
	if not is_on_floor():
		velocity.y -= _gravity * delta
		
	velocity.x = _dir_x * speed
	velocity.z = 0.0
	
	move_and_slide()
	global_position.z = 0.0
	
	# Rebote en paredes
	if is_on_wall():
		var norm := get_wall_normal()
		if norm.x != 0.0:
			_dir_x = signf(norm.x)
			velocity.x = _dir_x * speed


## Contrato de contacto con el jugador:
func on_player_contact(player_node: Node) -> void:
	if is_contained or player_node == null:
		return
		
	# Si la papa se está deslizando (Dash / Shift), la lechuga queda contenida
	var sliding := false
	if player_node.has_method("is_sliding"):
		sliding = player_node.call("is_sliding")
		
	if sliding:
		contain()
	else:
		if player_node.has_method("take_damage"):
			player_node.call("take_damage", 1)
