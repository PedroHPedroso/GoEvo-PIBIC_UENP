extends Node

@onready var hud: CanvasLayer = $HUD
@onready var sapinha: Area2D = $Sapinha

var trocando_fase: bool = false

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

	print("Mostrando mensagem...")

	hud.mostrar_fase_concluida()

	await get_tree().create_timer(3.0).timeout

	print("Indo para Fase 2...")

	var erro = get_tree().change_scene_to_file("res://Cenas/Fase2/Fase2.tscn")

	if erro != OK:
		print(
			"Erro ao carregar Fase 2: ",
			erro
		)
