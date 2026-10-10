# level/building.gd
# Raiz de level/building.tscn. Persona C (c-nivel).
# Interfaz interna CONGELADA v1 (docs/flujo-subagentes-persona-C.md, seccion 2).
# Los nombres de nodo (F1_A..F3_D, PlayerSpawn, Container_F<n>, BlockF<n>) son parte del contrato.
class_name Building
extends Node3D


## Marker3D con ese nombre (F1_A a F3_D). Devuelve null si no existe.
func get_spawn(spawn_id: StringName) -> Marker3D:
	var marker := find_child(String(spawn_id), true, false) as Marker3D
	if marker == null:
		push_error("Building: no existe el spawn '%s'" % String(spawn_id))
	return marker


## Posicion global del Marker3D PlayerSpawn (piso 1).
func get_player_spawn() -> Vector3:
	var marker := get_node_or_null("PlayerSpawn") as Marker3D
	if marker == null:
		push_error("Building: falta el nodo PlayerSpawn")
		return global_position
	return marker.global_position


## Marker3D Container_F<n> del piso indicado (tambien en el grupo container).
func get_floor_container(floor_number: int) -> Marker3D:
	var container := get_node_or_null("Container_F%d" % floor_number) as Marker3D
	if container == null:
		push_error("Building: no existe Container_F%d" % floor_number)
	return container


## Libera BlockF<n>. Es idempotente: si ya no existe, no hace nada.
## No emite floor_unlocked; eso lo emite RoundManager.
func unlock_floor(floor_number: int) -> void:
	var block := get_node_or_null("BlockF%d" % floor_number)
	if block == null or block.is_queued_for_deletion():
		return
	block.queue_free()
