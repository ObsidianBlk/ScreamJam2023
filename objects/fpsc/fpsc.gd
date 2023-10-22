extends CharacterBody3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal death(reason : String)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SETTINGS_SECTION : String = "Graphics"
const SETTINGS_KEY_FOV : String = "fov"

const CAMERA_PITCH_ANGLE : float = deg_to_rad(70.0)

const ACTION_HIDE : String = "Hide"
const ACTION_PICKUP : String = "Pickup"
const ACTION_ACTIVITY : String = "Activity"
const ACTION_SHOW_FLASHLIGHT : String = "Show_Flashlight"
const ACTION_HIDE_FLASHLIGHT : String = "Hide_Flashlight"

const FLING_OBJECT_GROUP : String = "Fling"
const MUSIC_DEATH_TIME : float = 60.0

const DEATH_REASON_MUSIC : String = "Musical"

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

var _has_flashlight : bool = false
var _item : Node3D = null

var _music_death_active : bool = false
var _music_death : float = 0.0
var _times_hit : int = 0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _camera: Camera3D = %Camera
@onready var _atree: AnimationTree = %ATree
@onready var _camera_ray: RayCast3D = %CameraRay
@onready var _mop_ray: RayCast3D = %MopRay
@onready var _item_drop: Marker3D = %ItemDrop
@onready var _flashlight: Node3D = $Hand/Flashlight
@onready var _hand_container: Node3D = $Hand

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.relayed.connect(_on_relayed)
	Settings.loaded.connect(_UpdateFromSettings)
	Settings.value_changed.connect(_on_settings_value_changed)
	_UpdateFromSettings()

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
#		if event.is_action_pressed("ui_cancel"):
#			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	
	if event.is_action_pressed("dummy1"):
		Relay.relay(&"lights_out")
	elif event.is_action_pressed("dummy2"):
		Relay.relay(&"lights_on")
	
	if event is InputEventMouseMotion:
		_UpdateCamera(event.relative * _mouse_sensitivity)
	elif event.is_action("look_down") or event.is_action("look_up") or event.is_action("turn_left") or event.is_action("turn_right"):
		var rel : Vector2 = Input.get_vector("turn_left", "turn_right", "look_up", "look_down")
		_UpdateCamera(rel)
	elif event.is_action("move_forward") or event.is_action("move_backward") or event.is_action("move_left") or event.is_action("move_right"):
		_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	elif event.is_action("use"):
		var strength : float = Input.get_action_strength("use")
		match _hand:
			HAND.Mop:
				if _atree.get("parameters/Actions/current_state") == ACTION_ACTIVITY:
					_mopping = strength > 0.5
			HAND.Item:
				if _camera_ray.is_colliding():
					var collision : Node3D = _camera_ray.get_collider()
					if collision is Interactable:
						if collision.type == &"Shelf":
							_DropItem(_camera_ray.get_collision_point())
				else:
					_DropItem(Vector3(
						_item_drop.global_position.x,
						global_position.y,
						_item_drop.global_position.z
					))
			HAND.Empty:
				if _has_flashlight:
					var state : String = _atree.get("parameters/Actions/current_state")
					if strength >= 0.5 and state != ACTION_SHOW_FLASHLIGHT and state != ACTION_HIDE_FLASHLIGHT:
						_atree.set("parameters/Actions/transition_request", ACTION_SHOW_FLASHLIGHT)
					elif strength < 0.5 and state == ACTION_SHOW_FLASHLIGHT:
						_atree.set("parameters/Actions/transition_request", ACTION_HIDE_FLASHLIGHT)

	elif event.is_action_pressed("interact"):
		match _hand:
			HAND.Empty:
				if not _camera_ray.is_colliding(): return
				var collision : Node3D = _camera_ray.get_collider()
				if not collision is Interactable: return
				#if collision.hand_required and _hand != HAND.Empty: return
				collision.interact({"player":self})
			HAND.Mop:
				Relay.relay(&"spawn_mop", {"position": Vector3(
					_item_drop.global_position.x,
					global_position.y,
					_item_drop.global_position.z
				)})
				_hand = HAND.Empty
				_atree.set("parameters/Actions/transition_request", ACTION_HIDE)

func _physics_process(delta: float) -> void:
	if _music_death_active:
		if _music_death < MUSIC_DEATH_TIME:
			_music_death += delta
			if _music_death >= MUSIC_DEATH_TIME:
				death.emit(DEATH_REASON_MUSIC)
	
	_CheckInteractable()
	_UpdateMopping(delta)
	
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
func _UpdateFromSettings() -> void:
	var fov : float = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_FOV, 0.0)
	if fov >= 1.0:
		_camera.fov = fov

func _UpdateCamera(relative : Vector2) -> void:
	if _camera == null: return
	rotate_y(-relative.x)
	_camera.rotate_x(-relative.y)
	_camera.rotation.x = clampf(_camera.rotation.x, -CAMERA_PITCH_ANGLE, CAMERA_PITCH_ANGLE)

func _CheckInteractable() -> void:
	if _camera_ray.is_colliding():
		var collision : Node3D = _camera_ray.get_collider()
		if collision is Interactable:
			match collision.type:
				&"Shelf":
					if _hand != HAND.Item: return
					collision.message()
				_:
					collision.message()
	else:
		Relay.relay(&"screen_message_hide")

func _UpdateMopping(delta : float) -> void:
	if _mopping:
		var val : float = _atree.get("parameters/Activity/blend_amount")
		if val < 1.0:
			_atree.set("parameters/Activity/blend_amount", min(1.0, val + delta))
		if _mop_ray.is_colliding():
			Relay.relay(&"mopping", {
				"collider": _mop_ray.get_collider(),
				"point": _mop_ray.get_collision_point()
			})
	elif _atree.get("parameters/Actions/current_state") == ACTION_ACTIVITY:
		var val : float = _atree.get("parameters/Activity/blend_amount")
		if val > 0.0:
			_atree.set("parameters/Activity/blend_amount", max(0.0, val - delta))

func _DropItem(pos : Vector3) -> void:
	if _item == null: return
	_hand_container.remove_child(_item)
	var itm : Node3D = _item
	_item = null
	_hand = HAND.Empty
	if itm is Food:
		itm.in_hand = false
	Relay.relay(&"drop_food", {
		"item": itm,
		"position": pos
	})
	

func _ToggleFlashlight() -> void:
	_flashlight.enabled = not _flashlight.enabled

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func give_item(item : Node3D) -> void:
	if _hand != HAND.Empty: return
	_item = item
	_hand_container.add_child(_item)
	_item.rotation = Vector3.ZERO
	_item.position = Vector3.ZERO
	if item is Food:
		item.in_hand = true
	_hand = HAND.Item

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"unpaused":
			_UpdateFromSettings()
		&"mop_pickup":
			_hand = HAND.Mop
			_atree.set("parameters/Actions/transition_request", ACTION_PICKUP)
		&"flashlight_pickup":
			_has_flashlight = true
		&"music_attack_start":
			_music_death_active = true
		&"music_attack_end":
			_music_death_active = false

func _on_settings_value_changed(section : String, key : String, value : Variant) -> void:
	if section == SETTINGS_SECTION and key == SETTINGS_KEY_FOV:
		if typeof(value) == TYPE_FLOAT:
			_camera.fov = value

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group(FLING_OBJECT_GROUP):
		_times_hit += 1
