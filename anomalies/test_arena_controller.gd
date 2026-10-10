class_name TestArenaController
extends Node3D

## Controlador de la arena de pruebas y Editor Manual Pre-Partida.
## Permite configurar cantidad de entidades con steppers limpios,
## selector de dificultad táctica (1-6) y pisos (1 a 3 + sótano).

const SCENE_CUCUMBER := preload("res://anomalies/cucumber.tscn")
const SCENE_LETTUCE := preload("res://anomalies/lettuce.tscn")
const SCENE_PEA := preload("res://anomalies/pea.tscn")

@export var cucumber_count: int = 1
@export var lettuce_count: int = 1
@export var pea_count: int = 1
@export_range(1, 6) var difficulty_level: int = 4
@export_range(1, 3) var active_floors: int = 2

@onready var player: Node3D = $Player
@onready var anomalies_container: Node3D = $SpawnedAnomalies
@onready var setup_canvas: CanvasLayer = $SetupUI
@onready var hud_canvas: CanvasLayer = $UI
@onready var hud_label: Label = $UI/HUDCard/Margin/VBox/Label
@onready var floor_2_node: Node3D = $Architecture/Floor2
@onready var floor_3_node: Node3D = $Architecture/Floor3
@onready var ladder_f1_f2: Node3D = $Architecture/Ladder_F1_F2
@onready var ladder_f2_f3: Node3D = $Architecture/Ladder_F2_F3

# Referencias del editor manual rediseñado
@onready var lbl_cuc_val: Label = %LblCucVal
@onready var btn_cuc_minus: Button = %BtnCucMinus
@onready var btn_cuc_plus: Button = %BtnCucPlus

@onready var lbl_let_val: Label = %LblLetVal
@onready var btn_let_minus: Button = %BtnLetMinus
@onready var btn_let_plus: Button = %BtnLetPlus

@onready var lbl_pea_val: Label = %LblPeaVal
@onready var btn_pea_minus: Button = %BtnPeaMinus
@onready var btn_pea_plus: Button = %BtnPeaPlus

@onready var btn_diff_prev: Button = %BtnDiffPrev
@onready var btn_diff_next: Button = %BtnDiffNext
@onready var lbl_diff_title: Label = %LblDiffTitle
@onready var lbl_diff_dots: Label = %LblDiffDots
@onready var lbl_diff_desc: Label = %LblDiffDesc

@onready var btn_floor_1: Button = %BtnFloor1
@onready var btn_floor_2: Button = %BtnFloor2
@onready var btn_floor_3: Button = %BtnFloor3

@onready var btn_start: Button = %BtnStart
@onready var btn_reopen: Button = $UI/BtnReopenSetup


func _ready() -> void:
	_init_setup_ui()
	show_setup_editor()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			show_setup_editor()


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
	
	btn_diff_prev.pressed.connect(func():
		difficulty_level = maxi(difficulty_level - 1, 1)
		_update_diff_ui()
	)
	btn_diff_next.pressed.connect(func():
		difficulty_level = mini(difficulty_level + 1, 6)
		_update_diff_ui()
	)
	
	btn_floor_1.pressed.connect(func(): _set_floors(1))
	btn_floor_2.pressed.connect(func(): _set_floors(2))
	btn_floor_3.pressed.connect(func(): _set_floors(3))
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_reopen.pressed.connect(show_setup_editor)
	
	_update_diff_ui()
	_update_floor_buttons()


func _update_entity_labels() -> void:
	lbl_cuc_val.text = str(cucumber_count)
	lbl_let_val.text = str(lettuce_count)
	lbl_pea_val.text = str(pea_count)


func _update_diff_ui() -> void:
	var titles: Array[String] = [
		"NIVEL 1: FÁCIL (BÁSICO)",
		"NIVEL 2: FÁCIL+ (ESTÁNDAR)",
		"NIVEL 3: PROMEDIO (REBOTE EN TECHOS)",
		"NIVEL 4: PROMEDIO+ (REBOTE ERRÁTICO)",
		"NIVEL 5: INTELIGENTE (LEADING SHOT)",
		"NIVEL 6: PAC-MAN COORDINADO"
	]
	lbl_diff_title.text = titles[clamp(difficulty_level - 1, 0, 5)]
	
	var dots := ""
	for i in range(1, 7):
		if i <= difficulty_level:
			dots += "● "
		else:
			dots += "○ "
	lbl_diff_dots.text = dots.strip_edges()
	
	match difficulty_level:
		1:
			lbl_diff_desc.text = "Pepino huye solo a corta distancia. Lechuga rebota lineal en suelo. Guisante dispara recto a intervalo largo."
		2:
			lbl_diff_desc.text = "Reacciones estándar y velocidad base. Las anomalías responden con mayor fluidez."
		3:
			lbl_diff_desc.text = "Lechuga rebota elásticamente en techos y paredes sólidas. Guisante acelera su cadencia a 2.0s."
		4:
			lbl_diff_desc.text = "Pepino busca escaleras si es acorralado. Lechuga salta al techo para esquivar slides y contraataca si fallas."
		5:
			lbl_diff_desc.text = "Pepino omnisciente. Guisante predice tu trayectoria de carrera (leading shot) y retrocede disparando si te acercas."
		6:
			lbl_diff_desc.text = "Estrategia Pac-Man coordinada: el pepino usa lechugas y guisantes como escudo humano, emboscándote en equipo."


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
	hud_canvas.visible = false
	get_tree().paused = true


func _on_btn_start_pressed() -> void:
	setup_canvas.visible = false
	hud_canvas.visible = true
	get_tree().paused = false
	
	_apply_floor_configuration()
	_respawn_simulation()


func _apply_floor_configuration() -> void:
	floor_2_node.visible = (active_floors >= 2)
	floor_2_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	ladder_f1_f2.visible = (active_floors >= 2)
	ladder_f1_f2.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	
	floor_3_node.visible = (active_floors >= 3)
	floor_3_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED
	ladder_f2_f3.visible = (active_floors >= 3)
	ladder_f2_f3.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED


func _respawn_simulation() -> void:
	for child in anomalies_container.get_children():
		child.queue_free()
	
	if player != null and player.has_method("reset_to"):
		player.call("reset_to", Vector3(-10.0, -3.5, 0.0))
	elif player != null:
		player.global_position = Vector3(-10.0, -3.5, 0.0)
		player.velocity = Vector3.ZERO
		
	var floor_heights: Array[float] = [0.5]
	if active_floors >= 2:
		floor_heights.append(4.5)
	if active_floors >= 3:
		floor_heights.append(8.5)
		
	for i in range(cucumber_count):
		var cuc := SCENE_CUCUMBER.instantiate() as Anomaly
		cuc.difficulty = difficulty_level
		anomalies_container.add_child(cuc)
		var f_y: float = floor_heights[i % floor_heights.size()]
		var pos_x: float = randf_range(-4.0, 8.0)
		cuc.global_position = Vector3(pos_x, f_y, 0.0)
		
	for i in range(lettuce_count):
		var let := SCENE_LETTUCE.instantiate() as Anomaly
		let.difficulty = difficulty_level
		anomalies_container.add_child(let)
		var f_y: float = floor_heights[(i + 1) % floor_heights.size()]
		var pos_x: float = randf_range(-6.0, 7.0)
		let.global_position = Vector3(pos_x, f_y + 0.5, 0.0)
		
	for i in range(pea_count):
		var pea := SCENE_PEA.instantiate() as Anomaly
		pea.difficulty = difficulty_level
		anomalies_container.add_child(pea)
		var f_y: float = floor_heights[(i + 2) % floor_heights.size()]
		var pos_x: float = randf_range(-3.0, 9.0)
		pea.global_position = Vector3(pos_x, f_y, 0.0)
		
	_update_hud_status()


func _physics_process(_delta: float) -> void:
	if not setup_canvas.visible:
		_update_hud_status()


func _update_hud_status() -> void:
	var alive_cuc := 0
	var alive_let := 0
	var alive_pea := 0
	for child in anomalies_container.get_children():
		if child is CucumberAnomaly and not child.is_contained:
			alive_cuc += 1
		elif child is LettuceAnomaly and not child.is_contained:
			alive_let += 1
		elif child is PeaAnomaly and not child.is_contained:
			alive_pea += 1
			
	var diff_names: Array[String] = ["Fácil", "Fácil+", "Promedio", "Promedio+", "Inteligente", "Pac-Man"]
	var diff_str: String = diff_names[clamp(difficulty_level - 1, 0, 5)]
	
	hud_label.text = "SIMULADOR • Dificultad %d (%s) • %d Pisos (+ Sótano)\nVivas -> Pepinos: %d  |  Lechugas: %d  |  Guisantes: %d\nWASD (Mover/Escalar) | Espacio (Salto) | Shift (Slide) | E (Herbicida)" % [
		difficulty_level, diff_str, active_floors, alive_cuc, alive_let, alive_pea
	]
