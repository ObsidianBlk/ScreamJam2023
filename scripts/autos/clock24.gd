extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal clock_ticked(hour : int, minute : int)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _enabled : bool = false
var _spm : float = 60.0
var _dtime : float = 0.0
var _hour : int = 0
var _minute : int = 0


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _enabled: return
	_dtime += delta
	if _dtime >= _spm:
		_dtime -= _spm
		_minute += 1
		if _minute > 59:
			_minute = 0
			_hour = wrapi(_hour + 1, -1, 23)
		clock_ticked.emit(_hour, _minute)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reset(hour : int = 0, minute : int = 0) -> void:
	_hour = wrapi(hour, 0, 24)
	_minute = wrapi(minute, 0, 60)
	_dtime = 0.0
	clock_ticked.emit(_hour, _minute)

func enable(e : bool = true) -> void:
	_enabled = e

func is_enabled() -> bool:
	return _enabled

func set_seconds_per_minute(spm : float) -> void:
	if spm > 0.0 and spm != _spm:
		_spm = spm
		_dtime = 0.0

func get_seconds_per_minute() -> float:
	return _spm

func get_minute() -> int:
	return _minute

func get_hour_24() -> int:
	return _hour

func get_hour_12() -> int:
	return _hour % 12

func get_time(h24 : bool = true) -> Dictionary:
	return {
		"hour": _hour if h24 else (_hour % 12),
		"minute": _minute
	}

func is_morning() -> bool:
	return _hour < 12


