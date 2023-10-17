extends GridMap


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_category("SplatGrid")
@export var tile_name : String = "":			set = set_tile_name
@export var splat_view : SubViewport = null:	set = set_splat_view


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _queue_reset : bool = true
var _rect : Rect2 = Rect2()

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_tile_name(tn : String) -> void:
	if tn != tile_name:
		tile_name = tn
		_queue_reset = true

func set_splat_view(sv : SubViewport) -> void:
	if sv != splat_view:
		splat_view = sv
		_queue_reset = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.relayed.connect(_on_relayed)

func _physics_process(_delta: float) -> void:
	if _queue_reset:
		_Reset()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetAABB() -> AABB:
	if mesh_library == null: return AABB()
	
	var main_aabb : AABB = AABB()
	for pos in get_used_cells():
		var id : int = get_cell_item(pos)
		var mesh : Mesh = mesh_library.get_item_mesh(id)
		var maabb : AABB = mesh.get_aabb()
		maabb.position = map_to_local(pos) + maabb.position
		if not main_aabb.has_volume():
			main_aabb = maabb
		else:
			main_aabb = main_aabb.merge(maabb)
	
	return main_aabb


func _Reset() -> void:
	if _rect.has_area(): _rect = Rect2()
	if not mesh_library: return
	var tid : int = mesh_library.find_item_by_name(tile_name)
	if tid < 0: return
	
	if splat_view != null:
		splat_view.set_match_target_to_color(Color.BLACK)
	
	var aabb : AABB = _GetAABB()
	if not aabb.has_volume(): return
	
	_rect = Rect2(
		Vector2(aabb.position.x, aabb.position.z),
		Vector2(aabb.size.x, aabb.size.z)
	)
	
	var tmesh : Mesh = mesh_library.get_item_mesh(tid)
	var mat = tmesh.surface_get_material(0)
	if mat is ShaderMaterial:
		var tex : Texture = null if not splat_view else splat_view.get_texture()
		mat.set_shader_parameter("mask_texture", tex)
		mat.set_shader_parameter("ground_offset", _rect.position)
		mat.set_shader_parameter("ground_area", _rect.size)
	
	_queue_reset = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func update_splat(object : Node3D, point : Vector3) -> void:
	if not _rect.has_area() or splat_view == null: return
	if object != self: return
	var uv : Vector2 = Vector2.ZERO
	uv = (Vector2(point.x, point.z) - _rect.position) / _rect.size
	splat_view.update_brush(&"Mop", uv, true)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_relayed(action_name : StringName, payload : Dictionary) -> void:
	if action_name == &"mopping" and not payload.is_empty():
		update_splat(payload.collider, payload.point)

