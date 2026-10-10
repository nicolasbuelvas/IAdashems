class_name OfficeHeatVisuals
extends Node

## Controla la estética del meme "This is fine" quemando progresivamente la oficina según el calor.

var _flames: Array[Node3D] = []
var _target_root: Node3D
var _sun_light: DirectionalLight3D


func setup(root: Node3D) -> void:
	_target_root = root
	var bus := root.get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("heat_changed"):
		bus.connect("heat_changed", _on_heat_changed)
	_sun_light = root.find_child("Sun", true, false) as DirectionalLight3D
	_create_flames()


func _create_flames() -> void:
	if _target_root == null:
		return
	var decor := _target_root.find_child("Decor", true, false)
	var targets: Array[Node3D] = []
	if decor != null:
		for child in decor.get_children():
			if child is Node3D and child.name.begins_with("Desk"):
				targets.append(child)
	if targets.is_empty():
		var arch := _target_root.find_child("Architecture", true, false)
		if arch != null:
			for child in arch.get_children():
				if child is Node3D:
					targets.append(child)

	var frames := SpriteFrames.new()
	frames.add_animation(&"burn")
	frames.set_animation_loop(&"burn", true)
	frames.set_animation_speed(&"burn", 8.0)
	for i in 4:
		var tex := load("res://Sprites/FLAMES/flame_%d.png" % i) as Texture2D
		if tex != null:
			frames.add_frame(&"burn", tex)

	for target in targets:
		var flame := AnimatedSprite3D.new()
		flame.sprite_frames = frames
		flame.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		flame.pixel_size = 0.016
		flame.position = Vector3(randf_range(-0.5, 0.5), 0.75, randf_range(-0.1, 0.1))
		flame.visible = false
		target.add_child(flame)
		flame.play(&"burn")
		_flames.append(flame)


func _on_heat_changed(val: float, max_val: float) -> void:
	var ratio := clampf(val / max_val, 0.0, 1.0) if max_val > 0.0 else 0.0
	_apply(ratio)


func _apply(ratio: float) -> void:
	# 1. Llamas cómicas del meme "This is fine"
	var show_flames := ratio >= 0.28
	for flame in _flames:
		if is_instance_valid(flame):
			flame.visible = show_flames
			if show_flames:
				var flame_scale := lerpf(0.45, 1.6, (ratio - 0.28) / 0.72)
				flame.scale = Vector3.ONE * flame_scale
				flame.modulate.a = lerpf(0.6, 1.0, (ratio - 0.28) / 0.72)

	# 2. Luz solar / ambiente caliente y fuego
	if is_instance_valid(_sun_light):
		_sun_light.light_color = Color(1.0, 0.98, 0.95).lerp(Color(1.0, 0.38, 0.12), ratio)
		_sun_light.light_energy = lerpf(1.15, 1.85, ratio)

	# 3. Quemado y chamuscado de muebles y decoraciones
	if _target_root != null:
		var decor := _target_root.find_child("Decor", true, false)
		if decor != null:
			var base_desk_color := Color(0.62, 0.48, 0.32, 1.0)
			var charred_color := Color(0.18, 0.12, 0.08, 1.0)
			var target_color: Color = base_desk_color.lerp(charred_color, ratio)
			for d in decor.get_children():
				if d is MeshInstance3D:
					var mi := d as MeshInstance3D
					var mat := mi.material_override as StandardMaterial3D
					if mat == null:
						mat = StandardMaterial3D.new()
						mi.material_override = mat
					mat.albedo_color = target_color
				elif "modulate" in d:
					d.modulate = Color.WHITE.lerp(Color(0.24, 0.16, 0.12), ratio)
