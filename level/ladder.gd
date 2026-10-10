class_name VerticalLadder
extends Node3D

## Escalera vertical estilo Minecraft (no rampa).
## Una vez iniciada la animación de subir o bajar, no se puede cancelar.

@export var bottom_y: float = 0.0
@export var top_y: float = 3.8
@export var bottom_exit_offset_x: float = -0.8
@export var top_exit_offset_x: float = 1.0

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
