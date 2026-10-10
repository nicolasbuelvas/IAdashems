extends Area3D

var _contact_reported := false


func on_player_contact(_player: Node) -> void:
	if _contact_reported:
		return
	_contact_reported = true
	print("Test anomaly: player contact detected")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.35, 0.2)
	$MeshInstance3D.material_override = material


func on_herbicide_hit() -> void:
	print("Test anomaly: herbicide hit detected")
	queue_free()
