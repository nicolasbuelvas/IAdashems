extends Control

@onready var heat_bar = $"TopBar/HeatBar"
@onready var clock_label = $"TopBar/ClockLabel"
@onready var life_icons = [
	$"BottomBar/HealthIcons/Life1",
	$"BottomBar/HealthIcons/Life2",
	$"BottomBar/HealthIcons/Life3",
]
@onready var anomalies_label = $"BottomBar/AnomaliesLabel"
@onready var herbicide_icon = $"BottomBar/HerbicideIcon"


func _ready():
	# Conectar a un emisor de prueba si el EventBus no está disponible
	# En un entorno real, esto se conectaría al EventBus global.
	var test_emitter = get_node_or_null("/root/TestSignalEmitter")
	if test_emitter:
		test_emitter.heat_changed.connect(_on_heat_changed)
		test_emitter.player_health_changed.connect(_on_player_health_changed)
		test_emitter.round_timer_changed.connect(_on_round_timer_changed)
		test_emitter.anomalies_remaining_changed.connect(_on_anomalies_remaining_changed)
		test_emitter.herbicide_cooldown_changed.connect(_on_herbicide_cooldown_changed)
		test_emitter.herbicide_ready.connect(_on_herbicide_ready)

func _on_heat_changed(value: float, max_value: float):
	heat_bar.value = value
	heat_bar.max_value = max_value
	# Lógica para cambiar color de barra si el calor es alto (pendiente)

func _on_player_health_changed(current: int, max_hp: int):
	for i in range(max_hp):
		if i < current:
			life_icons[i].visible = true
		else:
			life_icons[i].visible = false

func _on_round_timer_changed(seconds_left: float):
	var minutes = int(seconds_left / 60)
	var seconds = int(fmod(seconds_left, 60))
	clock_label.text = "%02d:%02d" % [minutes, seconds]

func _on_anomalies_remaining_changed(remaining: int):
	anomalies_label.text = "Anomalías: %d" % remaining

func _on_herbicide_cooldown_changed(progress: float):
	# Oscurecer icono según el progreso del cooldown (0.0 a 1.0)
	var color = Color(1.0, 1.0, 1.0, 1.0 - progress * 0.7) # Se oscurece hasta un 30% visible
	herbicide_icon.modulate = color

func _on_herbicide_ready():
	herbicide_icon.modulate = Color(1.0, 1.0, 1.0, 1.0) # Icono brillante
	# Lógica para hacer temblar el icono (pendiente)
