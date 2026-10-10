extends Node

# autoload/game_config.gd — valores de balance (spec sección 2.4)
# Se ajustan SOLO aquí, nunca dentro del código de cada sistema.

# Calor (0 a 100)
const HEAT_MAX := 100.0
const HEAT_PER_SEC_TIME := 1.11          # unos 90 s hasta el máximo sin otros factores
const HEAT_PER_SEC_PER_ANOMALY := 0.3
const HEAT_PER_HIT := 10.0
const HEAT_EXPIRED_MULTIPLIER := 3.0
const HEAT_COOL_PER_CONTAIN := 20.0       # enfriamiento total por captura
const HEAT_COOL_RATE := 8.0               # velocidad del enfriamiento gradual, por segundo
const HEAT_HIGH_THRESHOLD := 70.0         # desde aquí sale humo

# Reloj
const ROUND_BASE_TIME := 90.0
const ROUND_TIME_PER_ANOMALY := 15.0
const ROUND_MIN_TIME_LEFT := 10.0

# Jugador
const PLAYER_MAX_HP := 3
const PLAYER_SPEED := 6.0
const PLAYER_JUMP_VELOCITY := 9.0
const PLAYER_IFRAMES := 1.0
const SLIDE_DURATION := 0.5
const SLIDE_COOLDOWN := 0.6
const SLIDE_SPEED := 11.0
const HERBICIDE_COOLDOWN := 5.0
const HERBICIDE_SPEED := 14.0

# Anomalías
const CUCUMBER_SPEED := 5.0
const CUCUMBER_FLEE_DISTANCE := 6.0
const CUCUMBER_STAIRS_MULT := 0.5
const LETTUCE_SPEED := 4.0
const PEA_SPEED := 1.5
const PEA_FIRE_INTERVAL := 2.5
const PEA_PROJECTILE_SPEED := 7.0
