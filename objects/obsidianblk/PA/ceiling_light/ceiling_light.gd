@tool
extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ENERGY_AMOUNT_THRESHOLD : float = 0.1
const LIGHT_SPEED : float = 10.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Ceiling Light")
@export var color : Color = Color.WHITE:				set=set_color
@export_range(0.0, 16.0) var min_energy : float = 1.0:	set=set_min_energy
@export_range(0.0, 16.0) var max_energy : float = 1.0:	set=set_max_energy
@export var flicker_noise : Noise = null
@export var flicker_in_editor : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _energy_amount : float = 0.0
var _noise_pos : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _light = $Light
@onready var _light_block_mesh = $LightBlockMesh


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	if c != color:
		color = c
		_UpdateColor()

func set_min_energy(e : float) -> void:
	if e >= 0.0 and e <= 16.0:
		_UpdateEnergyAmount()

func set_max_energy(e : float) -> void:
	if e >= 0.0 and e <= 16.0:
		max_energy = max(min_energy, e)
		_UpdateEnergyAmount()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateColor()
	_UpdateEnergyAmount()

func _process(delta : float) -> void:
	if flicker_noise == null or _energy_amount <= 0.0 : return
	if not flicker_in_editor:
		if Engine.is_editor_hint(): return
	
	_noise_pos = fmod(_noise_pos + (delta * LIGHT_SPEED), 128.0)
	var mult : float = wrapf(flicker_noise.get_noise_1d(_noise_pos) + 1.0, 0.0, 1.0)
	_UpdateEnergy(min_energy + (_energy_amount * mult))

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
	if _light != null:
		_light.light_energy = amount
	if _light_block_mesh != null:
		_light_block_mesh.mesh.material.emission_energy_multiplier = amount

