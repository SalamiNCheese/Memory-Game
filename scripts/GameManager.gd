extends Node

## Arquivo Global

## Onde a Game Scene está
@onready var Game = get_node('/root/Game/') ## Dá ao GameManager um ponteiro, permite ela acessar a Cena do jogo
@onready var scoreLabel = Game.get_node("HUD/Panel/Sections/SectionScore/ScoreLabel")
@onready var timerSecLabel = Game.get_node("HUD/Panel/Sections/SectionTimer/TimerLabel")
@onready var movesLabel = Game.get_node("HUD/Panel/Sections/SectionMoves/MovesLabel")
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
var goal = 10 ## Para teste, mudar número depois <---------------------------------------------------------
##-------------------------------------------

var resetButton
var exitButton

## Medir tempo de reação
var timeStart = 0
var elapsedTime = 0
var reaction = Array()

## Se igual a 0, espelhado. Se igual 1, seguidas
var perfect = 0
var times = 5
var is_busy = false

## --------------------MAIN---------------------
func _ready():
	fillDeck()
	randomize()
	deck.shuffle()
	dealDeck()
	setupTimers()
	setupHUD()
	## Normal Play
	var firstScreen = popUp.instantiate()
	Game.add_child(firstScreen)
	## AutoPlay
	#await get_tree().process_frame ## Esperar renderização
	#await get_tree().create_timer(0.5).timeout ## Esperar meio segundo
	#autoLoop(times)

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

## Preencher o Deck / Criar cartas
func fillDeck():
	if(perfect == 0): ## Ordem de criação, espelhadas
		var s = 0
		var v = 0
		while(s < 2):
			v = 0
			while(v < 10):
				deck.append(Card.new(v))	## s,v = i,j
				v += 1
			s += 1

	elif(perfect == 1): ## Ordem de criação, seguidas
		var s = 0
		var v = 0
		var v2 = 0
		while(s < 2):
			v2 = 0
			while(v2 < 5):
				deck.append(Card.new(v))	## s,v = i,j
				deck.append(Card.new(v))
				v += 1
				v2 += 1
			v = 5
			s += 1

## Distribuir as Cartas / Colocar no tabuleiro
func dealDeck():
	var c = 0
	while(c < deck.size()):
		## Adicionando Vetor ao grid (malha)
		Game.get_node('grid').add_child(deck[c])
		c += 1

## Funcionar o jogo várias vezes seguidas
func autoLoop(times):
	var rounds = 0
	
	## Número de rodadas
	while(rounds < times):
		print(">>> Rodada ", rounds + 1)
		if(score == goal):
			## Resetar a rodada manualmente (como no resetGame)
			for c in range(deck.size()):
				deck[c].queue_free()
			deck.clear()
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
		
		await get_tree().process_frame ## Espera um frame antes de começar
		await autoChoose() ## Executa jogada automática
		rounds += 1
		
		await get_tree().create_timer(1.0).timeout ## Espera um tempo antes de reiniciar


## Escolher as cartas automaticamente
func autoChoose():
	var memory = Dictionary() ## Dicionário: valor -> índice
	var used = Array()  ## Índices já combinados
	var i = 0

	while(i < deck.size()): ## Percorrer as cartas do baralho
		if(i in used): ## Se a carta já fez par, pula para a próxima
			i += 1
			continue
		
		chooseCard(deck[i])
		await get_tree().create_timer(0.2).timeout
		
		var value = deck[i].value ## Valor da carta
		
		if(memory.has(value) && memory[value] not in used): ## Verifica se já existe esse valor no dicionário
			var j = memory[value]  ## Atualizar se existir valor no dicionário
			chooseCard(deck[j])
			await get_tree().create_timer(1.0).timeout
			if(j in used): ## Se a carta já fez par, pula para a próxima
				i += 1
				continue
	
			## Se der Match, marcar como usado
			used.append(i)
			used.append(j)
			memory.erase(value)
		
		else:
			## Salvar carta na memória
			memory[value] = i
		
		i += 1
		await get_tree().create_timer(0.3).timeout


## Ponteiro para carta
func chooseCard(c):
	## Impedir de escolher (quando não se deve) quando estiver no autoChoose
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
		is_busy = true ## Está ocupado
		checkCards()
		
		## Tempo que o jogador levou para clicar nas cartas
		elapsedTime = Time.get_ticks_msec() - timeStart
		reaction.append(elapsedTime)
		
		print(reaction)

## Checar se as cartas são iguais
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
	is_busy = false ## Não está mais ocupado (autoChoose pode voltar a escolher cartas)

## Aplicar filtro e contar pontuação (Jogador acertou o par)
func matchCardsAndScore():
	score += 1
	scoreLabel.text = str(score)
	if(is_instance_valid(card1)):
		card1.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	if(is_instance_valid(card2)):
		card2.set_modulate(Color(0.6, 0.6, 0.6, 0.5))
	card1 = null
	card2 = null
	resetButton.set_disabled(false) ## Permitir que o jogador clique no botão de Reset
	is_busy = false ## Não está mais ocupado (autoChoose pode voltar a escolher cartas)
	
	## Quando vencer o jogo
	if(score == goal):
		## Jogo normal (Sem comentar) VS Jogo Teste Bot (Comentado)
		var winScreen = popUp.instantiate()
		Game.add_child(winScreen)
		winScreen.setupWinScreen()
		saveData(str(reaction))
		reaction.clear()
		hudCount.append(score)
		hudCount.append(timerSec)
		hudCount.append(moves)
		saveData2(str(hudCount)) ## 1º= Score, 2º = Timer, 3º = Moves
		print(hudCount)
		hudCount.clear()
		OS.shell_open(ProjectSettings.globalize_path("user://"))
		resetGame()

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
	randomize() ## Para fazer o aleatório
	deck.shuffle() ## Para fazer o aleatório
	dealDeck()

## Sair do jogo
func exitGame():
	## Salvar caso o jogador feche o jogo
	saveData(str(reaction))
	reaction.clear()
	hudCount.append(score)
	hudCount.append(timerSec)
	hudCount.append(moves)
	saveData2(str(hudCount)) ## 1º= Score, 2º = Timer, 3º = Moves
	print(hudCount)
	hudCount.clear()
	OS.shell_open(ProjectSettings.globalize_path("user://"))
	get_tree().quit()

## Carregar Dados
func loadData():
	var file = FileAccess.open("user://Dados.txt", FileAccess.READ)
	var content = file.get_as_text()
	return content

func loadData2():
	var file2 = FileAccess.open("user://Dados2.txt", FileAccess.READ)
	var content2 = file2.get_as_text()
	return content2

## Salvar Dados
func saveData(content):
	var file
	
	if(FileAccess.file_exists("user://Dados.txt")): ## Verifica se o arquivo existe
		file = FileAccess.open("user://Dados.txt", FileAccess.READ_WRITE)
		file.seek_end() ## Move o cursor para o final do arquivo
	else: ## Se o arquivo não existir
		file =  FileAccess.open("user://Dados.txt", FileAccess.WRITE) ## Cria um novo arquivo
	
	if(file):
		file.store_line(str(content)) ## Armazenar string com quebra de linha
	else:
		push_error("Erro ao abrir ou criar arquivo Dados.txt")


func saveData2(content2):
	var file2
	
	if(FileAccess.file_exists("user://Dados2.txt")): ## Verifica se o arquivo existe
		file2 = FileAccess.open("user://Dados2.txt", FileAccess.READ_WRITE)
		file2.seek_end() ## Move o cursor para o final do arquivo
	else: ## Se o arquivo não existir
		file2 =  FileAccess.open("user://Dados2.txt", FileAccess.WRITE) ## Cria um novo arquivo
	
	if(file2):
		file2.store_line(str(content2)) ## Armazenar string com quebra de linha
	else:
		push_error("Erro ao abrir ou criar arquivo Dados2.txt")


#func get_desktop_path():
	#var os_name = OS.get_name()
	#var desktop_path = ""
	#
	#if(os_name == "Windows"):
		#desktop_path = OS.get_environment("USERPROFILE") + "/Desktop"
		#
	#elif(os_name == "Linux"):
		#desktop_path = "/home/%s/Desktop" % OS.get_environment("USER")
		#if(not DirAccess.dir_exists_absolute(desktop_path)):
			#desktop_path = "/home/%s/Área de Trabalho" % OS.get_environment("USER")
	#
	#elif(os_name == "macOS"):
		#desktop_path = "/Users/%s/Desktop" % OS.get_environment("USER")
	#
	#else:
		#print("Sistem Operacional não suportado para Area de Trabalho")
		#desktop_path = "user://"
	#
	#return desktop_path
