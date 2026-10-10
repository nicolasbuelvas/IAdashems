extends Node3D
## Raíz de game/game.tscn (persona C). Solo conecta y arranca: el calor vive en HeatSystem
## y las rondas, el reloj y el progreso en RoundManager.
## Contrato: docs/spec-mvp-reparto.md (4 y 5, persona C) y docs/flujo-subagentes-persona-C.md (2).

const TOTAL_ROUNDS := 6
## Tiempo de la tarjeta "Turno N". Es presentación, no balance: no va en GameConfig.
const ROUND_INTRO_SECONDS := 2.0


func _ready() -> void:
	EventBus.round_won.connect(_on_round_won)
	EventBus.round_failed.connect(_on_round_failed)
	_start_round_after_card()


func _start_round_after_card() -> void:
	GameManager.set_state(GameManager.ROUND_INTRO)
	await get_tree().create_timer(ROUND_INTRO_SECONDS).timeout
	# La escena pudo cambiar durante la tarjeta (goto): no toques $RoundManager si ya no estamos en el árbol.
	if not is_inside_tree():
		return
	$RoundManager.start_round(GameManager.current_round)
	GameManager.set_state(GameManager.PLAYING)


func _on_round_won(round_number: int) -> void:
	GameManager.set_state(GameManager.ROUND_WON)
	if round_number < TOTAL_ROUNDS:
		GameManager.current_round = round_number + 1
		_start_round_after_card()
	# En la ronda final no hace nada: EventBus.game_won lo lleva a outro (GameManager.game_won).


func _on_round_failed(_reason: StringName) -> void:
	# RoundManager conserva el progreso: se reintenta la misma ronda.
	GameManager.set_state(GameManager.ROUND_FAILED)
	_start_round_after_card()
