extends Node2D

enum FoodKind { SEED }

const ASSET_ROOT := "res://Animações/Fase4/Sprites/"
const FOOD_FILES := ["semente_dura.png"]
const DISPLAY_HEIGHTS := [24.0]

var kind := FoodKind.SEED
var active := true
var phase_offset := 0.0
var elapsed := 0.0
@onready var sprite: Sprite2D = $RecursoSprite

func _ready() -> void:
	refresh_sprite()

func setup(food_kind: FoodKind, offset: float = 0.0) -> void:
	kind = food_kind
	phase_offset = offset
	refresh_sprite()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	if sprite:
		sprite.position.y = sin(elapsed * 2.5 + phase_offset) * 1.5

func consume() -> void:
	active = false
	visible = false

func refresh_sprite() -> void:
	if not sprite:
		return
	var file_name: String = FOOD_FILES[kind]
	var path := ASSET_ROOT + file_name
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		var display_scale: float = DISPLAY_HEIGHTS[kind] / sprite.texture.get_height()
		sprite.scale = Vector2.ONE * display_scale
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
