extends CanvasLayer
class_name UIRoot


# --------------------------------------------------------------------------------------------------
# Signals
# --------------------------------------------------------------------------------------------------
signal requested(action : StringName, payload : Dictionary)
signal active_ui_changed(ui_name : StringName)

# --------------------------------------------------------------------------------------------------
# Export Variables
# --------------------------------------------------------------------------------------------------
@export_category("UI Root")
@export var initial_ui : StringName = &""

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------
var _ui : Dictionary = {}
var _breadcrumbs : Array = []

# --------------------------------------------------------------------------------------------------
# Override Methods
# --------------------------------------------------------------------------------------------------
func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exited_tree)
	_ConnectAllChildren()
	show_ui.call_deferred(initial_ui)

# --------------------------------------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------------------------------------
func _ConnectAllChildren() -> void:
	for child in get_children():
		_on_child_entered_tree(child)

# --------------------------------------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------------------------------------
func has(ui_name : StringName) -> bool:
	for child in get_children():
		if is_instance_of(child, UIControl):
			if child.name == ui_name:
				return true
	return false

func is_showing(ui_name : StringName) -> bool:
	if not ui_name in _ui: return false
	if _breadcrumbs.size() <= 0: return false
	return _breadcrumbs[0] == ui_name

func get_active_ui() -> StringName:
	return &"" if _breadcrumbs.size() <= 0 else _breadcrumbs[0]

func show_ui(ui_name : StringName) -> void:
	if not ui_name in _ui: return
	var active : StringName = get_active_ui()
	if ui_name == active: return
	
	_breadcrumbs.push_front(ui_name)
	if active != &"":
		_ui[active].close_ui()
	_ui[ui_name].show_ui()
	active_ui_changed.emit(ui_name)

func close_ui() -> void:
	var active : StringName = get_active_ui()
	if active == &"": return
	_ui[active].close_ui()
	_breadcrumbs.pop_front()
	if _breadcrumbs.size() > 0:
		_ui[_breadcrumbs[0]].show_ui()
	active_ui_changed.emit(get_active_ui())
	

func close_all() -> void:
	var active : StringName = get_active_ui()
	if active != &"":
		_ui[active].close_ui()
		_breadcrumbs.clear()
		active_ui_changed.emit(&"")

# --------------------------------------------------------------------------------------------------
# Handler Methods
# --------------------------------------------------------------------------------------------------
func _on_child_entered_tree(child : Node) -> void:
	if is_instance_of(child, UIControl):
		if not child.name in _ui:
			_ui[child.name] = child
			
		if not child.requested.is_connected(_on_requested):
			child.requested.connect(_on_requested)

func _on_child_exited_tree(child : Node) -> void:
	if is_instance_of(child, UIControl):
		if child.name in _ui:
			_ui.erase(child.name)
		var active : StringName = get_active_ui()
		if active != &"":
			_breadcrumbs = _breadcrumbs.filter(func(item): return item != child.name)
			if _breadcrumbs.size() > 0:
				if _breadcrumbs[0] != active:
					_ui[_breadcrumbs[0]].show_ui()
		
		if child.requested.is_connected(_on_requested):
			child.requested.disconnect(_on_requested)

func _on_requested(action : StringName, payload : Dictionary):
	match action:
		&"show_ui":
			if not payload.is_empty() and "ui_name" in payload and typeof(payload["ui_name"]) == TYPE_STRING_NAME:
				show_ui(payload["ui_name"])
		&"close_ui":
			close_ui()
		&"close_all":
			close_all()
		_:
			requested.emit(action, payload)


