extends Node2D

const ASSET_ROOT := "res://Animações/Fase4/Sprites/"
const BACKGROUNDS := ["ilha_sementes.png", "ilha_cactos.png", "ilha_troncos.png"]

var island := 0
var background: Sprite2D

func _ready() -> void:
	background = Sprite2D.new()
	background.name = "CenarioSprite"
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(background)
	refresh_background()

func set_island(value: int) -> void:
	island = value
	refresh_background()

func refresh_background() -> void:
	if not background:
		return
	var path: String = ASSET_ROOT + str(BACKGROUNDS[island])
	if ResourceLoader.exists(path):
		background.texture = load(path)
	else:
		background.texture = null
		push_warning("Sprite ausente: %s" % path)
