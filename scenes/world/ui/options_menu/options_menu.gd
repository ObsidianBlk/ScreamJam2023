extends UIControl


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _button_group : ButtonGroup = null
var _subops : Dictionary = {}
var _active : String = ""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _subop_buttons = %SubOpButtons
@onready var _subop_container = %SubOpContainer


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	_UpdateSubOps()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateSubOps() -> void:
	if _subop_container == null or _subop_buttons == null: return
	for child in _subop_container.get_children():
		_on_suboption_child_entered(child)

func _ActivateSubop(subop_name : String) -> void:
	if (not subop_name in _subops) or subop_name == _active: return
	if _active in _subops:
		_subops[_active].op.visible = false
		_active = ""
	_active = subop_name
	_subops[_active].op.visible = true
	if not _subops[_active].btn.button_pressed:
		_subops[_active].btn.button_pressed = true

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_suboption_child_entered(child : Node) -> void:
	if _subop_container == null or _subop_buttons == null: return
	if not child.has_method(&"get_subop_name"): return
	if child.name in _subops: return
	_subops[child.name] = {
		"op": child,
		"btn": null
	}
	if _button_group == null:
		_button_group = ButtonGroup.new()
	var btn : Button = Button.new()
	btn.text = child.get_subop_name()
	btn.toggle_mode = true
	btn.button_group = _button_group
	_subops[child.name].btn = btn
	_subop_buttons.add_child(btn)
	btn.pressed.connect(_on_subop_button_pressed.bind(child.name))

func _on_suboption_child_exited(child : Node) -> void:
	if _subop_container == null or _subop_buttons == null: return
	if not child.name in _subops: return
	_subop_buttons.remove_child(_subops[child.name].btn)
	_subops.erase[child.name]
	if _active == child.name:
		_active = ""
		if _subops.size() <= 0: return
		_ActivateSubop(_subops.keys()[0])

func _on_subop_button_pressed(subop_name : String) -> void:
	_ActivateSubop(subop_name)

func _on_btn_reset_pressed():
	Settings.load()

func _on_btn_back_pressed():
	Settings.save()
	request(&"close_ui")
