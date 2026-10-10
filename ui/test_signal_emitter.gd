extends Node

# Simula las señales del EventBus para probar el HUD

signal heat_changed(value: float, max_value: float)
signal player_health_changed(current: int, max_hp: int)
signal round_timer_changed(seconds_left: float)
signal anomalies_remaining_changed(remaining: int)
signal herbicide_cooldown_changed(progress: float) # 0.0 = recién lanzado, 1.0 = listo
signal herbicide_ready()

var current_heat: float = 0.0
var current_hp: int = 3
var current_time: float = 90.0
var current_anomalies: int = 5
var current_cooldown_progress: float = 0.0

func _ready():
	# Añadir este nodo al autoload para que el HUD lo encuentre
	# Ojo: esto es solo para TESTING. No debe ir en producción.
	add_child(self)
	set_name("TestSignalEmitter")

	# Emitir señales iniciales
	heat_changed.emit(current_heat, 100.0)
	player_health_changed.emit(current_hp, 3)
	round_timer_changed.emit(current_time)
	anomalies_remaining_changed.emit(current_anomalies)
	herbicide_cooldown_changed.emit(current_cooldown_progress)
	herbicide_ready.emit()

func _process(delta):
	# Simular cambio de valores para probar el HUD
	current_heat += delta * 5
	if current_heat > 100:
		current_heat = 0
	heat_changed.emit(current_heat, 100.0)

	current_time -= delta
	if current_time < 0:
		current_time = 90.0
	round_timer_changed.emit(current_time)

	current_cooldown_progress += delta * 0.2
	if current_cooldown_progress > 1.0:
		current_cooldown_progress = 0.0
		herbicide_ready.emit()
	else:
		herbicide_cooldown_changed.emit(current_cooldown_progress)

	# Simular un golpe de vez en cuando
	if randf() < 0.001:
		current_hp -= 1
		if current_hp < 0:
			current_hp = 3
		player_health_changed.emit(current_hp, 3)

	# Simular contención de anomalía
	if randf() < 0.005 and current_anomalies > 0:
		current_anomalies -= 1
		anomalies_remaining_changed.emit(current_anomalies)
		if current_anomalies == 0:
			current_anomalies = 5 # Reset para demo