extends Control
## Tarjeta de ronda (persona D): pantalla blanca fija, sin animaciones, al empezar cada ronda.
## Rondas 1-3 presentan una anomalía (imagen + verbo + tecla); 4-6 solo un texto corto centrado.
## game.gd congela la ronda durante duration_for(n), así que la tarjeta y la espera coinciden.
##
## Escucha EventBus si C ya lo creó; si no, queda mudo hasta que alguien lo
## llame con show_turn() / show_floor_unlocked() o attach_source().

const LONG_SECONDS := 2.5
const SHORT_SECONDS := 1.5

## Una entrada por ronda: icon (ruta o ""), title y subtitle ("" = oculto).
const CARDS := [
	{"icon": "res://Sprites/HONGUITO/HonguitoMamadisimo_0000.png", "title": "ATRÁPALO", "subtitle": ""},
	{"icon": "res://Sprites/Lechuga/LechugonXLL.png", "title": "PATÉALO", "subtitle": "con SHIFT"},
	{"icon": "res://Sprites/GUISANTE_TATATATAA/verde_0000.png", "title": "DISPÁRALE", "subtitle": "con \"E\""},
	{"icon": "", "title": "MÁS PLAGA", "subtitle": ""},
	{"icon": "", "title": "SIN PIEDAD", "subtitle": ""},
	{"icon": "", "title": "PISO FINAL", "subtitle": ""},
]

@onready var icon_rect: TextureRect = $"Center/Rows/Icon"
@onready var turn_label: Label = $"Center/Rows/TurnLabel"
@onready var subtitle_label: Label = $"Center/Rows/Subtitle"
@onready var floor_notice: Label = $"Center/Rows/FloorNotice"

var _event_bus: Node = null
var _token := 0
var _seconds := LONG_SECONDS


## Segundos que se muestra la tarjeta de la ronda n (más corta cuando no hay imagen).
static func duration_for(round_number: int) -> float:
	var data := _card_for(round_number)
	return LONG_SECONDS if data["icon"] != "" else SHORT_SECONDS


static func _card_for(round_number: int) -> Dictionary:
	if round_number >= 1 and round_number <= CARDS.size():
		return CARDS[round_number - 1]
	return {"icon": "", "title": "RONDA %d" % round_number, "subtitle": ""}


func _ready() -> void:
	hide()
	attach_source(get_node_or_null("/root/EventBus"))


## Conecta las señales del contrato que existan en `source` (EventBus en
## producción, test_signal_emitter en las pruebas).
func attach_source(source: Node) -> void:
	_event_bus = source
	if source == null:
		return
	_connect_if_missing(&"round_started", _on_round_started)
	_connect_if_missing(&"floor_unlocked", _on_floor_unlocked)
	_connect_if_missing(&"heat_maxed", _on_game_over)
	_connect_if_missing(&"round_failed", _on_round_failed)


func _connect_if_missing(signal_name: StringName, handler: Callable) -> void:
	if _event_bus.has_signal(signal_name) and not _event_bus.is_connected(signal_name, handler):
		_event_bus.connect(signal_name, handler)


## Contrato: round_started(round_number: int, remaining: int)
## En game over (ROUND_FAILED) no se muestra: el reintento pasa antes a ROUND_INTRO desde game.gd.
func _on_round_started(round_number: int, _remaining: int) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.state == gm.ROUND_FAILED:
		return
	show_turn(round_number)


## round_failed(reason): por calor es game over; la tarjeta no puede quedar encima del modal.
func _on_round_failed(reason: StringName) -> void:
	if reason == &"heat":
		_on_game_over()


func _on_game_over() -> void:
	_token += 1
	hide()
	floor_notice.visible = false


## Contrato: floor_unlocked(floor_number: int)
func _on_floor_unlocked(_floor_number: int) -> void:
	show_floor_unlocked()


func show_turn(round_number: int) -> void:
	var data := _card_for(round_number)
	var icon_path: String = data["icon"]
	icon_rect.texture = load(icon_path) if icon_path != "" else null
	icon_rect.visible = icon_path != ""
	turn_label.text = data["title"]
	subtitle_label.text = data["subtitle"]
	subtitle_label.visible = data["subtitle"] != ""
	floor_notice.visible = false
	_seconds = duration_for(round_number)
	_show_card()


## Se emite en el mismo start_round que round_started: solo añade la línea, sin reiniciar el tiempo.
func show_floor_unlocked() -> void:
	floor_notice.visible = true
	if not visible:
		_show_card()


func _show_card() -> void:
	show()
	_token += 1
	# process_always = true por defecto: sigue corriendo con el juego pausado.
	get_tree().create_timer(_seconds).timeout.connect(_on_timer.bind(_token), CONNECT_ONE_SHOT)


func _on_timer(token: int) -> void:
	if token == _token:
		hide()
		floor_notice.visible = false
