extends Node2D

const PigmentScene := preload("res://Cenas/Fase3/pigmento.tscn")
const Predator = preload("res://Scripts/predador_fase_3.gd")
const EducationalHUDScene := preload("res://Cenas/HUDEducativo.tscn")

const RED := Color("db3f3f")
const YELLOW := Color("f0d45a")
const BLACK := Color("202225")
const TARGET_NAMES := ["Vermelho", "Amarelo", "Preto", "Amarelo", "Vermelho"]
const TARGET_COLORS: Array[Color] = [RED, YELLOW, BLACK, YELLOW, RED]
const CHECKPOINT_X := [205.0, 345.0, 485.0, 625.0, 765.0]
const PATROL_HALF_WIDTH := 52.0
const PATROL_SPEED := 45.0
const REACTION_END_DISTANCE := 230.0
const BADGER_CONFUSED_PAUSE := 1.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var pattern_row: HBoxContainer = $HUD/TopBar/Margin/HBox/PatternBlock/PatternLine/PatternRow
@onready var status_label: Label = $HUD/StatusLabel
@onready var section_label: Label = $HUD/TopBar/Margin/HBox/TitleBlock/SectionLabel
@onready var progress: ProgressBar = $HUD/TopBar/Margin/HBox/ProgressBlock/Progress
@onready var intro: Control = $HUD/Intro
@onready var end_panel: Control = $HUD/EndPanel
@onready var end_title: Label = $HUD/EndPanel/Panel/VBox/Title
@onready var end_body: Label = $HUD/EndPanel/Panel/VBox/Body
@onready var end_button: Button = $HUD/EndPanel/Panel/VBox/ActionButton

var pattern_names: Array[String] = []
var pattern_colors: Array[Color] = []
var pigments: Array[Node2D] = []
var enemies: Array[Node2D] = []
var game_over := false
var victory := false
var badger_active := false
var badger_shelter_phase := "chasing"
var badger_confused_pause := 0.0
var last_status := ""
var educational_hud: CanvasLayer

func _ready() -> void:
	GestaoJogo.iniciar_fase(3)
	create_pigments()
	register_enemies()
	update_pattern_hud()
	get_tree().paused = true
	intro.visible = false
	end_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$HUD/TopBar/Margin/HBox/PatternBlock/PatternLine/UndoButton.pressed.connect(undo_last_pigment)
	end_button.pressed.connect(end_action)
	educational_hud = EducationalHUDScene.instantiate()
	add_child(educational_hud)
	educational_hud.mostrar_como_jogar(3)
	await educational_hud.continuar
	start_level()

func create_pigments() -> void:
	var options: Array[Array] = [
		[[RED, "Vermelho"], [YELLOW, "Amarelo"], [BLACK, "Preto"]],
		[[BLACK, "Preto"], [RED, "Vermelho"], [YELLOW, "Amarelo"]],
		[[YELLOW, "Amarelo"], [BLACK, "Preto"], [RED, "Vermelho"]],
		[[RED, "Vermelho"], [YELLOW, "Amarelo"], [BLACK, "Preto"]],
		[[BLACK, "Preto"], [RED, "Vermelho"], [YELLOW, "Amarelo"]],
	]
	var ys := [126.0, 188.0, 250.0]
	for checkpoint in range(options.size()):
		for option_index in range(3):
			var data: Array = options[checkpoint][option_index]
			var pigment := PigmentScene.instantiate()
			$Pigments.add_child(pigment)
			pigment.position = Vector2(CHECKPOINT_X[checkpoint], ys[option_index])
			pigment.setup(data[0], data[1], checkpoint)
			pigments.append(pigment)

func register_enemies() -> void:
	for enemy in $Enemies.get_children():
		enemy.set_meta("origin", enemy.position)
		enemy.set_meta("patrol_direction", enemy.facing)
		enemy.visible = enemy.kind != Predator.Kind.BADGER
		enemies.append(enemy)

func start_level() -> void:
	intro.visible = false
	get_tree().paused = false
	player.pode_mover = true
	set_status("Escolha o primeiro pigmento.")

func _physics_process(delta: float) -> void:
	if game_over or victory or not player.pode_mover:
		return

	detect_pigments()
	update_progress_and_section()
	update_predators(delta)

	if player.global_position.x >= 1850.0:
		win_level()

func detect_pigments() -> void:
	for pigment in pigments:
		if pigment.active and pigment.checkpoint == pattern_names.size() and player.global_position.distance_to(pigment.global_position) < 20.0:
			collect_pigment(pigment)
			return

func collect_pigment(selected: Node2D) -> void:
	pattern_names.append(selected.pigment_name)
	pattern_colors.append(selected.pigment_color)
	for pigment in pigments:
		if pigment.checkpoint == selected.checkpoint:
			pigment.set_active(false)
	player.set_pattern(pattern_colors)
	update_pattern_hud()
	if pattern_names.size() == TARGET_NAMES.size():
		if is_pattern_correct():
			set_status("Disfarce completo. Os predadores reconhecem o aviso.")
		else:
			set_status("Padrão incorreto. Volte um passo antes de seguir.")
	else:
		set_status("Pigmento %d de 5 coletado." % pattern_names.size())

func undo_last_pigment() -> void:
	if game_over or victory or pattern_names.is_empty():
		return
	var checkpoint := pattern_names.size() - 1
	pattern_names.pop_back()
	pattern_colors.pop_back()
	for pigment in pigments:
		if pigment.checkpoint == checkpoint:
			pigment.set_active(true)
	player.set_pattern(pattern_colors)
	update_pattern_hud()
	player.global_position.x = minf(player.global_position.x, CHECKPOINT_X[checkpoint] - 34.0)
	set_status("Escolha novamente o pigmento %d." % (checkpoint + 1))

func update_pattern_hud() -> void:
	for child in pattern_row.get_children():
		child.queue_free()
	for i in range(5):
		var slot := ColorRect.new()
		slot.custom_minimum_size = Vector2(30, 14)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.color = pattern_colors[i] if i < pattern_colors.size() else Color("3b4039")
		pattern_row.add_child(slot)

func update_progress_and_section() -> void:
	progress.value = clampf(player.global_position.x / 1850.0 * 100.0, 0.0, 100.0)
	var x := player.global_position.x
	if x < 860:
		section_label.text = "PIGMENTOS %d/5" % pattern_names.size()
	elif x < 1450:
		section_label.text = "ZONA DE PREDADORES"
	else:
		section_label.text = "FUGA FINAL"

func update_predators(delta: float) -> void:
	var disguised := is_pattern_correct()
	for enemy in enemies:
		if enemy.kind == Predator.Kind.BADGER:
			update_badger(enemy, delta)
			continue

		var origin: Vector2 = enemy.get_meta("origin")
		var distance := enemy.global_position.distance_to(player.global_position)
		var detected: bool = enemy.can_see_position(player.global_position)
		var reacting: bool = detected or (enemy.state in ["attacking", "deterred"] and distance < REACTION_END_DISTANCE)
		if reacting:
			if disguised:
				enemy.alert_text = "!"
				enemy.state = "deterred"
				var away := (enemy.global_position - player.global_position).normalized()
				if absf(away.x) > 0.05:
					enemy.facing = signf(away.x)
				enemy.global_position += away * delta * (72.0 if enemy.kind == Predator.Kind.BIRD else 28.0)
				set_status("Blefe aceito: o predador hesitou.")
			else:
				enemy.alert_text = "X"
				enemy.state = "attacking"
				var direction := (player.global_position - enemy.global_position).normalized()
				enemy.facing = signf(direction.x) if absf(direction.x) > 0.05 else enemy.facing
				enemy.global_position += direction * delta * (170.0 if enemy.kind == Predator.Kind.BIRD else 92.0)
				set_status("Predador atacando: o padrão não convenceu.")
		else:
			enemy.alert_text = ""
			enemy.state = "watching"
			patrol_enemy(enemy, origin, delta)

		if not disguised and enemy.is_in_attack_range(player.global_position):
			lose_level("O predador identificou a falsa-coral como presa.")

func patrol_enemy(enemy: Node2D, origin: Vector2, delta: float) -> void:
	var patrol_direction: float = enemy.get_meta("patrol_direction", -1.0)
	var left_limit := origin.x - PATROL_HALF_WIDTH
	var right_limit := origin.x + PATROL_HALF_WIDTH
	if enemy.global_position.x <= left_limit:
		patrol_direction = 1.0
	elif enemy.global_position.x >= right_limit:
		patrol_direction = -1.0

	enemy.facing = patrol_direction
	enemy.set_meta("patrol_direction", patrol_direction)
	var next_x := enemy.global_position.x + patrol_direction * PATROL_SPEED * delta
	if enemy.global_position.x < left_limit:
		enemy.global_position.x = minf(next_x, left_limit)
	elif enemy.global_position.x > right_limit:
		enemy.global_position.x = maxf(next_x, right_limit)
	else:
		enemy.global_position.x = clampf(next_x, left_limit, right_limit)
	enemy.global_position.y = move_toward(enemy.global_position.y, origin.y, PATROL_SPEED * delta)

func update_badger(badger: Node2D, delta: float) -> void:
	if not badger_active and player.global_position.x >= 1460.0:
		badger_active = true
		badger.visible = true
		badger.global_position = Vector2(player.global_position.x - 95.0, 250.0)
		set_status("O texugo-do-mel é imune ao blefe. Alcance a clareira!")
	if not badger_active:
		return

	var player_hidden: bool = player.is_inside_shelter()

	if not player_hidden:
		badger_shelter_phase = "chasing"
		badger_confused_pause = 0.0
		badger.alert_text = "X"
		badger.state = "attacking"
		var direction := (player.global_position - badger.global_position).normalized()
		badger.facing = signf(direction.x) if absf(direction.x) > 0.05 else badger.facing
		badger.global_position += direction * delta * 102.0
	else:
		update_sheltered_badger(badger, delta)

	if badger.is_in_attack_range(player.global_position) and not player_hidden:
		lose_level("O texugo-do-mel não teme as cores da coral.")

func update_sheltered_badger(badger: Node2D, delta: float) -> void:
	if badger_shelter_phase == "chasing":
		badger_shelter_phase = "confused"
		badger_confused_pause = 0.0
		badger.alert_text = "X"
		badger.state = "confused"
		set_status("Abrigo estreito: o texugo não consegue entrar.")
		return

	if badger_shelter_phase == "confused":
		badger.state = "confused"
		if badger.is_animation_finished(&"confused"):
			badger_confused_pause += delta
			if badger_confused_pause >= BADGER_CONFUSED_PAUSE:
				badger_shelter_phase = "patrolling"
		return

	badger.alert_text = ""
	badger.state = "watching"
	var origin: Vector2 = badger.get_meta("origin")
	patrol_enemy(badger, origin, delta)

func is_pattern_correct() -> bool:
	return pattern_names == TARGET_NAMES

func set_status(text: String) -> void:
	if text == last_status:
		return
	last_status = text
	status_label.text = text

func lose_level(reason: String) -> void:
	if game_over or victory:
		return
	game_over = true
	player.pode_mover = false
	end_title.text = "A seleção agiu"
	end_body.text = reason + "\n\nO mimetismo só funciona quando o sinal é reconhecido pelo predador."
	end_button.text = "Tentar novamente"
	end_panel.visible = true
	get_tree().paused = true

func win_level() -> void:
	if game_over or victory:
		return
	victory = true
	player.pode_mover = false
	GestaoJogo.concluir_fase()
	get_tree().paused = true
	educational_hud.mostrar_conclusao(3, "Continuar para a Fase 4")
	await educational_hud.continuar
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Cenas/Fase4/Fase4.tscn")

func end_action() -> void:
	get_tree().paused = false
	if victory:
		get_tree().change_scene_to_file("res://Cenas/Fase4/Fase4.tscn")
	else:
		get_tree().reload_current_scene()
