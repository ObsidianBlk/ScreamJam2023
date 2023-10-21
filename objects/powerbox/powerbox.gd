extends StaticBody3D


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_interactable_interacted(payload) -> void:
	Relay.relay(&"lights_on")
