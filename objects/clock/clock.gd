extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TICK_PITCH_MIN : float = 0.6
const TICK_PITCH_MAX : float = 1.4

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _hour_hand: MeshInstance3D = $HourHand
@onready var _minute_hand: MeshInstance3D = $MinuteHand
@onready var _audio_tick: AudioStreamPlayer3D = %AudioTick

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Clock24.clock_ticked.connect(_on_clock_ticked)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _AdjustHands(hour12 : int, minute : int) -> void:
	if _hour_hand != null:
		_hour_hand.rotation.z = deg_to_rad(360.0 - (hour12 * 30.0))
	if _minute_hand != null:
		_minute_hand.rotation.z = deg_to_rad(360.0 - (minute * 6.0))

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_clock_ticked(hour : int, minute : int) -> void:
	_AdjustHands(hour % 12, minute)
	_audio_tick.pitch_scale = randf_range(TICK_PITCH_MIN, TICK_PITCH_MAX)
	_audio_tick.play()
