class_name FrenchFriesExplosion
extends Node3D

class FryParticle:
	var node: Node3D
	var velocity: Vector3
	var rot_velocity: Vector3

var _particles: Array[FryParticle] = []
var _gravity: float = 26.0
var _lifetime: float = 4.0


func add_fry(node: Node3D, vel: Vector3, rot_vel: Vector3) -> void:
	var p := FryParticle.new()
	p.node = node
	p.velocity = vel
	p.rot_velocity = rot_vel
	_particles.append(p)


func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return

	for p in _particles:
		if is_instance_valid(p.node):
			p.velocity.y -= _gravity * delta
			p.node.position += p.velocity * delta
			p.node.rotation += p.rot_velocity * delta
