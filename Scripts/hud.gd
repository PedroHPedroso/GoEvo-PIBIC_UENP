extends CanvasLayer

@export var player: CharacterBody2D
@onready var moscas_label: Label = ($MarginContainer/HBoxContainer/MoscaLabel)
@onready var mensagem_fase: PanelContainer = $MsgFase
@onready var mensagem_fase_label: Label = ($MsgFase/Label)


func _ready() -> void:
	# A mensagem começa escondida.
	mensagem_fase.visible = false

	if player == null:
		return

	# Mostra o valor inicial.
	atualizar_contador(player.moscas)

	# Conecta o HUD ao contador.
	if not player.moscas_atualizadas.is_connected(_on_moscas_atualizadas):
		player.moscas_atualizadas.connect(_on_moscas_atualizadas)

func _on_moscas_atualizadas(total: int) -> void:
	atualizar_contador(total)

func atualizar_contador(total: int) -> void:
	moscas_label.text = "Moscas: %d/10" % total

# MENSAGEM DE FASE CONCLUÍDA
func mostrar_fase_concluida() -> void:
	mensagem_fase_label.text = ("Parabéns, você concluiu a Fase 1!")
	mensagem_fase.visible = true
