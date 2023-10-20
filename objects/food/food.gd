extends RigidBody3D
class_name Food

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Food")
@export var in_hand : bool = false

# ------------------------------------------------------------------------------
# Override Method
# ------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if freeze == true: return
	if linear_velocity.length() < 0.01 and angular_velocity.length() < 0.01:
		freeze = true

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func fling(strength : float = 1.0) -> void:
	if in_hand: return
	var plist = get_tree().get_nodes_in_group(GROUP_PLAYER)
	if plist.size() <= 0: return
	var direction : Vector3 = global_position.direction_to(plist[0].global_position)
	freeze = false
	apply_central_force(direction * strength)

# ------------------------------------------------------------------------------
# Handlers Methods
# ------------------------------------------------------------------------------
func _on_interacted(payload) -> void:
	if not freeze: return
