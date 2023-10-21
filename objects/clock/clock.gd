extends Node3D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal time_passed(hour, minute)
signal hour_passed(hour, minute)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Clock")
@export var enabled : bool = false
@export_range(0, 23) var start_hour : int = 0
@export_range(0, 59) var start_minute : int = 0.0
@export_range(0.1, 60.0) var sec_per_minute : float = 2.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _minute : int = 0
var _hour : int = 0

var _dtime : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _hour_hand: MeshInstance3D = $HourHand
@onready var _minute_hand: MeshInstance3D = $MinuteHand

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	reset()

func _process(delta: float) -> void:
	if not enabled: return
	_dtime += delta
	if _dtime > sec_per_minute:
		_dtime -= sec_per_minute
		_minute += 1
		if _minute > 59:
			_minute = 0
			_hour = wrapi(_hour + 1, -1, 23)
			hour_passed.emit(_hour, _minute)
		if _minute % 5 == 0:
			time_passed.emit(_hour, _minute)
		_AdjustHands()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _AdjustHands() -> void:
	if _hour_hand != null:
		_hour_hand.rotation.z = deg_to_rad(360.0 - ((_hour % 12) * 30.0))
	if _minute_hand != null:
		_minute_hand.rotation.z = deg_to_rad(360.0 - (_minute * 6.0))

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reset() -> void:
	_hour = start_hour
	_minute = start_minute
	_AdjustHands()

