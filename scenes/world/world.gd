extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SETTINGS_SECTION : String = "Graphics"
const SETTINGS_KEY_FULLSCREEN : String = "fullscreen"

const MARKET : PackedScene = preload("res://scenes/market/market.tscn")

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _game_scene : Node3D = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ui = $UIRoot
@onready var _container: Node3D = $Container

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


func _unhandled_input(event: InputEvent) -> void:
	if not get_tree().paused: return
	if event.is_action_pressed("ui_cancel"):
		if _game_scene != null:
			request(&"unpause_game")

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

func _StartGame() -> void:
	if _container == null or _game_scene != null: return
	_game_scene = MARKET.instantiate()
	_game_scene.requested.connect(request)
	_container.add_child(_game_scene)
	request(&"unpause_game")

func _UnsetGame() -> void:
	if _container == null or _game_scene == null: return
	if _game_scene.requested.is_connected(request):
		_game_scene.requested.disconnect(request)
	_container.remove_child(_game_scene)
	_game_scene.queue_free()
	_game_scene = null

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary = {}) -> void:
	match action:
		&"start_game":
			_StartGame()
		&"game_over":
			if "ending" in payload:
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_UnsetGame()
				_ui.show_ui(&"GameOver")
				Relay.relay(&"gameover_ending", payload)
		&"unpause_game":
			if get_tree().paused:
				_ui.close_all()
				get_tree().paused = false
				Relay.relay(&"unpaused")
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		&"pause_game":
			if not get_tree().paused:
				Clock24.enable(false)
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_ui.show_ui(&"PauseMenu")
		&"quit_game":
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_UnsetGame()
			_ui.show_ui(&"MainMenu")
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
