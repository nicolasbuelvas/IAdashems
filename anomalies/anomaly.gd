class_name Anomaly
extends CharacterBody3D

## Clase base para todas las anomalías (Persona B).
## Cumple con el contrato de RoundManager y EventBus.
## Soporta niveles de dificultad (1 a 6) para IA táctica / coordinada estilo Pac-Man.
## Incluye soporte nativo de tránsito y escalada vertical en escaleras para todas las anomalías.

@export var spawn_id: StringName = &""
@export_range(1, 6) var difficulty: int = 1
var is_contained: bool = false
var in_stairs: bool = false

var is_climbing: bool = false
var climb_target_y: float = 0.0
var climb_exit_x: float = 0.0
var climb_speed: float = 5.0
var _climb_ladder_x: float = 0.0
var _post_climb_cooldown: float = 0.0

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


## Inicia la escalada vertical (acción de tránsito entre pisos)
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


## Actualiza el movimiento en escalera. Retorna true si está actualmente escalando.
func process_climbing(delta: float) -> bool:
	if is_contained:
		return false
	if _post_climb_cooldown > 0.0:
		_post_climb_cooldown -= delta
	if not is_climbing:
		return false
	global_position.x = move_toward(global_position.x, _climb_ladder_x, 12.0 * delta)
	global_position.y = move_toward(global_position.y, climb_target_y, climb_speed * delta)
	global_position.z = 0.0
	velocity = Vector3.ZERO
	if is_equal_approx(global_position.y, climb_target_y):
		is_climbing = false
		global_position.x = climb_exit_x
		velocity = Vector3.ZERO
		_post_climb_cooldown = 0.8
	return true


func get_all_floors() -> Array[float]:
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


func get_closest_floor(floors: Array[float], y: float) -> float:
	var closest := y
	var min_d := INF
	for f in floors:
		var d := absf(f - y)
		if d < min_d:
			min_d = d
			closest = f
	return closest


func get_ladders_touching_floor(floor_y: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for lad in get_tree().get_nodes_in_group("ladder"):
		if lad is Node3D:
			var bot: float = float(lad.get("bottom_y") if lad.get("bottom_y") != null else 0.0)
			var top: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
			if absf(floor_y - bot) < 1.6 or absf(floor_y - top) < 1.6:
				result.append(lad as Node3D)
	return result


func get_safe_x_range(ladders: Array[Node3D]) -> Vector2:
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


func get_safe_exit_x(ladder: Node3D, dest_floor_y: float) -> float:
	var dest_ladders := get_ladders_touching_floor(dest_floor_y)
	var bounds := get_safe_x_range(dest_ladders)
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


func get_ladder_dest_y(lad: Node3D, current_floor_y: float) -> float:
	var bot: float = float(lad.get("bottom_y") if lad.get("bottom_y") != null else 0.0)
	var top: float = float(lad.get("top_y") if lad.get("top_y") != null else 0.0)
	if absf(current_floor_y - bot) < 1.5:
		return top
	elif absf(current_floor_y - top) < 1.5:
		return bot
	if global_position.y >= (bot + top) * 0.5:
		return bot
	return top


func climb_ladder_safely(ladder: Node3D, dest_y: float) -> void:
	if is_climbing or _post_climb_cooldown > 0.0 or is_contained:
		return
	var safe_exit_x := get_safe_exit_x(ladder, dest_y)
	start_climb(dest_y, safe_exit_x, ladder.global_position.x)


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
	is_climbing = false
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
