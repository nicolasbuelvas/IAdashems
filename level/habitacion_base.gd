@tool
class_name HabitacionBase
extends Node3D
## Habitación base 2.5D: genera piso, pared de fondo y paredes de los extremos con
## el GridMap del edificio, más sus colisiones. Se ajusta con `ancho` y `alto`
## (en celdas). El origen del nodo es la esquina izquierda del piso: la habitación
## se extiende hacia +X. Para armar un mapa, coloca varias instancias:
## - Lado a lado: separa `ancho` unidades en X y desmarca `cerrar_derecha` de una
##   y `cerrar_izquierda` de la otra para poder caminar de una a otra.
## - Una sobre otra: sube la de arriba `alto` unidades en Y (su piso hace de techo
##   de la de abajo; desmarca `cerrar_techo` en la de abajo) y abre un hueco con
##   `huecos_piso` en la de arriba, donde va una Escalera (o se sube saltando).

const PROFUNDIDAD := 3
const _LIBRARY := preload("res://MeshesLibrary/MeshLibraryBuilding.meshlib")
## Mismo giro que tenía el nodo Mapa del pasillo: las celdas (x, z) del GridMap
## pasan a ser (z, -x) en el mundo.
const _MAPA_BASIS := Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
## Alto del piso sobre el origen (el piso de la celda y=0 queda centrado en 0.5).
const _PISO_Y := 0.5
const _GROSOR_PISO := 0.2
const _META := &"_habitacion_generado"

## Largo de la habitación, en celdas (eje X).
@export_range(1, 200) var ancho: int = 12:
	set(valor):
		ancho = maxi(valor, 1)
		_reconstruir()
## Alto de la habitación, en celdas (eje Y).
@export_range(1, 50) var alto: int = 3:
	set(valor):
		alto = maxi(valor, 1)
		_reconstruir()
## Pared sólida en el extremo izquierdo. Desmárcala para dejar un pasaje.
@export var cerrar_izquierda: bool = true:
	set(valor):
		cerrar_izquierda = valor
		_reconstruir()
## Pared sólida en el extremo derecho.
@export var cerrar_derecha: bool = true:
	set(valor):
		cerrar_derecha = valor
		_reconstruir()
## Colisión invisible en el techo, para que no se pueda saltar fuera de la habitación.
@export var cerrar_techo: bool = true:
	set(valor):
		cerrar_techo = valor
		_reconstruir()
## Huecos en el piso, como Vector2i(columna_inicial, cuantas_columnas). Sirven para
## subir por una escalera o saltando desde la habitación de abajo, o para caer a ella.
@export var huecos_piso: Array[Vector2i] = []:
	set(valor):
		huecos_piso = valor
		_reconstruir()
@export var item_piso: int = 46:
	set(valor):
		item_piso = valor
		_reconstruir()
@export var item_pared: int = 85:
	set(valor):
		item_pared = valor
		_reconstruir()


func _ready() -> void:
	_reconstruir()


func _reconstruir() -> void:
	if not is_node_ready():
		return
	for hijo in get_children():
		if hijo.has_meta(_META):
			remove_child(hijo)
			hijo.queue_free()
	_crear_gridmap()
	_crear_colisiones()


func _crear_gridmap() -> void:
	var mapa := Node3D.new()
	mapa.name = "Mapa"
	mapa.transform = Transform3D(_MAPA_BASIS, Vector3.ZERO)
	mapa.set_meta(_META, true)

	var gridmap := GridMap.new()
	gridmap.name = "GridMap"
	gridmap.mesh_library = _LIBRARY
	gridmap.cell_size = Vector3.ONE
	# Columna i del mundo (X) -> celda z = -(i + 1). Profundidad: celdas x = -2..0
	# son el piso y x = -3 la pared de fondo.
	var hueco := _columnas_hueco()
	for i in range(ancho):
		var z := -(i + 1)
		if not hueco[i]:
			for x in range(-2, 1):
				gridmap.set_cell_item(Vector3i(x, 0, z), item_piso)
		for y in range(alto):
			gridmap.set_cell_item(Vector3i(-3, y, z), item_pared)
	if cerrar_izquierda:
		_pared_extremo(gridmap, 0)
	if cerrar_derecha:
		_pared_extremo(gridmap, -(ancho + 1))

	mapa.add_child(gridmap)
	add_child(mapa)


func _pared_extremo(gridmap: GridMap, z: int) -> void:
	for x in range(-2, 1):
		for y in range(alto):
			gridmap.set_cell_item(Vector3i(x, y, z), item_pared)


func _crear_colisiones() -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = "Colisiones"
	cuerpo.set_meta(_META, true)

	var piso_base := _PISO_Y - _GROSOR_PISO
	var alto_m := float(alto)
	var z_centro := -0.5  # las celdas x = -2..0 cubren z de -2 a 1
	var hueco := _columnas_hueco()
	var inicio := -1
	for i in range(ancho + 1):
		var libre := i < ancho and not hueco[i]
		if libre and inicio < 0:
			inicio = i
		elif not libre and inicio >= 0:
			var largo := i - inicio
			_caja(cuerpo, Vector3(largo, _GROSOR_PISO, PROFUNDIDAD),
					Vector3(inicio + largo * 0.5, piso_base + _GROSOR_PISO * 0.5, z_centro))
			inicio = -1
	_caja(cuerpo, Vector3(ancho, alto_m, 1.0),
			Vector3(ancho * 0.5, piso_base + alto_m * 0.5, -2.5))
	if cerrar_izquierda:
		_caja(cuerpo, Vector3(1.0, alto_m, PROFUNDIDAD),
				Vector3(-0.5, piso_base + alto_m * 0.5, z_centro))
	if cerrar_derecha:
		_caja(cuerpo, Vector3(1.0, alto_m, PROFUNDIDAD),
				Vector3(ancho + 0.5, piso_base + alto_m * 0.5, z_centro))
	if cerrar_techo:
		_caja(cuerpo, Vector3(ancho, _GROSOR_PISO, PROFUNDIDAD),
				Vector3(ancho * 0.5, piso_base + alto_m + _GROSOR_PISO * 0.5, z_centro))
	add_child(cuerpo)


## 1 en las columnas (0..ancho-1) que tienen hueco en el piso.
func _columnas_hueco() -> PackedByteArray:
	var columnas := PackedByteArray()
	columnas.resize(ancho)
	for h in huecos_piso:
		for i in range(maxi(h.x, 0), mini(h.x + h.y, ancho)):
			columnas[i] = 1
	return columnas


func _caja(cuerpo: StaticBody3D, tamano: Vector3, centro: Vector3) -> void:
	var forma := BoxShape3D.new()
	forma.size = tamano
	var col := CollisionShape3D.new()
	col.shape = forma
	col.position = centro
	cuerpo.add_child(col)
