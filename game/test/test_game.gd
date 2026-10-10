extends "res://game/game.gd"
## Escena de prueba de C (test_game.tscn). Hereda game.gd: el flujo de rondas es el mismo.
## Agrega dummies (papa y anomalías), un Camera3D fijo y teclas de debug:
##   C: contiene la anomalía más cercana a la papa.
##   K: emite EventBus.player_died.
##   H: HeatSystem.debug_add_heat(50), solo actúa con una ronda activa.
## Las teclas solo actúan en PLAYING: en ROUND_INTRO no se juega.
## Autoplay (@export autoplay, o el argumento de usuario --autoplay para headless):
##   contiene una anomalía cada 0,5 s en PLAYING e imprime las señales de sistemas.
##   En la ronda 4 fuerza un player_died cuando ya hay 2 contenidas, para probar el reintento con progreso.

@export var autoplay := false

const AUTOPLAY_INTERVAL := 0.5
const AUTOPLAY_FORCED_DEATH_ROUND := 4
const AUTOPLAY_FORCED_DEATH_AFTER := 2
const AUTOPLAY_TIMEOUT := 180.0

var _forced_death_done: bool = false


func _ready() -> void:
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
	# Los logs se conectan antes de super._ready(): la ronda 1 arranca dentro de game.gd (_ready) y sin esto no se imprimiría.
	if autoplay:
		_connect_autoplay_logs()
	super._ready()
	if autoplay:
		_start_autoplay_timers()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if GameManager.state != GameManager.PLAYING:
		return
	match key.keycode:
		KEY_C:
			var target := _nearest_anomaly()
			if target != null:
				print("[DEBUG] C: contengo %s" % _describe(target))
				target.call(&"contain")
		KEY_K:
			print("[DEBUG] K: player_died")
			EventBus.player_died.emit()
		KEY_H:
			var heat := $HeatSystem as HeatSystem
			heat.debug_add_heat(50.0)


func _connect_autoplay_logs() -> void:
	print("[AUTOPLAY] activo: contengo una anomalía cada %.1f s, solo en PLAYING" % AUTOPLAY_INTERVAL)
	EventBus.round_started.connect(func(n: int, remaining: int) -> void: print("[SIGNAL] round_started(%d, remaining=%d)" % [n, remaining]))
	EventBus.floor_unlocked.connect(func(f: int) -> void: print("[SIGNAL] floor_unlocked(%d)" % f))
	EventBus.round_won.connect(func(n: int) -> void: print("[SIGNAL] round_won(%d)" % n))
	EventBus.round_failed.connect(func(reason: StringName) -> void: print("[SIGNAL] round_failed(%s)" % reason))
	EventBus.heat_maxed.connect(func() -> void: print("[SIGNAL] heat_maxed()"))
	EventBus.game_won.connect(_on_autoplay_game_won)
	# Extra para verificar el reintento: que las anomalías contenidas no se reinstancien.
	EventBus.anomaly_spawned.connect(func(a: Node) -> void: print("[SIGNAL] anomaly_spawned(%s)" % _describe(a)))
	EventBus.anomaly_contained.connect(func(a: Node) -> void: print("[SIGNAL] anomaly_contained(%s)" % _describe(a)))


func _start_autoplay_timers() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOPLAY_INTERVAL
	timer.timeout.connect(_autoplay_tick)
	add_child(timer)
	timer.start()
	get_tree().create_timer(AUTOPLAY_TIMEOUT).timeout.connect(_on_autoplay_timeout)


func _autoplay_tick() -> void:
	# Durante ROUND_INTRO la papa y las anomalías están congeladas: no se contiene ni se fuerza nada.
	if GameManager.state != GameManager.PLAYING:
		return
	var rm: RoundManager = $RoundManager
	if not rm.active:
		return
	if not _forced_death_done and rm.current_round == AUTOPLAY_FORCED_DEATH_ROUND and rm.contained_ids.size() >= AUTOPLAY_FORCED_DEATH_AFTER:
		_forced_death_done = true
		print("[AUTOPLAY] fuerzo player_died en la ronda %d con %d contenidas" % [rm.current_round, rm.contained_ids.size()])
		EventBus.player_died.emit()
		return
	var target := _nearest_anomaly()
	if target != null:
		target.call(&"contain")


func _on_autoplay_game_won() -> void:
	print("[SIGNAL] game_won()")
	print("[AUTOPLAY] partida completa. GameManager.state=%s" % GameManager.state)
	# GameManager ya cambió a outro y este nodo puede estar fuera del árbol: se usa el SceneTree global.
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(1.0).timeout.connect(tree.quit)


func _on_autoplay_timeout() -> void:
	print("[AUTOPLAY] TIMEOUT tras %.0f s sin game_won (state=%s, ronda=%d)" % [AUTOPLAY_TIMEOUT, GameManager.state, GameManager.current_round])
	var tree := Engine.get_main_loop() as SceneTree
	tree.quit(1)


func _nearest_anomaly() -> Node:
	var from := Vector3.ZERO
	var player := get_node_or_null("Player") as Node3D
	if player != null:
		from = player.global_position
	var best: Node = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"anomaly"):
		var body := node as Node3D
		if body == null or body.is_queued_for_deletion() or not body.has_method(&"contain"):
			continue
		var d := body.global_position.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = body
	return best


func _describe(anomaly: Node) -> String:
	if not is_instance_valid(anomaly):
		return "anomalía ?"
	return "anomalía %s" % String(anomaly.get(&"spawn_id"))
