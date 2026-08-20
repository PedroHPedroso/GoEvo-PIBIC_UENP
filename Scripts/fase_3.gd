extends Node2D

const PlayerSnake = preload("res://Scripts/player_cobra.gd")
const Pigment = preload("res://Scripts/pigmento_fase_3.gd")
const Predator = preload("res://Scripts/predador_fase_3.gd")

const RED := Color("db3f3f")
const YELLOW := Color("f0d45a")
const BLACK := Color("202225")
const TARGET_NAMES := ["Vermelho", "Amarelo", "Preto", "Amarelo", "Vermelho"]
const TARGET_COLORS: Array[Color] = [RED, YELLOW, BLACK, YELLOW, RED]
const CHECKPOINT_X := [205.0, 345.0, 485.0, 625.0, 765.0]

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var pattern_row: HBoxContainer = $HUD/TopBar/PatternRow
@onready var status_label: Label = $HUD/StatusLabel
@onready var section_label: Label = $HUD/TopBar/SectionLabel
@onready var progress: ProgressBar = $HUD/TopBar/Progress
@onready var intro: Control = $HUD/Intro
@onready var end_panel: Control = $HUD/EndPanel
@onready var end_title: Label = $HUD/EndPanel/Panel/VBox/Title
@onready var end_body: Label = $HUD/EndPanel/Panel/VBox/Body
@onready var end_button: Button = $HUD/EndPanel/Panel/VBox/ActionButton

var pattern_names: Array[String] = []
var pattern_colors: Array[Color] = []
var pigments: Array[Node2D] = []
var enemies: Array[Node2D] = []
var safe_zones: Array[Rect2] = [Rect2(1518, 205, 105, 48), Rect2(1690, 105, 96, 45)]
var game_over := false
var victory := false
var badger_active := false
var last_status := ""

func _ready() -> void:
	create_pigments()
	create_enemies()
	update_pattern_hud()
	get_tree().paused = true
	intro.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	end_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	$HUD/TopBar/UndoButton.pressed.connect(undo_last_pigment)
	$HUD/Intro/Panel/VBox/StartButton.pressed.connect(start_level)
	end_button.pressed.connect(end_action)

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
			var pigment := Node2D.new()
			pigment.set_script(Pigment)
			$Pigments.add_child(pigment)
			pigment.position = Vector2(CHECKPOINT_X[checkpoint], ys[option_index])
			pigment.setup(data[0], data[1], checkpoint)
			pigments.append(pigment)

func create_enemies() -> void:
	var configs := [
		[Predator.Kind.BIRD, Vector2(1010, 135)],
		[Predator.Kind.BIRD, Vector2(1165, 245)],
		[Predator.Kind.OPOSSUM, Vector2(1340, 165)],
		[Predator.Kind.BADGER, Vector2(1450, 250)],
	]
	for config in configs:
		var enemy := Node2D.new()
		enemy.set_script(Predator)
		$Enemies.add_child(enemy)
		enemy.position = config[1]
		enemy.setup(config[0])
		enemy.set_meta("origin", config[1])
		enemy.visible = config[0] != Predator.Kind.BADGER
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
		var detected := predator_can_see(enemy, distance)
		if detected:
			if disguised:
				enemy.alert_text = "!"
				enemy.state = "deterred"
				var away := (enemy.global_position - player.global_position).normalized()
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
			var patrol_target := origin
			if enemy.kind == Predator.Kind.OPOSSUM:
				patrol_target += Vector2(sin(enemy.animation_time * 0.8) * 52.0, 0)
				enemy.facing = signf(patrol_target.x - enemy.global_position.x) if absf(patrol_target.x - enemy.global_position.x) > 0.5 else enemy.facing
			enemy.global_position = enemy.global_position.move_toward(patrol_target, delta * 45.0)

		if distance < 19.0:
			lose_level("O predador identificou a falsa-coral como presa.")

func predator_can_see(enemy: Node2D, distance: float) -> bool:
	if enemy.kind == Predator.Kind.OPOSSUM:
		return distance < 125.0
	var relative := player.global_position - enemy.global_position
	if relative.x > 15.0 or relative.x < -195.0:
		return false
	var cone_half_height := lerpf(12.0, 68.0, absf(relative.x) / 195.0)
	return absf(relative.y) <= cone_half_height

func update_badger(badger: Node2D, delta: float) -> void:
	if not badger_active and player.global_position.x >= 1460.0:
		badger_active = true
		badger.visible = true
		badger.global_position = Vector2(player.global_position.x - 95.0, 250.0)
		set_status("O texugo-do-mel é imune ao blefe. Alcance a clareira!")
	if not badger_active:
		return

	var player_hidden := false
	for zone in safe_zones:
		if zone.has_point(player.global_position):
			player_hidden = true
			break

	badger.alert_text = "X"
	if not player_hidden:
		var direction := (player.global_position - badger.global_position).normalized()
		badger.facing = signf(direction.x) if absf(direction.x) > 0.05 else badger.facing
		badger.global_position += direction * delta * 102.0
	else:
		set_status("Abrigo estreito: o texugo não consegue entrar.")

	if badger.global_position.distance_to(player.global_position) < 23.0 and not player_hidden:
		lose_level("O texugo-do-mel não teme as cores da coral.")

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
	end_title.text = "Blefe perfeito"
	end_body.text = "A falsa-coral sobreviveu ao imitar o padrão de alerta da coral verdadeira e escapou do predador imune."
	end_button.text = "Continuar"
	end_panel.visible = true
	get_tree().paused = true

func end_action() -> void:
	get_tree().paused = false
	if victory:
		get_tree().change_scene_to_file("res://Cenas/Fase4/Fase4.tscn")
	else:
		get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not pattern_names.is_empty() and not game_over and not victory:
		undo_last_pigment()
