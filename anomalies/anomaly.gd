class_name Anomaly
extends CharacterBody3D

## Clase base para todas las anomalías (Persona B).
## Cumple con el contrato de RoundManager y EventBus.
## Soporta niveles de dificultad (1 a 6) para IA táctica / coordinada estilo Pac-Man.

@export var spawn_id: StringName = &""
@export_range(1, 6) var difficulty: int = 1
var is_contained: bool = false
var in_stairs: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	add_to_group("anomaly")
	axis_lock_linear_z = true
	floor_constant_speed = true
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(60.0)
	
	# Registrar detección de escaleras si existe StairsDetector
	var detector = get_node_or_null("StairsDetector") as Area3D
	if detector != null:
		detector.area_entered.connect(_on_detector_area_entered)
		detector.area_exited.connect(_on_detector_area_exited)
	
	# Notificar spawn a EventBus
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("anomaly_spawned"):
		bus.emit_signal("anomaly_spawned", self)


func _on_detector_area_entered(area: Area3D) -> void:
	if area.is_in_group("stairs") or area.name.to_lower().contains("stair") or area.name.to_lower().contains("ladder"):
		in_stairs = true


func _on_detector_area_exited(area: Area3D) -> void:
	if area.is_in_group("stairs") or area.name.to_lower().contains("stair") or area.name.to_lower().contains("ladder"):
		in_stairs = false


## Obtiene referencia al jugador si está en escena
func get_player_node() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and is_instance_valid(players[0]):
		return players[0] as Node3D
	return null


## Obtiene otras anomalías vivas para tácticas de grupo
func get_allies() -> Array[Anomaly]:
	var result: Array[Anomaly] = []
	for n in get_tree().get_nodes_in_group("anomaly"):
		if n is Anomaly and n != self and not n.is_contained:
			result.append(n)
	return result


func contain() -> void:
	if is_contained:
		return
	is_contained = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	
	# Desactivar áreas hijas de colisión
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
		elif child is Area3D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
	
	# Buscar contenedor más cercano
	var target_pos := global_position + Vector3(0.0, 1.2, 0.0)
	var containers := get_tree().get_nodes_in_group("container")
	var closest_dist := INF
	for c: Node in containers:
		if c is Node3D:
			var d := global_position.distance_to(c.global_position)
			if d < closest_dist:
				closest_dist = d
				target_pos = c.global_position
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		var bus := get_node_or_null("/root/EventBus")
		if bus and bus.has_signal("anomaly_contained"):
			bus.emit_signal("anomaly_contained", self)
		queue_free()
	)
