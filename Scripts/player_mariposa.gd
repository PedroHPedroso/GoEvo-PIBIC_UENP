extends CharacterBody2D

signal camuflagem_concluida
signal predador_alerta(posicao: Vector2)

enum CorMariposa { NENHUMA, BRANCA, MARROM, PRETA }
var cor_atual: CorMariposa = CorMariposa.NENHUMA

const SPEED: float = 220.0
const GRAVIDADE_QUEDA: float = 350.0

var arvore_atual: Area2D = null
var agarrado: bool = false
var pode_mover: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer_camuflagem: Timer = $CamuflagemTimer
@onready var area_detector: Area2D = $AreaDetector

func _ready() -> void:
	area_detector.area_entered.connect(_on_area_detector_entered)
	area_detector.area_exited.connect(_on_area_detector_exited)
	timer_camuflagem.timeout.connect(_on_tempo_camuflagem_esgotado)

func definir_cor(cor_escolhida: CorMariposa) -> void:
	cor_atual = cor_escolhida
	match cor_atual:
		CorMariposa.BRANCA:
			anim.modulate = Color(0.95, 0.95, 0.95)
		CorMariposa.MARROM:
			anim.modulate = Color(0.776, 0.51, 0.373, 1.0)
		CorMariposa.PRETA:
			anim.modulate = Color(0.15, 0.15, 0.15)
	pode_mover = true
	# Exemplo: anim.play("voar_" + CorMariposa.keys()[cor_escolhida].to_lower())

func _physics_process(delta: float) -> void:
	if not pode_mover:
		return

	# Tentar agarrar ao segurar Espaço junto a um tronco
	if (Input.is_action_pressed("ui_select") or Input.is_action_pressed("interacao")) and arvore_atual != null:
		if not agarrado:
			iniciar_agarro()
		velocity = Vector2.ZERO
	else:
		if agarrado:
			soltar_agarro()
		processar_voo(delta)

	move_and_slide()

func processar_voo(delta: float) -> void:
	# As ações em português estão configuradas no project.godot para WASD e setas.
	var direcao := Input.get_vector("esquerda", "direita", "frente", "tras")
	anim.play("Branca")
	
	if direcao != Vector2.ZERO:
		velocity = direcao.normalized() * SPEED
	else:
		# Gravidade suave caso esteja no ar sem comando
		velocity.y = move_toward(velocity.y, GRAVIDADE_QUEDA, 400.0 * delta)
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta)

func iniciar_agarro() -> void:
	agarrado = true
	anim.stop()
	# Checagem de cor entre a mariposa e o tronco
	if arvore_atual.cor_arvore == cor_atual:
		timer_camuflagem.start(5.0)
	else:
		# Aciona alerta de predador por camuflagem errada
		predador_alerta.emit(global_position)

func soltar_agarro() -> void:
	agarrado = false
	timer_camuflagem.stop()

func _on_tempo_camuflagem_esgotado() -> void:
	if agarrado:
		camuflagem_concluida.emit()

func _on_area_detector_entered(area: Area2D) -> void:
	if area.is_in_group("arvores"):
		arvore_atual = area

func _on_area_detector_exited(area: Area2D) -> void:
	if area == arvore_atual:
		arvore_atual = null
		if agarrado:
			soltar_agarro()
