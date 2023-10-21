extends Node3D
class_name Level3D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(action : StringName, payload : Dictionary)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MOP : PackedScene = preload("res://objects/mop_bucket/mop_bucket.tscn")

const SETTINGS_SECTION : String = "Graphics"
const SETTINGS_KEY_SSAO : String = "ssao"
const SETTINGS_KEY_SSIL : String = "ssil"

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Level 3D")
@export var pause_action_name : StringName = &""
@export var environment : WorldEnvironment = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_environment(e : WorldEnvironment) -> void:
	if e != environment:
		environment = e
		_UpdateFromSettings()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.relayed.connect(_on_relayed)
	Settings.loaded.connect(_UpdateFromSettings)
	Settings.value_changed.connect(_on_settings_value_changed)


func _unhandled_input(event : InputEvent) -> void:
	if pause_action_name == &"": return
	if event.is_action_pressed(pause_action_name, false, true):
		requested.emit(&"pause_game", {})
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFromSettings() -> void:
	if environment == null: return
	var env : Environment = environment.environment
	var val : Variant = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_SSAO, null)
	if typeof(val) == TYPE_BOOL:
		env.ssao_enabled = val
	val = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_SSIL, null)
	if typeof(val) == TYPE_BOOL:
		env.ssil_enabled = val

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary) -> void:
	requested.emit(action, payload)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"unpaused":
			_UpdateFromSettings()
		&"spawn_mop":
			var mop : Node3D = MOP.instantiate()
			add_child(mop)
			mop.global_position = payload.position

func _on_settings_value_changed(section : String, key : String, value : Variant) -> void:
	if environment == null or section != SETTINGS_SECTION: return
	var env : Environment = environment.environment
	
	match key:
		SETTINGS_KEY_SSAO:
			if typeof(value) == TYPE_BOOL:
				env.ssao_enabled = value
		SETTINGS_KEY_SSIL:
			if typeof(value) == TYPE_BOOL:
				env.ssil_enabled = value

func _on_clock_time_passed(hour : int, minute : int) -> void:
	if hour == 0 and minute == 15:
		Relay.relay(&"lights_out")
