extends RigidBody3D


const AUDIO_A : AudioStream = preload("res://assets/audio/sfx/cardboard_foley_01.wav")
const AUDIO_B : AudioStream = preload("res://assets/audio/sfx/cardboard_foley_02.wav")

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
func _ready() -> void:
	contact_monitor = true
	body_entered.connect(_on_body_entered)
	_PlayAudio()

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

func _PlayAudio() -> void:
	if %Audio == null: return
	%Audio.stream = AUDIO_A if randf() < 0.5 else AUDIO_B
	%Audio.pitch_scale = randf_range(0.6, 1.4)
	%Audio.play()

# ------------------------------------------------------------------------------
# Handlers Methods
# ------------------------------------------------------------------------------

func _on_body_entered(body: Node) -> void:
	_PlayAudio()
