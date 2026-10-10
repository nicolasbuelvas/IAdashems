extends Node
## Escena de debug: arranca game/game.tscn (el juego real) directamente en start_round.
## Ábrela y pulsa F6. Cambia start_round en el inspector para empezar en otra ronda.
## No usa GameManager.goto(&"game") porque ese reinicia current_round a 1.

@export_range(1, 6) var start_round: int = 5


func _ready() -> void:
	GameManager.current_round = start_round
	get_tree().change_scene_to_file.call_deferred("res://game/game.tscn")
