extends Node2D

enum Kind { BIRD, OPOSSUM, BADGER }

const ASSET_ROOT := "res://Animações/Fase3/Sprites/"
const BODY_FILES := ["predador_ave.png", "predador_gamba.png", "predador_texugo.png"]

var kind := Kind.BIRD
var state := "watching"
var facing := -1.0
var animation_time := 0.0
var alert_text := ""
var body_sprite: Sprite2D
var alert_sprite: Sprite2D
var cone_sprite: Sprite2D
var last_alert := ""

func _ready() -> void:
	cone_sprite = create_sprite("ConeVisao")
	cone_sprite.position = Vector2(-98, 3)
	cone_sprite.z_index = -1
	body_sprite = create_sprite("PredadorSprite")
	alert_sprite = create_sprite("AlertaSprite")
	alert_sprite.position = Vector2(0, -31)
	refresh_body()

func setup(kind_value: Kind) -> void:
	kind = kind_value
	refresh_body()

func _process(delta: float) -> void:
	animation_time += delta
	if body_sprite:
		body_sprite.flip_h = facing > 0.0
		body_sprite.position.y = sin(animation_time * (7.0 if kind == Kind.BIRD else 3.0)) * (2.0 if kind == Kind.BIRD else 0.8)
	if cone_sprite:
		cone_sprite.visible = kind == Kind.BIRD and state != "deterred"
	if alert_text != last_alert:
		last_alert = alert_text
		refresh_alert()

func create_sprite(node_name: String) -> Sprite2D:
	var new_sprite := Sprite2D.new()
	new_sprite.name = node_name
	new_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(new_sprite)
	return new_sprite

func refresh_body() -> void:
	if not body_sprite:
		return
	set_texture(body_sprite, BODY_FILES[kind])
	if cone_sprite:
		set_texture(cone_sprite, "cone_visao.png")

func refresh_alert() -> void:
	if not alert_sprite:
		return
	alert_sprite.visible = not alert_text.is_empty()
	if alert_text == "!":
		set_texture(alert_sprite, "icone_hesitacao.png")
	elif alert_text == "X":
		set_texture(alert_sprite, "icone_ataque.png")

func set_texture(target: Sprite2D, file_name: String) -> void:
	var path := ASSET_ROOT + file_name
	if ResourceLoader.exists(path):
		target.texture = load(path)
	else:
		target.texture = null
		push_warning("Sprite ausente: %s" % path)
