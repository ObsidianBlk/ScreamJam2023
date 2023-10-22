extends Node3D
class_name Food

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Food")
@export var in_hand : bool = false:					set = set_in_hand
@export var rigid_version : PackedScene = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _interactable: Interactable = $Interactable

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_in_hand(h : bool) -> void:
	in_hand = h
	if _interactable != null:
		_interactable.enabled = not in_hand

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func fling(strength : float = 1.0) -> void:
	if in_hand or rigid_version == null: return
	var plist = get_tree().get_nodes_in_group(GROUP_PLAYER)
	if plist.size() <= 0: return
	var direction : Vector3 = global_position.direction_to(plist[0].global_position + Vector3(0.0, 1.0, 0.0))
	var r : Node3D = rigid_version.instantiate()
	if r is RigidBody3D:
		r.rotation = rotation
		r.apply_central_impulse(direction * strength)
		Relay.relay(&"drop_food", {
			"item": r,
			"position": global_position
		})
		queue_free()
	else:
		r.queue_free()

# ------------------------------------------------------------------------------
# Handlers Methods
# ------------------------------------------------------------------------------
func _on_interacted(payload : Dictionary = {}) -> void:
	if "player" in payload:
		if not payload["player"] is Node3D: return
		if not payload["player"].has_method("give_item"): return
		var parent : Node3D = get_parent()
		if parent != null:
			parent.remove_child(self)
		payload["player"].give_item(self)
	elif "fling_strength" in payload:
		if typeof(payload["fling_strength"]) != TYPE_FLOAT: return
		fling.call_deferred(payload["fling_strength"])
