extends CanvasLayer

var _active : Control = null

func _ready() -> void:
	Relay.relayed.connect(_on_relayed)
	_HideAll()

func _HideAll() -> void:
	for child in get_children():
		child.visible = false

func _HideActive() -> void:
	if _active == null: return
	_active.visible = false
	_active = null

func _ActivateMsg(msg_name : String) -> void:
	if msg_name.is_empty(): return
	if _active != null:
		if _active.name == msg_name: return
		_HideActive()
	for child in get_children():
		if child.name == msg_name:
			child.visible = true
			_active = child
			break

func _on_relayed(action : StringName, payload : Dictionary) -> void:
	if action == &"message":
		var msg_name : String = "" if not "name" in payload else payload["name"]
		var show : bool = false if not "show" in payload else payload["show"]
		if not show and _active != null:
			_HideActive()
		elif show:
			_ActivateMsg(msg_name)


