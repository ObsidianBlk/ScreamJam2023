extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANGLE_PER_SECOND : float = deg_to_rad(10.0)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _spin_plate: Node3D = $SpinPlate

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	_spin_plate.rotation.y = wrapf(
		_spin_plate.rotation.y + ANGLE_PER_SECOND * delta,
		0.0,
		deg_to_rad(360.0)
	)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearPlate() -> void:
	if _spin_plate == null: return
	for child in _spin_plate.get_children():
		child.queue_free()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func plate_scene(scene_path : String) -> int:
	var packed_scene = load(scene_path)
	if not packed_scene is PackedScene:
		return ERR_FILE_BAD_PATH
	
	var scene : Node = packed_scene.instantiate()
	if scene is Node3D:
		_spin_plate.add_node(scene)
	else:
		scene.queue_free()
		return ERR_INVALID_DECLARATION
	return OK

