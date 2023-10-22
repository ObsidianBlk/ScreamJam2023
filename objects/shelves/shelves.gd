extends StaticBody3D
class_name Shelves

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal shelf_items_changed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
var ITEMS : Array[PackedScene] = [
	preload("res://objects/food/bottle_01.tscn"),
	preload("res://objects/food/bottle_02.tscn"),
	preload("res://objects/food/bottle_03.tscn"),
	preload("res://objects/food/box_01.tscn"),
	preload("res://objects/food/box_02.tscn"),
	preload("res://objects/food/box_03.tscn"),
]

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _items : Array[Interactable] = []

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _item_spawn_loc: Node3D = $ItemSpawnLoc


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SpawnItem(pos : Vector3) -> void:
	var idx : int = randi_range(0, ITEMS.size() - 1)
	var item : Node3D = ITEMS[idx].instantiate()
	if item != null:
		Relay.relay(&"drop_food", {
			"item": item,
			"position": pos
		})

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_total_items() -> int:
	return _items.size()

func spawn_items(count : int) -> void:
	if _item_spawn_loc == null or count <= 0: return
	var children : Array = _item_spawn_loc.get_children()
	if count > children.size():
		count = children.size() - 1
	for i in range(count):
		if children.size() <= 0: break
		var idx : int = randi_range(0, children.size() - 1)
		var child : Node3D = children[idx]
		children.remove_at(idx)
		_SpawnItem(child.global_position)
		

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_entered(area : Area3D) -> void:
	if not area is Interactable: return
	if area.type == &"Item":
		if _items.find(area) < 0:
			_items.append(area)
			shelf_items_changed.emit()

func _on_exited(area : Area3D) -> void:
	if not area is Interactable: return
	if area.type != &"Item":
		var count : int = _items.size()
		_items = _items.filter(func(item): item != area)
		if _items.size() != count:
			shelf_items_changed.emit()

