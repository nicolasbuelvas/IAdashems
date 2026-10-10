# level/tests/level_layout_test.gd
# Prueba headless del edificio y las trampas (persona C). No es autoload ni escena.
# Ejecutar desde la raíz del proyecto:
#   godot --headless --path . -s res://level/tests/level_layout_test.gd
# Sale con código 0 si todo pasa, 1 si hay algún FAIL.
#
# Comprueba: marcadores del contrato, spawns apoyados en el suelo, escaleras ocultas mientras el piso
# está cerrado, distancia de seguridad de las trampas, activación de trampas por ronda, daño con y sin
# slide, y que la capa 8 solo choque con la papa.
extends SceneTree

const BUILDING_SCENE := "res://level/building.tscn"
const FLOOR_Y := {1: 0.0, 2: 4.0, 3: 8.0}
const SPAWN_IDS := ["F1_A", "F1_B", "F1_C", "F1_D", "F2_A", "F2_B", "F2_C", "F2_D", "F3_A", "F3_B", "F3_C", "F3_D"]
## Marcadores que la tabla de rondas usa con un pepino: deben quedar dentro del pasillo entre escaleras.
const CUCUMBER_SPAWNS := ["F1_A", "F1_C", "F2_A", "F2_C", "F3_A"]
## Distancia mínima en X entre el borde de una trampa y el spawn de la papa, una escalera o su salida.
const SAFE_DISTANCE := 3.0
## Trampas activas esperadas por ronda (1 a 6).
const EXPECTED_ACTIVE := [1, 2, 3, 4, 5, 9]
const PLAYER_OBSTACLE_BIT := 128

var _fails := 0
var _passes := 0
var _bus: Node
var _building: Node3D


func _initialize() -> void:
	_bus = root.get_node("EventBus")
	_run.call_deferred()


func _check(cond: bool, label: String) -> void:
	if cond:
		_passes += 1
		print("  PASS ", label)
	else:
		_fails += 1
		print("  FAIL ", label)


func _run() -> void:
	_building = (load(BUILDING_SCENE) as PackedScene).instantiate()
	root.add_child(_building)
	await physics_frame
	await physics_frame

	_test_contract()
	_test_spawns_on_floor()
	_test_cucumber_corridors()
	_test_hazard_spacing()
	_test_ladders_lock()
	_test_hazards_by_round()
	await _test_hazard_damage()
	_test_layers()

	_building.queue_free()
	await process_frame
	print("level_layout_test: %d PASS, %d FAIL" % [_passes, _fails])
	quit(1 if _fails > 0 else 0)


func _test_contract() -> void:
	print("-- contrato de Building")
	_check(_building.get_node_or_null(^"PlayerSpawn") is Marker3D, "existe PlayerSpawn")
	for id in SPAWN_IDS:
		_check(_building.call(&"get_spawn", StringName(id)) != null, "existe el spawn %s" % id)
	for f in [1, 2, 3]:
		var c: Node = _building.call(&"get_floor_container", f)
		_check(c != null and c.is_in_group(&"container"), "Container_F%d existe y está en el grupo container" % f)
	for f in [2, 3]:
		_check(_building.get_node_or_null("BlockF%d" % f) != null, "existe BlockF%d" % f)


func _floor_of(y: float) -> int:
	var best := 1
	for f in FLOOR_Y:
		if absf(y - FLOOR_Y[f]) < absf(y - FLOOR_Y[best]):
			best = f
	return best


func _test_spawns_on_floor() -> void:
	print("-- spawns apoyados en su piso")
	var space := _building.get_world_3d().direct_space_state
	var markers: Array = SPAWN_IDS.duplicate()
	markers.append("PlayerSpawn")
	for id in markers:
		var m := _building.find_child(id, true, false) as Node3D
		var from := m.global_position
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0, 1)
		var hit := space.intersect_ray(query)
		var expected_floor: float = FLOOR_Y[int(id.substr(1, 1))] if id != "PlayerSpawn" else FLOOR_Y[1]
		var ok := not hit.is_empty() and absf(hit.position.y - expected_floor) < 0.05
		_check(ok, "%s cae sobre el suelo y=%.1f (hit=%s)" % [id, expected_floor, str(hit.get("position", "nada"))])
		_check(absf(m.global_position.x) < 23.5, "%s queda dentro de las paredes" % id)


func _ladder_xs_on_floor(floor_number: int) -> Array[float]:
	var xs: Array[float] = []
	for holder_name in ["LaddersF2", "LaddersF3"]:
		var holder := _ladder_holder(holder_name)
		var top_floor := int(holder_name.substr(8))
		if top_floor != floor_number and top_floor - 1 != floor_number:
			continue
		for lad in holder.get_children():
			xs.append(lad.position.x)
			xs.append(lad.position.x + float(lad.get(&"bottom_exit_offset_x")))
			xs.append(lad.position.x + float(lad.get(&"top_exit_offset_x")))
	return xs


func _ladder_holder(holder_name: String) -> Node3D:
	var holder := _building.get_node_or_null(holder_name) as Node3D
	if holder == null:
		var locked: Dictionary = _building.get(&"_locked_ladders")
		holder = locked.get(int(holder_name.substr(8))) as Node3D
	return holder


func _test_cucumber_corridors() -> void:
	print("-- pepinos dentro del pasillo entre escaleras")
	for id in CUCUMBER_SPAWNS:
		var m := _building.find_child(id, true, false) as Node3D
		var f := _floor_of(m.global_position.y - 1.0)
		var min_bound := 99.0
		for holder_name in ["LaddersF2", "LaddersF3"]:
			var top_floor := int(holder_name.substr(8))
			if top_floor == f or top_floor - 1 == f:
				for lad in _ladder_holder(holder_name).get_children():
					min_bound = minf(min_bound, absf(lad.position.x))
		_check(absf(m.global_position.x) < min_bound, "%s (x=%.1f) dentro de las escaleras del piso %d (|x| < %.1f)" % [id, m.global_position.x, f, min_bound])


func _hazards() -> Array[Hazard]:
	var result: Array[Hazard] = []
	for h in _building.get_node(^"Hazards").get_children():
		if h is Hazard:
			result.append(h)
	return result


func _half_width(h: Hazard) -> float:
	var shape := (h.get_node(^"CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	var half := shape.size.x * 0.5
	if h.mode == Hazard.Mode.PATROL:
		half += h.patrol_distance
	return half


func _test_hazard_spacing() -> void:
	print("-- distancia de seguridad de las trampas")
	var spawn := (_building.get_node(^"PlayerSpawn") as Node3D).global_position
	for h in _hazards():
		var f := _floor_of(h.global_position.y)
		var half := _half_width(h)
		if f == 1:
			var d := absf(h.global_position.x - spawn.x) - half
			_check(d >= SAFE_DISTANCE, "%s a %.1f m del spawn de la papa" % [h.name, d])
		var nearest := 99.0
		for x in _ladder_xs_on_floor(f):
			nearest = minf(nearest, absf(h.global_position.x - x) - half)
		_check(nearest >= SAFE_DISTANCE, "%s a %.1f m de la escalera o salida más cercana" % [h.name, nearest])
		_check(absf(h.global_position.x) + half < 24.5, "%s queda dentro de las paredes" % h.name)


func _ladders_in_group() -> int:
	var n := 0
	for node in get_nodes_in_group(&"ladder"):
		if node is VerticalLadder:
			n += 1
	return n


func _test_ladders_lock() -> void:
	print("-- escaleras de pisos cerrados")
	_check(_ladders_in_group() == 0, "con F2 y F3 cerrados no hay escaleras en el grupo ladder (hay %d)" % _ladders_in_group())
	_check(not _building.call(&"is_floor_open", 2), "F2 empieza cerrado")
	_building.call(&"unlock_floor", 2)
	_check(_ladders_in_group() == 2, "unlock_floor(2) activa 2 escaleras (hay %d)" % _ladders_in_group())
	_check(_building.get_node(^"BlockF2").is_queued_for_deletion(), "unlock_floor(2) libera BlockF2")
	_building.call(&"unlock_floor", 2)
	_check(_ladders_in_group() == 2, "unlock_floor(2) es idempotente")
	_building.call(&"unlock_floor", 3)
	_check(_ladders_in_group() == 4, "unlock_floor(3) activa 4 escaleras en total (hay %d)" % _ladders_in_group())


func _test_hazards_by_round() -> void:
	print("-- trampas activas por ronda")
	for n in range(1, 7):
		_bus.emit_signal(&"round_started", n, 1)
		var active := 0
		for h in _hazards():
			if h.enabled:
				active += 1
				_check(h.visible, "%s visible en la ronda %d" % [h.name, n])
		_check(active == EXPECTED_ACTIVE[n - 1], "ronda %d: %d trampas activas (esperadas %d)" % [n, active, EXPECTED_ACTIVE[n - 1]])


func _make_fake_player() -> CharacterBody3D:
	var script := GDScript.new()
	script.source_code = """extends CharacterBody3D
var hits := 0
var sliding := false
var iframes := 0.0
func take_damage(_amount: int, pierce_slide: bool = false) -> void:
	if iframes > 0.0 or (sliding and not pierce_slide):
		return
	hits += 1
	iframes = 1.0
func is_sliding() -> bool:
	return sliding
func is_invulnerable() -> bool:
	return iframes > 0.0 or sliding
"""
	script.reload()
	var body := CharacterBody3D.new()
	body.set_script(script)
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_to_group(&"player")
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.6
	cs.shape = capsule
	cs.position.y = 0.8
	body.add_child(cs)
	return body


func _place_and_wait(body: Node3D, at: Vector3) -> void:
	body.global_position = at
	for i in 4:
		await physics_frame


func _test_hazard_damage() -> void:
	print("-- daño de las trampas")
	_bus.emit_signal(&"round_started", 6, 1)
	var player := _make_fake_player()
	root.add_child(player)
	var far := Vector3(-19, 20, 0)

	var staples := _building.get_node(^"Hazards/Staples_F1") as Hazard
	player.set(&"sliding", true)
	await _place_and_wait(player, staples.global_position)
	_check(player.get(&"hits") == 0, "las grapas no dañan durante el slide")
	player.set(&"sliding", false)
	await _place_and_wait(player, staples.global_position)
	_check(player.get(&"hits") == 1, "las grapas dañan sin slide (hits=%d)" % player.get(&"hits"))

	await _place_and_wait(player, far)
	player.set(&"hits", 0)
	player.set(&"iframes", 0.0)
	var steam := _building.get_node(^"Hazards/Steam_F1") as Hazard
	steam.call(&"_set_state", Hazard.State.OFF)
	steam.set(&"_state_left", 10.0)
	await _place_and_wait(player, steam.global_position)
	_check(player.get(&"hits") == 0, "el vapor apagado no daña")
	player.set(&"sliding", true)
	steam.call(&"_set_state", Hazard.State.ON)
	await _place_and_wait(player, steam.global_position)
	_check(player.get(&"hits") == 1, "el vapor encendido atraviesa el slide (hits=%d)" % player.get(&"hits"))
	player.set(&"sliding", false)

	await _place_and_wait(player, far)
	player.set(&"hits", 0)
	player.set(&"iframes", 0.0)
	var tile := _building.get_node(^"Hazards/Tile_F3_1") as Hazard
	_check(tile.state == Hazard.State.OFF, "el plafón espera a la papa")
	await _place_and_wait(player, tile.global_position)
	_check(tile.state == Hazard.State.WARN, "el plafón avisa al pasar la papa")
	for i in int((tile.warn_time + 0.2) * Engine.physics_ticks_per_second):
		await physics_frame
	_check(player.get(&"hits") == 1, "el plafón cae y daña tras el aviso (hits=%d)" % player.get(&"hits"))

	var chair := _building.get_node(^"Hazards/Chair_F2") as Hazard
	var x0 := chair.position.x
	for i in 10:
		await physics_frame
	_check(not is_equal_approx(chair.position.x, x0), "la silla patrulla")
	player.queue_free()


func _test_layers() -> void:
	print("-- capa 8 player_obstacle")
	var cabinet := (load("res://level/props/filing_cabinet.tscn") as PackedScene).instantiate() as CollisionObject3D
	_check(cabinet.collision_layer == PLAYER_OBSTACLE_BIT, "el archivador está solo en la capa 8")
	cabinet.free()
	var player := (load("res://player/player.tscn") as PackedScene).instantiate() as CollisionObject3D
	_check(player.collision_mask & PLAYER_OBSTACLE_BIT != 0, "la papa choca con la capa 8")
	_check(player.collision_mask & 1 != 0, "la papa choca con world")
	player.free()
	for path in ["res://anomalies/cucumber.tscn", "res://anomalies/lettuce.tscn", "res://anomalies/pea.tscn"]:
		var a := (load(path) as PackedScene).instantiate() as CollisionObject3D
		_check(a.collision_mask & PLAYER_OBSTACLE_BIT == 0, "%s atraviesa la capa 8" % path.get_file())
		a.free()
