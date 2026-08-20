extends Node2D

const ASSET_ROOT := "res://Animações/Fase3/Sprites/"

func _ready() -> void:
	add_sprite("cenario_trilha.png", Vector2.ZERO, false, "CenarioTrilha")
	add_sprite("tronco_abrigo.png", Vector2(1570, 229), true, "Abrigo1")
	var second_shelter := add_sprite("tronco_abrigo.png", Vector2(1738, 127), true, "Abrigo2")
	if second_shelter:
		second_shelter.scale = Vector2(0.82, 0.82)
	add_sprite("clareira_final.png", Vector2(1870, 185), true, "ClareiraFinal")

func add_sprite(file_name: String, sprite_position: Vector2, centered: bool, node_name: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.position = sprite_position
	sprite.centered = centered
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var path := ASSET_ROOT + file_name
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("Sprite ausente: %s" % path)
	add_child(sprite)
	return sprite
