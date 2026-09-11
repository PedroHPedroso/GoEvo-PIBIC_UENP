extends CanvasLayer

signal continuar

const PHASE_DATA := {
	1: {
		"topic": "SELEÇÃO SEXUAL",
		"title": "Uma escolha que atravessa gerações",
		"context": "Na seleção sexual, certos comportamentos ou características aumentam a chance de conquistar um parceiro e deixar descendentes.",
		"objective": "Capture as 10 moscas, volte até a sapinha e converse com ela para demonstrar que o sapo é um bom parceiro.",
		"controls": [
			["A / D  ou  ← / →", "Andar"],
			["ESPAÇO", "Pular"],
			["CLIQUE ESQUERDO", "Capturar moscas"],
			["E", "Conversar e avançar falas"],
		],
		"conclusion": "Ao reunir alimento e ser escolhido pela sapinha, você representou a escolha de parceiros. Comportamentos e características que elevam o sucesso reprodutivo podem se tornar mais frequentes nas gerações seguintes.",
		"insight": "A evolução também depende de quem consegue se reproduzir e transmitir seus genes.",
	},
	2: {
		"topic": "MELANISMO INDUSTRIAL",
		"title": "Camuflagem em um ambiente que muda",
		"context": "Em Manchester, a fuligem da Revolução Industrial escureceu os troncos e alterou quais mariposas Biston betularia ficavam mais protegidas dos predadores.",
		"objective": "Atravesse os 4 ambientes: escolha a cor mais camuflada e permaneça no tronco da mesma cor por 2,5 segundos.",
		"controls": [
			["WASD  ou  SETAS", "Voar em quatro direções"],
			["E  ou  ESPAÇO", "Segurar para grudar no tronco"],
			["MOUSE", "Escolher mariposa clara ou escura"],
		],
		"conclusion": "Nos troncos claros, mariposas claras ficaram menos visíveis; com a fuligem, a vantagem passou às escuras. A população mudou ao longo das gerações porque variantes já existentes tiveram chances diferentes de sobreviver e se reproduzir.",
		"insight": "Quando o ambiente muda, muda também quais variações são favorecidas pela seleção natural.",
	},
	3: {
		"topic": "MIMETISMO BATESIANO",
		"title": "O blefe da falsa-coral",
		"context": "Uma espécie inofensiva pode reduzir ataques ao imitar o sinal de alerta de uma espécie perigosa. Aqui, a falsa-coral copia as cores da coral verdadeira.",
		"objective": "Monte Vermelho • Amarelo • Preto • Amarelo • Vermelho, atravesse os predadores e use os troncos estreitos para escapar do texugo-do-mel.",
		"controls": [
			["WASD  ou  SETAS", "Rastejar em quatro direções"],
			["BOTÃO  <", "Desfazer o último pigmento"],
		],
		"conclusion": "A falsa-coral sobreviveu porque seu padrão se parece com o aviso da coral venenosa. Falcões e gambás evitaram o sinal, mas o texugo-do-mel mostrou o limite do blefe: o mimetismo só protege quando o predador reconhece e teme o modelo.",
		"insight": "No mimetismo batesiano, uma espécie inofensiva obtém proteção ao imitar uma espécie perigosa.",
	},
	4: {
		"topic": "IRRADIAÇÃO ADAPTATIVA E ESPECIALIZAÇÃO",
		"title": "Bicos moldados por diferentes nichos",
		"context": "Ao colonizar ilhas com alimentos distintos, uma população ancestral encontra pressões seletivas diferentes. Cada recurso favorece uma forma de bico.",
		"objective": "Em cada uma das 3 ilhas, escolha o bico adequado e alcance 90 de energia ou consuma todos os alimentos disponíveis.",
		"controls": [
			["A / D  ou  ← / →", "Andar"],
			["ESPAÇO", "Pular; no ar, saltar de novo ou planar"],
			["E", "Bicar o alimento próximo"],
			["MOUSE", "Escolher o formato do bico"],
		],
		"conclusion": "Uma espécie ancestral colonizou o arquipélago. Sementes, flores e larvas favoreceram bicos diferentes; ao longo das gerações, as populações ocuparam nichos próprios, especializaram-se e deram origem a linhagens distintas.",
		"insight": "A irradiação adaptativa transforma uma linhagem ancestral em várias linhagens adaptadas a nichos diferentes.",
	},
}

@onready var surface: Control = $Surface
@onready var eyebrow: Label = $Surface/Panel/VBox/Eyebrow
@onready var title: Label = $Surface/Panel/VBox/Title
@onready var context: Label = $Surface/Panel/VBox/Context
@onready var objective_panel: PanelContainer = $Surface/Panel/VBox/ObjectivePanel
@onready var objective_text: Label = $Surface/Panel/VBox/ObjectivePanel/HBox/Text
@onready var commands_title: Label = $Surface/Panel/VBox/CommandsTitle
@onready var commands_grid: GridContainer = $Surface/Panel/VBox/CommandsGrid
@onready var insight_panel: PanelContainer = $Surface/Panel/VBox/InsightPanel
@onready var insight_text: Label = $Surface/Panel/VBox/InsightPanel/VBox/Text
@onready var action_button: Button = $Surface/Panel/VBox/ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action_button_pressed)


func mostrar_como_jogar(fase: int) -> void:
	var data: Dictionary = _dados_da_fase(fase)
	eyebrow.text = "FASE %d  •  COMO JOGAR  •  %s" % [fase, data["topic"]]
	title.text = data["title"]
	context.text = data["context"]
	objective_text.text = data["objective"]
	objective_panel.visible = true
	commands_title.visible = true
	commands_grid.visible = true
	insight_panel.visible = false
	_popular_controles(data["controls"])
	action_button.text = "Começar fase"
	_abrir()


func mostrar_conclusao(fase: int, texto_botao: String) -> void:
	var data: Dictionary = _dados_da_fase(fase)
	eyebrow.text = "FASE %d CONCLUÍDA  •  CONCEITO EVOLUTIVO" % fase
	title.text = data["topic"]
	context.text = data["conclusion"]
	objective_panel.visible = false
	commands_title.visible = false
	commands_grid.visible = false
	insight_text.text = data["insight"]
	insight_panel.visible = true
	action_button.text = texto_botao
	_abrir()


func _dados_da_fase(fase: int) -> Dictionary:
	assert(PHASE_DATA.has(fase), "Fase sem conteúdo educativo: %d" % fase)
	return PHASE_DATA[fase]


func _abrir() -> void:
	surface.visible = true
	action_button.disabled = false
	action_button.grab_focus.call_deferred()


func _popular_controles(controles: Array) -> void:
	for child in commands_grid.get_children():
		child.queue_free()
	for controle in controles:
		commands_grid.add_child(_criar_cartao_de_controle(str(controle[0]), str(controle[1])))


func _criar_cartao_de_controle(teclas: String, acao: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 29)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _estilo_do_cartao())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var key_label := Label.new()
	key_label.custom_minimum_size = Vector2(112, 0)
	key_label.add_theme_font_override("font", preload("res://Fonts/determination.ttf"))
	key_label.add_theme_font_size_override("font_size", 9)
	key_label.add_theme_color_override("font_color", Color("f0c968"))
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.text = teclas
	row.add_child(key_label)

	var action_label := Label.new()
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_label.add_theme_font_override("font", preload("res://Fonts/determination.ttf"))
	action_label.add_theme_font_size_override("font_size", 9)
	action_label.add_theme_color_override("font_color", Color("d5dccd"))
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_label.text = acao
	row.add_child(action_label)
	return card


func _estilo_do_cartao() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	style.bg_color = Color("15241c")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color("435848")
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 3
	style.corner_radius_bottom_left = 3
	return style


func _on_action_button_pressed() -> void:
	action_button.disabled = true
	surface.visible = false
	continuar.emit()
