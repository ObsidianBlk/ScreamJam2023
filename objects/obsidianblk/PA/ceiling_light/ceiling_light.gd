@tool
extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ENERGY_AMOUNT_THRESHOLD : float = 0.1
const LIGHT_SPEED : float = 10.0

const START_PITCH_MIN : float = 0.6
const START_PITCH_MAX : float = 1.4


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Ceiling Light")
@export var enabled : bool = true:						set = set_enabled
@export var color : Color = Color.WHITE:				set = set_color
@export_range(0.0, 16.0) var min_energy : float = 1.0:	set = set_min_energy
@export_range(0.0, 16.0) var max_energy : float = 1.0:	set = set_max_energy
@export var chargeup_time : float = 0.5:				set = set_chargeup_time
@export var charge_curve : Curve = null
@export var flicker_noise : Noise = null
@export var flicker_in_editor : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _energy_amount : float = 0.0
var _noise_pos : float = 0.0

var _charge_time : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _light = $Light
@onready var _light_block_mesh = $LightBlockMesh
@onready var _audio_hum: AudioStreamPlayer3D = %AudioHum
@onready var _audio_start: AudioStreamPlayer3D = %AudioStart


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	if c != color:
		color = c
		_UpdateColor()

func set_min_energy(e : float) -> void:
	if e >= 0.0 and e <= 16.0:
		min_energy = min(max_energy, e)
		_UpdateEnergyAmount()

func set_max_energy(e : float) -> void:
	if e >= 0.0 and e <= 16.0:
		max_energy = max(min_energy, e)
		_UpdateEnergyAmount()

func set_chargeup_time(c : float) -> void:
	if c >= 0.0:
		chargeup_time = c

func set_enabled(e : bool) -> void:
	if e != enabled:
		enabled = e
		if not enabled:
			_charge_time = 0.0
			_UpdateEnergy(0.0)
		else:
			_TriggerStartAudio()
			_UpdateEnergyAmount()

# ------------------------------------------------------------------------------
# Override Methods
# -------------		_UpdateEnergy(0.0)-----------------------------------------------------------------
func _ready() -> void:
	if not Engine.is_editor_hint():
		Relay.relayed.connect(_on_relayed)
	_UpdateColor()
	_UpdateEnergyAmount()

func _process(delta : float) -> void:
	var charge : float = _HandleChargeUp(delta)
	var flicker_mult : float = _HandleFlicker(delta)
	_UpdateEnergy((min_energy + (_energy_amount * flicker_mult)) * charge)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateColor() -> void:
	if _light != null:
		_light.light_color = color
	if _light_block_mesh != null:
		_light_block_mesh.mesh.material.emission = color

func _UpdateEnergyAmount() -> void:
	_energy_amount = max_energy - min_energy
	if _energy_amount < ENERGY_AMOUNT_THRESHOLD:
		_energy_amount = 0.0
		_UpdateEnergy(max_energy)
	if flicker_noise == null:
		_UpdateEnergy(min_energy)

func _UpdateEnergy(amount : float) -> void:
	if not enabled :
		amount = 0.0
	
	if _light != null:
		_light.light_energy = amount
		_light.visible = amount > 0.0
	if _light_block_mesh != null:
		_light_block_mesh.mesh.material.emission_energy_multiplier = amount
		_light_block_mesh.mesh.material.emission_enabled = amount > 0.0

func _HandleChargeUp(delta : float) -> float:
	if not enabled:
		_charge_time = 0.0
		return 0.0
	
	if chargeup_time > 0.0:
		_charge_time = min(chargeup_time, _charge_time + delta)
		var charge : float = _charge_time / chargeup_time
		
		if charge_curve != null:
			return clampf(charge_curve.sample(charge), 0.0, 1.0)
		return charge
	return 1.0

func _HandleFlicker(delta : float) -> float:
	if flicker_noise == null or _energy_amount <= 0.0 : return 0.0
	if not flicker_in_editor:
		if Engine.is_editor_hint(): return 0.0
	
	_noise_pos = fmod(_noise_pos + (delta * LIGHT_SPEED), 128.0)
	return wrapf(flicker_noise.get_noise_1d(_noise_pos) + 1.0, 0.0, 1.0)

func _TriggerStartAudio() -> void:
	if _audio_start == null: return
	randomize()
	_audio_start.pitch_scale = randf_range(START_PITCH_MIN, START_PITCH_MAX)
	_audio_start.play()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	match action:
		&"lights_out":
			enabled = false
		&"lights_on":
			enabled = true

