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
			
		var ladder_x := global_position.x
		var is_near_bottom := body.global_position.y <= bottom_y + 1.2
		var is_near_top := body.global_position.y >= top_y - 1.2
		
		# Control de escalada para el jugador:
		if body.is_in_group("player"):
			var wants_up := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
			var wants_down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
			
			if is_near_bottom and wants_up:
				body.call("start_climb", top_y, ladder_x + top_exit_offset_x, ladder_x)
			elif is_near_top and wants_down:
				body.call("start_climb", bottom_y, ladder_x + bottom_exit_offset_x, ladder_x)
		
		# Comportamiento para Pepino que huye:
		elif body.is_in_group("anomaly") and body.has_method("start_climb"):
			if is_near_bottom and not body.get("is_contained"):
				var player := get_tree().get_first_node_in_group("player") as Node3D
				if player != null and player.global_position.y <= bottom_y + 1.5:
					if absf(player.global_position.x - body.global_position.x) < 5.5:
						body.call("start_climb", top_y, ladder_x + top_exit_offset_x, ladder_x)
