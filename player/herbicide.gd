class_name Herbicide
extends Area3D

const HERBICIDE_SPEED := 14.0
const _LIFETIME := 5.0

var direction := Vector3.RIGHT
var speed: float = HERBICIDE_SPEED
var _lifetime_left := _LIFETIME
var _spent := false


func _ready() -> void:
	direction = direction.normalized()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _spent:
		return
	global_position += direction * speed * delta
	_lifetime_left -= delta
	if _lifetime_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	_handle_impact(body)


func _on_area_entered(area: Area3D) -> void:
	# Los proyectiles enemigos no interceptan el herbicida: se atraviesan.
	if area is PeaProjectile:
		return
	_handle_impact(area)


func _handle_impact(target: Node) -> void:
	if _spent:
		return
	_spent = true
	if target.has_method("on_herbicide_hit"):
		target.call("on_herbicide_hit")
	queue_free()
