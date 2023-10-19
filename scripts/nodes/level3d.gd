extends Node3D
class_name Level3D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(action : StringName, payload : Dictionary)


# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Level 3D")
@export var pause_action_name : StringName = &""

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _unhandled_input(event : InputEvent) -> void:
	if pause_action_name == &"": return
	if event.is_action_pressed(pause_action_name, false, true):
		requested.emit(&"pause_game", {})
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary) -> void:
	requested.emit(action, payload)

