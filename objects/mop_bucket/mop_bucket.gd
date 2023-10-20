extends Node3D


func _PickedUp() -> void:
	Relay.relay(&"mop_pickup")
	queue_free()


func _on_interactable_interacted(payload) -> void:
	_PickedUp.call_deferred()
