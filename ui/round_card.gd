extends Control
## Tarjeta de ronda (persona D): muestra "Turno N" durante 2 segundos y el
## aviso "Nuevo piso habilitado" cuando C habilita un piso.
##
## Escucha EventBus si C ya lo creó; si no, queda mudo hasta que alguien lo
## llame con show_turn() / show_floor_unlocked() o attach_source().

const VISIBLE_SECONDS := 2.0

@onready var turn_label = $"Center/Rows/TurnLabel"
@onready var floor_notice = $"Center/Rows/FloorNotice"

var _event_bus: Node = null
var _token := 0


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


func _connect_if_missing(signal_name: StringName, handler: Callable) -> void:
	if _event_bus.has_signal(signal_name) and not _event_bus.is_connected(signal_name, handler):
		_event_bus.connect(signal_name, handler)


## Contrato: round_started(round_number: int, remaining: int)
func _on_round_started(round_number: int, _remaining: int) -> void:
	show_turn(round_number)


## Contrato: floor_unlocked(floor_number: int)
func _on_floor_unlocked(_floor_number: int) -> void:
	show_floor_unlocked()


func show_turn(round_number: int) -> void:
	turn_label.text = "TURNO %02d" % round_number
	floor_notice.visible = false
	_show_card()


func show_floor_unlocked() -> void:
	floor_notice.visible = true
	_show_card()


func _show_card() -> void:
	show()
	_token += 1
	# process_always = true por defecto: sigue corriendo con el juego pausado.
	get_tree().create_timer(VISIBLE_SECONDS).timeout.connect(_on_timer.bind(_token), CONNECT_ONE_SHOT)


func _on_timer(token: int) -> void:
	if token == _token:
		hide()
		floor_notice.visible = false
