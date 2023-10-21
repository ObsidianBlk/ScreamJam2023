extends Area3D
class_name Interactable

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal interacted(payload : Dictionary)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Interactable")
@export var enabled : bool = true:						set = set_enabled
@export var hand_required : bool = false
@export var type : StringName = &""
@export_multiline var interact_message : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _coll_layer : int = -1

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_enabled(e : bool) -> void:
	enabled = e
	if _coll_layer < 0:
		_coll_layer = collision_layer
	collision_layer = _coll_layer if enabled else 0

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_enabled(enabled)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func interact(payload : Dictionary = {}) -> void:
	interacted.emit(payload)

func message() -> void:
	if interact_message.is_empty(): return
	Relay.relay(&"screen_message_show", {"text":interact_message})
