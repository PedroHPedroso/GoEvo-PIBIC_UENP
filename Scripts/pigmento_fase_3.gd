extends Node2D

const ASSET_ROOT := "res://Animações/Fase3/Sprites/"

var pigment_color := Color.WHITE
var pigment_name := ""
var checkpoint := 0
var active := true
var bob_time := 0.0
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.name = "PigmentoSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

func setup(color_value: Color, name_value: String, checkpoint_value: int) -> void:
	pigment_color = color_value
	pigment_name = name_value
	checkpoint = checkpoint_value
	refresh_sprite()

func _process(delta: float) -> void:
	if not active:
		return
	bob_time += delta
	if sprite:
		sprite.position.y = sin(bob_time * 3.0) * 2.5

func set_active(value: bool) -> void:
	active = value
	visible = value

func refresh_sprite() -> void:
	if not sprite:
		return
	var color_key := pigment_name.to_lower()
	var path := ASSET_ROOT + "pigmento_%s.png" % color_key
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
