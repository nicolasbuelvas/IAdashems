extends CharacterBody3D
## Dummy de anomalía mientras B no entrega anomalies/. Cubo con color que no se mueve.
## Sigue la tabla de docs/spec-mvp-reparto.md 2.6 según kind (0 pepino, 1 lechuga, 2 guisante).
## RoundManager asigna spawn_id antes de add_child, porque _ready() emite anomaly_spawned.

enum Kind { CUCUMBER, LETTUCE, PEA }

var kind: int = Kind.CUCUMBER
var spawn_id: StringName = &""

var _contained: bool = false


func _ready() -> void:
	EventBus.anomaly_spawned.emit(self)


func on_player_contact(player) -> void:
	if _contained:
		return
	match kind:
		Kind.CUCUMBER:
			contain()
		Kind.LETTUCE:
			if player.is_sliding():
				contain()
			else:
				player.take_damage(1)
		Kind.PEA:
			player.take_damage(1)


func on_herbicide_hit() -> void:
	if kind == Kind.PEA:
		contain()


## Desactiva colisiones, emite anomaly_contained una sola vez y se libera.
func contain() -> void:
	if _contained:
		return
	_contained = true
	collision_layer = 0
	collision_mask = 0
	remove_from_group(&"anomaly")
	EventBus.anomaly_contained.emit(self)
	queue_free()
