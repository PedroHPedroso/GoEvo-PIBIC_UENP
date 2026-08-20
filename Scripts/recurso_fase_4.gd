extends Node2D

enum FoodKind { SEED, NECTAR, LARVA }

const ASSET_ROOT := "res://Animações/Fase4/Sprites/"
const FOOD_FILES := ["semente_dura.png", "flor_nectar.png", "larva_visivel.png"]

var kind := FoodKind.SEED
var active := true
var available := true
var phase_offset := 0.0
var elapsed := 0.0
var sprite: Sprite2D
var last_available := true

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.name = "RecursoSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	refresh_sprite()

func setup(food_kind: FoodKind, offset: float = 0.0) -> void:
	kind = food_kind
	phase_offset = offset
	refresh_sprite()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if kind == FoodKind.LARVA:
		available = fmod(elapsed + phase_offset, 2.4) < 0.82
		if available != last_available:
			last_available = available
			refresh_sprite()
	if sprite and kind != FoodKind.LARVA:
		sprite.position.y = sin(elapsed * 2.5 + phase_offset) * 1.5

func consume() -> void:
	active = false
	visible = false

func refresh_sprite() -> void:
	if not sprite:
		return
	var file_name: String = FOOD_FILES[kind]
	if kind == FoodKind.LARVA and not available:
		file_name = "larva_escondida.png"
	var path := ASSET_ROOT + file_name
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
