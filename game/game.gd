extends Node3D
## Raíz de game/game.tscn (persona C). Solo conecta y arranca: el calor vive en HeatSystem
## y las rondas, el reloj y el progreso en RoundManager.
## Contrato: docs/spec-mvp-reparto.md (4 y 5, persona C) y docs/flujo-subagentes-persona-C.md (2).

const TOTAL_ROUNDS := 6
## Tarjeta de ronda (ui/hud.tscn la muestra con round_started). Su duración por ronda la define ella:
## es presentación, no balance, así que no va en GameConfig.
const RoundCard := preload("res://ui/round_card.gd")
## Nodos que se congelan durante ROUND_INTRO: papa, reloj, calor y anomalías. Si alguno no existe en la escena, se omite.
const ROUND_FROZEN_NODES := ["Player", "RoundManager", "HeatSystem", "Anomalies"]

## Se incrementa en cada entrada a ROUND_INTRO. Una espera de tarjeta vieja no descongela ni pasa a PLAYING.
var _intro_token: int = 0


func _ready() -> void:
	EventBus.round_won.connect(_on_round_won)
	EventBus.round_failed.connect(_on_round_failed)
	_start_round_after_card()


## Entra en ROUND_INTRO. Arranca la ronda de inmediato (round_started dispara la tarjeta "Turno N" del HUD y
## reset_to coloca la papa), congela la ronda mientras dura la tarjeta (RoundCard.duration_for) y luego la descongela y pasa a PLAYING.
## En ROUND_INTRO no se juega: la papa, el reloj, el calor y las anomalías están congelados.
func _start_round_after_card() -> void:
	_intro_token += 1
	var token := _intro_token
	GameManager.set_state(GameManager.ROUND_INTRO)
	$RoundManager.start_round(GameManager.current_round)
	_set_round_frozen(true)
	await get_tree().create_timer(RoundCard.duration_for(GameManager.current_round)).timeout
	# La escena pudo cambiar durante la tarjeta (goto) o la ronda pudo reiniciarse: esta espera ya no manda.
	if not is_inside_tree() or token != _intro_token:
		return
	_set_round_frozen(false)
	GameManager.set_state(GameManager.PLAYING)


## Congela (PROCESS_MODE_DISABLED) o descongela (PROCESS_MODE_INHERIT) los nodos de ROUND_FROZEN_NODES.
## Con DISABLED no corren _process, _physics_process ni _unhandled_input de esos nodos y sus hijos.
func _set_round_frozen(frozen: bool) -> void:
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	for node_name: String in ROUND_FROZEN_NODES:
		var node := get_node_or_null(node_name) as Node
		if node != null:
			node.process_mode = mode


func _on_round_won(round_number: int) -> void:
	GameManager.set_state(GameManager.ROUND_WON)
	if round_number < TOTAL_ROUNDS:
		GameManager.current_round = round_number + 1
		# Diferido un frame: round_won se emite desde RoundManager._win(), que todavía lee current_round
		# para decidir si emite game_won. Arrancar la ronda siguiente aquí lo dejaría en 6 y dispararía game_won al empezar la ronda 6.
		call_deferred(&"_start_round_after_card")
	# En la ronda final no hace nada: EventBus.game_won lo lleva a outro (GameManager.game_won).


func _on_round_failed(_reason: StringName) -> void:
	# Se reintenta la misma ronda tras permitir ver la explosión de la papa.
	# RoundManager decide qué se conserva: al morir, capturas y reloj; con el reloj agotado, nada.
	GameManager.set_state(GameManager.ROUND_FAILED)
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_start_round_after_card()
