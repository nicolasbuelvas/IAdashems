extends Control
## Escena de prueba del HUD y la tarjeta de ronda.
## Cumple el criterio de aceptación de D: "el HUD reacciona a todas las señales
## usando un script de prueba que las emite", sin depender de EventBus (C).

@onready var emitter = $TestSignalEmitter


func _ready() -> void:
	$HUD.attach_source(emitter)
