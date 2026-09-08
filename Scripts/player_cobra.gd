extends CharacterBody2D

const SPEED := 132.0
const WORLD_BOUNDS := Rect2(18, 96, 1882, 178)
const SKIN_ROOT := "res://Animações/Fase3/Sprites/Peles/"
const SEGMENT5_REFERENCE_REGION := Vector2(212.0, 52.0)
const SEGMENT5_REFERENCE_SCALE := Vector2(0.075, 0.07)
const SHELTER_ZONES: Array[Rect2] = [
	Rect2(1518, 205, 105, 48),
	Rect2(1690, 105, 96, 45),
]
const SHELTER_OPENING_HALF_HEIGHT := 8.0
const SHELTER_FADE_DISTANCE := 24.0

@onready var visual_root: Node2D = $CobraVisual
@onready var head_sprite: Sprite2D = $CobraVisual/Cabeca
@onready var segment_sprites: Array[Sprite2D] = [
	$CobraVisual/Segmento2,
	$CobraVisual/Segmento3,
	$CobraVisual/Segmento4,
	$CobraVisual/Segmento5,
]
@onready var articulated_parts: Array[Sprite2D] = [
	$CobraVisual/Cabeca,
	$CobraVisual/Segmento2,
	$CobraVisual/Segmento3,
	$CobraVisual/Segmento4,
	$CobraVisual/Segmento5,
]

var pode_mover := false
var pattern_colors: Array[Color] = []
var slither_time := 0.0
var slither_strength := 0.0
var visual_angle := 0.0
var articulated_base_positions: Array[Vector2] = []
var current_shelter := -1

func _ready() -> void:
	for part in articulated_parts:
		articulated_base_positions.append(part.position)
	refresh_pattern_visuals()

func _physics_process(delta: float) -> void:
	if not pode_mover:
		velocity = Vector2.ZERO
		update_slither_visual(delta, Vector2.ZERO)
		update_shelter_fade()
		return

	var direction := Input.get_vector("esquerda", "direita", "frente", "tras")
	velocity = direction.normalized() * SPEED

	var moving := direction != Vector2.ZERO
	if moving:
		slither_time += delta * 9.0

	var previous_position := global_position
	move_and_slide()
	global_position.x = clampf(global_position.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x)
	global_position.y = clampf(global_position.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)
	apply_shelter_constraints(previous_position)
	update_shelter_fade()
	update_slither_visual(delta, direction)

func update_slither_visual(delta: float, direction: Vector2) -> void:
	var moving := direction.length_squared() > 0.001
	var target_strength := 1.0 if moving else 0.0
	slither_strength = move_toward(slither_strength, target_strength, delta * 5.0)
	if moving:
		visual_angle = lerp_angle(visual_angle, direction.angle(), minf(delta * 11.0, 1.0))

	var body_wave := sin(slither_time) * slither_strength
	var perpendicular := Vector2(0.0, 1.0).rotated(visual_angle)
	visual_root.position = perpendicular * body_wave * 1.15
	visual_root.rotation = visual_angle + sin(slither_time * 0.5) * 0.022 * slither_strength
	var stretch := sin(slither_time * 2.0) * 0.018 * slither_strength
	visual_root.scale = Vector2(1.0 + stretch, 1.0 - stretch * 1.4)

	var last_part_index := maxf(articulated_parts.size() - 1.0, 1.0)
	for i in range(articulated_parts.size()):
		var part := articulated_parts[i]
		var tail_factor := float(i) / last_part_index
		var part_phase := slither_time - float(i) * 0.82
		var amplitude := lerpf(0.15, 0.85, tail_factor)
		part.position = articulated_base_positions[i] + Vector2(
			0.0,
			sin(part_phase) * amplitude * slither_strength
		)
		part.rotation = cos(part_phase) * deg_to_rad(lerpf(0.8, 3.2, tail_factor)) * slither_strength

func set_pattern(colors: Array[Color]) -> void:
	pattern_colors = colors.duplicate()
	refresh_pattern_visuals()

func is_inside_shelter() -> bool:
	return current_shelter >= 0

func apply_shelter_constraints(previous_position: Vector2) -> void:
	if current_shelter >= 0:
		keep_player_inside_shelter(SHELTER_ZONES[current_shelter])
		return

	for index in range(SHELTER_ZONES.size()):
		var zone := SHELTER_ZONES[index]
		if not zone.has_point(global_position):
			continue

		var center_y := zone.get_center().y
		var crossed_left_end := previous_position.x <= zone.position.x and global_position.x > zone.position.x
		var crossed_right_end := previous_position.x >= zone.end.x and global_position.x < zone.end.x
		var was_aligned := absf(previous_position.y - center_y) <= SHELTER_OPENING_HALF_HEIGHT
		var is_aligned := absf(global_position.y - center_y) <= SHELTER_OPENING_HALF_HEIGHT
		if (crossed_left_end or crossed_right_end) and was_aligned and is_aligned:
			current_shelter = index
			global_position.y = clampf(
				global_position.y,
				center_y - SHELTER_OPENING_HALF_HEIGHT,
				center_y + SHELTER_OPENING_HALF_HEIGHT
			)
			return

		block_invalid_shelter_entry(zone, previous_position)
		return

func keep_player_inside_shelter(zone: Rect2) -> void:
	var center_y := zone.get_center().y
	global_position.y = clampf(
		global_position.y,
		center_y - SHELTER_OPENING_HALF_HEIGHT,
		center_y + SHELTER_OPENING_HALF_HEIGHT
	)
	if global_position.x <= zone.position.x or global_position.x >= zone.end.x:
		current_shelter = -1

func block_invalid_shelter_entry(zone: Rect2, previous_position: Vector2) -> void:
	if previous_position.x <= zone.position.x:
		global_position.x = zone.position.x - 0.01
	elif previous_position.x >= zone.end.x:
		global_position.x = zone.end.x + 0.01
	elif previous_position.y <= zone.position.y:
		global_position.y = zone.position.y - 0.01
	else:
		global_position.y = zone.end.y + 0.01

func update_shelter_fade() -> void:
	if current_shelter < 0:
		visual_root.modulate.a = 1.0
		return
	var zone := SHELTER_ZONES[current_shelter]
	var depth := minf(global_position.x - zone.position.x, zone.end.x - global_position.x)
	visual_root.modulate.a = 1.0 - clampf(depth / SHELTER_FADE_DISTANCE, 0.0, 1.0)

func refresh_pattern_visuals() -> void:
	if not is_node_ready():
		return
	for i in range(segment_sprites.size()):
		var segment := segment_sprites[i]
		var pattern_index := i + 1
		segment.visible = pattern_index < pattern_colors.size()
		if not segment.visible:
			segment.texture = null
			continue
		var color_key := color_to_key(pattern_colors[pattern_index])
		var segment_number := i + 2
		var segment_path := SKIN_ROOT + "segmento%d_%s.png" % [segment_number, color_key]
		if ResourceLoader.exists(segment_path):
			segment.texture = load(segment_path)
			segment.region_rect = get_segment_region(segment_number, color_key)
			if segment_number == 5:
				# Normaliza vermelho e preto para o mesmo tamanho visual do amarelo.
				var region_size := segment.region_rect.size
				segment.scale = Vector2(
					SEGMENT5_REFERENCE_SCALE.x * SEGMENT5_REFERENCE_REGION.x / region_size.x,
					SEGMENT5_REFERENCE_SCALE.y * SEGMENT5_REFERENCE_REGION.y / region_size.y
				)
		else:
			segment.texture = null
			segment.visible = false
			push_warning("Sprite ausente: %s" % segment_path)
	refresh_head()

func refresh_head() -> void:
	if pattern_colors.is_empty():
		head_sprite.visible = false
		head_sprite.texture = null
		return

	var color_key := color_to_key(pattern_colors.front())
	var file_name: String = {
		"vermelho": "Cabeça_vermelha.png",
		"amarelo": "Cabeca_amarela.png",
		"preto": "Cabeca_preta.png",
	}[color_key]
	var regions := {
		# As cabeças atuais são imagens individuais, não folhas de sprites.
		"vermelho": Rect2(0, 0, 250, 71),
		"amarelo": Rect2(0, 0, 250, 75),
		"preto": Rect2(0, 0, 250, 72),
	}
	var head_path: String = SKIN_ROOT + file_name
	if ResourceLoader.exists(head_path):
		head_sprite.texture = load(head_path)
		head_sprite.region_rect = regions[color_key]
		head_sprite.visible = true
	else:
		head_sprite.texture = null
		head_sprite.visible = false
		push_warning("Sprite ausente: %s" % head_path)

func color_to_key(color: Color) -> String:
	if color.is_equal_approx(Color("f0d45a")):
		return "amarelo"
	if color.is_equal_approx(Color("202225")):
		return "preto"
	return "vermelho"

func get_segment_region(segment_number: int, color_key: String) -> Rect2:
	var regions := {
		2: {
			"amarelo": Rect2(0, 2, 173, 73),
			"preto": Rect2(1, 0, 179, 75),
			"vermelho": Rect2(1, 2, 169, 72),
		},
		3: {
			"amarelo": Rect2(0, 0, 158, 75),
			"preto": Rect2(0, 0, 158, 73),
			"vermelho": Rect2(0, 0, 160, 76),
		},
		4: {
			"amarelo": Rect2(0, 0, 149, 61),
			"preto": Rect2(1, 0, 148, 60),
			"vermelho": Rect2(0, 0, 150, 61),
		},
		5: {
			# Regiões opacas dos novos PNGs, que possuem telas transparentes maiores.
			"amarelo": Rect2(564, 359, 212, 52),
			"preto": Rect2(430, 266, 163, 43),
			"vermelho": Rect2(231, 237, 544, 133),
		},
	}
	return regions[segment_number][color_key]
