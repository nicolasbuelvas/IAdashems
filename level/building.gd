# level/building.gd
# Raiz de level/building.tscn. Persona C (c-nivel).
# Interfaz interna CONGELADA v1 (docs/flujo-subagentes-persona-C.md, seccion 2).
# Los nombres de nodo (F1_A..F3_D, PlayerSpawn, Container_F<n>, BlockF<n>) son parte del contrato.
#
# Escaleras: LaddersF<n> contiene las escaleras que llevan al piso n. Mientras el piso esta cerrado,
# ese nodo se saca del arbol: las anomalias navegan con el grupo "ladder" y no deben verlas.
# unlock_floor(n) lo vuelve a meter y libera la barricada BlockF<n>.
class_name Building
extends Node3D

## Numero de piso -> LaddersF<n> sacado del arbol (piso cerrado).
var _locked_ladders: Dictionary = {}


func _ready() -> void:
	for child in get_children():
		if not child.name.begins_with("LaddersF"):
			continue
		var floor_number := int(String(child.name).trim_prefix("LaddersF"))
		if floor_number > 1:
			_locked_ladders[floor_number] = child
			remove_child(child)


func _exit_tree() -> void:
	for holder in _locked_ladders.values():
		if is_instance_valid(holder):
			holder.queue_free()
	_locked_ladders.clear()


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


## Abre el piso: activa sus escaleras y libera BlockF<n>. Es idempotente.
## No emite floor_unlocked; eso lo emite RoundManager.
func unlock_floor(floor_number: int) -> void:
	if _locked_ladders.has(floor_number):
		var holder: Node = _locked_ladders[floor_number]
		_locked_ladders.erase(floor_number)
		if is_instance_valid(holder):
			add_child(holder)
	var block := get_node_or_null("BlockF%d" % floor_number)
	if block == null or block.is_queued_for_deletion():
		return
	block.queue_free()


## true si el piso ya tiene sus escaleras activas (piso 1 siempre).
func is_floor_open(floor_number: int) -> bool:
	return floor_number <= 1 or not _locked_ladders.has(floor_number)
