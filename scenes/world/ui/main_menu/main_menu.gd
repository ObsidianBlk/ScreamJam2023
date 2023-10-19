extends UIControl


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const URI_OBSIDIAN_ITCHIO : String = "https://obsidianblk.itch.io/"

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------

func _on_op_start_pressed():
	_Request(&"start_game")


func _on_op_options_pressed():
	_Request(&"show_ui", {"ui_name":&"OptionsMenu"})


func _on_op_quit_pressed():
	_Request(&"quit_application")


func _on_btn_obs_pressed():
	OS.shell_open(URI_OBSIDIAN_ITCHIO)
