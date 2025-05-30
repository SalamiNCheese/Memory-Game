extends TextureButton

class_name Card

var value ## Número da carta / ID
var face ## Verso de cima da carta
var back ## Verso de baixo da carta

func _ready():
	set_h_size_flags(3) ## Ajustar tamanho da carta horizontalmente
	set_v_size_flags(3) ## Ajustar tamanho da carta verticalmente
	#set_ignore_texture_size(true) ## Ajustar distorção da carta
	set_stretch_mode(TextureButton.STRETCH_KEEP_ASPECT_CENTERED) ## Ajustar aspecto da carta

## Construtor com Naipe e Numero da carta
func _init(v):
	value = v
	face = load("res://assets/cards/card-"+str(value)+".png")
	back = GameManager.cardBack
	set_texture_normal(back)

func _pressed():
	GameManager.chooseCard(self) ## GameManager fará as alterações, ponteiro para carta

## Adicionar delay nas cartas ao virar
func flip():
	## Se for virado pra baixo
	if(get_texture_normal() == back):
		set_texture_normal(face)
	else:
		set_texture_normal(back)
