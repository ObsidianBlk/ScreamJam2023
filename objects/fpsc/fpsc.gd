extends CharacterBody3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CAMERA_PITCH_ANGLE : float = deg_to_rad(70.0)

const ACTION_HIDE : String = "Hide"
const ACTION_PICKUP : String = "Pickup"
const ACTION_ACTIVITY : String = "Activity"

enum HAND {Empty=0, Mop=1, Item=2}

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("FPSC")
@export var speed : float = 5.0
@export var jump_speed : float = 5.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _mouse_sensitivity : Vector2 = Vector2(0.02, 0.02)

var _gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _input : Vector2 = Vector2.ZERO
var _jump : bool = false

var _hand : HAND = HAND.Empty
var _mopping : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _camera: Camera3D = %Camera
@onready var _atree: AnimationTree = %ATree
@onready var _camera_ray: RayCast3D = %CameraRay

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pass
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
#		if event.is_action_pressed("ui_cancel"):
#			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion:
		_UpdateCamera(event.relative * _mouse_sensitivity)
	elif event.is_action("look_down") or event.is_action("look_up") or event.is_action("turn_left") or event.is_action("turn_right"):
		var rel : Vector2 = Input.get_vector("turn_left", "turn_right", "look_up", "look_down")
		_UpdateCamera(rel)
	elif event.is_action("move_forward") or event.is_action("move_backward") or event.is_action("move_left") or event.is_action("move_right"):
		_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	elif event.is_action("use"):
		match _hand:
			HAND.Mop:
				if _atree.get("parameters/Actions/current_state") == ACTION_ACTIVITY:
					_mopping = Input.get_action_strength("use") > 0.5
			HAND.Item:
				if _camera_ray.is_colliding():
					var collision : Node3D = _camera_ray.get_collider()
					if collision is Interactable:
						collision.interact()

	elif event.is_action_pressed("interact"):
		pass

func _physics_process(delta: float) -> void:
	_CheckInteractable()
	
	velocity.y += -_gravity * delta
	var move_dir : Vector3 = transform.basis * Vector3(_input.x, 0.0, _input.y)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	move_and_slide()
	if is_on_floor() and _jump:
		velocity.y = jump_speed
	_jump = false

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateCamera(relative : Vector2) -> void:
	if _camera == null: return
	rotate_y(-relative.x)
	_camera.rotate_x(-relative.y)
	_camera.rotation.x = clampf(_camera.rotation.x, -CAMERA_PITCH_ANGLE, CAMERA_PITCH_ANGLE)

func _CheckInteractable() -> void:
	if _camera_ray.is_colliding():
		var collision : Node3D = _camera_ray.get_collider()
		if collision is Interactable:
			Relay.relay(&"message", {"show":true, "name": "InteractMessage"})
	else:
		Relay.relay(&"message", {"show": false})
