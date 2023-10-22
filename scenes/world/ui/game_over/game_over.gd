extends UIControl

const ENDINGS : Dictionary = {
	"FrontDoor": {
		"title": "Out the Front Door",
		"text": "You found the job a little... [i]intense[/i]. Whether that be from the work or, well, other things is a matter for debate.\n\nNeedless to say, you will not be getting paid, but, at least the rest of your evening was far more relaxing!",
		"scene": ""
	},
	
	"BackDoor": {
		"title": "Back Door Bailout",
		"text": "With one foot in front of the other you managed to make your way to the back of this creepy corner store... and right out the back door! You trip on some rather slimey looking trash piled all about the back of the building, but you're free! You're broke, but you're [b]free[/b]!",
		"scene": ""
	}
}


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _scenette: Node3D = %Scenette
@onready var _title: Label = %LblTitle
@onready var _body: RichTextLabel = %RLblBody

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	Relay.relayed.connect(_on_relayed)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_relayed(action : StringName, payload : Dictionary) -> void:
	if action != &"gameover_ending": return
	if not "ending" in payload: return
	if not payload["ending"] in ENDINGS: return
	_scenette.plate_scene(ENDINGS[payload["ending"]].scene)
	_title.text = ENDINGS[payload["ending"]].title
	_body.text = ENDINGS[payload["ending"]].text

func _on_btn_close_pressed() -> void:
	request(&"close_all")
	request(&"show_ui", {"ui_name":&"MainMenu"})
