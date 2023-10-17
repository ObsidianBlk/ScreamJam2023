extends Resource
class_name SplatBrush


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal texture_changed()
signal rotation_changed()
signal scale_changed()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Splat Brush")
@export var name : StringName = &""
@export var texture : Texture = null:								set = set_texture
@export_range(-180.0, 180.0) var texture_rotation : float = 0.0:	set = set_texture_rotation
@export var texture_scale : Vector2 = Vector2.ONE:					set = set_texture_scale
@export var modulate : Color = Color.WHITE

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_texture(tex : Texture) -> void:
	if texture != tex:
		texture = tex
		texture_changed.emit()

func set_texture_rotation(r : float) -> void:
	if r != texture_rotation and r >= -180.0 and r <= 180.0:
		texture_rotation = r
		rotation_changed.emit()

func set_texture_scale(s : Vector2) -> void:
	if not texture_scale.is_equal_approx(s):
		texture_scale = s
		scale_changed.emit()
