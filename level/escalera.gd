@tool
class_name Escalera
extends Area3D
## Escalera vertical. El origen va a la altura del piso de abajo (y = 0.5 dentro de
## una habitación) y `alto` es lo que sube, normalmente el `alto` de la habitación.
## Con el jugador frente a ella: W sube, S baja, A/D (arriba o abajo del todo) o
## salto la sueltan. Para atravesar un piso, abre un hueco ahí con `huecos_piso`.

const _GROSOR_RIEL := 0.08
const _SEPARACION_PELDANO := 0.35
## Desfase entre el origen del jugador y la superficie del piso donde se para.
const _PIES := 0.06

## Cuánto sube la escalera, en unidades (el piso de arriba queda a esta altura).
@export_range(0.5, 40.0) var alto: float = 3.0:
	set(valor):
		alto = valor
		_reconstruir()
@export_range(0.3, 3.0) var ancho: float = 0.9:
	set(valor):
		ancho = valor
		_reconstruir()

var _generado: Array[Node] = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_al_entrar)
		body_exited.connect(_al_salir)
	_reconstruir()


## Altura (global) en la que el jugador queda parado sobre el piso de arriba.
func y_cima() -> float:
	return global_position.y + alto + _PIES


func _reconstruir() -> void:
	if not is_node_ready():
		return
	for nodo in _generado:
		remove_child(nodo)
		nodo.queue_free()
	_generado.clear()

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.38, 0.2)
	for lado in [-1.0, 1.0]:
		_caja(Vector3(_GROSOR_RIEL, alto, _GROSOR_RIEL),
				Vector3(lado * ancho * 0.5, alto * 0.5, -1.85), material)
	var peldanos := int(alto / _SEPARACION_PELDANO)
	for n in range(1, peldanos + 1):
		_caja(Vector3(ancho, _GROSOR_RIEL, _GROSOR_RIEL),
				Vector3(0.0, n * _SEPARACION_PELDANO - 0.1, -1.85), material)

	var forma := BoxShape3D.new()
	forma.size = Vector3(ancho, alto + 0.4, 3.0)
	var colision := CollisionShape3D.new()
	colision.shape = forma
	colision.position = Vector3(0.0, (alto + 0.4) * 0.5, -0.5)
	add_child(colision)
	_generado.append(colision)


func _caja(tamano: Vector3, posicion: Vector3, material: Material) -> void:
	var malla := BoxMesh.new()
	malla.size = tamano
	var instancia := MeshInstance3D.new()
	instancia.mesh = malla
	instancia.material_override = material
	instancia.position = posicion
	add_child(instancia)
	_generado.append(instancia)


func _al_entrar(cuerpo: Node3D) -> void:
	if cuerpo.has_method("set_ladder"):
		cuerpo.call("set_ladder", self)


func _al_salir(cuerpo: Node3D) -> void:
	if cuerpo.has_method("clear_ladder"):
		cuerpo.call("clear_ladder", self)
