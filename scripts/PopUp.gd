extends Control

var playButton
var press

## Adicionar PopUp à cena
func _ready():
	playButton = get_node('CenterContainer/Panel/VBoxContainer/Button')
	playButton.connect("pressed", Callable(self, "newGame"))
	get_tree().set_pause(true) ## Pausar o jogo

## Iniciar um Novo Jogo
func newGame():
	get_tree().set_pause(false)
	if(GameManager.score == GameManager.goal):
		GameManager.resetGame(false) ## Para quando o jogo for vencido
		await get_tree().create_timer(1.5).timeout
		GameManager.revealCards()
	queue_free() ## Deletar/Liberar (da memória) a cena PopUp

## Trocar imagem de vitória
func setupWinScreen():
	## Acessar o nó
	$CenterContainer/Panel/VBoxContainer/TextureRect.set_texture(load('res://assets/ui/complete-memory.png'))
	$CenterContainer/Panel/VBoxContainer/Label.text = "Você encontrou %d pares em %d segundos \n e virou %d pares de cartas!" % [GameManager.goal, GameManager.timerSec, GameManager.moves]
	$CenterContainer/Panel/VBoxContainer/Button.text = "Jogue Novamente!"
