extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"
const MOVE_SPEED : float = 2.0

const FLING_STRENGTH : float = 8.0

const WAIT_CHANCE : float = 0.3
const WAIT_TIME_MIN : float = 1.0
const WAIT_TIME_MAX : float = 4.0

const ATTACK_TIME_MIN : float = 0.8
const ATTACK_TIME_MAX : float = 1.4


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Invis. Walker")
@export var nav_group : StringName = &""
@export_range(0.0, 20.0) var min_distance : float = 4.0
@export_range(0.0, 20.0) var max_distance : float = 10.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _lights_out : bool = false
var _player : WeakRef = weakref(null)
var _next_pos : Vector3 = Vector3.ZERO
var _need_dest : bool = true
var _wait_time : float = 0.0

var _items : Array = []

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ghost: AnimatedSprite3D = $Ghost
@onready var _agent: NavigationAgent3D = $Agent
@onready var _player_attack_timer: Timer = $PlayerAttackTimer
@onready var _player_ray: RayCast3D = $PlayerRay

@onready var _audio_step1: AudioStreamPlayer3D = $AudioStep1
@onready var _audio_step2: AudioStreamPlayer3D = $AudioStep2


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.relayed.connect(_on_relayed)

func _process(delta: float) -> void:
	_UpdateGhostVis()
	if _need_dest:
		if _wait_time <= 0.0:
			_FindNewDestination()
		else:
			#print("Wait Time: ", _wait_time)
			_wait_time -= delta
	_UpdatePosition(delta)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateGhostVis() -> void:
	if _lights_out:
		var player = _GetPlayer()
		if player == null:
			_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
			return
		var alpha : float = _AlphaFromDistance(global_position, player.global_position)
		_ghost.modulate = Color(1.0, 1.0, 1.0, alpha)
		_player_ray.look_at(player.global_position)
	else:
		_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _UpdatePosition(delta : float) -> void:
	var pos : Vector3 = _agent.get_next_path_position()
	if not pos.is_equal_approx(_next_pos):
		_next_pos = pos
	var direction : Vector3 = global_position.direction_to(_next_pos)
	direction.y = 0.0
	global_position += direction * MOVE_SPEED * delta


func _GetPlayer() -> Node3D:
	var player : Node3D = _player.get_ref()
	if player == null:
		var plist : Array = get_tree().get_nodes_in_group(GROUP_PLAYER)
		if plist.size() > 0:
			player = plist[0]
			_player = weakref(player)
	return player

func _DistanceTo2D(from : Vector3, to : Vector3) -> float:
	return Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))

func _AlphaFromDistance(from : Vector3, to : Vector3) -> float:
	var dist = _DistanceTo2D(from, to)
	var total_dist : float = max_distance - min_distance
	if total_dist == 0.0: return 0.0
	return clampf((dist - min_distance) / total_dist, 0.0, 1.0)

func _FindNewDestination() -> void:
	if nav_group == &"": return
	var dstlist : Array = get_tree().get_nodes_in_group(nav_group)
	if dstlist.size() <= 1 : return
	var didx : int = randi_range(0, dstlist.size() - 1)
	_agent.target_position = Vector3(
		dstlist[didx].global_position.x,
		global_position.y,
		dstlist[didx].global_position.z
	)
	_need_dest = false

func _TakeStep(right : bool) -> void:
	if not _lights_out or _wait_time > 0.0: return
	_PlayStep()
	var direction : Vector3 = global_position.direction_to(_next_pos)
	var angle = Vector2(direction.x, direction.z).angle()
	Relay.relay(&"splat", {
		"brush":&"RightFoot" if right else &"LeftFoot",
		"point": global_position,
		"stamp": true,
		"rotation": angle + deg_to_rad(90)
	})

func _PlayStep() -> void:
	var pitch = randf_range(.8, 1.0)
	var audio : AudioStreamPlayer3D = _audio_step1 if randf() < 0.5 else _audio_step2
	audio.pitch_scale = pitch
	audio.play()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"lights_out":
			var dstlist : Array = get_tree().get_nodes_in_group(nav_group)
			if dstlist.size() >= 1 :
				_need_dest = true
				var didx : int = randi_range(0, dstlist.size() - 1)
				global_position = dstlist[didx].global_position
			_lights_out = true
		&"lights_on":
			_lights_out = false

func _on_agent_target_reached() -> void:
	_need_dest = true
	if randf() <= WAIT_CHANCE:
		_wait_time = randf_range(WAIT_TIME_MIN, WAIT_TIME_MAX)
	else:
		_FindNewDestination()

func _on_player_attack_timer_timeout() -> void:
	var delay : float = randf_range(ATTACK_TIME_MIN, ATTACK_TIME_MIN)
	_player_attack_timer.start(delay)
	var player : Node3D = _GetPlayer()
	if player == null: return
	if _player_ray.is_colliding():
		if _items.size() <= 0: return
		var idx : int = randi_range(0, _items.size() - 1)
		var inter : Interactable = _items[idx]
		_items.remove_at(idx)
		inter.interact({"fling_strength": FLING_STRENGTH})


func _on_food_area_entered(area: Area3D) -> void:
	if area is Interactable:
		if area.type != &"Item": return
		_items.append(area)

func _on_food_area_exited(area: Area3D) -> void:
	if area is Interactable and area.type == &"Item":
		_items = _items.filter(func(item): item != area)
