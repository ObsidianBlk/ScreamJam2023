extends Node3D
class_name Level3D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal requested(action : StringName, payload : Dictionary)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MOP : PackedScene = preload("res://objects/mop_bucket/mop_bucket.tscn")

const SETTINGS_SECTION : String = "Graphics"
const SETTINGS_KEY_SSAO : String = "ssao"
const SETTINGS_KEY_SSIL : String = "ssil"

const GROUP_SHELVES : StringName = &"Shelves"
const GROUP_ITEM : StringName = &"Item"

const CLOCK_SEC_PER_MINUTE : float = 2.0
const CLOCK_START_HOUR : int = 23
const CLOCK_START_MINUTE : int = 0
const CLOCK_END_HOUR : int = 6

const MINUTES_BETWEEN_EVENTS_MIN : int = 15
const MINUTES_BETWEEN_EVENTS_MAX : int = 45

# ------------------------------------------------------------------------------
# Exports
# ------------------------------------------------------------------------------
@export_category("Level 3D")
@export var pause_action_name : StringName = &""
@export var environment : WorldEnvironment = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _init : bool = false

var _floor_percent : float = 0.0

var _event_active : bool = false
var _event_end_timestamp : int = 0
var _event_delay : int = 60

var _last_event : StringName = &""
var _door_exit_type : String = ""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _door_exit_timer: Timer = $DoorExitTimer
@onready var _music: AudioStreamPlayer = $Music

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_environment(e : WorldEnvironment) -> void:
	if e != environment:
		environment = e
		_UpdateFromSettings()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Clock24.clock_ticked.connect(_on_clock_time_passed)
	Relay.relayed.connect(_on_relayed)
	Settings.loaded.connect(_UpdateFromSettings)
	Settings.value_changed.connect(_on_settings_value_changed)


func _unhandled_input(event : InputEvent) -> void:
	if pause_action_name == &"": return
	if event.is_action_pressed(pause_action_name, false, true):
		requested.emit(&"pause_game", {})
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateFromSettings() -> void:
	if environment == null: return
	var env : Environment = environment.environment
	var val : Variant = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_SSAO, null)
	if typeof(val) == TYPE_BOOL:
		env.ssao_enabled = val
	val = Settings.get_value(SETTINGS_SECTION, SETTINGS_KEY_SSIL, null)
	if typeof(val) == TYPE_BOOL:
		env.ssil_enabled = val

func _EventOver() -> void:
	_event_active = false
	_event_delay = randi_range(MINUTES_BETWEEN_EVENTS_MIN, MINUTES_BETWEEN_EVENTS_MAX)
	_event_end_timestamp = Clock24.get_minutes_elapsed()

func _GameOverSurvived() -> void:
	var shelves_percent : float = get_percent_items_shelved()
	var total_percent = (shelves_percent + _floor_percent) * 0.5
	if total_percent < 0.6:
		game_over_ending("AnyWork")
	elif total_percent < 0.8:
		game_over_ending("GoodWork")

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func initialize() -> void:
	if _init: return
	_init = true
	Clock24.reset(CLOCK_START_HOUR, CLOCK_START_MINUTE)
	Clock24.set_seconds_per_minute(CLOCK_SEC_PER_MINUTE)
	randomize()
	var shelves : Array = get_tree().get_nodes_in_group(GROUP_SHELVES)
	for shelf in shelves:
		if shelf is Shelves:
			shelf.spawn_items(randi_range(4, 10))

func request(action : StringName, payload : Dictionary) -> void:
	requested.emit(action, payload)

func get_percent_items_shelved() -> float:
	var total_shelved : int = 0
	var shelves : Array = get_tree().get_nodes_in_group(GROUP_SHELVES)
	for shelf in shelves:
		if shelf is Shelves:
			total_shelved += shelf.get_total_items()
	
	var items : Array = get_tree().get_nodes_in_group(GROUP_ITEM)
	
	if items.size() > 0:
		return float(total_shelved) / float(items.size())
	return 0.0

func game_over_ending(ending_name : String) -> void:
	if _door_exit_timer == null: return
	if not _door_exit_timer.is_stopped(): return
	if ending_name.is_empty(): return
	_door_exit_type = ending_name
	_door_exit_timer.start()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"unpaused":
			_UpdateFromSettings()
			if not Clock24.is_enabled():
				Clock24.enable()
			if not _init:
				initialize()
		&"spawn_mop":
			var mop : Node3D = MOP.instantiate()
			add_child(mop)
			mop.global_position = payload.position
		&"drop_food":
			if not "item" in payload: return
			if not payload["item"] is Node3D: return
			if not "position" in payload: return
			if typeof(payload["position"]) != TYPE_VECTOR3: return
			add_child(payload["item"])
			payload["item"].global_position = payload["position"]
		&"lights_on":
			_EventOver()

func _on_settings_value_changed(section : String, key : String, value : Variant) -> void:
	if environment == null or section != SETTINGS_SECTION: return
	var env : Environment = environment.environment
	
	match key:
		SETTINGS_KEY_SSAO:
			if typeof(value) == TYPE_BOOL:
				env.ssao_enabled = value
		SETTINGS_KEY_SSIL:
			if typeof(value) == TYPE_BOOL:
				env.ssil_enabled = value

func _on_clock_time_passed(hour : int, minute : int) -> void:
	if hour == CLOCK_END_HOUR:
		# If we got to 6am, we survived! Time to tally success!
		_GameOverSurvived()
		return
	
	# If we're already in an event, can't start another.
	if _event_active == true : return
	
	# Don't bother if there's less than "15 minutes" left.
	if Clock24.get_minutes_until(CLOCK_END_HOUR, 0) < 30: return
	
	if _event_delay > 0:
		_event_delay -= 1
		return
	
	randomize()
	var prob : float = randf()
	if prob < 0.1:
		if _last_event == &"music": return
		_last_event = &"music"
		_event_active = true
		Relay.relay(&"music_attack_start")
		_music.play()
	else: # Lights Out is allowed even if it was the last event.
		_last_event = &"" # Which is why we don't record it.
		_event_active = true
		Relay.relay(&"lights_out")


func _on_match_percentage_updated(percent : float) -> void:
	_floor_percent = percent

func _on_shelf_items_changed() -> void:
	pass
	#print("Shelved Items: ", get_percent_items_shelved())

func _on_door_exit_timer_timeout() -> void:
	if _door_exit_type == "": return
	request(&"game_over", {"ending": _door_exit_type})

func _on_music_finished() -> void:
	Relay.relay(&"music_attack_end")
	_EventOver()


func _on_music_protection_zone_body_entered(body: Node3D) -> void:
	if body.has_method("protection_from_music"):
		body.protection_from_music(true)


func _on_music_protection_zone_body_exited(body: Node3D) -> void:
	if body.has_method("protection_from_music"):
		body.protection_from_music(false)
