extends CanvasLayer

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _rlabel: RichTextLabel = %RLabel


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.relayed.connect(_on_relayed)
	visible = false


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"screen_message_show":
			if not "text" in payload: return
			if typeof(payload["text"]) != TYPE_STRING: return
			visible = true
			_rlabel.text = payload["text"]
		&"screen_message_hide":
			visible = false


