extends SubViewport
class_name SplatCanvas


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal match_percentage_updated(percent : float)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("Splat Canvas")
@export var clear_color : Color = Color.BLACK
@export var match_target : Texture = null:			set = set_match_target
@export var brushes : Array[SplatBrush] = []:		set = set_brushes


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _brushes : Dictionary = {}
var _active : Dictionary = {}

var _brush_update_queued : bool = true
var _clear_queued : bool = false

var _match_target_mean : float = 0.0

var _clear_rect : ColorRect = null
var _hold_clear_toggle : bool = true
var _negative_img : Image = null


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_brushes(b : Array[SplatBrush]) -> void:
	brushes = b
	_brush_update_queued = true

func set_match_target(mt : Texture) -> void:
	if mt == null or (mt != match_target and mt.get_size().is_equal_approx(size)):
		match_target = mt
		_match_target_mean = 0.0

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_clear_rect = ColorRect.new()
	add_child(_clear_rect)
	_clear_rect.size = size
	_clear_rect.color = clear_color
	
	_UpdateBrushDictionary()
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
	render_target_update_mode = SubViewport.UPDATE_ONCE


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateBrushDictionary() -> void:
	if not _brush_update_queued: return
	_brush_update_queued = false
	
	for brush_name in _brushes.keys():
		if brushes.filter(func(brush): brush.name == brush_name).size() > 0: continue
		_DisconnectBrush(brush_name)
	
	for brush in brushes:
		if brush.name == &"": continue
		_ConnectBrush(brush)
	
	for brush_name in _active.keys():
		if brush_name in _brushes: continue
		_active.erase(brush_name)


func _ConnectBrush(brush : SplatBrush) -> void:
	if brush.name in _brushes: return
	var sprite : Sprite2D = Sprite2D.new()
	sprite.texture = brush.texture
	sprite.scale = brush.texture_scale
	sprite.rotation_degrees = brush.texture_rotation
	sprite.visible = false
	add_child(sprite)
	if not brush.texture_changed.is_connected(_on_brush_texture_changed.bind(sprite, brush)):
		brush.texture_changed.connect(_on_brush_texture_changed.bind(sprite, brush))
	if not brush.rotation_changed.is_connected(_on_brush_rotation_changed.bind(sprite, brush)):
		brush.rotation_changed.connect(_on_brush_rotation_changed.bind(sprite, brush))
	if not brush.scale_changed.is_connected(_on_brush_scale_changed.bind(sprite, brush)):
		brush.scale_changed.connect(_on_brush_scale_changed.bind(sprite, brush))
	_brushes[brush.name] = {
		"sprite": sprite,
		"brush": brush
	}

func _DisconnectBrush(brush_name : StringName) -> void:
	if not brush_name in _brushes: return
	var sprite : Sprite2D = _brushes[brush_name].sprite
	var brush : SplatBrush = _brushes[brush_name].brush
	if brush.texture_changed.is_connected(_on_brush_texture_changed.bind(sprite, brush)):
		brush.texture_changed.disconnect(_on_brush_texture_changed.bind(sprite, brush))
	if brush.rotation_changed.is_connected(_on_brush_rotation_changed.bind(sprite, brush)):
		brush.rotation_changed.disconnect(_on_brush_rotation_changed.bind(sprite, brush))
	if brush.scale_changed.is_connected(_on_brush_scale_changed.bind(sprite, brush)):
		brush.scale_changed.disconnect(_on_brush_scale_changed.bind(sprite, brush))
	remove_child(sprite)
	sprite.queue_free()
	_brushes.erase(brush_name)

func _CheckMatchTarget() -> void:
	if match_target == null: return
	var simg : Image = get_texture().get_image()
	var timg : Image = match_target.get_image()
	var info : Dictionary = simg.compute_image_metrics(timg, true)
	if _match_target_mean <= 0.0:
		_match_target_mean = info.mean
	if _match_target_mean > 0.0:
		var percent : float = 1.0 - (info.mean / _match_target_mean)
		match_percentage_updated.emit(percent)
	

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_brush(brush_name : StringName) -> bool:
	# NOTE: This may return false until the exported brushes array is updated into the
	#   internal _brushes dictionary.
	return brush_name in _brushes

func is_brush_active(brush_name : StringName) -> bool:
	return brush_name in _active

func update_brush(brush_name : StringName, uv : Vector2, rotation : float = 0.0, stamp : bool = false) -> void:
	if not brush_name in _brushes: return
	if not brush_name in _active:
		_active[brush_name] = {
			"remove": false,
			"rotation": rotation,
			"stamp": stamp
		}
	else:
		_active[brush_name].remove = false
		_active[brush_name].rotation = rotation
		_active[brush_name].stamp = stamp
	_brushes[brush_name].sprite.position = Vector2(size) * uv

func clear_brush(brush_name : StringName) -> void:
	if not brush_name in _active: return
	_active[brush_name].remove = true

func clear() -> void:
	_clear_queued = true
	_clear_rect.color = clear_color

func set_match_target_to_color(color : Color) -> void:
	var img : Image = get_texture().get_image()
	var mimg : Image = Image.create(
		img.get_width(),
		img.get_height(),
		false,
		img.get_format()
	)
	mimg.fill(color)
	match_target = ImageTexture.create_from_image(mimg)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_size_changed() -> void:
	if _clear_rect == null: return
	_clear_rect.size = size
	match_target = null

func _on_brush_texture_changed(sprite : Sprite2D, brush : SplatBrush) -> void:
	if sprite == null or brush == null: return
	sprite.texture = brush.texture

func _on_brush_rotation_changed(sprite : Sprite2D, brush : SplatBrush) -> void:
	if sprite == null or brush == null: return
	sprite.rotation_degrees = brush.texture_rotation

func _on_brush_scale_changed(sprite : Sprite2D, brush : SplatBrush) -> void:
	if sprite == null or brush == null: return
	sprite.scale = brush.texture_scale

func _on_frame_post_draw() -> void:
	if _brush_update_queued:
		_UpdateBrushDictionary()
	
	var update_view : bool = false
	for brush_name in _active.keys():
		if not brush_name in _brushes: continue
		var sprite : Sprite2D = _brushes[brush_name].sprite
		var brush : SplatBrush = _brushes[brush_name].brush
		if not _active[brush_name].remove:
			#print("Setting brush: ", brush_name, " | Pos: ", sprite.position)
			if not sprite.visible:
				sprite.visible = true
			sprite.modulate = brush.modulate
			sprite.rotation = _active[brush_name].rotation
			#print("Color: ", sprite.modulate)
			if _active[brush_name].stamp:
				_active[brush_name].remove = true
			update_view = true
		else:
			#print("Removing Brush: ", brush_name)
			sprite.visible = false
			_active.erase(brush_name)

	if _clear_rect.visible or _clear_queued:
		if not _hold_clear_toggle:
			_clear_rect.visible = not _clear_rect.visible
		_hold_clear_toggle = false
		_clear_queued = false
		update_view = true
	
	if update_view:
		_CheckMatchTarget()
		render_target_update_mode = SubViewport.UPDATE_ONCE
