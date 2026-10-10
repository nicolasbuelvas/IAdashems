class_name GameOverModal
extends CanvasLayer
## Modal de derrota minimalista (anti-AI-slop, sin bloques de texto explicativo).
## Presenta exactamente 3 opciones limpias con iconografía técnica:
## 1) ⟳ REINTENTAR (misma ronda/simulación)
## 2) ⏮ REINICIAR DESDE CERO (vuelve a ronda 1)
## 3) ↶ MENÚ (regresa a main_menu.tscn)

signal retry_pressed
signal restart_game_pressed
signal main_menu_pressed

@onready var btn_retry: Button = %BtnRetry
@onready var btn_restart_game: Button = %BtnRestartGame
@onready var btn_main_menu: Button = %BtnMainMenu
@onready var card: Control = %Card

var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if btn_retry:
		btn_retry.pressed.connect(_on_btn_retry)
	if btn_restart_game:
		btn_restart_game.pressed.connect(_on_btn_restart_game)
	if btn_main_menu:
		btn_main_menu.pressed.connect(_on_btn_main_menu)


func show_modal() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	get_tree().paused = true
	
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("play_music"):
		audio.call("play_music", "res://audio/bgm_game_over.ogg")
	
	if card:
		card.scale = Vector2(0.85, 0.85)
		card.modulate.a = 0.0
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.parallel().tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(card, "modulate:a", 1.0, 0.2)


func hide_modal() -> void:
	_is_open = false
	visible = false


func _on_btn_retry() -> void:
	hide_modal()
	get_tree().paused = false
	retry_pressed.emit()


func _on_btn_restart_game() -> void:
	hide_modal()
	get_tree().paused = false
	restart_game_pressed.emit()


## El cambio de escena lo hace quien escucha main_menu_pressed (hud.gd -> GameManager.goto).
## Antes se cambiaba aquí también: el HUD ya había sacado la escena del árbol y get_tree() era null.
func _on_btn_main_menu() -> void:
	hide_modal()
	get_tree().paused = false
	main_menu_pressed.emit()
