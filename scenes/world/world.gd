extends Node3D

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ui = $UIRoot

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	get_tree().paused = true

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary = {}) -> void:
	match action:
		&"start_game":
			if get_tree().paused:
				_ui.close_all()
				get_tree().paused = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		&"quit_game":
			if not get_tree().paused:
				get_tree().paused = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				_ui.show_ui(&"MainMenu")
		&"quit_application":
			get_tree().quit()

