extends TextureButton

var can_pause = true

func _ready():
	pass

func _pressed():
	if(!can_pause):
		return
	
	if(!get_tree().is_paused()):
		get_tree().set_pause(true) ## Acessar a estrutura de árvore do jogo
		set_texture_normal(load('res://assets/ui/play.png'))
	elif(get_tree().is_paused()):
		get_tree().set_pause(false)
		set_texture_normal(load('res://assets/ui/pause.png'))
