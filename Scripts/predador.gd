extends CharacterBody2D

enum Estado {INATIVO, PREPARANDO_MERGULHO, MERGULHANDO, RETORNANDO }
var estado_atual: Estado = Estado.INATIVO

@export var velocidade_mergulho: float = 400.0
@export var velocidade_retorno: float = 200.0

var ponto_inicial: Vector2
var alvo_posicao: Vector2

func _ready() -> void:
	ponto_inicial = global_position
	visible = false

func iniciar_ataque(posicao_player: Vector2) -> void:
	if estado_atual == Estado.INATIVO:
		alvo_posicao = posicao_player
		global_position = Vector2(posicao_player.x + randf_range(-150, 150), ponto_inicial.y)
		visible = true
		estado_atual = Estado.PREPARANDO_MERGULHO
		
		# Pequeno delay antes do rasante
		await get_tree().create_timer(0.5).timeout
		estado_atual = Estado.MERGULHANDO

func _physics_process(delta: float) -> void:
	match estado_atual:
		Estado.MERGULHANDO:
			var direcao = (alvo_posicao - global_position).normalized()
			velocity = direcao * velocidade_mergulho
			move_and_slide()
			
			# Se passou do ponto ou chegou muito perto, retorna ao céu
			if global_position.distance_to(alvo_posicao) < 20.0 or global_position.y > alvo_posicao.y + 50.0:
				estado_atual = Estado.RETORNANDO

		Estado.RETORNANDO:
			var direcao_retorno = (ponto_inicial - global_position).normalized()
			velocity = direcao_retorno * velocidade_retorno
			move_and_slide()
			
			if global_position.distance_to(ponto_inicial) < 20.0:
				estado_atual = Estado.INATIVO
				visible = false

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if body.name == "PlayerMariposa":
		get_tree().reload_current_scene() # Game Over / Reiniciar
