extends Node

# autoload/game_manager.gd — estado del juego y cambio de escenas (spec sección 4)
# DUEÑO: C. Este es un stub; C completa la lógica.

enum State { MENU, INTRO, ROUND_INTRO, PLAYING, PAUSED, ROUND_WON, ROUND_FAILED, OUTRO, CREDITS }

var current_state: State = State.MENU

# Claves de escena válidas: menu, intro, game, outro, credits
var _scenes := {
	&"menu": "res://scenes/main_menu.tscn",
	&"intro": "res://scenes/intro.tscn",
	&"game": "res://game/game.tscn",
	&"outro": "res://scenes/outro.tscn",
	&"credits": "res://scenes/credits.tscn",
}

func goto(scene_key: StringName) -> void:
	if not _scenes.has(scene_key):
		push_error("GameManager.goto: escena desconocida '%s'" % scene_key)
		return
	get_tree().change_scene_to_file(_scenes[scene_key])

func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	EventBus.pause_toggled.emit(paused)
