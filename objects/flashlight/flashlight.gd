extends Node3D


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Flashlight")
@export var enabled : bool = false:						set = set_enabled
@export var interactable : bool = true:					set = set_interactable
@export_range(0.0, 16.0) var energy : float = 5.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _light: SpotLight3D = $Light
@onready var _interactable: Interactable = $Interactable

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_enabled(e : bool) -> void:
	if e != enabled:
		enabled = e
		_UpdateLight()

func set_interactable(i : bool) -> void:
	interactable = i
	if _interactable != null:
		_interactable.enabled = interactable

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	set_interactable(interactable)
	_UpdateLight()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateLight() -> void:
	if _light == null: return
	_light.light_energy = energy if enabled else 0.0

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_interactable_interacted(payload : Dictionary = {}) -> void:
	queue_free()
	Relay.relay(&"flashlight_pickup")
