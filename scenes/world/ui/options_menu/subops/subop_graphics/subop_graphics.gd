extends Control

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SECTION : String = "Graphics"
const SETTINGS_KEY_FULLSCREEN : String = "fullscreen"
const SETTINGS_KEY_SSAO : String = "ssao"
const SETTINGS_KEY_SSIL : String = "ssil"
const SETTINGS_KEY_FOV : String = "fov"
const DEFAULTS : Dictionary = {
	SETTINGS_KEY_FULLSCREEN: false,
	SETTINGS_KEY_SSAO: true,
	SETTINGS_KEY_SSIL: true,
	SETTINGS_KEY_FOV: 75.0
}


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _check_fullscreen = %CheckFullscreen
@onready var _slider_fov = %SliderFOV
@onready var _lbl_fov = %LblFOV
@onready var _check_ssao = %CheckSSAO
@onready var _check_ssil = %CheckSSIL


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Settings.reset.connect(_on_reset)
	Settings.loaded.connect(_on_loaded)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_subop_name() -> String:
	return "Graphics"

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_reset() -> void:
	for key in DEFAULTS.keys():
		Settings.set_value(SECTION, key, DEFAULTS[key])

func _on_loaded() -> void:
	for key in DEFAULTS.keys():
		var val : Variant = Settings.get_value(SECTION, key, DEFAULTS[key])
		match key:
			"fullscreen":
				_check_fullscreen.button_pressed = val
			"ssao":
				_check_ssao.button_pressed = val
			"ssil":
				_check_ssil.button_pressed = val
			"fov":
				_slider_fov.value = val
				_lbl_fov.text = "[ %d ]"%[val]

func _on_check_fullscreen_toggled(button_pressed : bool) -> void:
	Settings.set_value(SECTION, SETTINGS_KEY_FULLSCREEN, button_pressed)


func _on_check_ssao_toggled(button_pressed : bool) -> void:
	Settings.set_value(SECTION, SETTINGS_KEY_SSAO, button_pressed)


func _on_check_ssil_toggled(button_pressed: bool) -> void:
	Settings.set_value(SECTION, SETTINGS_KEY_SSIL, button_pressed)


func _on_slider_fov_value_changed(value : float) -> void:
	_lbl_fov.text = "[ %d ]"%[value]
	Settings.set_value(SECTION, SETTINGS_KEY_FOV, value)
