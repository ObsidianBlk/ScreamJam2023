extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SETTINGS_SECTION : String = "Graphics"
const SETTINGS_KEY_FULLSCREEN : String = "fullscreen"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ui = $UIRoot

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	get_tree().paused = true
	Settings.loaded.connect(_UpdateFromSettings)
	Settings.value_changed.connect(_on_settings_value_changed)
	if not Settings.load() == OK:
		Settings.request_reset()
		Settings.save()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFromSettings() -> void:
	var val : Variant = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_FULLSCREEN, null)
	if typeof(val) == TYPE_BOOL:
		val = DisplayServer.WINDOW_MODE_FULLSCREEN if val == true else DisplayServer.WINDOW_MODE_WINDOWED
		var mode : int = DisplayServer.window_get_mode()
		if mode != val:
			DisplayServer.window_set_mode(val)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary = {}) -> void:
	match action:
		&"start_game":
			if get_tree().paused:
				_ui.close_all()
				get_tree().paused = false
				Relay.relay(&"unpaused")
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		&"pause_game":
			if not get_tree().paused:
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_ui.show_ui(&"MainMenu")
		&"quit_game":
			pass
		&"quit_application":
			get_tree().quit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_settings_value_changed(section : String, key : String, value : Variant) -> void:
	if not section == SETTINGS_SECTION: return
	if key == SETTINGS_KEY_FULLSCREEN:
		if typeof(value) == TYPE_BOOL:
			var mode : int = DisplayServer.WINDOW_MODE_FULLSCREEN if value == true else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)
