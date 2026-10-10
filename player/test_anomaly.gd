extends Area3D

var _contact_reported := false


func on_player_contact(player_node: Node) -> void:
	if _contact_reported:
		return
	_contact_reported = true
	print("Test anomaly: player contact detected")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.35, 0.2)
	$MeshInstance3D.material_override = material
	if player_node.has_method("take_damage"):
		player_node.call("take_damage", 1)


func on_herbicide_hit() -> void:
	print("Test anomaly: herbicide hit detected")
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("anomaly_contained"):
		bus.emit_signal("anomaly_contained", self)
	queue_free()
