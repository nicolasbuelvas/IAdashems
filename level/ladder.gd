class_name VerticalLadder
extends Node3D

## Escalera vertical estilo Minecraft (no rampa).
## Una vez iniciada la animación de subir o bajar, no se puede cancelar.

@export var bottom_y: float = 0.0
@export var top_y: float = 3.8
@export var bottom_exit_offset_x: float = -0.8
@export var top_exit_offset_x: float = 1.0

## Holgura (m) sobre la caja del área para el cuerpo que la toca (origen del cuerpo en los pies).
const INSIDE_MARGIN := 1.0

@onready var area: Area3D = $Area3D


func _ready() -> void:
	add_to_group("stairs")
	add_to_group("ladder")


func _physics_process(_delta: float) -> void:
	for body in area.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		if not body.has_method("start_climb"):
			continue
		if body.get("is_climbing") == true:
			continue
		if body.get("_post_climb_cooldown") != null and body.get("_post_climb_cooldown") > 0.0:
			continue
		if not _is_really_inside(body):
			continue

		var ladder_x := global_position.x
		var mid_y := (bottom_y + top_y) * 0.5
		var is_near_bottom := body.global_position.y < mid_y
		var is_near_top := body.global_position.y >= mid_y
		
		# Control de escalada para el jugador:
		if body.is_in_group("player"):
			var wants_up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
			var wants_down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
			
			if is_near_bottom and wants_up:
				body.call("start_climb", top_y, ladder_x + top_exit_offset_x, ladder_x)
			elif is_near_top and wants_down:
				body.call("start_climb", bottom_y, ladder_x + bottom_exit_offset_x, ladder_x)


## get_overlapping_bodies() se actualiza en el paso de física, no al mover un cuerpo. Tras un
## teletransporte (reset_to al empezar ronda) la escalera aún ve a la papa en ese frame y, con W/S
## pulsada, la volvía a enganchar en su sitio viejo. Se comprueba la posición real contra la caja del área.
func _is_really_inside(body: Node3D) -> bool:
	var shape_node := area.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	var box := shape_node.shape as BoxShape3D if shape_node != null else null
	if box == null:
		return true
	var local := shape_node.global_transform.affine_inverse() * body.global_position
	var half := box.size * 0.5 + Vector3(INSIDE_MARGIN, INSIDE_MARGIN, INSIDE_MARGIN)
	return absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z
