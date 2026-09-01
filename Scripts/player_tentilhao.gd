extends CharacterBody2D

const SPEED := 138.0
const JUMP_SPEED := -340.0
const GRAVITY := 560.0
const DISPLAY_HEIGHT := 48.0
const WALK_FPS := 4.0
const AIR_FPS := 5.0
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
var respawn_position := Vector2(38, 244)
@onready var sprite: Sprite2D = $TentilhaoSprite

func _ready() -> void:
	refresh_sprite()

func configure(island_index: int, selected_beak: int) -> void:
	island = island_index
	beak_kind = selected_beak
	extra_jump_available = island >= 1
	refresh_sprite()

func reset_at(spawn_position: Vector2) -> void:
	self.respawn_position = spawn_position
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
		animate_sprite(delta, false, false)
		return

	var direction := Input.get_axis("esquerda", "direita")
	velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 7.0 * delta)
	if absf(direction) > 0.05:
		facing = signf(direction)

	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y += GRAVITY * delta
		if island >= 1 and Input.is_action_pressed("ui_accept") and velocity.y > 70.0:
			velocity.y = move_toward(velocity.y, 70.0, GRAVITY * 1.6 * delta)
	else:
		extra_jump_available = island >= 1

	if Input.is_action_just_pressed("ui_accept"):
		if on_floor:
			velocity.y = JUMP_SPEED
		elif extra_jump_available:
			velocity.y = JUMP_SPEED * 0.88
			extra_jump_available = false

	move_and_slide()
	global_position.x = clampf(global_position.x, 14.0, 626.0)
	if global_position.y > 360.0:
		reset_at(respawn_position)
	animate_sprite(delta, absf(direction) > 0.05, on_floor)

func animate_sprite(delta: float, moving: bool, on_floor: bool) -> void:
	if not sprite:
		return
	sprite.flip_h = facing < 0.0

	if stunned_time > 0.0:
		# Atordoado: frame fixo 0
		sprite.frame = 0
		sprite.rotation = clampf(velocity.y / 1000.0, -0.25, 0.25)
		return

	sprite.rotation = 0.0
	if on_floor:
		if moving:
			# Dois quadros precisam de uma cadência baixa para a passada ser legível.
			flap_time += delta
			sprite.frame = int(flap_time * WALK_FPS) % 2
		else:
			# Parado no chão: frame 0
			sprite.frame = 0
			flap_time = 0.0
		# Bounce leve das patas ao caminhar
		sprite.position.y = sin(flap_time * WALK_FPS * PI) * 1.2 if moving else 0.0
	else:
		flap_time += delta
		sprite.frame = int(flap_time * AIR_FPS) % 2
		sprite.position.y = 0.0

func refresh_sprite() -> void:
	if not sprite:
		return
	var path: String = ASSET_ROOT + str(SPRITE_FILES[island][beak_kind])
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		var frame_height := sprite.texture.get_height() / float(sprite.vframes)
		var display_scale := DISPLAY_HEIGHT / frame_height
		sprite.scale = Vector2.ONE * display_scale
	else:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % path)
