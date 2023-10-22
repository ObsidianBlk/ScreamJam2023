extends Node3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal opened()
signal closed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANGLE_CLOSED : float = 0.0
const ANGLE_OPENED : float = deg_to_rad(90)
const TRANSITION_DURATION : float = 1.0

enum STATE {Closed=0, Opening=1, Opened=2, Closing=3}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Door")
@export_enum("exterior", "interior") var type : int = 0
@export_enum("closed:0", "opened:2") var initial_state : int = 0
@export var locked : bool = false
@export var sound_opening : AudioStream = null
@export var sound_closing : AudioStream = null
@export var sound_locked : AudioStream = null


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _state : STATE = STATE.Closed
var _static_layer : int = 0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _door_01: Node3D = $Body/door_01
@onready var _door_02: Node3D = $Body/door_02
@onready var _body: Node3D = $Body
@onready var _static: StaticBody3D = $StaticBody3D
@onready var _audio: AudioStreamPlayer3D = $Audio

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_type(t : int) -> void:
	if t != 0 and t != 1: return
	type = t
	_UpdateDoorViz()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_static_layer = _static.collision_layer
	_SetState(initial_state)
	_UpdateDoorViz()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateDoorViz() -> void:
	if _door_01 == null or _door_02 == null: return
	match type:
		0:
			_door_01.visible = true
			_door_02.visible = false
		1:
			_door_02.visible = true
			_door_01.visible = false

func _SetState(s : STATE) -> void:
	match s:
		STATE.Opened:
			_state = s
			_body.rotation.y = ANGLE_OPENED
			_static.collision_layer = 0
			opened.emit()
		STATE.Closed:
			_state = s
			_body.rotation.y = ANGLE_CLOSED
			_static.collision_layer = _static_layer
			closed.emit()

func _Anim_Open() -> void:
	if _state != STATE.Closed: return
	_state = STATE.Opening
	var tween : Tween = create_tween()
	tween.tween_property(_body, "rotation:y", ANGLE_OPENED, TRANSITION_DURATION)
	opened.emit()
	_static.collision_layer = 0
	_PlaySound(sound_opening)
	await tween.finished
	_state = STATE.Opened

func _Anim_Close() -> void:
	if _state != STATE.Opened: return
	_state = STATE.Closing
	var tween : Tween = create_tween()
	tween.tween_property(_body, "rotation:y", ANGLE_CLOSED, TRANSITION_DURATION)
	closed.emit()
	_static.collision_layer = _static_layer
	_PlaySound(sound_closing)
	await tween.finished
	_state = STATE.Closed

func _PlaySound(sound : AudioStream) -> void:
	if sound == null: return
	_audio.stream = sound
	_audio.play()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_interacted(payload : Dictionary = {}) -> void:
	if _state == STATE.Closed or _state == STATE.Opened:
		if locked:
			_PlaySound(sound_locked)
			opened.emit() # This is a technicality
			return
		match _state:
			STATE.Opened:
				_Anim_Close()
			STATE.Closed:
				_Anim_Open()
