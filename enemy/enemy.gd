extends CharacterBody3D
## Enemigo que huye del jugador a lo largo del pasillo (eje X local del nodo).

@export var player: Node3D
@export var speed: float = 3.0
@export var acceleration: float = 20.0
@export var gravity: float = 20.0
## Distancia a la que el enemigo detecta al jugador y empieza a huir.
@export var flee_distance: float = 6.0


func _physics_process(delta: float) -> void:
	var right := global_transform.basis.x
	var dir := 0.0
	if player != null:
		var offset := (global_position - player.global_position).dot(right)
		if absf(offset) < flee_distance:
			dir = 1.0 if offset >= 0.0 else -1.0

	var current := velocity.dot(right)
	var vy := velocity.y
	if not is_on_floor():
		vy -= gravity * delta
	velocity = right * move_toward(current, dir * speed, acceleration * delta) + Vector3.UP * vy
	move_and_slide()
