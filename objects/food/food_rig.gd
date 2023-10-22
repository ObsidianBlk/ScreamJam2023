extends RigidBody3D


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_file("*.tscn") var static_version_path : String = ""

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _life : float = 0.5

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_life -= delta
	if _life > 0.0:return
	
	if _life < -1.0 or (linear_velocity.length() < 1.0 and angular_velocity.length() < 5.0):
		_Die()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Die() -> void:
	var static_version : PackedScene = load(static_version_path)
	if static_version != null:
		var s : Node3D = static_version.instantiate()
		s.rotation = rotation
		Relay.relay(&"drop_food", {
			"item": s,
			"position": global_position
		})
	queue_free()


