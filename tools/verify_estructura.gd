extends SceneTree

# Verificación headless de la estructura del paso 1 (D).
# Ejecutar: godot --headless --path . -s tools/verify_estructura.gd
const SCENES := [
	"res://ui/hud.tscn",
	"res://ui/pause_menu.tscn",
	"res://ui/options_menu.tscn",
	"res://ui/round_card.tscn",
	"res://scenes/main_menu.tscn",
	"res://scenes/intro.tscn",
	"res://scenes/outro.tscn",
	"res://scenes/credits.tscn",
]

var ok := true
var _checked := false

func _process(_delta: float) -> bool:
	if _checked:
		return false
	_checked = true
	_run_checks()
	return false

func _run_checks() -> void:
	for path in SCENES:
		var ps := load(path)
		if ps == null:
			printerr("FAIL: no se pudo cargar ", path)
			ok = false
			continue
		var inst: Node = ps.instantiate()
		if inst == null:
			printerr("FAIL: no se pudo instanciar ", path)
			ok = false
			continue
		print("OK: ", path, " -> raíz '", inst.name, "' (", inst.get_class(), ")")
		inst.free()

	for a in ["EventBus", "GameConfig", "GameManager"]:
		var n := root.get_node_or_null("/root/" + a)
		if n == null:
			printerr("FAIL: autoload ", a, " no registrado")
			ok = false
		else:
			print("OK: autoload ", a)

	var bus := root.get_node_or_null("/root/EventBus")
	if bus != null:
		for sig in ["player_health_changed", "heat_changed", "round_won", "pause_toggled"]:
			if not bus.has_signal(sig):
				printerr("FAIL: EventBus sin señal ", sig)
				ok = false
		print("OK: señales del contrato verificadas")

	print("RESULTADO: ", "TODO OK" if ok else "HAY FALLOS")
	quit(0 if ok else 1)
