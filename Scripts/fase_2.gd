extends Node2D

const STAGE_NAMES := [
	"CAMPO PRÉ-INDUSTRIAL",
	"BÉTULAS CLARAS",
	"TRANSIÇÃO INDUSTRIAL",
	"MANCHESTER INDUSTRIAL",
]
const STAGE_INSTRUCTIONS := [
	"Os troncos ainda são claros e cobertos por líquens.",
	"A casca branca domina este ambiente rural.",
	"Troncos divididos: pouse na metade da mesma cor da mariposa.",
	"A fuligem escureceu completamente os troncos.",
]
const PLAYER_SPAWN := Vector2(320, 88)

@onready var player: CharacterBody2D = $PlayerMariposa
@onready var predator: CharacterBody2D = $Predador
@onready var scenarios: Node2D = $Cenarios
@onready var trunk_stages: Node2D = $Troncos
@onready var selection_panel: Control = $HUD/SelecaoCorPanel
@onready var selection_title: Label = $HUD/SelecaoCorPanel/Panel/VBox/Titulo
@onready var selection_instruction: Label = $HUD/SelecaoCorPanel/Panel/VBox/Instrucao
@onready var stage_label: Label = $HUD/TopBar/Margin/HBox/StageLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var completion_panel: Control = $HUD/MsgFase

var current_stage := 1
var finishing_phase := false

func _ready() -> void:
	GestaoJogo.iniciar_fase(2)
	completion_panel.visible = false
	completion_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	player.predador_alerta.connect(_on_predator_alert)
	configure_stage(1)

func configure_stage(stage: int) -> void:
	current_stage = clampi(stage, 1, 4)
	predator.resetar()
	player.pode_mover = false
	player.velocity = Vector2.ZERO
	player.agarrado = false
	player.zona_atual = null
	player.zonas_proximas.clear()
	player.cor_atual = player.CorMariposa.NENHUMA
	player.timer_camuflagem.stop()
	player.global_position = PLAYER_SPAWN
	player.anim.modulate = Color.WHITE

	for index in range(scenarios.get_child_count()):
		scenarios.get_child(index).visible = index == current_stage - 1

	for index in range(trunk_stages.get_child_count()):
		var stage_group := trunk_stages.get_child(index) as Node2D
		var enabled := index == current_stage - 1
		stage_group.visible = enabled
		for trunk in stage_group.get_children():
			trunk.set_stage_enabled(enabled)

	stage_label.text = "ETAPA %d/4  •  %s" % [current_stage, STAGE_NAMES[current_stage - 1]]
	selection_title.text = "Escolha sua mariposa  •  Etapa %d/4" % current_stage
	selection_instruction.text = STAGE_INSTRUCTIONS[current_stage - 1]
	status_label.text = ""
	selection_panel.visible = true

func _on_btn_branca_pressed() -> void:
	start_with_color(player.CorMariposa.BRANCA)

func _on_btn_preta_pressed() -> void:
	start_with_color(player.CorMariposa.PRETA)

func start_with_color(color: int) -> void:
	selection_panel.visible = false
	status_label.text = "Encontre um tronco e segure E ou Espaço para testar a camuflagem."
	player.definir_cor(color)

func _on_predator_alert(player_position: Vector2) -> void:
	status_label.text = "Camuflagem incorreta: o predador detectou a mariposa!"
	predator.iniciar_ataque(player_position)

func _on_player_mariposa_camuflagem_concluida() -> void:
	status_label.text = "Camuflagem correta!"
	if current_stage < 4:
		configure_stage(current_stage + 1)
	else:
		complete_phase()

func complete_phase() -> void:
	if finishing_phase:
		return
	finishing_phase = true
	player.pode_mover = false
	player.velocity = Vector2.ZERO
	selection_panel.visible = false
	completion_panel.visible = true
	get_tree().paused = true
	await GestaoJogo.esperar_transicao(3.0)
	GestaoJogo.concluir_fase()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/Fase3/Fase3.tscn")
