extends Area3D
class_name Interactable

signal interacted(payload : Dictionary)

func interact(payload : Dictionary = {}) -> void:
	interacted.emit(payload)
