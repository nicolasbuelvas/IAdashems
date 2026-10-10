# level/hazard.gd
# Area3D de peligro (pinchos). Persona C (c-nivel). Spec 2.5 (capa 7, grupo hazard) y seccion 5 (C).
# Capa 7 (hazard) y mascara capa 2 (player) se fijan en level/spikes.tscn.
#
# Al entrar un cuerpo del grupo "player" que tenga take_damage, intenta un golpe de DAMAGE.
# Mientras siga dentro, cuenta GameConfig.PLAYER_IFRAMES entre golpes y reinicia la cuenta
# solo cuando el golpe se aplica. Si la papa esta en iframes (is_invulnerable) o deslizandose
# (is_sliding), no se intenta el golpe: la cuenta queda en 0 y se reintenta en cada tick.
class_name Hazard
extends Area3D

## Dano por golpe (spec seccion 9: pinchos = 1 de dano).
const DAMAGE := 1

## Cuerpo dentro -> segundos que faltan para el siguiente intento. Valor <= 0: se intenta en el proximo tick.
var _inside: Dictionary = {}


func _ready() -> void:
	add_to_group(&"hazard")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	for body in _inside.keys():
		if not is_instance_valid(body):
			_inside.erase(body)
			continue
		_inside[body] -= delta
		if _inside[body] <= 0.0:
			_inside[body] = _try_hit(body)


func _on_body_entered(body) -> void:
	if not _is_player(body):
		return
	_inside[body] = _try_hit(body)


func _on_body_exited(body) -> void:
	_inside.erase(body)


## Si la papa puede recibir el golpe, lo aplica y devuelve los iframes que empiezan ahora.
## Si no puede (iframes o slide), no lo intenta y devuelve 0.0 para reintentar en el tick.
func _try_hit(body) -> float:
	if not _can_be_hit(body):
		return 0.0
	body.take_damage(DAMAGE)
	return GameConfig.PLAYER_IFRAMES


func _can_be_hit(body) -> bool:
	if body.has_method(&"is_invulnerable") and body.is_invulnerable():
		return false
	if body.has_method(&"is_sliding") and body.is_sliding():
		return false
	return true


func _is_player(body) -> bool:
	return body.is_in_group(&"player") and body.has_method(&"take_damage")
