extends CharacterBody2D

const SPEED := 138.0
const JUMP_SPEED := -225.0
const GRAVITY := 560.0
const ASSET_ROOT := "res://Animações/Fase4/Sprites/"
const SPRITE_FILES := [
	["tentilhao_alicate.png", "tentilhao_pinca.png", "tentilhao_tesoura.png"],
	["tentilhao_alicate.png", "tentilhao_pinca_longa.png", "tentilhao_colher.png"],
	["tentilhao_pinca.png", "tentilhao_colher.png", "tentilhao_formao.png"],
]

var pode_mover := false
var island := 0
var beak_kind := 0
var extra_jump_available := false
var facing := 1.0
var flap_time := 0.0
var stunned_time := 0.0
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.name = "TentilhaoSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	refresh_sprite()

func configure(island_index: int, selected_beak: int) -> void:
	island = island_index
	beak_kind = selected_beak
	extra_jump_available = island >= 1
	refresh_sprite()

func reset_at(spawn_position: Vector2) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	extra_jump_available = island >= 1

func stun(push_direction: float) -> void:
	stunned_time = 0.45
	velocity = Vector2(-push_direction * 105.0, -105.0)

func _physics_process(delta: float) -> void:
	if not pode_mover:
		velocity = Vector2.ZERO
		return

	if stunned_time > 0.0:
		stunned_time -= delta
		velocity.y += GRAVITY * delta
		move_and_slide()
		animate_sprite()
		return

	var direction := Input.get_axis("esquerda", "direita")
	velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 7.0 * delta)
	if absf(direction) > 0.05:
		facing = signf(direction)
		flap_time += delta * 9.0

	if not is_on_floor():
		velocity.y += GRAVITY * delta
		if island >= 1 and Input.is_action_pressed("ui_accept") and velocity.y > 70.0:
			velocity.y = move_toward(velocity.y, 70.0, GRAVITY * 1.6 * delta)
	else:
		extra_jump_available = island >= 1

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_SPEED
		elif extra_jump_available:
			velocity.y = JUMP_SPEED * 0.88
			extra_jump_available = false

	move_and_slide()
	global_position.x = clampf(global_position.x, 14.0, 626.0)
	if global_position.y > 360.0:
		reset_at(Vector2(48, 220))
	animate_sprite()

func animate_sprite() -> void:
	if not sprite:
		return
	sprite.flip_h = facing < 0.0
	sprite.position.y = sin(flap_time) * 1.8
	sprite.rotation = clampf(velocity.y / 1400.0, -0.12, 0.12)

func refresh_sprite() -> void:
	if not sprite:
		return
	var path: String = ASSET_ROOT + str(SPRITE_FILES[island][beak_kind])
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
