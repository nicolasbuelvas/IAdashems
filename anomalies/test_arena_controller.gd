class_name TestArenaController
extends Node3D

## Controlador de la arena de pruebas y Entrenamiento de Corredores.
## 3 Pepinos por default en 3 pisos para sesión de entrenamiento y evasión.

const SCENE_CUCUMBER := preload("res://anomalies/cucumber.tscn")
const SCENE_LETTUCE := preload("res://anomalies/lettuce.tscn")
const SCENE_PEA := preload("res://anomalies/pea.tscn")

@export var cucumber_count: int = 3
@export var lettuce_count: int = 0
@export var pea_count: int = 0
@export_range(1, 3) var active_floors: int = 3

@onready var player: Node3D = $Player
@onready var anomalies_container: Node3D = $SpawnedAnomalies
@onready var setup_canvas: CanvasLayer = $SetupUI
@onready var game_over_canvas: CanvasLayer = $GameOverUI
@onready var hud_node: Control = $HUDLayer/HUD
@onready var session_timer_label: Label = $HUDLayer/SessionCard/Label

@onready var floor_2_node: Node3D = $Architecture/Floor2
@onready var floor_3_node: Node3D = $Architecture/Floor3
@onready var ladders_f1_f2: Node3D = $Architecture/Ladders_F1_F2
@onready var ladders_f2_f3: Node3D = $Architecture/Ladders_F2_F3

# Referencias del editor manual
@onready var lbl_cuc_val: Label = %LblCucVal
@onready var btn_cuc_minus: Button = %BtnCucMinus
@onready var btn_cuc_plus: Button = %BtnCucPlus

@onready var lbl_let_val: Label = %LblLetVal
@onready var btn_let_minus: Button = %BtnLetMinus
@onready var btn_let_plus: Button = %BtnLetPlus

@onready var lbl_pea_val: Label = %LblPeaVal
@onready var btn_pea_minus: Button = %BtnPeaMinus
@onready var btn_pea_plus: Button = %BtnPeaPlus

@onready var btn_floor_1: Button = %BtnFloor1
@onready var btn_floor_2: Button = %BtnFloor2
@onready var btn_floor_3: Button = %BtnFloor3

@onready var btn_start: Button = %BtnStart

# Game Over botones
@onready var btn_retry: Button = %BtnRetry
@onready var btn_game_over_setup: Button = %BtnGameOverSetup

var _session_time: float = 0.0
var _session_active: bool = false


func _ready() -> void:
	_init_setup_ui()
	_connect_event_bus()
	# Iniciar sesión directamente con 3 corredores
	_on_btn_start_pressed()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			show_setup_editor()


func _connect_event_bus() -> void:
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("player_died"):
		bus.connect("player_died", _on_player_died)
	if bus and bus.has_signal("anomaly_contained"):
		bus.connect("anomaly_contained", _on_anomaly_contained)


func _init_setup_ui() -> void:
	_update_entity_labels()
	
	btn_cuc_minus.pressed.connect(func():
		cucumber_count = maxi(cucumber_count - 1, 0)
		_update_entity_labels()
	)
	btn_cuc_plus.pressed.connect(func():
		cucumber_count = mini(cucumber_count + 1, 10)
		_update_entity_labels()
	)
	
	btn_let_minus.pressed.connect(func():
		lettuce_count = maxi(lettuce_count - 1, 0)
		_update_entity_labels()
	)
	btn_let_plus.pressed.connect(func():
		lettuce_count = mini(lettuce_count + 1, 10)
		_update_entity_labels()
	)
	
	btn_pea_minus.pressed.connect(func():
		pea_count = maxi(pea_count - 1, 0)
		_update_entity_labels()
	)
	btn_pea_plus.pressed.connect(func():
		pea_count = mini(pea_count + 1, 10)
		_update_entity_labels()
	)
	
	btn_floor_1.pressed.connect(func(): _set_floors(1))
	btn_floor_2.pressed.connect(func(): _set_floors(2))
	btn_floor_3.pressed.connect(func(): _set_floors(3))
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_retry.pressed.connect(_on_btn_retry_pressed)
	btn_game_over_setup.pressed.connect(show_setup_editor)
	
	_update_floor_buttons()


func _update_entity_labels() -> void:
	lbl_cuc_val.text = str(cucumber_count)
	lbl_let_val.text = str(lettuce_count)
	lbl_pea_val.text = str(pea_count)


func _set_floors(f: int) -> void:
	active_floors = f
	_update_floor_buttons()


func _update_floor_buttons() -> void:
	_style_toggle_button(btn_floor_1, active_floors == 1)
	_style_toggle_button(btn_floor_2, active_floors == 2)
	_style_toggle_button(btn_floor_3, active_floors == 3)


func _style_toggle_button(btn: Button, is_active: bool) -> void:
	if is_active:
		btn.theme_type_variation = "PrimaryButton"
	else:
		btn.theme_type_variation = ""


func show_setup_editor() -> void:
	setup_canvas.visible = true
	game_over_canvas.visible = false
	_session_active = false
	get_tree().paused = true


func _on_btn_start_pressed() -> void:
	setup_canvas.visible = false
	game_over_canvas.visible = false
	get_tree().paused = false
	_session_time = 0.0
	_session_active = true
	
	_apply_floor_configuration()
	_respawn_simulation()


func _on_btn_retry_pressed() -> void:
	game_over_canvas.visible = false
	get_tree().paused = false
	_session_time = 0.0
	_session_active = true
	_respawn_simulation()


func _on_player_died() -> void:
	_session_active = false
	game_over_canvas.visible = true
	get_tree().paused = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music"):
		audio.call("play_music", "res://audio/bgm_game_over.ogg")


func _on_anomaly_contained(_anomaly: Node) -> void:
	call_deferred("_update_remaining_anomalies")


func _update_remaining_anomalies() -> void:
	var remaining := 0
	for c in anomalies_container.get_children():
		if c is Anomaly and not c.is_contained:
			remaining += 1
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("anomalies_remaining_changed"):
		bus.emit_signal("anomalies_remaining_changed", remaining)
	if remaining == 0 and _session_active:
		_session_active = false
		print("==================================================")
		print("¡SESIÓN DE ENTRENAMIENTO FINALIZADA!")
		print("TIEMPO TOTAL DE SUPERVIVENCIA DE CORREDORES: %.2f s" % _session_time)
		print("==================================================")


func _apply_floor_configuration() -> void:
	floor_2_node.visible = (active_floors >= 2)
	floor_2_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	ladders_f1_f2.visible = (active_floors >= 2)
	ladders_f1_f2.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	
	floor_3_node.visible = (active_floors >= 3)
	floor_3_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED
	ladders_f2_f3.visible = (active_floors >= 3)
	ladders_f2_f3.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED


func _respawn_simulation() -> void:
	for child in anomalies_container.get_children():
		child.queue_free()
	
	if player != null and player.has_method("reset_to"):
		player.call("reset_to", Vector3(-10.0, -3.5, 0.0))
	elif player != null:
		player.global_position = Vector3(-10.0, -3.5, 0.0)
		player.velocity = Vector3.ZERO
		
	var bus := get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("player_health_changed"):
		bus.emit_signal("player_health_changed", 3, 3)
	if bus and bus.has_signal("heat_changed"):
		bus.emit_signal("heat_changed", 0.0, 100.0)
		
	var floor_heights: Array[float] = [0.5]
	if active_floors >= 2:
		floor_heights.append(4.5)
	if active_floors >= 3:
		floor_heights.append(8.5)
		
	# Instanciar corredores distribuidos en los pisos superiores
	for i in range(cucumber_count):
		var cuc := SCENE_CUCUMBER.instantiate() as Anomaly
		anomalies_container.add_child(cuc)
		var f_y: float = floor_heights[i % floor_heights.size()]
		var pos_x: float = -4.0 + float(i) * 5.0
		cuc.global_position = Vector3(pos_x, f_y, 0.0)
		
	for i in range(lettuce_count):
		var let := SCENE_LETTUCE.instantiate() as Anomaly
		anomalies_container.add_child(let)
		var f_y: float = floor_heights[(i + 1) % floor_heights.size()]
		var pos_x: float = randf_range(-6.0, 7.0)
		let.global_position = Vector3(pos_x, f_y + 0.5, 0.0)
		
	for i in range(pea_count):
		var pea := SCENE_PEA.instantiate() as Anomaly
		anomalies_container.add_child(pea)
		var f_y: float = floor_heights[(i + 2) % floor_heights.size()]
		var pos_x: float = randf_range(-3.0, 9.0)
		pea.global_position = Vector3(pos_x, f_y, 0.0)
		
	var total_anomalies := cucumber_count + lettuce_count + pea_count
	if bus and bus.has_signal("anomalies_remaining_changed"):
		bus.emit_signal("anomalies_remaining_changed", total_anomalies)
		
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music"):
		audio.call("play_music", "res://audio/bgm_gameplay.ogg")


func _process(delta: float) -> void:
	if _session_active:
		_session_time += delta
		var remaining := 0
		for c in anomalies_container.get_children():
			if c is Anomaly and not c.is_contained:
				remaining += 1
		session_timer_label.text = "ENTRENAMIENTO • SUPERVIVENCIA: %.1f s • CORREDORES VIVOS: %d / %d" % [
			_session_time, remaining, cucumber_count
		]
