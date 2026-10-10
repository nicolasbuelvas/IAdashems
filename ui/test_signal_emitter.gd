extends Node
## EMISOR DE PRUEBAS — solo para validar la UI sin depender de C.
## No se instancia dentro de hud.tscn: vive en ui/hud_test.tscn.
## Reproduce las señales del contrato de EventBus (spec 2.3).

signal heat_changed(value: float, max_value: float)
signal player_health_changed(current: int, max_hp: int)
signal round_timer_changed(seconds_left: float)
signal anomalies_remaining_changed(remaining: int)
signal herbicide_cooldown_changed(progress: float)  # 0.0 = recién lanzado, 1.0 = listo
signal herbicide_ready()
signal round_started(round_number: int, remaining: int)
signal floor_unlocked(floor_number: int)

var current_heat := 0.0
var current_hp := 3
var current_time := 90.0
var current_anomalies := 5
var current_cooldown_progress := 0.0
var current_round := 1

var _round_clock := 0.0


func _ready() -> void:
	randomize()
	# Diferido: así HUD y tarjeta ya se conectaron cuando llegan las señales.
	call_deferred("_emit_initial")


func _emit_initial() -> void:
	heat_changed.emit(current_heat, 100.0)
	player_health_changed.emit(current_hp, 3)
	round_timer_changed.emit(current_time)
	anomalies_remaining_changed.emit(current_anomalies)
	herbicide_cooldown_changed.emit(current_cooldown_progress)
	round_started.emit(current_round, current_anomalies)


func _process(delta: float) -> void:
	current_heat += delta * 5.0
	if current_heat > 100.0:
		current_heat = 0.0
	heat_changed.emit(current_heat, 100.0)

	current_time -= delta
	if current_time < 0.0:
		current_time = 90.0
	round_timer_changed.emit(current_time)

	current_cooldown_progress += delta * 0.2
	if current_cooldown_progress >= 1.0:
		current_cooldown_progress = 0.0
		herbicide_ready.emit()
	else:
		herbicide_cooldown_changed.emit(current_cooldown_progress)

	_round_clock += delta
	if _round_clock >= 6.0:
		_round_clock = 0.0
		current_round = current_round % 6 + 1
		round_started.emit(current_round, current_anomalies)
		if current_round == 3 or current_round == 6:
			floor_unlocked.emit(2 if current_round == 3 else 3)

	# Simula un golpe de vez en cuando
	if randf() < 0.001:
		current_hp = 3 if current_hp <= 0 else current_hp - 1
		player_health_changed.emit(current_hp, 3)

	# Simula la contención de anomalías
	if randf() < 0.005 and current_anomalies > 0:
		current_anomalies -= 1
		anomalies_remaining_changed.emit(current_anomalies)
		if current_anomalies == 0:
			current_anomalies = 5  # reinicio para la demo
