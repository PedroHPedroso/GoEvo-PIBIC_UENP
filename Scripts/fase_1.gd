extends Node

const EducationalHUDScene := preload("res://Cenas/HUDEducativo.tscn")

@onready var hud: CanvasLayer = $HUD
@onready var sapinha: Area2D = $Sapinha

var trocando_fase: bool = false
var educational_hud: CanvasLayer

func _ready() -> void:
	GestaoJogo.iniciar_fase(1)
	educational_hud = EducationalHUDScene.instantiate()
	add_child(educational_hud)
	get_tree().paused = true
	educational_hud.mostrar_como_jogar(1)
	await educational_hud.continuar
	get_tree().paused = false

# ============================================
# FASE CONCLUÍDA
# ============================================

func _on_sapinha_fase_concluida() -> void:
	print("SINAL DA SAPINHA RECEBIDO!")
	finalizar_fase()

func finalizar_fase() -> void:
	if trocando_fase:
		return

	trocando_fase = true
	GestaoJogo.concluir_fase()
	get_tree().paused = true
	educational_hud.mostrar_conclusao(1, "Continuar para a Fase 2")
	await educational_hud.continuar
	get_tree().paused = false
	var erro = get_tree().change_scene_to_file("res://Cenas/Fase2/Fase2.tscn")

	if erro != OK:
		print(
			"Erro ao carregar Fase 2: ",
			erro
		)
