extends Control
class_name UIControl


# --------------------------------------------------------------------------------------------------
# Signals
# --------------------------------------------------------------------------------------------------
signal requested(action : StringName, payload : Dictionary)
signal active()
signal deactive()

# --------------------------------------------------------------------------------------------------
# Export Variables
# --------------------------------------------------------------------------------------------------
@export_category("UI Control")
@export var hide_at_start : bool = true
@export var explicit_close_only : bool = false

# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------
func _ready() -> void:
	if hide_at_start:
		visible = false

# --------------------------------------------------------------------------------------------------
# "Virtual" Methods
# --------------------------------------------------------------------------------------------------
func _Pre_Visible_Change():
	pass

# --------------------------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------------------------------------

#func _Request(action : StringName, payload : Dictionary = {}):
#	# DEPRECATED: Use request() instead
#	requested.emit(action, payload)

# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------
func request(action : StringName, payload : Dictionary = {}) -> void:
	requested.emit(action, payload)

func show_ui() -> void:
	if not visible:
		_Pre_Visible_Change()
		visible = true
		active.emit()

func close_ui() -> void:
	if visible:
		_Pre_Visible_Change()
		visible = false
		deactive.emit()
