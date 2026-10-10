# systems/tests/rm_dummy_anomaly.gd
# Anomalía dummy para round_manager_test.gd. Imita el contrato de B: RoundManager fija spawn_id
# antes de add_child, y _ready() emite anomaly_spawned. No tiene lógica de captura: la simula el test.
extends Node3D

var spawn_id: StringName = &""


func _ready() -> void:
	var bus = get_node("/root/EventBus")
	bus.anomaly_spawned.emit(self)
