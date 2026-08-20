extends Node2D

@onready var player: CharacterBody2D = $PlayerMariposa
@onready var predador: CharacterBody2D = $Predador
@onready var selecao_painel: Control = $HUD/SelecaoCorPanel
@onready var troncos_container: Node2D = $Troncos

var etapa_atual: int = 1

func _ready() -> void:
	player.predador_alerta.connect(predador.iniciar_ataque)
	configurar_etapa(1)

func configurar_etapa(etapa: int) -> void:
	etapa_atual = etapa
	player.pode_mover = false
	player.velocity = Vector2.ZERO
	player.agarrado = false
	player.cor_atual = player.CorMariposa.NENHUMA
	player.timer_camuflagem.stop()
	player.global_position = Vector2(100, 300)
	selecao_painel.visible = true
	
	var arvores = troncos_container.get_children()

	match etapa_atual:
		1: # Etapa 1: Misto de árvores Marrons e Brancas
			for i in range(arvores.size()):
				var cor = player.CorMariposa.MARROM if i % 2 == 0 else player.CorMariposa.BRANCA
				arvores[i].definir_tonalidade(cor)
		2: # Etapa 2: Apenas árvores Brancas (Manchester pré-industrial)
			for arvore in arvores:
				arvore.definir_tonalidade(player.CorMariposa.BRANCA)
		3: # Etapa 3: Apenas árvores Pretas (Manchester industrial/fuligem)
			for arvore in arvores:
				arvore.definir_tonalidade(player.CorMariposa.PRETA)

# Sinais dos Botões do HUD
func _on_btn_marrom_pressed() -> void:
	iniciar_jogo_com_cor(player.CorMariposa.MARROM)

func _on_btn_branca_pressed() -> void:
	iniciar_jogo_com_cor(player.CorMariposa.BRANCA)

func _on_btn_preta_pressed() -> void:
	iniciar_jogo_com_cor(player.CorMariposa.PRETA)

func iniciar_jogo_com_cor(cor) -> void:
	selecao_painel.visible = false
	player.definir_cor(cor)

func _on_player_mariposa_camuflagem_concluida() -> void:
	if etapa_atual < 3:
		configurar_etapa(etapa_atual + 1)
	else:
		# Finaliza a fase e carrega a Fase 3
		get_tree().change_scene_to_file("res://Cenas/Fase3/Fase3.tscn")
