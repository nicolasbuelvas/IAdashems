extends Control

@onready var music_slider = $"Center/Rows/MusicRow/MusicSlider"
@onready var sfx_slider = $"Center/Rows/SfxRow/SfxSlider"
@onready var fullscreen_check = $"Center/Rows/FullscreenCheck"
@onready var resolution_option = $"Center/Rows/ResolutionOption"


func _ready():
	# Cargar valores guardados (si hubiera un sistema de guardado)
	music_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) + 80 # Convertir dB a 0-100
	sfx_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")) + 80
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Poblar opciones de resolución
	_populate_resolutions()
	_select_current_resolution()

func _populate_resolutions():
	resolution_option.add_item("1920x1080 (Full HD)")
	resolution_option.set_item_metadata(0, Vector2i(1920, 1080))
	resolution_option.add_item("1280x720 (HD)")
	resolution_option.set_item_metadata(1, Vector2i(1280, 720))
	resolution_option.add_item("960x540 (qHD)")
	resolution_option.set_item_metadata(2, Vector2i(960, 540))

func _select_current_resolution():
	var current_size = DisplayServer.window_get_size()
	for i in range(resolution_option.item_count):
		var res = resolution_option.get_item_metadata(i)
		if res == current_size:
			resolution_option.select(i)
			return
	# Si no se encuentra, añadir la resolución actual al final
	resolution_option.add_item(str(current_size.x) + "x" + str(current_size.y) + " (Actual)")
	resolution_option.set_item_metadata(resolution_option.item_count - 1, current_size)
	resolution_option.select(resolution_option.item_count - 1)

func _on_MusicSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value - 80)

func _on_SfxSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value - 80)

func _on_FullscreenCheck_toggled(button_pressed):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_ResolutionOption_item_selected(index):
	var res = resolution_option.get_item_metadata(index)
	DisplayServer.window_set_size(res)

func _on_BackButton_pressed():
	# Reemplazar con GameManager.goto("main_menu") o volver a la escena anterior
	print("Volver desde opciones")
	get_tree().set_input_as_handled()
