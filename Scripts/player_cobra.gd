extends CharacterBody2D

const SPEED := 132.0
const WORLD_BOUNDS := Rect2(18, 96, 1882, 178)
const ASSET_ROOT := "res://Animações/Fase3/Sprites/"

var pode_mover := false
var pattern_colors: Array[Color] = []
var facing := 1.0
var slither_time := 0.0
var visual_root: Node2D
var sprite: Sprite2D
var band_sprites: Array[Sprite2D] = []

func _ready() -> void:
	visual_root = Node2D.new()
	visual_root.name = "CobraVisual"
	add_child(visual_root)
	sprite = Sprite2D.new()
	sprite.name = "CobraSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_root.add_child(sprite)
	for i in range(5):
		var band := Sprite2D.new()
		band.name = "Faixa%d" % (i + 1)
		band.position = Vector2(20.0 - i * 12.0, 0)
		band.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		band.visible = false
		visual_root.add_child(band)
		band_sprites.append(band)
	refresh_sprite()

func _physics_process(delta: float) -> void:
	if not pode_mover:
		velocity = Vector2.ZERO
		return

	var direction := Input.get_vector("esquerda", "direita", "frente", "tras")
	velocity = direction.normalized() * SPEED
	if absf(direction.x) > 0.05:
		facing = signf(direction.x)
	if direction != Vector2.ZERO:
		slither_time += delta * 9.0
	move_and_slide()
	global_position.x = clampf(global_position.x, WORLD_BOUNDS.position.x, WORLD_BOUNDS.end.x)
	global_position.y = clampf(global_position.y, WORLD_BOUNDS.position.y, WORLD_BOUNDS.end.y)
	if visual_root:
		visual_root.scale.x = facing
		visual_root.rotation = sin(slither_time) * 0.035
		visual_root.position.y = sin(slither_time * 0.65) * 1.5

func set_pattern(colors: Array[Color]) -> void:
	pattern_colors = colors.duplicate()
	refresh_sprite()

func refresh_sprite() -> void:
	if not sprite:
		return
	var path := ASSET_ROOT + "cobra_base.png"
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
	for i in range(band_sprites.size()):
		var band := band_sprites[i]
		band.visible = i < pattern_colors.size()
		if not band.visible:
			continue
		var color_name := "vermelha"
		if pattern_colors[i].is_equal_approx(Color("f0d45a")):
			color_name = "amarela"
		elif pattern_colors[i].is_equal_approx(Color("202225")):
			color_name = "preta"
		var band_path := ASSET_ROOT + "faixa_%s.png" % color_name
		if ResourceLoader.exists(band_path):
			band.texture = load(band_path)
		else:
			band.texture = null
			push_warning("Sprite ausente: %s" % band_path)
