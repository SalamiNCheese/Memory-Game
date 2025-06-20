extends Node

## Arquivo Global

## Onde a Game Scene está
## Dá ao GameManager um ponteiro, permite ela acessar a Cena do jogo
@onready var Game = get_node('/root/Game/')
@onready var scoreLabel = Game.get_node("HUD/Panel/Sections/SectionScore/ScoreLabel")
@onready var timerSecLabel = Game.get_node("HUD/Panel/Sections/SectionTimer/TimerLabel")
@onready var movesLabel = Game.get_node("HUD/Panel/Sections/SectionMoves/MovesLabel")

## ------------------DECLARAÇÃO DE VARIÁVEIS---------------------

## Carregar arquivo previamente
var cardBack = preload('res://assets/cards/card-back.png') 
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

var goal = 10

var resetButton
var exitButton
var pauseButton

## Medir tempo de reação
var timeStart = 0
var elapsedTime = 0
var reaction = Array()


## Se igual a 0, espelhado. Se igual 1, seguidas
var perfect = 0
var reveal_button = false
var parMovesStatus = Dictionary()
var is_busy = false

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
	pauseButton = Game.get_node("HUD/Panel/Sections/SectionButtons/ButtonPause")
	
	## Chamada de função ao apertar um botão específico
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

## Preencher o Deck / Criar cartas
func fillDeck():
	if(perfect == 0): ## Ordem de criação, espelhadas
		var i = 0
		var v = 0
		while(i < 2):
			v = 0
			while(v < 10):
				deck.append(Card.new(v))
				v += 1
			i += 1

	elif(perfect == 1): ## Ordem de criação, seguidas
		var i = 0
		var v = 0
		var v2 = 0
		while(i < 2):
			v2 = 0
			while(v2 < 5):
				deck.append(Card.new(v))
				deck.append(Card.new(v))
				v += 1
				v2 += 1
			v = 5
			i += 1

## Distribuir as Cartas / Colocar no tabuleiro
func dealDeck():
	var c = 0
	while(c < deck.size()):
		## Adicionando Vetor ao grid (malha)
		Game.get_node('grid').add_child(deck[c])
		c += 1

## Revelar cartas (opcional)
func revealCards():
	if(reveal_button == false):
		return
	
	else:
		## Impedir jogador de clicar quando não deve
		is_busy = true
		pauseButton.can_pause = false
		resetButton.set_disabled(true)
		exitButton.set_disabled(true)
		pauseButton.set_disabled(true)
		
		for c in deck:
			c.flip()
		
		await get_tree().create_timer(3.0).timeout
		
		for c in deck:
			c.flip()
		
		## Habilitar jogador pra clicar novamente
		resetButton.set_disabled(false)
		exitButton.set_disabled(false)
		pauseButton.can_pause = true
		pauseButton.set_disabled(false)
		is_busy = false


## Ponteiro para carta
func chooseCard(c):
	##Impedir de escolher quando está ocupado
	if(is_busy == true):
		return
	
	## Impedir de escolher quando é nulo
	if(c == null || !is_instance_valid(c)):
		return
	
	## Escolher a Primeira Carta
	if(card1 == null):
		card1 = c
		card1.flip()
		card1.set_disabled(true) ## Impedir que o jogador clique na carta 2x
		timeStart = Time.get_ticks_msec()
	
	## Escolher a Segunda Carta
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

## Checar se as cartas são iguais
func checkCards():
	if(card1.value == card2.value):
		matchTimer.start(0.15)

	else:
		flipTimer.start(1)


## Virar a carta para baixo novamente (Jogador errou o par)
func turnOverCards():
	parMovesStatus[moves] = 0
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
	parMovesStatus[moves] = 1
	scoreLabel.text = str(score)
	if(is_instance_valid(card1)):
		card1.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	if(is_instance_valid(card2)):
		card2.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	card1 = null
	card2 = null
	resetButton.set_disabled(false) ## Permitir que o jogador clique no botão de Reset
	
	## Quando vencer o jogo
	if(score == goal):
		var winScreen = popUp.instantiate()
		Game.add_child(winScreen)
		winScreen.setupWinScreen()
		saveData(str(reaction))
		print(reaction)
		reaction.clear()
		hudCount.append(score)
		hudCount.append(timerSec)
		hudCount.append(moves)
		saveData2(str(hudCount)) ## 1º= Score, 2º = Timer, 3º = Moves
		print(hudCount)
		hudCount.clear()
		saveData3(str(parMovesStatus))
		print(parMovesStatus)
		parMovesStatus.clear()
		resetGame()

## Contar o Tempo
func countSeconds():
	timerSec += 1
	timerSecLabel.text = str(timerSec)

## Resetar o Jogo
func resetGame(show_reveal = true):
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
	randomize() ## Para fazer o aleatório
	deck.shuffle() ## Para fazer o aleatório
	dealDeck()
	
	if(show_reveal == true):
		revealCards()

## Sair do jogo
func exitGame():
	## Salvar caso o jogador feche o jogo
	saveData(str(reaction))
	print(reaction)
	reaction.clear()
	hudCount.append(score)
	hudCount.append(timerSec)
	hudCount.append(moves)
	saveData2(str(hudCount)) ## 1º= Score, 2º = Timer, 3º = Moves
	print(hudCount)
	hudCount.clear()
	saveData3(str(parMovesStatus))
	print(parMovesStatus)
	parMovesStatus.clear()
	OS.shell_open(ProjectSettings.globalize_path("user://")) ## Abrir pasta para dados
	get_tree().quit()


## Salvar Dados
func saveData(content):
	var file
	
	if(reveal_button == false):
		if(FileAccess.file_exists("user://Dados.txt")): ## Verifica se o arquivo existe
			file = FileAccess.open("user://Dados.txt", FileAccess.READ_WRITE)
			file.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file =  FileAccess.open("user://Dados.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file):
			file.store_line(str(content)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados.txt")
	
	else:
		if(FileAccess.file_exists("user://Dados_Reveal_Mode.txt")): ## Verifica se o arquivo existe
			file = FileAccess.open("user://Dados_Reveal_Mode.txt", FileAccess.READ_WRITE)
			file.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file =  FileAccess.open("user://Dados_Reveal_Mode.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file):
			file.store_line(str(content)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados_Reveal_Mode.txt")


func saveData2(content2):
	var file2
	
	if(reveal_button == false):
		if(FileAccess.file_exists("user://Dados2.txt")): ## Verifica se o arquivo existe
			file2 = FileAccess.open("user://Dados2.txt", FileAccess.READ_WRITE)
			file2.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file2 =  FileAccess.open("user://Dados2.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file2):
			file2.store_line(str(content2)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados2.txt")
	
	else:
		if(FileAccess.file_exists("user://Dados2_Reveal_Mode.txt")): ## Verifica se o arquivo existe
			file2 = FileAccess.open("user://Dados2_Reveal_Mode.txt", FileAccess.READ_WRITE)
			file2.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file2 =  FileAccess.open("user://Dados2_Reveal_Mode.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file2):
			file2.store_line(str(content2)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados2_Reveal_Mode.txt")
	
func saveData3(content3):
	var file3
	
	if(reveal_button == false):
		if(FileAccess.file_exists("user://Dados3.txt")): ## Verifica se o arquivo existe
			file3 = FileAccess.open("user://Dados3.txt", FileAccess.READ_WRITE)
			file3.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file3 =  FileAccess.open("user://Dados3.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file3):
			file3.store_line(str(content3)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados3.txt")
		
	else:
		if(FileAccess.file_exists("user://Dados3_Reveal_Mode.txt")): ## Verifica se o arquivo existe
			file3 = FileAccess.open("user://Dados3_Reveal_Mode.txt", FileAccess.READ_WRITE)
			file3.seek_end() ## Move o cursor para o final do arquivo
		else: ## Se o arquivo não existir
			file3 =  FileAccess.open("user://Dados3_Reveal_Mode.txt", FileAccess.WRITE) ## Cria um novo arquivo
		
		if(file3):
			file3.store_line(str(content3)) ## Armazenar string com quebra de linha
		else:
			push_error("Erro ao abrir ou criar arquivo Dados3_Reveal_Mode.txt")
