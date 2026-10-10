class_name TestArenaController
extends Node3D

## Controlador de la arena de pruebas y Editor Manual Pre-Partida.
## Permite configurar cantidad de entidades, dificultad de IA (1-6)
## y número de pisos (1, 2 o 3 pisos además del sótano base).

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
@onready var hud_label: Label = $UI/HUD/Label
@onready var floor_2_node: Node3D = $Architecture/Floor2
@onready var floor_3_node: Node3D = $Architecture/Floor3
@onready var ladder_f1_f2: Node3D = $Architecture/Ladder_F1_F2
@onready var ladder_f2_f3: Node3D = $Architecture/Ladder_F2_F3

# Controles de la UI de configuración
@onready var spin_cucumber: SpinBox = $SetupUI/Panel/VBox/RowCucumber/SpinCucumber
@onready var spin_lettuce: SpinBox = $SetupUI/Panel/VBox/RowLettuce/SpinLettuce
@onready var spin_pea: SpinBox = $SetupUI/Panel/VBox/RowPea/SpinPea
@onready var opt_diff: OptionButton = $SetupUI/Panel/VBox/RowDiff/OptDiff
@onready var opt_floors: OptionButton = $SetupUI/Panel/VBox/RowFloors/OptFloors
@onready var diff_desc_label: Label = $SetupUI/Panel/VBox/DiffDescLabel
@onready var btn_start: Button = $SetupUI/Panel/VBox/BtnStart


func _ready() -> void:
	_init_setup_ui()
	show_setup_editor()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			show_setup_editor()


func _init_setup_ui() -> void:
	spin_cucumber.value = cucumber_count
	spin_lettuce.value = lettuce_count
	spin_pea.value = pea_count
	
	opt_diff.clear()
	opt_diff.add_item("Nivel 1: Fácil (Básico)", 1)
	opt_diff.add_item("Nivel 2: Fácil+ (Movimiento estándar)", 2)
	opt_diff.add_item("Nivel 3: Promedio (Rebote en techos)", 3)
	opt_diff.add_item("Nivel 4: Promedio+ (Rebote errático & táctica)", 4)
	opt_diff.add_item("Nivel 5: Inteligente (Leading shot & evasión)", 5)
	opt_diff.add_item("Nivel 6: Pac-Man Coordinado (Escudos y emboscadas)", 6)
	opt_diff.selected = difficulty_level - 1
	
	opt_floors.clear()
	opt_floors.add_item("1 Piso (+ Sótano)", 1)
	opt_floors.add_item("2 Pisos (+ Sótano)", 2)
	opt_floors.add_item("3 Pisos (+ Sótano)", 3)
	opt_floors.selected = active_floors - 1
	
	_update_diff_description(difficulty_level)
	
	opt_diff.item_selected.connect(func(idx):
		_update_diff_description(idx + 1)
	)
	
	btn_start.pressed.connect(_on_btn_start_pressed)


func _update_diff_description(lvl: int) -> void:
	match lvl:
		1:
			diff_desc_label.text = "IA Básica: El pepino huye linealmente si estás cerca. La lechuga rebota solo en suelo. El guisante dispara recto a intervalo largo."
		2:
			diff_desc_label.text = "IA Fácil+: Movimiento continuo y reacción estándar a la presencia de la papa."
		3:
			diff_desc_label.text = "IA Promedio: La lechuga rebota elásticamente en techos y paredes. El guisante acelera su cadencia de disparo."
		4:
			diff_desc_label.text = "IA Promedio+: El pepino busca escaleras si es arrinconado. La lechuga esquiva slides saltando al techo y castiga si fallas."
		5:
			diff_desc_label.text = "IA Inteligente: El pepino es omnisciente. El guisante predice tu trayectoria (leading shot) y retrocede si te acercas."
		6:
			diff_desc_label.text = "IA Pac-Man Coordinada: El pepino se resguarda detrás de lechugas/guisantes usándolos como escudo humano. ¡Trabajo en equipo hostil!"


func show_setup_editor() -> void:
	setup_canvas.visible = true
	get_tree().paused = true


func _on_btn_start_pressed() -> void:
	cucumber_count = int(spin_cucumber.value)
	lettuce_count = int(spin_lettuce.value)
	pea_count = int(spin_pea.value)
	difficulty_level = opt_diff.selected + 1
	active_floors = opt_floors.selected + 1
	
	setup_canvas.visible = false
	get_tree().paused = false
	
	_apply_floor_configuration()
	_respawn_simulation()


func _apply_floor_configuration() -> void:
	# Piso 1 y Sótano siempre existen
	floor_2_node.visible = (active_floors >= 2)
	floor_2_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	ladder_f1_f2.visible = (active_floors >= 2)
	ladder_f1_f2.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 2) else Node.PROCESS_MODE_DISABLED
	
	floor_3_node.visible = (active_floors >= 3)
	floor_3_node.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED
	ladder_f2_f3.visible = (active_floors >= 3)
	ladder_f2_f3.process_mode = Node.PROCESS_MODE_INHERIT if (active_floors >= 3) else Node.PROCESS_MODE_DISABLED


func _respawn_simulation() -> void:
	# Limpiar anomalías anteriores
	for child in anomalies_container.get_children():
		child.queue_free()
	
	# Reposicionar jugador en el SÓTANO por default (Y = -3.5)
	if player != null and player.has_method("reset_to"):
		player.call("reset_to", Vector3(-10.0, -3.5, 0.0))
	elif player != null:
		player.global_position = Vector3(-10.0, -3.5, 0.0)
		player.velocity = Vector3.ZERO
		
	# Alturas de suelo según piso:
	# Sótano: Y = -3.5 (Jugador)
	# Piso 1: Y = 0.5
	# Piso 2: Y = 4.5
	# Piso 3: Y = 8.5
	var floor_heights: Array[float] = [0.5]
	if active_floors >= 2:
		floor_heights.append(4.5)
	if active_floors >= 3:
		floor_heights.append(8.5)
		
	# Instanciar pepinos
	for i in range(cucumber_count):
		var cuc := SCENE_CUCUMBER.instantiate() as Anomaly
		cuc.difficulty = difficulty_level
		anomalies_container.add_child(cuc)
		var f_y: float = floor_heights[i % floor_heights.size()]
		var pos_x: float = randf_range(-4.0, 8.0)
		cuc.global_position = Vector3(pos_x, f_y, 0.0)
		
	# Instanciar lechugas
	for i in range(lettuce_count):
		var let := SCENE_LETTUCE.instantiate() as Anomaly
		let.difficulty = difficulty_level
		anomalies_container.add_child(let)
		var f_y: float = floor_heights[(i + 1) % floor_heights.size()]
		var pos_x: float = randf_range(-6.0, 7.0)
		let.global_position = Vector3(pos_x, f_y + 0.5, 0.0)
		
	# Instanciar lanzaguisantes
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
			
	var diff_names: Array[String] = ["Fácil", "Fácil+", "Promedio", "Promedio+", "Inteligente", "Pac-Man Coordinado"]
	var diff_str: String = diff_names[clamp(difficulty_level - 1, 0, 5)]
	
	hud_label.text = "SIMULADOR DE ANOMALÍAS [F1: Reconfigurar]
Dificultad: Nivel %d (%s) | Pisos: %d (+ Sótano de inicio)
Activas -> Pepinos: %d | Lechugas: %d | Guisantes: %d
Controles: WASD (Mover/Escalar) | Espacio (Salto) | Shift (Slide) | E (Herbicida)" % [
		difficulty_level, diff_str, active_floors, alive_cuc, alive_let, alive_pea
	]
