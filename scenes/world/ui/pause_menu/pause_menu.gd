extends UIControl



# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_btn_resume_pressed() -> void:
	request(&"unpause_game")

func _on_btn_options_pressed() -> void:
	request(&"show_ui", {"ui_name": &"OptionsMenu"})

func _on_btn_main_pressed() -> void:
	request(&"quit_game")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
