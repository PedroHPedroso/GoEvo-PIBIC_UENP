extends CharacterBody2D

enum Estado {INATIVO, PREPARANDO_MERGULHO, MERGULHANDO, RETORNANDO }
const ANIMACAO_ATAQUE_CIMA := &"attacking"
const ANIMACAO_ATAQUE_LADO := &"attacking_side"
const ANIMACAO_RETORNO := &"backing"

var estado_atual: Estado = Estado.INATIVO

@export var velocidade_mergulho: float = 400.0
@export var velocidade_retorno: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var ponto_inicial: Vector2
var alvo_posicao: Vector2
var attack_version := 0

func _ready() -> void:
	ponto_inicial = global_position
	sprite.play(ANIMACAO_ATAQUE_CIMA)
	visible = false

func iniciar_ataque(posicao_player: Vector2) -> void:
	if estado_atual == Estado.INATIVO:
		attack_version += 1
		var current_version := attack_version
		alvo_posicao = posicao_player
		global_position = Vector2(posicao_player.x + randf_range(-150, 150), ponto_inicial.y)
		atualizar_visual_ataque(alvo_posicao - global_position)
		visible = true
		estado_atual = Estado.PREPARANDO_MERGULHO
		
		# Pequeno delay antes do rasante
		await get_tree().create_timer(0.5).timeout
		if current_version == attack_version and estado_atual == Estado.PREPARANDO_MERGULHO:
			estado_atual = Estado.MERGULHANDO

func resetar() -> void:
	attack_version += 1
	estado_atual = Estado.INATIVO
	velocity = Vector2.ZERO
	global_position = ponto_inicial
	if is_node_ready():
		sprite.play(ANIMACAO_ATAQUE_CIMA)
		sprite.flip_h = false
	visible = false

func _physics_process(delta: float) -> void:
	match estado_atual:
		Estado.MERGULHANDO:
			var direcao := (alvo_posicao - global_position).normalized()
			velocity = direcao * velocidade_mergulho
			atualizar_visual_ataque(direcao)
			move_and_slide()
			
			# Se passou do ponto ou chegou muito perto, retorna ao céu
			if global_position.distance_to(alvo_posicao) < 20.0 or global_position.y > alvo_posicao.y + 50.0:
				estado_atual = Estado.RETORNANDO
				atualizar_visual_retorno(ponto_inicial - global_position)

		Estado.RETORNANDO:
			var direcao_retorno := (ponto_inicial - global_position).normalized()
			velocity = direcao_retorno * velocidade_retorno
			atualizar_visual_retorno(direcao_retorno)
			move_and_slide()
			
			if global_position.distance_to(ponto_inicial) < 20.0:
				estado_atual = Estado.INATIVO
				visible = false

func atualizar_visual_ataque(direcao: Vector2) -> void:
	var animacao := ANIMACAO_ATAQUE_CIMA if absf(direcao.y) >= absf(direcao.x) else ANIMACAO_ATAQUE_LADO
	if sprite.animation != animacao:
		sprite.play(animacao)
	sprite.flip_h = direcao.x < 0.0

func atualizar_visual_retorno(direcao: Vector2) -> void:
	if sprite.animation != ANIMACAO_RETORNO:
		sprite.play(ANIMACAO_RETORNO)
	sprite.flip_h = direcao.x < 0.0

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if body.name == "PlayerMariposa":
		get_tree().reload_current_scene() # Game Over / Reiniciar
