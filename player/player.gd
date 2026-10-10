extends CharacterBody3D
## Jugador 2.5D: se mueve solo hacia la izquierda/derecha de la pantalla,
## que es el eje X local del nodo (rótalo en Y para pasillos que van en otra dirección).

@export var speed: float = 4.0
@export var acceleration: float = 30.0
@export var gravity: float = 20.0

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _physics_process(delta: float) -> void:
	var dir := _get_input_dir()

	var right := global_transform.basis.x
	var current := velocity.dot(right)
	var vy := velocity.y
	if not is_on_floor():
		vy -= gravity * delta
	velocity = right * move_toward(current, dir * speed, acceleration * delta) + Vector3.UP * vy

	move_and_slide()

	if dir != 0.0:
		sprite.flip_h = dir < 0.0
		sprite.play("run")
	else:
		sprite.stop()
		sprite.frame = 0


func _get_input_dir() -> float:
	var dir := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	return clampf(dir, -1.0, 1.0)
