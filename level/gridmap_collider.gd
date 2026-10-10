extends StaticBody3D
## Genera colisiones a partir de las celdas de un GridMap: así, al pintar más piso
## y paredes, el personaje las pisa sin tener que crear colisiones a mano.

@export var gridmap: GridMap
## IDs de la MeshLibrary que son piso (plano sin grosor).
@export var floor_items: PackedInt32Array = [46]
## IDs de la MeshLibrary que son pared (cubo de una celda).
@export var wall_items: PackedInt32Array = [85]


func _ready() -> void:
	if gridmap == null:
		return
	var cell := gridmap.cell_size
	for pos in gridmap.get_used_cells():
		var item := gridmap.get_cell_item(pos)
		var center := gridmap.position + gridmap.map_to_local(pos)
		var shape := BoxShape3D.new()
		var col := CollisionShape3D.new()
		if item in floor_items:
			shape.size = Vector3(cell.x, 0.2, cell.z)
			col.position = center - Vector3(0, 0.1, 0)
		elif item in wall_items:
			shape.size = cell
			col.position = center + Vector3(0, cell.y * 0.5, 0)
		else:
			continue
		col.shape = shape
		add_child(col)
