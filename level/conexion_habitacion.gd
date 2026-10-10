class_name ConexionHabitacion
extends Area3D
## Puerta/escalera entre habitaciones. Colócala (hija de una habitación) con el
## origen a la altura del piso y asigna `destino` a otra conexión. Al estar encima
## y pulsar arriba (W / flecha arriba) el jugador aparece en la conexión destino.
## Si el destino no tiene `destino`, se enlaza de vuelta automáticamente.

## Conexión a la que lleva.
@export var destino: NodePath
@export var tamano := Vector3(1.0, 2.0, 2.0)

var _jugador: Node3D
var _bloqueada := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var forma := BoxShape3D.new()
	forma.size = tamano
	var col := CollisionShape3D.new()
	col.shape = forma
	col.position.y = tamano.y * 0.5
	add_child(col)
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var otra := _destino_nodo()
	if otra != null and otra.destino.is_empty():
		otra.destino = otra.get_path_to(self)


func _physics_process(_delta: float) -> void:
	if _jugador == null or _bloqueada:
		return
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		_viajar()


func _viajar() -> void:
	var otra := _destino_nodo()
	if otra == null:
		return
	# Evita rebotar de vuelta mientras el jugador sigue pulsando arriba.
	otra._bloqueada = true
	_jugador.global_position = otra.global_position + Vector3(0.0, 0.1, 0.0)
	if _jugador is CharacterBody3D:
		(_jugador as CharacterBody3D).velocity = Vector3.ZERO


func _destino_nodo() -> ConexionHabitacion:
	if destino.is_empty():
		return null
	return get_node_or_null(destino) as ConexionHabitacion


func _al_entrar(cuerpo: Node3D) -> void:
	if cuerpo.is_in_group("player"):
		_jugador = cuerpo


func _al_salir(cuerpo: Node3D) -> void:
	if cuerpo == _jugador:
		_jugador = null
		_bloqueada = false
