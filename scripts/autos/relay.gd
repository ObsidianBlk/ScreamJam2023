extends Node


signal relayed(action_name : StringName, payload : Dictionary)

func relay(action : StringName, payload : Dictionary = {}) -> void:
	relayed.emit(action, payload)
