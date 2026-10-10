# systems/tests/round_manager_test.gd
# Prueba headless de RoundManager (persona C). No es autoload ni escena.
# Ejecutar desde la raíz del proyecto:
#   Godot_v4.7.2-stable_win64.exe --headless --path . -s res://systems/tests/round_manager_test.gd
# Sale con código 0 si todo pasa, 1 si hay algún FAIL.
#
# Carga round_manager.gd con load() dentro de _initialize(), nunca con preload(), como heat_system_test.gd.
# Con -s los autoloads existen como nodos (/root/EventBus, /root/GameConfig) y sus nombres globales compilan
# (comprobado con Godot 4.7.2). Por seguridad, _ensure_node() los crea si faltan.
# Las expectativas de balance salen de GameConfig (preload de su script): aquí no hay números de balance.
# Building falso, jugador falso y la anomalía dummy (rm_dummy_anomaly.tscn) viven en systems/tests/,
# sin depender de game/test/.
extends SceneTree

const GameConfigScript := preload("res://autoload/game_config.gd")
const EventBusScript := preload("res://autoload/event_bus.gd")
const DUMMY_SCENE := "res://systems/tests/rm_dummy_anomaly.tscn"
const MISSING_SCENE := "res://systems/tests/rm_no_existe.tscn"

## Copia literal de la tabla de la sección 3 de docs/spec-mvp-reparto.md. Sirve para comparar con ROUNDS.
const SPEC_TABLE := [
	{"floors": [1], "anomalies": [["cucumber", "F1_A"]]},
	{"floors": [1], "anomalies": [["cucumber", "F1_A"], ["lettuce", "F1_B"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", "F1_C"], ["lettuce", "F2_A"], ["pea", "F2_B"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", "F1_A"], ["cucumber", "F2_C"], ["lettuce", "F1_B"], ["pea", "F2_D"]]},
	{"floors": [1, 2], "anomalies": [["cucumber", "F1_C"], ["cucumber", "F2_A"], ["lettuce", "F1_D"], ["lettuce", "F2_B"], ["pea", "F2_C"]]},
	{"floors": [1, 2, 3], "anomalies": [["cucumber", "F1_A"], ["cucumber", "F3_A"], ["lettuce", "F2_A"], ["lettuce", "F3_B"], ["pea", "F2_C"], ["pea", "F3_C"]]},
]


## Building falso: implementa la interfaz congelada que RoundManager llama por nombre.
class FakeBuilding extends Node3D:
	var events: Array = []         # diario compartido con el test
	var unlock_calls: Array = []   # pisos pedidos a unlock_floor, en orden
	var markers: Dictionary = {}   # spawn_id (StringName) -> Marker3D
	var player_marker: Marker3D

	func add_marker(sid: StringName, local_pos: Vector3) -> void:
		var m := Marker3D.new()
		m.name = String(sid)
		m.position = local_pos
		add_child(m)
		markers[sid] = m

	func get_spawn(spawn_id: StringName) -> Marker3D:
		return markers.get(spawn_id) as Marker3D

	func get_player_spawn() -> Vector3:
		return player_marker.global_position

	func get_floor_container(_floor_number: int) -> Marker3D:
		return null

	func unlock_floor(floor_number: int) -> void:
		unlock_calls.append(floor_number)
		events.append("unlock:%d" % floor_number)


## Jugador falso: reset_to es lo único que RoundManager le llama.
class FakePlayer extends Node3D:
	var events: Array = []
	var resets: Array = []

	func reset_to(pos: Vector3) -> void:
		resets.append(pos)
		events.append("reset")


## Nodo sin tipar para simular ajenas, clones y spawn_id como String.
class FakeAnomaly extends Node3D:
	var spawn_id: Variant = null


var _failures := 0
var _checks := 0

var _log: Array = []           # diario del test: round_started, reset, unlock, spawn, remaining, timer, floor, won, game_won, failed
var _spawned: Array = []       # nodos que llegaron por anomaly_spawned, en orden
var _floors: Array = []        # floor_unlocked
var _won: Array = []           # round_won
var _failed: Array = []        # reasons de round_failed
var _game_won := 0
var _spawn_events := 0
var _remaining_seen: Array = []  # valores de anomalies_remaining_changed desde el último vaciado del test
var _timer_seen: Array = []      # valores de round_timer_changed desde el último vaciado del test
var _spawn_fields_ok := true   # al llegar anomaly_spawned ya hay spawn_id y posición final

var _rm_script    # Script de round_manager.gd (cargado con load)
var _event_bus    # autoload EventBus, tomado de /root
var _building: FakeBuilding
var _player: FakePlayer
var _anomalies: Node3D         # hace de anomalies_root
var _rm            # RoundManager del escenario actual (sin tipar: la clase se resuelve en runtime)


func _initialize() -> void:
	# En _initialize() el root todavía no está en el árbol. Esperar un frame lo deja listo.
	await process_frame
	_event_bus = _ensure_node("EventBus", EventBusScript)
	_ensure_node("GameConfig", GameConfigScript)
	_rm_script = load("res://systems/round_manager.gd")
	if _rm_script == null:
		print("FAIL  no se pudo cargar res://systems/round_manager.gd")
		quit(1)
		return
	_build_world()
	_connect_listeners()

	_test_data()
	_test_spawn_order()
	_test_floor_unlock()
	_test_capture_clock()
	await _test_defeat_and_retry()
	await _test_start_signals()
	_test_win_all_rounds()
	_test_discards()
	_test_missing_player_and_scene()

	_teardown()
	print("---")
	print("%d comprobaciones, %d fallos" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("OK    ", label)
	else:
		_failures += 1
		print("FAIL  ", label)


## Devuelve el autoload /root/<node_name>. Si -s no lo creó, instancia su script y lo agrega con ese nombre.
func _ensure_node(node_name: String, script: GDScript) -> Node:
	var existing := root.get_node_or_null(node_name)
	if existing != null:
		return existing
	var created: Node = script.new()
	created.name = node_name
	root.add_child(created)
	return created


func _describe(anomalies: Array) -> Array:
	var out: Array = []
	for entry in anomalies:
		out.append("%s@%s" % [entry[0], String(entry[1])])
	return out


func _build_world() -> void:
	_building = FakeBuilding.new()
	_building.position = Vector3(20.0, 0.0, 0.0)  # fuera del origen: prueba coordenadas globales y locales
	root.add_child(_building)
	var i := 0
	for round_data in SPEC_TABLE:
		for entry in round_data["anomalies"]:
			var sid := StringName(entry[1])
			if not _building.markers.has(sid):
				_building.add_marker(sid, Vector3(3.0 * i, 1.0, 0.0))
				i += 1
	var pm := Marker3D.new()
	pm.name = "PlayerSpawn"
	pm.position = Vector3(-4.0, 2.0, 0.0)
	_building.add_child(pm)
	_building.player_marker = pm
	_building.events = _log

	_anomalies = Node3D.new()
	_anomalies.name = "AnomaliesRoot"
	_anomalies.position = Vector3(0.0, 5.0, 0.0)  # distinto del origen: la posición debe pasarse a local
	root.add_child(_anomalies)

	_player = FakePlayer.new()
	root.add_child(_player)
	_player.events = _log


func _connect_listeners() -> void:
	_event_bus.round_started.connect(_on_round_started)
	_event_bus.anomaly_spawned.connect(_on_anomaly_spawned)
	_event_bus.anomalies_remaining_changed.connect(_on_remaining_changed)
	_event_bus.round_timer_changed.connect(_on_timer_changed)
	_event_bus.floor_unlocked.connect(_on_floor_unlocked)
	_event_bus.round_won.connect(_on_round_won)
	_event_bus.game_won.connect(_on_game_won)
	_event_bus.round_failed.connect(_on_round_failed)


func _on_round_started(n: int, remaining: int) -> void:
	_log.append("round_started:%d:%d" % [n, remaining])


func _on_anomaly_spawned(anomaly) -> void:
	var sid := StringName(str(anomaly.get(&"spawn_id")))
	_log.append("spawn:%s" % sid)
	_spawned.append(anomaly)
	_spawn_events += 1
	# Corre dentro de add_child (desde _ready). Ya deben estar fijados spawn_id y la posición final.
	var marker: Marker3D = _building.get_spawn(sid)
	if marker == null or not anomaly.is_inside_tree() or not anomaly.global_position.is_equal_approx(marker.global_position):
		_spawn_fields_ok = false


func _on_remaining_changed(n: int) -> void:
	_remaining_seen.append(n)
	_log.append("remaining:%d" % n)


func _on_timer_changed(seconds: float) -> void:
	_timer_seen.append(seconds)
	_log.append("timer:%d" % roundi(seconds))


func _on_floor_unlocked(f: int) -> void:
	_floors.append(f)
	_log.append("floor:%d" % f)


func _on_round_won(n: int) -> void:
	_won.append(n)
	_log.append("won:%d" % n)


func _on_game_won() -> void:
	_game_won += 1
	_log.append("game_won")


func _on_round_failed(reason: StringName) -> void:
	_failed.append(reason)
	_log.append("failed:%s" % reason)


## Crea un RoundManager limpio para cada escenario: libera el anterior y sus anomalías, y vacía los diarios.
func _new_rm(scenes: Dictionary = {}) -> void:
	if _rm != null:
		_drop(_rm)
		_rm = null
	for child in _anomalies.get_children():
		_anomalies.remove_child(child)
		child.queue_free()
	_log.clear()
	_spawned.clear()
	_remaining_seen.clear()
	_timer_seen.clear()
	_floors.clear()
	_won.clear()
	_failed.clear()
	_game_won = 0
	_spawn_events = 0
	_spawn_fields_ok = true
	_building.unlock_calls.clear()

	var map: Dictionary = scenes
	if map.is_empty():
		map = {"cucumber": DUMMY_SCENE, "lettuce": DUMMY_SCENE, "pea": DUMMY_SCENE}
	_rm = _rm_script.new()
	_rm.building = _building
	_rm.anomalies_root = _anomalies
	_rm.player = _player
	_rm.anomaly_scenes = map
	root.add_child(_rm)
	_rm.set_process(false)  # el reloj se prueba llamando a _process a mano, sin tiempo real


func _drop(node: Node) -> void:
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _settle() -> void:
	await process_frame
	await process_frame


## Último nodo instanciado para ese spawn (en un reintento, el nuevo).
func _find_spawned(sid: StringName) -> Variant:
	for i in range(_spawned.size() - 1, -1, -1):
		var node = _spawned[i]
		if is_instance_valid(node) and node.get(&"spawn_id") == sid:
			return node
	return null


## Simula la captura que haría B: emite anomaly_contained con el nodo vivo de ese spawn.
func _capture(sid: StringName) -> bool:
	var node = _find_spawned(sid)
	if node == null:
		return false
	_event_bus.anomaly_contained.emit(node)
	return true


func _test_data() -> void:
	print("-- datos de las rondas")
	var rounds: Array = _rm_script.ROUNDS
	var scenes: Dictionary = _rm_script.SCENES
	_check(rounds.size() == SPEC_TABLE.size(), "hay 6 rondas")
	var total := 0
	for i in range(mini(rounds.size(), SPEC_TABLE.size())):
		var got: Dictionary = rounds[i]
		var want: Dictionary = SPEC_TABLE[i]
		var label := "ronda %d" % (i + 1)
		_check(Array(got["floors"]) == Array(want["floors"]), label + ": pisos coinciden con el spec")
		_check(_describe(got["anomalies"]) == _describe(want["anomalies"]), label + ": anomalías y spawns (en orden) coinciden con el spec")
		var seen := {}
		var unique := true
		for entry in got["anomalies"]:
			var sid := String(entry[1])
			if seen.has(sid):
				unique = false
			seen[sid] = true
			_check(scenes.has(entry[0]), label + ": tipo '%s' existe en SCENES" % entry[0])
		_check(unique, label + ": ningún spawn se repite")
		total += got["anomalies"].size()
	_check(total == 21, "total de anomalías = 21 (es %d)" % total)


func _test_spawn_order() -> void:
	print("-- start_round: orden de pasos y spawn")
	_new_rm()
	_rm.start_round(1)  # F1_A
	var i_started := _log.find("round_started:1:1")
	var i_reset := _log.find("reset")
	var i_spawn := _log.find("spawn:F1_A")
	_check(i_started == 0, "round_started es lo primero que pasa en start_round (log: %s)" % str(_log))
	_check(i_spawn > i_started, "round_started se emite antes de anomaly_spawned")
	_check(i_reset > i_started and i_reset < i_spawn, "la papa se reposiciona entre round_started y el spawn")
	_check(_spawned.size() == 1 and _spawn_events == 1, "la ronda 1 instancia una anomalía")
	_check(_spawn_fields_ok, "al llegar anomaly_spawned ya hay spawn_id y posición final (se verifica dentro de _ready)")
	var node = _find_spawned(&"F1_A")
	if node != null:
		_check(node.get_parent() == _anomalies, "la anomalía queda como hija de anomalies_root")
		_check(node.global_position.is_equal_approx(_building.get_spawn(&"F1_A").global_position), "posición final = marcador F1_A")
	_check(_player.resets.size() == 1 and _player.resets[0].is_equal_approx(_building.get_player_spawn()), "reset_to recibe get_player_spawn()")
	_check(_rm.active and _rm.current_round == 1 and _rm.remaining == 1, "tras start_round(1): activa, ronda 1, 1 restante")
	_check(is_equal_approx(_rm.time_left, GameConfigScript.ROUND_BASE_TIME + GameConfigScript.ROUND_TIME_PER_ANOMALY * 1.0), "reloj inicial = 90 + 15 x 1")

	# Fuera de rango no hace nada (push_error).
	_log.clear()
	_rm.start_round(7)
	_check(_log.is_empty() and _rm.current_round == 1, "start_round(7) no existe: no emite nada y no cambia la ronda")


func _test_floor_unlock() -> void:
	print("-- pisos: floor_unlocked solo en las rondas 3 y 6")
	_new_rm()
	var expected := [[], [], [2], [], [], [3]]
	for n in range(1, 7):
		_floors.clear()
		_building.unlock_calls.clear()
		_rm.start_round(n)
		_check(_floors == expected[n - 1], "ronda %d: floor_unlocked = %s (es %s)" % [n, str(expected[n - 1]), str(_floors)])
		_check(_building.unlock_calls == expected[n - 1], "ronda %d: unlock_floor llamado = %s" % [n, str(expected[n - 1])])
	_check(_rm.max_floor_unlocked == 3, "al llegar a la ronda 6, max_floor_unlocked = 3")


func _test_capture_clock() -> void:
	print("-- reloj al capturar")
	_new_rm()
	_rm.start_round(5)  # 5 anomalías: F1_C, F2_A, F1_D, F2_B, F2_C
	var before: float = _rm.time_left
	_check(_capture(&"F1_C"), "F1_C existe en la ronda 5")
	_check(is_equal_approx(_rm.time_left, before - GameConfigScript.ROUND_TIME_PER_ANOMALY), "captura normal: el reloj baja 15")
	_check(_log.has("remaining:4"), "anomalies_remaining_changed sale con 4")

	_rm.time_left = GameConfigScript.ROUND_MIN_TIME_LEFT + GameConfigScript.ROUND_TIME_PER_ANOMALY * 0.5  # 17.5
	_check(_capture(&"F2_A"), "F2_A existe en la ronda 5")
	_check(is_equal_approx(_rm.time_left, GameConfigScript.ROUND_MIN_TIME_LEFT), "reloj en 17.5: resta 15 pero se queda en el piso de 10 s")

	var low: float = GameConfigScript.ROUND_MIN_TIME_LEFT - 2.0
	_rm.time_left = low
	_check(_capture(&"F1_D"), "F1_D existe en la ronda 5")
	_check(is_equal_approx(_rm.time_left, low), "reloj por debajo de 10 s: la captura no lo sube ni lo baja")
	_check(_rm.active and _rm.remaining == 2, "tras 3 capturas quedan 2 y la ronda sigue activa")


func _test_defeat_and_retry() -> void:
	print("-- muerte por daño: castigo de 15s y la ronda sigue viva")
	_new_rm()
	_rm.start_round(2)
	_check(_capture(&"F1_A"), "F1_A se contiene en la ronda 2")
	var initial_time: float = _rm.time_left
	_event_bus.player_died.emit()
	await _settle()
	_check(_rm.active, "al morir la ronda sigue activa")
	_check(_rm.contained_ids == [&"F1_A"], "al morir se conservan las capturas")
	_check(_rm.time_left < initial_time, "al morir se descuentan segundos del reloj (tiempo: %.2f vs %.2f)" % [_rm.time_left, initial_time])

	print("-- derrota por calor: borra capturas y reinicia todo")
	var b_old = _find_spawned(&"F1_B")
	var b_old_id: int = b_old.get_instance_id() if b_old != null else 0
	_event_bus.heat_maxed.emit()
	_check(not _rm.active, "heat_maxed desactiva la ronda")
	_check(_failed.size() == 1 and _failed[0] == &"heat", "heat_maxed emite round_failed(heat) una vez")
	_check(_rm._live.is_empty(), "_fail deja _live vacío")
	await _settle()
	_check(b_old_id != 0 and not is_instance_id_valid(b_old_id), "_fail libera la anomalía viva F1_B")
	_check(_rm.contained_ids.is_empty(), "derrota por calor borra el progreso de capturas")

	_spawned.clear()
	_log.clear()
	_rm.start_round(2)
	_check(_log.has("round_started:2:2"), "el reintento por calor reinicia desde cero con 2 restantes")
	_check(_log.has("spawn:F1_A") and _log.has("spawn:F1_B") and _spawned.size() == 2, "el reintento por calor vuelve a instanciar todas las anomalías")
	_check(is_equal_approx(_rm.time_left, _expected_clock(2)), "el reloj vuelve completo")

	print("-- reloj agotado: game over del turno, todo desde cero")
	_failed.clear()
	_rm.time_left = 0.05
	_rm._process(0.1)
	_check(_failed == [&"time"], "el reloj agotado emite round_failed(time) (es %s)" % str(_failed))
	_check(not _rm.active and _rm.contained_ids.is_empty(), "el reloj agotado borra el progreso")
	await _settle()
	_spawned.clear()
	_log.clear()
	_rm.start_round(2)
	_check(_log.has("round_started:2:2"), "tras el reloj agotado: round_started(2, 2 restantes)")
	_check(_log.has("spawn:F1_A") and _log.has("spawn:F1_B") and _spawned.size() == 2, "tras el reloj agotado vuelven F1_A y F1_B")
	_check(is_equal_approx(_rm.time_left, _expected_clock(2)), "tras el reloj agotado el reloj vuelve completo (90 + 15 x 2)")
	_check(_capture(&"F1_A") and _capture(&"F1_B") and _won == [2] and _game_won == 0, "capturar las dos gana la ronda 2 (sin game_won)")


## Reloj esperado para un número de restantes: 90 + 15 x restantes.
func _expected_clock(remaining_count: int) -> float:
	return GameConfigScript.ROUND_BASE_TIME + GameConfigScript.ROUND_TIME_PER_ANOMALY * float(remaining_count)


## true si round_started es la primera entrada del diario y no hay otra round_started después.
func _starts_with_round_started() -> bool:
	if _log.is_empty() or not str(_log[0]).begins_with("round_started:"):
		return false
	for i in range(1, _log.size()):
		if str(_log[i]).begins_with("round_started:"):
			return false
	return true


## start_round emite anomalies_remaining_changed y round_timer_changed una vez cada uno, al final del arranque
## (después de instanciar), con el valor correcto. Y round_started sigue siendo lo primero.
func _test_start_signals() -> void:
	print("-- start_round: anomalies_remaining_changed y round_timer_changed al empezar y al reintentar")

	_new_rm()
	_rm.start_round(1)  # F1_A: 1 anomalía, reloj 90 + 15 x 1
	_check(_log.size() > 0 and _log[0] == "round_started:1:1", "ronda 1: round_started sigue siendo lo primero (log: %s)" % str(_log))
	_check(_remaining_seen == [1], "ronda 1 al empezar: anomalies_remaining_changed una vez con 1 (es %s)" % str(_remaining_seen))
	_check(_timer_seen.size() == 1 and is_equal_approx(_timer_seen[0], _expected_clock(1)), "ronda 1 al empezar: round_timer_changed una vez con 105 (es %s)" % str(_timer_seen))

	_new_rm()
	_rm.start_round(4)  # F1_A, F2_C, F1_B, F2_D: 4 anomalías, reloj 90 + 15 x 4
	_check(_log.size() > 0 and _log[0] == "round_started:4:4", "ronda 4: round_started sigue siendo lo primero (log: %s)" % str(_log))
	_check(_starts_with_round_started(), "ronda 4: round_started es el único del arranque y va primero")
	_check(_remaining_seen == [4], "ronda 4 al empezar: anomalies_remaining_changed una vez con 4 (es %s)" % str(_remaining_seen))
	_check(_timer_seen.size() == 1 and is_equal_approx(_timer_seen[0], _expected_clock(4)), "ronda 4 al empezar: round_timer_changed una vez con 150 (es %s)" % str(_timer_seen))
	var last_spawn := _log.find("spawn:F2_D")
	_check(_spawned.size() == 4 and last_spawn >= 0, "ronda 4 instancia sus 4 anomalías antes de los avisos")
	_check(last_spawn >= 0 and _log.find("remaining:4") > last_spawn, "ronda 4: anomalies_remaining_changed sale después de instanciar las anomalías")
	_check(last_spawn >= 0 and _log.find("timer:150") > last_spawn, "ronda 4: round_timer_changed sale después de instanciar las anomalías")

	# Reintento tras morir con 2 restantes: F1_A y F2_C ya están contenidas y el reloj sigue donde iba.
	_remaining_seen.clear()
	_timer_seen.clear()
	_check(_capture(&"F1_A") and _capture(&"F2_C"), "ronda 4: se contienen F1_A y F2_C antes de la derrota")
	_check(_remaining_seen == [3, 2], "ronda 4: cada captura emite anomalies_remaining_changed con el nuevo valor (es %s)" % str(_remaining_seen))
	var clock_at_death: float = _rm.time_left
	_event_bus.heat_maxed.emit()
	_check(not _rm.active and _failed.size() == 1 and _failed[0] == &"heat", "ronda 4: la derrota por calor desactiva la ronda")
	await _settle()

	_remaining_seen.clear()
	_timer_seen.clear()
	_spawned.clear()
	_log.clear()
	_rm.start_round(4)
	_check(_log.size() > 0 and _log[0] == "round_started:4:4", "reintento de la ronda 4: round_started(4, 4) es lo primero (log: %s)" % str(_log))
	_check(_starts_with_round_started(), "reintento de la ronda 4: round_started es el único del arranque y va primero")
	_check(_remaining_seen == [4], "reintento de la ronda 4: anomalies_remaining_changed una vez con 4 (es %s)" % str(_remaining_seen))
	_check(_timer_seen.size() == 1 and is_equal_approx(_timer_seen[0], _expected_clock(4)), "reintento de la ronda 4: round_timer_changed una vez con reloj completo (es %s)" % str(_timer_seen))
	_check(_spawned.size() == 4, "reintento de la ronda 4: instancia las 4 anomalías")
	var last_retry_spawn := _log.find("spawn:F2_D")
	_check(last_retry_spawn >= 0 and _log.find("remaining:4") > last_retry_spawn and _log.find("timer:%d" % roundi(_expected_clock(4))) > last_retry_spawn, "reintento de la ronda 4: los dos avisos salen después de instanciar")
	_check(_rm.active and _rm.remaining == 4, "reintento de la ronda 4: queda activa con 4 restantes")


func _test_win_all_rounds() -> void:
	print("-- victoria: round_won por ronda y game_won solo en la 6")
	_new_rm()
	for n in range(1, SPEC_TABLE.size() + 1):
		_rm.start_round(n)
		var all_ok := true
		for entry in SPEC_TABLE[n - 1]["anomalies"]:
			if not _capture(StringName(entry[1])):
				all_ok = false
		_check(all_ok, "ronda %d: se contienen todas sus anomalías" % n)
		_check(_won.size() == n and _won[n - 1] == n, "ronda %d: round_won(%d) sale una vez" % [n, n])
		var want_game_won := 1 if n == SPEC_TABLE.size() else 0
		_check(_game_won == want_game_won, "ronda %d: game_won = %d (es %d)" % [n, want_game_won, _game_won])
	_check(not _rm.active, "al ganar la ronda 6 la ronda queda inactiva")


func _test_discards() -> void:
	print("-- descartes: ajenas, clones, repetidas y spawn_id como String")
	_new_rm()
	_rm.start_round(2)  # F1_A y F1_B
	var stranger := Node3D.new()  # sin spawn_id
	_event_bus.anomaly_contained.emit(stranger)
	_check(_rm.remaining == 2 and _rm.contained_ids.is_empty(), "una ajena sin spawn_id no cuenta")

	var clone := FakeAnomaly.new()  # mismo spawn que F1_A, pero no es la viva
	clone.spawn_id = &"F1_A"
	_event_bus.anomaly_contained.emit(clone)
	_check(_rm.remaining == 2 and _rm.contained_ids.is_empty(), "un clon con el spawn de F1_A no cuenta")

	_check(_capture(&"F1_A"), "F1_A existe")
	_check(_rm.remaining == 1, "la captura real de F1_A deja 1 restante")
	_event_bus.anomaly_contained.emit(_find_spawned(&"F1_A"))
	_check(_rm.remaining == 1 and _rm.contained_ids.size() == 1, "la misma anomalía contenida otra vez no cuenta dos veces")

	# spawn_id como String: se normaliza a StringName y cuenta igual.
	var as_text := FakeAnomaly.new()
	as_text.spawn_id = "F1_B"
	_rm._live[&"F1_B"] = as_text
	_event_bus.anomaly_contained.emit(as_text)
	_check(_rm.remaining == 0 and _rm.contained_ids.size() == 2, "spawn_id String 'F1_B' cuenta igual que StringName")
	_check(_won == [2], "al contener F1_B la ronda 2 se gana")

	stranger.free()
	clone.free()
	as_text.free()


func _test_missing_player_and_scene() -> void:
	print("-- player ausente y escena inexistente")
	_new_rm()
	_rm.player = null
	_rm.start_round(1)
	_check(_rm.active and _spawned.size() == 1, "sin player la ronda arranca igual (se avisa con push_warning)")

	_new_rm({"cucumber": MISSING_SCENE, "lettuce": DUMMY_SCENE, "pea": DUMMY_SCENE})
	_rm.start_round(2)  # F1_A (escena inexistente) y F1_B
	_check(_rm.active and _spawned.size() == 1 and _rm.remaining == 2, "escena inexistente: push_error, la ronda sigue y solo se instancia F1_B")


func _teardown() -> void:
	if _rm != null:
		_drop(_rm)
		_rm = null
	_drop(_building)
	_drop(_player)
	_drop(_anomalies)
