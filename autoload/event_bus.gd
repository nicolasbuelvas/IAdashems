# autoload/event_bus.gd
extends Node

# Jugador (emite A)
signal player_health_changed(current: int, max_hp: int)
signal player_damaged(amount: int)
signal player_died()
signal lives_sacrificed_for_heat(heat_added: float)
signal holders_shattered()
signal player_slide_started()
signal player_slide_ended()
signal dash_cooldown_changed(progress: float)
signal dash_speed_threshold_changed(speed_reached: bool)
signal herbicide_fired()
signal herbicide_cooldown_changed(progress: float)  # 0.0 = recién lanzado, 1.0 = listo
signal herbicide_ready()
signal player_jumped()

# Anomalías (emite B)
signal anomaly_spawned(anomaly: Node)
signal anomaly_contained(anomaly: Node)

# Sistemas (emite C)
signal heat_changed(value: float, max_value: float)
signal heat_maxed()
signal heat_penalty_requested(amount: float)
signal round_started(round_number: int, remaining: int)
signal round_timer_changed(seconds_left: float)
signal round_timer_expired()
signal anomalies_remaining_changed(remaining: int)
signal round_won(round_number: int)
signal round_failed(reason: StringName)   # &"heat", &"health" o &"time"
signal floor_unlocked(floor_number: int)
signal game_won()

# Flujo (emite D o GameManager)
signal pause_toggled(paused: bool)
