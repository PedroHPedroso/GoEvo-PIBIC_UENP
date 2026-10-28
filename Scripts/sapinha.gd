extends Area2D

signal fase_concluida

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_interacao: PanelContainer = $PromptInteracao
@onready var tecla_interacao: TextureRect = $PromptInteracao/HBox/TeclaE
@onready var caixa_de_dialogo: PanelContainer = $CanvasLayer/CaixaDeDialogo
@onready var texto_dialogo: Label = $CanvasLayer/CaixaDeDialogo/Margin/HBox/TextBlock/TextoDialogo
@onready var advance_hint: Label = $CanvasLayer/CaixaDeDialogo/Margin/HBox/TextBlock/Header/AdvanceHint

var player_in_area = false
var player_atual = null

var falando = false
var pode_avancar = false
var versao_dialogo: int = 0

var fala_index = 0
var falas: Array[String] = []
var animacoes_falas: Array[StringName] = []

var deve_concluir_fase: bool = false
var fase_ja_concluida: bool = false
var animacao_tecla: Tween

func _ready() -> void:
	# Os sprites originais olham para a direita.
	anim.flip_h = true
	anim.play("Idle")
	caixa_de_dialogo.visible = false
	advance_hint.visible = false
	prompt_interacao.visible = false
	
func _process(_delta) -> void:
	if player_in_area and not falando and Input.is_action_just_pressed("interacao"):
		iniciar_dialogo()
	elif falando and pode_avancar and Input.is_action_just_pressed("interacao"):
		proxima_fala()
		
func _on_body_entered(body: Node2D) -> void:
	if body.name ==  "Player":
		player_in_area = true
		player_atual = body
		mostrar_prompt_interacao()

func _on_body_exited(body) -> void:
	if body.name == "Player":
		player_in_area = false
		player_atual = null
		ocultar_prompt_interacao()
		if falando:
			encerrar_dialogo()
			
func iniciar_dialogo():
	if player_atual == null:
		return
		
	selecionar_dialogo()
	
	falando = true
	versao_dialogo += 1
	ocultar_prompt_interacao()
	caixa_de_dialogo.visible = true
	fala_index = 0
	proxima_fala()

func mostrar_prompt_interacao() -> void:
	prompt_interacao.visible = true
	iniciar_animacao_tecla()

func ocultar_prompt_interacao() -> void:
	prompt_interacao.visible = false
	parar_animacao_tecla()

func iniciar_animacao_tecla() -> void:
	parar_animacao_tecla()

	animacao_tecla = create_tween().set_loops()
	animacao_tecla.tween_interval(0.45)
	animacao_tecla.tween_property(tecla_interacao, "scale", Vector2(1.0, 0.72), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	animacao_tecla.parallel().tween_property(tecla_interacao, "modulate", Color(0.76, 0.76, 0.76, 1.0), 0.1)
	animacao_tecla.tween_property(tecla_interacao, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animacao_tecla.parallel().tween_property(tecla_interacao, "modulate", Color.WHITE, 0.14)
	animacao_tecla.tween_interval(0.55)

func parar_animacao_tecla() -> void:
	if animacao_tecla != null:
		animacao_tecla.kill()
		animacao_tecla = null

	tecla_interacao.scale = Vector2.ONE
	tecla_interacao.modulate = Color.WHITE
	
func selecionar_dialogo() -> void:
	var quantidade_moscas: int = player_atual.moscas
	
	deve_concluir_fase = false
	
	# EXATAMENTE 10 MOSCAS
	if quantidade_moscas == 10:
		deve_concluir_fase = true
		falas = [
			"Estou impressionada com sua dedicação!",
			"Tenho certeza que será o parceiro certo para cuidar dos nossos filhotes e perpetuar nossa espécie!",
			"Gostaria de compartilhar a vida comigo ?"
		]
		animacoes_falas = [&"Idle", &"concluido", &"concluido"]
	# MENOS DE 10 MOSCAS
	elif(quantidade_moscas < 10):
		var faltam: int = 10 - quantidade_moscas
		falas = [
			"Você ainda não está apto para ser pai dos meus filhotes.",
			"Ainda faltam %d moscas!" % faltam
		]
		animacoes_falas = [&"brava", &"brava"]
		
func proxima_fala():
	if fala_index < falas.size():
		pode_avancar = false
		advance_hint.visible = false
		texto_dialogo.text = ""
		var texto = falas[fala_index]
		atualizar_animacao_da_fala(fala_index)
		fala_index += 1
		mostrar_texto_com_efeito(texto, versao_dialogo)
	else:
		encerrar_dialogo(true)

func atualizar_animacao_da_fala(indice: int) -> void:
	if indice >= animacoes_falas.size():
		return

	# Reinicia a animação a cada interação, inclusive quando duas falas
	# consecutivas usam a mesma reação da sapinha.
	anim.stop()
	anim.frame = 0
	anim.frame_progress = 0.0
	anim.play(animacoes_falas[indice])
		
func mostrar_texto_com_efeito(texto: String, versao_atual: int):
	await get_tree().create_timer(0.1, false).timeout
	if versao_atual != versao_dialogo or not falando:
		return

	for letra in texto:
		texto_dialogo.text += letra
		await get_tree().create_timer(0.02, false).timeout
		if versao_atual != versao_dialogo or not falando:
			return
	pode_avancar = true
	advance_hint.visible = true
	
func encerrar_dialogo(dialogo_finalizado: bool = false) -> void:
	falando = false
	pode_avancar = false
	versao_dialogo += 1
	
	caixa_de_dialogo.visible = false
	advance_hint.visible = false
	
	if(dialogo_finalizado and deve_concluir_fase and not fase_ja_concluida):
		fase_ja_concluida = true
		print("FASE 1 CONCLUÍDA!")
		fase_concluida.emit()
