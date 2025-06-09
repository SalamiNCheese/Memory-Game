extends Button


func _ready():
	update_icon()

func _pressed():
	GameManager.reveal_button = !GameManager.reveal_button
	update_icon()

func update_icon():
	if(GameManager.reveal_button):
		icon = load("res://assets/ui/ButtonActive.png")
	else:
		icon = load("res://assets/ui/ButtonNotActive.png")
