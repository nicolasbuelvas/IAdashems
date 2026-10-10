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

## Script del menú de pausa de D. Si hay un nodo con este script en el árbol, D procesa Esc y GameManager
## no lo toma. Ver el comentario "Pendiente para D" junto a set_paused(). Solo se compara el script: el spec 2.5
## no define grupo para el menú de pausa.
const PAUSE_MENU_SCRIPT := "res://ui/pause_menu.gd"

## true solo mientras GameManager emite pause_toggled; su propio handler ignora esa emisión.
var _emitting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.game_won.connect(game_won)
	EventBus.pause_toggled.connect(_on_pause_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	# Con el menú de D en el árbol, D procesa Esc en su _input y emite pause_toggled. Si GameManager
	# también lo tomara, cada Esc pausaría y reanudaría dos veces seguidas.
	if _pause_menu_in_tree():
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
		_emit_pause_toggled(false)
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
##
## Decisión: no se admite pausa en ROUND_INTRO (la tarjeta de 2 s). game.gd congela la ronda durante la tarjeta
## y la descongela con create_timer, que sigue corriendo con el árbol pausado; si se aceptara la pausa, el
## timer pasaría a PLAYING con el árbol pausado. La tabla del spec solo define PLAYING <-> PAUSED.
func _set_paused(paused: bool) -> void:
	if paused and state != PLAYING:
		return
	if not paused and state != PAUSED:
		return
	get_tree().paused = paused
	set_state(PAUSED if paused else PLAYING)
	_emit_pause_toggled(paused)


## Listener de EventBus.pause_toggled para emisiones ajenas (hoy, pause_menu.gd de D).
## Sincroniza state y get_tree().paused SIN volver a emitir. Las emisiones propias llegan con
## _emitting = true y se ignoran, así no hay bucle.
func _on_pause_toggled(paused: bool) -> void:
	if _emitting:
		return
	if paused:
		if state == PLAYING:
			get_tree().paused = true
			set_state(PAUSED)
		elif state != PAUSED:
			# Pausa no admitida fuera de PLAYING. D ya congeló el árbol y mostró su menú:
			# se revierte al final del frame, cuando el listener de D ya terminó.
			call_deferred(&"_undo_rejected_pause")
	else:
		get_tree().paused = false
		if state == PAUSED:
			set_state(PLAYING)


func _undo_rejected_pause() -> void:
	if state == PAUSED or not get_tree().paused:
		return
	get_tree().paused = false
	_emit_pause_toggled(false)


## Emite pause_toggled marcando que el emisor es GameManager, para que _on_pause_toggled la ignore.
func _emit_pause_toggled(paused: bool) -> void:
	_emitting = true
	EventBus.pause_toggled.emit(paused)
	_emitting = false


## true si hay un menú de pausa en el árbol que procesa Esc por su cuenta (ver PAUSE_MENU_SCRIPT).
func _pause_menu_in_tree() -> bool:
	return _find_pause_menu(get_tree().root) != null


## Busca el menú de pausa de D recorriendo el árbol y comparando el script de cada nodo con PAUSE_MENU_SCRIPT.
func _find_pause_menu(node: Node) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == PAUSE_MENU_SCRIPT:
		return node
	for child in node.get_children():
		var found := _find_pause_menu(child)
		if found != null:
			return found
	return null


## API pública de pausa. El menú de pausa de D (process_mode ALWAYS) debe usar estas funciones
## y NO tocar get_tree().paused directamente, o state y EventBus.pause_toggled quedan desincronizados.
##   GameManager.set_paused(true)   pausa si state == PLAYING; en otro estado no hace nada.
##   GameManager.set_paused(false)  reanuda si state == PAUSED; en otro estado no hace nada.
## Para reanudar desde el botón "Continuar" de D: GameManager.set_paused(false).
##
## Pendiente para D (no bloquea el MVP, pause_menu.gd no se toca aquí): que su _input y sus botones
## llamen a GameManager.toggle_pause() o GameManager.set_paused(...) en vez de emitir pause_toggled y
## tocar get_tree().paused. Con eso GameManager queda como único dueño de Esc, y _pause_menu_in_tree()
## y _on_pause_toggled() dejan de ser necesarios (se pueden borrar). "Salir al menú" debería llamar a
## GameManager.goto(&"menu"). "Opciones" necesita una clave en SCENE_PATHS o una escena propia.
func set_paused(paused: bool) -> void:
	_set_paused(paused)


## Alterna entre PLAYING y PAUSED (ver set_paused). En cualquier otro estado no hace nada.
func toggle_pause() -> void:
	if state == PLAYING:
		_set_paused(true)
	elif state == PAUSED:
		_set_paused(false)
