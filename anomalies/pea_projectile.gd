class_name PeaProjectile
extends Area3D

var direction := Vector3.RIGHT
var speed: float = 7.0
var _spent := false
var _lifetime := 4.0


func _ready() -> void:
	direction = direction.normalized()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	global_position += direction * speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	_handle_hit(body)


func _on_area_entered(area: Area3D) -> void:
	_handle_hit(area)


func _handle_hit(target: Node) -> void:
	if _spent:
		return
	
	# Si toca al jugador o su área de contacto
	var player: Node = null
	if target.is_in_group("player"):
		player = target
	elif target.get_parent() != null and target.get_parent().is_in_group("player"):
		player = target.get_parent()
		
	if player != null:
		var invulnerable := false
		if player.has_method("is_invulnerable"):
			invulnerable = player.call("is_invulnerable")
		_play_impact_sfx()
		if not invulnerable and player.has_method("take_damage"):
			player.call("take_damage", 1)
			_spent = true
			queue_free()
			return
		elif invulnerable:
			_spent = true
			queue_free()
			return

	# Si choca contra el escenario (StaticBody, paredes, suelo)
	if target is StaticBody3D or target is GridMap:
		_play_impact_sfx()
		_spent = true
		queue_free()


func _play_impact_sfx() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.call("play_sfx", "res://audio/sfx_pea_impact.wav", -2.0)
