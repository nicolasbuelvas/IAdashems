class_name FrenchFriesExplosion
extends Node3D

class FryParticle:
	var node: Node3D
	var velocity: Vector3
	var rot_velocity: Vector3

var _particles: Array[FryParticle] = []
var _gravity: float = 26.0
var _lifetime: float = 4.0


func _ready() -> void:
	_spawn_blast_sprite()


func _spawn_blast_sprite() -> void:
	var anim_sprite := AnimatedSprite3D.new()
	var frames := SpriteFrames.new()
	frames.add_animation(&"blast")
	frames.set_animation_loop(&"blast", false)
	frames.set_animation_speed(&"blast", 15.0)
	for i in 6:
		var tex := load("res://Sprites/EXPLOSION/explosion_000%d.png" % i) as Texture2D
		if tex != null:
			frames.add_frame(&"blast", tex)
	anim_sprite.sprite_frames = frames
	anim_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	anim_sprite.pixel_size = 0.024
	anim_sprite.position = Vector3(0.0, 0.2, 0.1)
	add_child(anim_sprite)
	anim_sprite.play(&"blast")
	anim_sprite.animation_finished.connect(func(): anim_sprite.queue_free())


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
