extends UIControl


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_btn_reset_pressed():
	Settings.load()


func _on_btn_back_pressed():
	_Request(&"close_ui")
