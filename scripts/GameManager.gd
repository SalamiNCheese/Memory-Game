extends Node

## Arquivo Global

## Onde a Game Scene está
@onready var Game = get_node('/root/Game/') ## Dá ao GameManager um ponteiro, permite ela acessar a Cena do jogo

## ------------------DECLARAÇÃO DE VARIÁVEIS---------------------

## Carregar arquivo previamente
var cardBack = preload('res://assets/cards/card-back.png') ## PS: Eventualmente deixar o jogador escolher o verso
var popUp = preload('res://scripts/PopUp.tscn')

var deck =  Array()
var card1
var card2

var matchTimer = Timer.new()
var flipTimer = Timer.new()
var secondsTimer = Timer.new()

var score = 0
var timerSec = 0
var moves = 0

var hudCount = Array() ## 1º= Score, 2º = Timer, 3º = Moves
##-------------------------------------------
var goal = 3 ## Para teste, mudar número depois <---------------------------------------------------------
##-------------------------------------------
var scoreLabel
var timerSecLabel
var movesLabel

var resetButton
var exitButton

## Medir tempo de reação
var timeStart = 0
var elapsedTime = 0
var reaction = Array()

## --------------------MAIN---------------------
func _ready():
	fillDeck()
	randomize()
	deck.shuffle()
	dealDeck()
	setupTimers()
	setupHUD()
	var firstScreen = popUp.instantiate()
	Game.add_child(firstScreen)
	

## -----------------MÉTODOS------------------

## Ponteiros para manipulação dos valores em cena
func setupHUD():
	## Atribuição das referências
	scoreLabel = Game.get_node('HUD/Panel/Sections/SectionScore/ScoreDisplay')
	timerSecLabel = Game.get_node('HUD/Panel/Sections/SectionTimer/TimerDisplay')
	movesLabel = Game.get_node('HUD/Panel/Sections/SectionMoves/MovesDisplay')
	resetButton = Game.get_node('HUD/Panel/Sections/SectionButtons/ButtonReset')
	exitButton = Game.get_node('HUD/Panel2/SectionExit/ButtonExit')
	
	resetButton.connect("pressed", Callable(self, "resetGame"))
	exitButton.connect("pressed", Callable(self, "exitGame"))
	
	## Atribuição dos valores
	scoreLabel.text = str(score)
	timerSecLabel.text = str(timerSec)
	movesLabel.text = str(moves)



## Criar Temporizadores
func setupTimers():
	## Quando sinal for disparado, chamará outra função 
	flipTimer.connect("timeout", Callable(self, "turnOverCards"))
	flipTimer.set_one_shot(true) ## Rodar o Temporizador 1x
	add_child(flipTimer) ## Adicionar à cena
	
	matchTimer.connect("timeout", Callable(self, "matchCardsAndScore"))
	matchTimer.set_one_shot(true) 
	add_child(matchTimer) 
	
	secondsTimer.connect("timeout", Callable(self, "countSeconds"))
	add_child(secondsTimer)
	secondsTimer.start() ## Iniciar o temporizador
	

## Preencher o Deck
func fillDeck():
	var s = 0
	var v = 0
	while(s < 2):
		v = 0
		while(v < 10):
			deck.append(Card.new(v))
			v += 1
		s += 1

## Distribuir as Cartas
func dealDeck():
	var c = 0
	while (c < deck.size()):
		## Adicionando Vetor ao grid (malha)
		Game.get_node('grid').add_child(deck[c])
		c += 1

## Ponteiro para carta
func chooseCard(c):
	if(card1 == null):
		card1 = c
		card1.flip()
		card1.set_disabled(true) ## Impedir que o jogador clique na carta 2x
		timeStart = Time.get_ticks_msec()
	
	elif(card2 == null):
		card2 = c
		card2.flip()
		card2.set_disabled(true) ## Impedir que o jogador clique na carta 2x
		moves += 1 ## Pares Virados
		movesLabel.text = str(moves)
		resetButton.set_disabled(true) ## Impedir que o jogador resete enquanto está comparando
		checkCards()
		
		## Tempo que o jogador levou para clicar nas cartas
		elapsedTime = Time.get_ticks_msec() - timeStart
		reaction.append(elapsedTime)
		
		print(reaction)

func checkCards():
	if(card1.value == card2.value):
		matchTimer.start(0.15)

	else:
		flipTimer.start(1)


## Virar a carta para baixo novamente (Jogador errou o par)
func turnOverCards():
	card1.flip()
	card2.flip()
	card1.set_disabled(false) ## Permitir que o jogador clique na carta novamente
	card2.set_disabled(false)
	card1 = null
	card2 = null
	resetButton.set_disabled(false) ## Permitir que o jogador clique no botão de Reset

## Aplicar filtro e contar pontuação (Jogador acertou o par)
func matchCardsAndScore():
	score += 1
	scoreLabel.text = str(score)
	card1.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	card2.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	card1 = null
	card2 = null
	
	## Quando vencer o jogo
	if(score == goal):
		var winScreen = popUp.instantiate()
		Game.add_child(winScreen)
		winScreen.setupWinScreen()
		saveData(str(reaction))
		hudCount.append(score)
		hudCount.append(timerSec)
		hudCount.append(moves)
		saveData2(str(hudCount)) ## 1º= Score, 2º = Timer, 3º = Moves
		print(hudCount) 

## Contar o Tempo
func countSeconds():
	timerSec += 1
	timerSecLabel.text = str(timerSec)

## Resetar o Jogo
func resetGame():
	for c in range(deck.size()):
		deck[c].queue_free() ## Deletar as cartas
	deck.clear() ## Verificar que deletou os ponteiros
	score = 0
	timerSec = 0
	moves = 0
	scoreLabel.text = str(score)
	timerSecLabel.text = str(timerSec)
	movesLabel.text = str(moves)
	fillDeck()
	randomize()
	deck.shuffle()
	dealDeck()

func exitGame():
	
	get_tree().quit()


func loadData():
	## CAMINHO:
	## C:\Users\user_name\AppData\Roaming\Godot\app_userdata\Memory Game\Dados.txt
	
	var file = FileAccess.open("user://Dados.txt", FileAccess.READ)
	var content = file.get_as_text()
	return content

func loadData2():
	var file = FileAccess.open("user://Dados2.txt", FileAccess.READ)
	var content2 = file.get_as_text()
	return content2

func saveData(content):
	var file = FileAccess.open("user://Dados.txt", FileAccess.WRITE)
	file.store_string(str(content))
	
func saveData2(content2):
	var file = FileAccess.open("user://Dados2.txt", FileAccess.WRITE)
	file.store_string(str(content2))
