extends UIControl

const ENDINGS : Dictionary = {
	"AnyWork": { # Survived the night, but shit ain't clean enough
		"title": "You Showed Up... At Least",
		"text": "Your boss walks in and doesn't look at all pleased with the state of their store.\n\n[b]Boss:[/b] This isn't the job I was expecting when I said I'd pay you. Sure, you didn't leave, but, you could have put some effort in at least!",
		"scene": "res://scenes/Scenettes/victory_a/victory_a.tscn"
	},
	
	"GoodWork":{ # Survived the night and shit is looking good!
		"title": "This is AMAZING!",
		"text": "Your boss walks in and upon seeing the state of their store, a wide smile spreads across their face.\n\n [b]Boss:[/b] This is mighty fine work! I'd love to keep you on as the night crew! You up for it? ... Wait... where are you...\n\n You hear his words trail off as you get as far from that store as possible!",
		"scene": "res://scenes/Scenettes/victory_a/victory_a.tscn"
	},
	
	"FrontDoor": { # Ran out the front door.
		"title": "Out the Front Door",
		"text": "You found the job a little... [i]intense[/i]. Whether that be from the work or, well, other things is a matter for debate.\n\nNeedless to say, you will not be getting paid, but, at least the rest of your evening was far more relaxing!",
		"scene": "res://scenes/Scenettes/out_the_front_door/out_the_front_door.tscn"
	},
	
	"BackDoor": { # Ran out the back door.
		"title": "Back Door Bailout",
		"text": "With one foot in front of the other you managed to make your way to the back of this creepy corner store... and right out the back door! You trip on some rather slimey looking trash piled all about the back of the building, but you're free! You're broke, but you're [b]free[/b]!",
		"scene": "res://scenes/Scenettes/back_door_bailout/back_door_bailout.tscn"
	},
	
	"Musical": { # Musical attack took player down
		"title": "Musical Spirit",
		"text": "Whether it was a [i]musical[/i] spirit that took you down, or something else, your were found unconsious on the floor. Your head ringed by the blood that flowed from your ears.",
		"scene": "res://scenes/Scenettes/generic_down/generic_down.tscn"
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
	if not ENDINGS[payload["ending"]].scene.is_empty():
		_scenette.plate_scene(ENDINGS[payload["ending"]].scene)
	_title.text = ENDINGS[payload["ending"]].title
	_body.text = ENDINGS[payload["ending"]].text

func _on_btn_close_pressed() -> void:
	request(&"close_all")
	request(&"show_ui", {"ui_name":&"MainMenu"})
