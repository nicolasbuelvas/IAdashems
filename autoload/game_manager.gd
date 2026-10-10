extends Node
## Estado del juego (spec 4) y cambio de escenas. Autoload "GameManager", process_mode ALWAYS.
## Persona C. Contrato v1: SCENE_PATHS, goto(), current_round y state no se renombran.

const SCENE_PATHS := {
	&"menu": "res://scenes/main_menu.tscn",
	&"intro": "res://scenes/intro.tscn",
	&"game": "res://game/game.tscn",
	&"outro": "res://scenes/outro.tscn",
	&"credits": "res://scenes/credits.tscn",
}

# Estados. Son StringName para que se impriman tal cual en la salida.
const MENU := &"MENU"
const INTRO := &"INTRO"
const ROUND_INTRO := &"ROUND_INTRO"
const PLAYING := &"PLAYING"
const ROUND_WON := &"ROUND_WON"
const ROUND_FAILED := &"ROUND_FAILED"
const OUTRO := &"OUTRO"
const CREDITS := &"CREDITS"
const PAUSED := &"PAUSED"

# Transiciones que set_state() acepta. goto() no pasa por aquí: fija el estado de la escena destino.
const _NEXT_STATES := {
	MENU: [INTRO, ROUND_INTRO],
	INTRO: [ROUND_INTRO, MENU],
	ROUND_INTRO: [PLAYING],
	PLAYING: [ROUND_WON, ROUND_FAILED, PAUSED],
	PAUSED: [PLAYING],
	ROUND_WON: [ROUND_INTRO],
	ROUND_FAILED: [ROUND_INTRO],
}

# Estado que queda al entrar a cada escena.
const _STATE_FOR_SCENE := {
	&"menu": MENU,
	&"intro": INTRO,
	&"game": ROUND_INTRO,
	&"outro": OUTRO,
	&"credits": CREDITS,
}

var state: StringName = MENU
var current_round: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_won.connect(game_won)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if state == PLAYING:
		_set_paused(true)
	elif state == PAUSED:
		_set_paused(false)
	else:
		return
	get_viewport().set_input_as_handled()


## Cambia de escena. goto(&"game") siempre empieza una partida nueva en la ronda 1;
## el reintento de una ronda no pasa por aquí (lo hace game.gd dentro de la escena).
func goto(scene_key: StringName) -> void:
	var path: String = SCENE_PATHS.get(scene_key, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("GameManager.goto: escena no disponible para la clave '%s'" % scene_key)
		return
	# Sin esto, la escena nueva nacería congelada si salimos desde la pausa.
	if get_tree().paused:
		get_tree().paused = false
		EventBus.pause_toggled.emit(false)
	if scene_key == &"game":
		current_round = 1
	state = _STATE_FOR_SCENE.get(scene_key, state)
	get_tree().change_scene_to_file(path)


func game_won() -> void:
	goto(&"outro")


## Transición interna del flujo (game.gd y pausa). Si la transición no está en la tabla,
## avisa con push_warning y la aplica igual, para no dejar el juego bloqueado.
func set_state(next: StringName) -> void:
	if next == state:
		return
	var allowed: Array = _NEXT_STATES.get(state, [])
	if not allowed.has(next):
		push_warning("GameManager.set_state: transición %s -> %s no está en la tabla" % [state, next])
	state = next


## Implementación compartida por set_paused(), toggle_pause() y el input de Esc.
## Solo pausa desde PLAYING y solo reanuda desde PAUSED. Fuera de esos estados no hace nada.
## Actualiza state y emite pause_toggled únicamente cuando el estado cambia.
func _set_paused(paused: bool) -> void:
	if paused and state != PLAYING:
		return
	if not paused and state != PAUSED:
		return
	get_tree().paused = paused
	set_state(PAUSED if paused else PLAYING)
	EventBus.pause_toggled.emit(paused)


## API pública de pausa. El menú de pausa de D (process_mode ALWAYS) debe usar estas funciones
## y NO tocar get_tree().paused directamente, o state y EventBus.pause_toggled quedan desincronizados.
##   GameManager.set_paused(true)   pausa si state == PLAYING; en otro estado no hace nada.
##   GameManager.set_paused(false)  reanuda si state == PAUSED; en otro estado no hace nada.
## Para reanudar desde el botón "Continuar" de D: GameManager.set_paused(false).
func set_paused(paused: bool) -> void:
	_set_paused(paused)


## Alterna entre PLAYING y PAUSED (ver set_paused). En cualquier otro estado no hace nada.
func toggle_pause() -> void:
	if state == PLAYING:
		_set_paused(true)
	elif state == PAUSED:
		_set_paused(false)
