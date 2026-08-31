extends CharacterBody2D

enum Kind { BIRD, OPOSSUM, BADGER }

const HESITATION_ICON := preload("res://Animações/Fase3/Sprites/Icones/icone_hesitacao.png")
const ATTACK_ICON := preload("res://Animações/Fase3/Sprites/Icones/icone_ataque.png")

@export var kind := Kind.BIRD

@onready var body_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_cone: Sprite2D = $VisionCone
@onready var vision_area: Area2D = $VisionArea
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var alert_icon: Sprite2D = $AlertIcon

var state := "watching"
var facing := -1.0
var animation_time := 0.0
var alert_text := ""
var last_alert := ""
var finished_animation := &""

func _ready() -> void:
	body_sprite.animation_finished.connect(on_animation_finished)
	body_sprite.play("walking")
	refresh_alert()
	refresh_visual_state()

func setup(kind_value: Kind) -> void:
	kind = kind_value
	refresh_visual_state()

func _process(delta: float) -> void:
	animation_time += delta
	body_sprite.flip_h = facing < 0.0
	var bob_speed := 7.0 if kind == Kind.BIRD else 3.0
	var bob_amplitude := 1.5 if kind == Kind.BIRD else 0.6
	body_sprite.position.y = sin(animation_time * bob_speed) * bob_amplitude
	vision_cone.position.x = 98.0 * facing
	vision_cone.flip_h = facing > 0.0
	vision_area.scale.x = -1.0 if facing > 0.0 else 1.0
	vision_cone.visible = kind == Kind.BIRD and state != "deterred"
	var desired_animation := &"confused" if kind == Kind.BADGER and state == "confused" else &"walking"
	if body_sprite.animation != desired_animation:
		finished_animation = &""
		body_sprite.play(desired_animation)
	if alert_text != last_alert:
		last_alert = alert_text
		refresh_alert()

func on_animation_finished() -> void:
	finished_animation = body_sprite.animation

func is_animation_finished(animation_name: StringName) -> bool:
	return body_sprite.animation == animation_name and finished_animation == animation_name

func can_see_position(target_position: Vector2) -> bool:
	var distance := global_position.distance_to(target_position)
	if kind == Kind.OPOSSUM:
		return distance < 125.0
	var relative := target_position - global_position
	var forward_distance := relative.x * facing
	if forward_distance < -15.0 or forward_distance > 195.0:
		return false
	var cone_half_height := lerpf(12.0, 68.0, clampf(forward_distance / 195.0, 0.0, 1.0))
	return absf(relative.y) <= cone_half_height

func is_in_attack_range(target_position: Vector2) -> bool:
	var attack_distance := 23.0 if kind == Kind.BADGER else 19.0
	return global_position.distance_to(target_position) < attack_distance

func is_distance_in_attack_range(distance: float) -> bool:
	var attack_distance := 23.0 if kind == Kind.BADGER else 19.0
	return distance < attack_distance

func refresh_visual_state() -> void:
	if not is_node_ready():
		return
	vision_area.visible = kind != Kind.BADGER
	attack_hitbox.visible = true
	vision_cone.visible = kind == Kind.BIRD and state != "deterred"

func refresh_alert() -> void:
	if not is_node_ready():
		return
	alert_icon.visible = not alert_text.is_empty()
	if alert_text == "!":
		alert_icon.texture = HESITATION_ICON
	elif alert_text == "X":
		alert_icon.texture = ATTACK_ICON
