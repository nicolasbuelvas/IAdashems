# systems/tests/heat_system_test.gd
# Prueba headless de HeatSystem (persona C). No es autoload ni escena.
# Ejecutar desde la raíz del proyecto:
#   godot --headless --path . -s res://systems/tests/heat_system_test.gd
# Sale con código 0 si todo pasa, 1 si hay algún FAIL.
#
# Nota: con -s los autoloads existen como nodos (/root/EventBus, /root/GameConfig), pero
# sus nombres globales no se resuelven al compilar este script. Por eso:
#   - EventBus se toma del árbol con get_node() dentro de _initialize().
#   - Las constantes de GameConfig se leen de su script con preload().
#   - heat_system.gd se carga con load() dentro de _initialize(), no con preload().
extends SceneTree

const DT := 0.1  # paso fijo; _process se llama a mano para que la prueba sea determinista
# Estímulos de prueba. No son valores de balance: los de balance se leen de GameConfig.
const STIM_START_FRACTION := 0.5  # calor inicial de la prueba de captura, como fracción de HEAT_MAX
const STIM_HEAT := 30.0  # calor metido a mano antes de round_failed
const STIM_OVERFLOW := 50.0  # exceso sobre HEAT_MAX para probar el tope
const STIM_EXTRA := 10.0  # calor extra con el medidor ya en HEAT_MAX
const GameConfigScript := preload("res://autoload/game_config.gd")

var _failures: int = 0
var _checks: int = 0


func _check(cond: bool, label: String) -> void:
	_checks += 1
	if cond:
		print("OK    ", label)
	else:
		_failures += 1
		print("FAIL  ", label)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


func _step(hs, seconds: float) -> void:
	var n: int = roundi(seconds / DT)
	for i in range(n):
		hs._process(DT)


func _initialize() -> void:
	# En _initialize() el root todavía no está dentro del árbol: add_child no dispararía _ready().
	# Esperar un frame lo deja listo. Después de esto, todo el test es síncrono.
	await process_frame
	var event_bus = root.get_node("EventBus")
	var heat_script = load("res://systems/heat_system.gd")

	var hs = heat_script.new()
	root.add_child(hs)

	var maxed_count := [0]
	var on_maxed := func() -> void:
		maxed_count[0] += 1
	event_bus.heat_maxed.connect(on_maxed)

	var changed_log := [0.0, 0.0]  # último value y max_value de heat_changed
	var changed_count := [0]  # cuántas veces salió heat_changed
	var on_changed := func(v: float, m: float) -> void:
		changed_count[0] += 1
		changed_log[0] = v
		changed_log[1] = m
	event_bus.heat_changed.connect(on_changed)

	# 1. round_started reinicia el estado y emite heat_changed(0, HEAT_MAX).
	event_bus.round_started.emit(1, 3)
	_check(hs.active, "round_started activa el sistema")
	_check(_near(hs.heat, 0.0), "round_started deja el calor en 0")
	_check(hs.active_anomalies == 0, "round_started deja active_anomalies en 0")
	_check(_near(changed_log[0], 0.0) and _near(changed_log[1], GameConfigScript.HEAT_MAX), "round_started emite heat_changed(0, HEAT_MAX)")

	# 2. Sin anomalías: sube HEAT_PER_SEC_TIME por segundo.
	_step(hs, 1.0)
	_check(_near(hs.heat, GameConfigScript.HEAT_PER_SEC_TIME), "sin anomalías sube HEAT_PER_SEC_TIME en un segundo (obtenido %.4f)" % hs.heat)

	# 3. Cada anomalía activa suma HEAT_PER_SEC_PER_ANOMALY por segundo.
	event_bus.round_started.emit(1, 3)
	var a1 := Node.new()
	var a2 := Node.new()
	event_bus.anomaly_spawned.emit(a1)
	event_bus.anomaly_spawned.emit(a2)
	_check(hs.active_anomalies == 2, "dos spawns cuentan dos anomalías activas")
	_step(hs, 1.0)
	_check(_near(hs.heat, GameConfigScript.HEAT_PER_SEC_TIME + 2 * GameConfigScript.HEAT_PER_SEC_PER_ANOMALY), "dos anomalías suman HEAT_PER_SEC_PER_ANOMALY por segundo cada una (obtenido %.4f)" % hs.heat)

	# 4. Reloj expirado: la tasa se multiplica por HEAT_EXPIRED_MULTIPLIER.
	event_bus.round_started.emit(2, 3)
	var a3 := Node.new()
	event_bus.anomaly_spawned.emit(a3)
	event_bus.round_timer_expired.emit()
	_step(hs, 1.0)
	_check(_near(hs.heat, (GameConfigScript.HEAT_PER_SEC_TIME + GameConfigScript.HEAT_PER_SEC_PER_ANOMALY) * GameConfigScript.HEAT_EXPIRED_MULTIPLIER), "reloj expirado multiplica la tasa por HEAT_EXPIRED_MULTIPLIER (obtenido %.4f)" % hs.heat)

	# 5. round_started limpia timer_expired.
	event_bus.round_started.emit(2, 3)
	_check(not hs.timer_expired, "round_started limpia timer_expired")

	# 6. Una captura resta HEAT_COOL_PER_CONTAIN en total, a HEAT_COOL_RATE por segundo.
	# start_heat es STIM_START_FRACTION de HEAT_MAX. cool_steps son los pasos DT que bastan para enfriar la captura del todo,
	# redondeados hacia arriba para que el paso fijo no deje enfriamiento pendiente.
	var start_heat := GameConfigScript.HEAT_MAX * STIM_START_FRACTION
	var cool_steps := ceili(GameConfigScript.HEAT_COOL_PER_CONTAIN / GameConfigScript.HEAT_COOL_RATE / DT)
	var cool_time := cool_steps * DT
	event_bus.round_started.emit(3, 2)
	hs.debug_add_heat(start_heat)
	var a4 := Node.new()
	event_bus.anomaly_spawned.emit(a4)
	event_bus.anomaly_contained.emit(a4)
	_check(hs.active_anomalies == 0, "captura baja active_anomalies a 0")
	_check(_near(hs.pending_cool, GameConfigScript.HEAT_COOL_PER_CONTAIN), "captura agrega HEAT_COOL_PER_CONTAIN de enfriamiento pendiente")
	_step(hs, DT)
	_check(_near(hs.pending_cool, GameConfigScript.HEAT_COOL_PER_CONTAIN - GameConfigScript.HEAT_COOL_RATE * DT), "enfriamiento descuenta HEAT_COOL_RATE por segundo (pendiente tras un paso = %.4f)" % hs.pending_cool)
	_step(hs, (cool_steps - 1) * DT)
	_check(_near(hs.pending_cool, 0.0), "el enfriamiento pendiente llega a 0 (en %.2f s)" % cool_time)
	_check(_near(hs.heat, start_heat + GameConfigScript.HEAT_PER_SEC_TIME * cool_time - GameConfigScript.HEAT_COOL_PER_CONTAIN), "la captura resta HEAT_COOL_PER_CONTAIN en total (obtenido %.4f)" % hs.heat)

	# 7. Reintento: no se cuenta dos veces ni se enfría dos veces.
	event_bus.round_started.emit(4, 2)
	var b1 := Node.new()
	var b2 := Node.new()
	event_bus.anomaly_spawned.emit(b1)
	event_bus.anomaly_spawned.emit(b1)  # duplicado: no debe contar dos veces
	event_bus.anomaly_spawned.emit(b2)
	_check(hs.active_anomalies == 2, "spawn duplicado no suma dos veces (cuenta %d)" % hs.active_anomalies)
	event_bus.anomaly_contained.emit(b1)
	_check(hs.active_anomalies == 1 and _near(hs.pending_cool, GameConfigScript.HEAT_COOL_PER_CONTAIN), "captura de b1 descuenta una vez y enfría una vez")
	event_bus.anomaly_contained.emit(b1)  # captura duplicada: no debe enfriar otra vez
	_check(hs.active_anomalies == 1 and _near(hs.pending_cool, GameConfigScript.HEAT_COOL_PER_CONTAIN), "captura duplicada no enfría ni descuenta de nuevo")
	var b3 := Node.new()
	root.add_child(b3)
	event_bus.anomaly_spawned.emit(b3)
	_check(hs.active_anomalies == 2, "b3 spawneada en el árbol suma (cuenta %d)" % hs.active_anomalies)
	root.remove_child(b3)  # sale del árbol sin captura (tree_exiting)
	_check(hs.active_anomalies == 1, "anomalía que sale del árbol sin captura se descuenta")
	b3.free()

	# Reintento: round_started vacía el conjunto. b2 viene del intento anterior.
	event_bus.round_started.emit(4, 2)
	_check(hs.active_anomalies == 0, "reintento: round_started deja el conteo en 0")
	event_bus.anomaly_contained.emit(b2)  # anomalía del intento anterior: no enfría ni baja el conteo
	_check(hs.active_anomalies == 0 and _near(hs.pending_cool, 0.0), "anomalía de intento anterior no enfría ni baja el conteo")

	# 8. round_failed y round_won desactivan el sistema.
	event_bus.round_started.emit(5, 1)
	hs.debug_add_heat(STIM_HEAT)
	event_bus.round_failed.emit(&"heat")
	var before: float = hs.heat
	_step(hs, 1.0)
	_check(not hs.active and _near(hs.heat, before), "round_failed detiene el calor")
	event_bus.round_started.emit(5, 1)
	event_bus.round_won.emit(5)
	_check(not hs.active, "round_won desactiva el sistema")

	# 9. heat_maxed sale una sola vez por intento al llegar a HEAT_MAX.
	var before_maxed: int = maxed_count[0]
	event_bus.round_started.emit(6, 1)
	hs.debug_add_heat(GameConfigScript.HEAT_MAX + STIM_OVERFLOW)
	_check(_near(hs.heat, GameConfigScript.HEAT_MAX), "el calor se limita a HEAT_MAX")
	_check(maxed_count[0] - before_maxed == 1, "heat_maxed sale una vez al llegar a HEAT_MAX")
	_step(hs, 1.0)
	hs.debug_add_heat(STIM_EXTRA)
	_check(maxed_count[0] - before_maxed == 1, "heat_maxed no vuelve a salir en el mismo intento")
	event_bus.round_started.emit(6, 1)
	hs.debug_add_heat(GameConfigScript.HEAT_MAX)
	_check(maxed_count[0] - before_maxed == 2, "heat_maxed vuelve a salir una vez en un intento nuevo")

	# 10. player_damaged suma HEAT_PER_HIT dentro de ronda.
	event_bus.round_started.emit(6, 1)
	event_bus.player_damaged.emit(1)
	_check(_near(hs.heat, GameConfigScript.HEAT_PER_HIT), "player_damaged suma HEAT_PER_HIT")

	# 10b. Golpe fuera de ronda: no suma y no emite heat_changed.
	event_bus.round_failed.emit(&"health")
	var heat_out: float = hs.heat
	var changes_out: int = changed_count[0]
	event_bus.player_damaged.emit(1)
	_check(_near(hs.heat, heat_out) and changed_count[0] == changes_out, "player_damaged fuera de ronda no suma ni emite heat_changed")

	# 10c. Un golpe que llega a HEAT_MAX emite heat_maxed una sola vez, igual que _process.
	event_bus.round_started.emit(7, 1)
	hs.debug_add_heat(GameConfigScript.HEAT_MAX - GameConfigScript.HEAT_PER_HIT)
	var maxed_before_hit: int = maxed_count[0]
	event_bus.player_damaged.emit(1)
	_check(_near(hs.heat, GameConfigScript.HEAT_MAX) and _near(changed_log[0], GameConfigScript.HEAT_MAX), "un golpe que llega a HEAT_MAX deja el calor en HEAT_MAX y lo publica")
	_check(maxed_count[0] - maxed_before_hit == 1, "un golpe que llega a HEAT_MAX emite heat_maxed una vez")
	event_bus.player_damaged.emit(1)
	_check(maxed_count[0] - maxed_before_hit == 1, "un golpe extra con el calor ya en HEAT_MAX no vuelve a emitir heat_maxed")

	# Limpieza de señales y nodos.
	event_bus.heat_maxed.disconnect(on_maxed)
	event_bus.heat_changed.disconnect(on_changed)
	for n in [a1, a2, a3, a4, b1, b2]:
		n.free()
	hs.free()

	print("---")
	print("%d comprobaciones, %d fallos" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
