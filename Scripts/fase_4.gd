extends Node2D

const Food = preload("res://Scripts/recurso_fase_4.gd")
const FoodScene := preload("res://Cenas/Fase4/recurso.tscn")
const PlatformScene := preload("res://Cenas/Fase4/plataforma.tscn")
const EducationalHUDScene := preload("res://Cenas/HUDEducativo.tscn")

const ISLAND_NAMES := ["Ilha das Sementes Duras", "Ilha dos Cactos", "Ilha dos Troncos Antigos"]
const ISLAND_SUBTITLES := ["Geospiza fortis", "Geospiza scandens", "Camarhynchus pallidus"]
const BEAK_OPTIONS := [
	["Alicate", "Pinça", "Tesoura"],
	["Alicate", "Pinça longa", "Colher"],
	["Pinça", "Colher", "Formão"],
]
const BEAK_DESCRIPTIONS := [
	["Curto, robusto e profundo", "Fino e delicado", "Longo e cortante"],
	["Grosso e curto", "Longo e afilado", "Largo e côncavo"],
	["Fino e flexível", "Curvo e arredondado", "Reto, rígido e pontiagudo"],
]
const CORRECT_BEAK := [0, 1, 2]
const ENERGY_GOAL := 90.0
const SPAWN_POSITIONS := [Vector2(38, 244), Vector2(38, 260), Vector2(158, 264)]
const SUMMARIES := [
	"Sementes duras favorecem bicos robustos e profundos. A força do alicate rompe a casca e transforma o alimento em energia.",
	"Flores tubulares funcionam como filtros ecológicos. Bicos longos e finos alcançam o néctar sem tocar nos espinhos.",
	"Presas ocultas exigem precisão e resistência. O bico em forma de formão explora um nicho com pouca competição.",
]

@onready var world = $World
@onready var player: CharacterBody2D = $Player
@onready var platforms: Node2D = $Platforms
@onready var stage_three_platforms: Node2D = $PlataformasEtapa3
@onready var foods: Node2D = $Foods
@onready var cactus_flowers: Node2D = $FloresCacto
@onready var larvae: Node2D = $Larvas
@onready var energy_bar: ProgressBar = $HUD/TopBar/Margin/HBox/EnergyBlock/Energy
@onready var time_label: Label = $HUD/TopBar/Margin/HBox/TimeBlock/TimeLabel
@onready var island_label: Label = $HUD/TopBar/Margin/HBox/IdentityBlock/IslandLabel
@onready var beak_label: Label = $HUD/TopBar/Margin/HBox/IdentityBlock/BeakLabel
@onready var interaction_label: Label = $HUD/InteractionLabel
@onready var feedback_label: Label = $HUD/FeedbackLabel
@onready var selection: Control = $HUD/Selection
@onready var selection_title: Label = $HUD/Selection/Panel/VBox/Title
@onready var selection_environment: Label = $HUD/Selection/Panel/VBox/Environment
@onready var cards: HBoxContainer = $HUD/Selection/Panel/VBox/Cards
@onready var summary: Control = $HUD/Summary
@onready var summary_title: Label = $HUD/Summary/Panel/VBox/Title
@onready var summary_body: Label = $HUD/Summary/Panel/VBox/Body
@onready var summary_button: Button = $HUD/Summary/Panel/VBox/ContinueButton

var island := 0
var selected_beak := -1
var energy := 34.0
var time_left := 48.0
var island_complete := false
var failed := false
var feedback_tween: Tween
var educational_hud: CanvasLayer

func _ready() -> void:
	GestaoJogo.iniciar_fase(4)
	larvae.visible = false
	set_cactus_flowers_enabled(false)
	set_stage_three_platforms_enabled(false)
	selection.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	summary.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	summary_button.pressed.connect(continue_from_summary)
	selection.visible = false
	summary.visible = false
	educational_hud = EducationalHUDScene.instantiate()
	add_child(educational_hud)
	get_tree().paused = true
	educational_hud.mostrar_como_jogar(4)
	await educational_hud.continuar
	show_beak_selection()

func show_beak_selection() -> void:
	get_tree().paused = true
	player.pode_mover = false
	selection.visible = true
	summary.visible = false
	selection_title.text = ISLAND_NAMES[island]
	selection_environment.text = environment_clue()
	for child in cards.get_children():
		child.queue_free()
	for option in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(158, 94)
		button.text = "%s\n%s" % [BEAK_OPTIONS[island][option], BEAK_DESCRIPTIONS[island][option]]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.tooltip_text = "Selecionar %s" % BEAK_OPTIONS[island][option]
		button.pressed.connect(select_beak.bind(option))
		cards.add_child(button)

func environment_clue() -> String:
	match island:
		0:
			return "Seca intensa • sementes grandes com casca espessa"
		1:
			return "Flores tubulares • néctar protegido por espinhos"
		_:
			return "Larvas escondidas • casca rígida e frestas estreitas"

func select_beak(option: int) -> void:
	selected_beak = option
	selection.visible = false
	setup_island()
	get_tree().paused = false
	player.pode_mover = true

func setup_island() -> void:
	island_complete = false
	failed = false
	energy = 34.0
	time_left = 48.0 if island != 1 else 55.0
	world.set_island(island)
	clear_children(platforms)
	clear_children(foods)
	set_cactus_flowers_enabled(island == 1)
	set_stage_three_platforms_enabled(island == 2)
	larvae.visible = island == 2
	for larva in larvae.get_children():
		larva.set_stage_enabled(island == 2)
	create_island_layout()
	player.configure(island, selected_beak)
	player.reset_at(SPAWN_POSITIONS[island])
	island_label.text = "%d/3  %s" % [island + 1, ISLAND_NAMES[island]]
	beak_label.text = "BICO: %s" % BEAK_OPTIONS[island][selected_beak].to_upper()
	feedback_label.text = ""
	update_hud()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func create_island_layout() -> void:
	match island:
		0:
			# Deserto: chão rachado e os dois grandes pilares de pedra.
			create_platform(Rect2(0, 258, 640, 62))
			create_platform(Rect2(164, 159, 127, 12))
			create_platform(Rect2(400, 116, 134, 12))
			for position in [Vector2(92, 252), Vector2(220, 153), Vector2(324, 252), Vector2(466, 110), Vector2(548, 252), Vector2(606, 252)]:
				create_food(position, Food.FoodKind.SEED)
		1:
			# Cactos: solo inferior e as quatro pedras flutuantes visíveis.
			for rect in [Rect2(0, 274, 640, 46), Rect2(62, 156, 78, 11), Rect2(216, 192, 79, 11), Rect2(374, 225, 82, 11), Rect2(505, 156, 71, 11)]:
				create_platform(rect)
		2:
			# As plataformas da floresta ficam editáveis em Fase4.tscn.
			pass

func set_stage_three_platforms_enabled(enabled: bool) -> void:
	stage_three_platforms.visible = enabled
	for platform in stage_three_platforms.get_children():
		platform.set_stage_enabled(enabled)

func set_cactus_flowers_enabled(enabled: bool) -> void:
	cactus_flowers.visible = enabled
	for flower in cactus_flowers.get_children():
		flower.set_stage_enabled(enabled)

func create_platform(rect: Rect2) -> void:
	var platform := PlatformScene.instantiate()
	platforms.add_child(platform)
	platform.setup(rect)

func create_food(position_value: Vector2, kind: Food.FoodKind, offset := 0.0) -> void:
	var food := FoodScene.instantiate()
	foods.add_child(food)
	food.position = position_value
	food.setup(kind, offset)

func _physics_process(delta: float) -> void:
	if get_tree().paused or island_complete or failed or selected_beak < 0:
		return
	time_left -= delta
	energy -= delta * (1.05 if selected_beak == CORRECT_BEAK[island] else 1.75)
	update_hud()
	update_nearby_food()

	if island_complete:
		return
	if time_left <= 0.0 or energy <= 0.0:
		fail_island()

func update_nearby_food() -> void:
	var closest: Node2D = null
	var closest_distance := 42.0
	var active_foods := current_island_foods()
	for food in active_foods:
		if not food.active:
			continue
		var distance := player.global_position.distance_to(food.global_position)
		if distance < closest_distance:
			closest = food
			closest_distance = distance

	interaction_label.visible = closest != null
	if closest == null:
		return
	interaction_label.text = "E  BICAR" if island != 2 else ("E  AGORA!" if closest.available else "AGUARDE...")
	if Input.is_action_just_pressed("interacao"):
		attempt_feed(closest)

func current_island_foods() -> Array[Node]:
	match island:
		1:
			return cactus_flowers.get_children()
		2:
			return larvae.get_children()
		_:
			return foods.get_children()

func all_food_consumed() -> bool:
	var island_foods := current_island_foods()
	if island_foods.is_empty():
		return false
	for food in island_foods:
		if food.active:
			return false
	return true

func attempt_feed(food: Node2D) -> void:
	if selected_beak != CORRECT_BEAK[island]:
		apply_feed_failure("O bico não consegue acessar esse alimento.")
		return
	if island == 2 and not food.available:
		apply_feed_failure("A larva recuou para dentro do tronco.")
		return

	food.consume()
	energy = minf(100.0, energy + 23.0)
	time_left += 2.0
	var effects := ["CRACK!  +energia", "SLURP!  +energia", "TUC-TUC!  +energia"]
	show_feedback(effects[island], Color("f2d15f"))
	if energy >= ENERGY_GOAL or all_food_consumed():
		complete_island()

func apply_feed_failure(message: String) -> void:
	energy -= 13.0
	time_left -= 5.0
	player.stun(player.facing)
	show_feedback(message, Color("ef6b55"))

func show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.modulate = color
	feedback_label.visible = true
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_interval(1.25)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.35)

func update_hud() -> void:
	energy_bar.value = clampf(energy, 0.0, 100.0)
	time_label.text = "%02d s" % maxi(0, ceili(time_left))

func fail_island() -> void:
	if failed:
		return
	failed = true
	player.pode_mover = false
	interaction_label.visible = false
	summary_title.text = "Energia esgotada"
	summary_body.text = "A morfologia escolhida não aproveitou o alimento a tempo. Observe o recurso dominante e tente outra adaptação."
	summary_button.text = "Reavaliar bico"
	summary.visible = true
	get_tree().paused = true

func complete_island() -> void:
	if island_complete:
		return
	island_complete = true
	if island == 2:
		GestaoJogo.concluir_fase()
	player.pode_mover = false
	interaction_label.visible = false
	summary_title.text = "Nicho explorado"
	summary_body.text = SUMMARIES[island]
	summary_button.text = "Próxima ilha" if island < 2 else "Ver síntese final"
	summary.visible = true
	get_tree().paused = true

func continue_from_summary() -> void:
	if failed:
		selected_beak = -1
		show_beak_selection()
		return
	if island < 2:
		island += 1
		selected_beak = -1
		show_beak_selection()
		return
	show_final_synthesis()

func show_final_synthesis() -> void:
	summary.visible = false
	educational_hud.mostrar_conclusao(4, "Retornar ao menu")
	await educational_hud.continuar
	GestaoJogo.voltar_ao_menu()
