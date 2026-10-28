extends CharacterBody2D

const SPEED := 138.0
const JUMP_SPEED := -340.0
const GRAVITY := 560.0
const DISPLAY_HEIGHT := 48.0
const WALK_FPS := 8.0
const AIR_FPS := 9.0
const FLIGHT_DISPLAY_HEIGHT := 46.0
const ASSET_ROOT := "res://Animações/Fase4/Sprites/"
const WALK_ASSET_ROOT := ASSET_ROOT + "andar/"
const FLIGHT_ASSET_ROOT := ASSET_ROOT + "voo/"
const SPRITE_FILES := [
	["tentilhao_alicate.png", "tentilhao_pinca.png", "tentilhao_tesoura.png"],
	["tentilhao_alicate.png", "tentilhao_pinca_longa.png", "tentilhao_colher.png"],
	["tentilhao_pinca.png", "tentilhao_colher.png", "tentilhao_formao.png"],
]
const WALK_SPRITE_FILES := [
	["tentilhao_alicate_andar.png", "tentilhao_pinca_andar.png", "tentilhao_tesoura_andar.png"],
	["tentilhao_alicate_andar.png", "tentilhao_pinca_longa_andar.png", "tentilhao_colher_andar.png"],
	["tentilhao_pinca_andar.png", "tentilhao_colher_andar.png", "tentilhao_formao_andar.png"],
]
const FLIGHT_SPRITE_FILES := [
	["tentilhao_alicate_voo.png", "tentilhao_pinca_voo.png", "tentilhao_tesoura_voo.png"],
	["tentilhao_alicate_voo.png", "tentilhao_pinca_longa_voo.png", "tentilhao_colher_voo.png"],
	["tentilhao_pinca_voo.png", "tentilhao_colher_voo.png", "tentilhao_formao_voo.png"],
]

var pode_mover := false
var island := 0
var beak_kind := 0
var extra_jump_available := false
var facing := 1.0
var flap_time := 0.0
var stunned_time := 0.0
var respawn_position := Vector2(38, 244)
var ground_texture: Texture2D
var flight_texture: Texture2D
var ground_frame_count := 2
var using_flight_texture := false
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
		set_animation_texture(false)
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
		sprite.position.y = 0.0
		return

	sprite.rotation = 0.0
	if on_floor:
		set_animation_texture(false)
		if moving:
			# Quatro quadros mantem a passada legivel e incluem os in-betweens.
			flap_time += delta
			sprite.frame = int(flap_time * WALK_FPS) % sprite.hframes
		else:
			# Parado no chão: frame 0
			sprite.frame = 0
			flap_time = 0.0
		# Bounce leve das patas ao caminhar
		sprite.position.y = sin(flap_time * WALK_FPS * PI) * 1.2 if moving else 0.0
	else:
		if flight_texture:
			set_animation_texture(true)
		else:
			set_animation_texture(false)
		flap_time += delta
		# Quatro poses: neutro, subida, asa no alto e retorno intermediario.
		sprite.frame = int(flap_time * AIR_FPS) % sprite.hframes
		# Pequeno deslocamento vertical evita a sensacao de estagnacao no ar.
		sprite.position.y = sin(flap_time * AIR_FPS * PI * 0.5) * 0.7

func refresh_sprite() -> void:
	if not sprite:
		return
	var ground_path: String = WALK_ASSET_ROOT + str(WALK_SPRITE_FILES[island][beak_kind])
	var fallback_ground_path: String = ASSET_ROOT + str(SPRITE_FILES[island][beak_kind])
	var flight_path: String = FLIGHT_ASSET_ROOT + str(FLIGHT_SPRITE_FILES[island][beak_kind])
	if ResourceLoader.exists(ground_path):
		ground_texture = load(ground_path)
		ground_frame_count = 4
	else:
		ground_texture = load(fallback_ground_path) if ResourceLoader.exists(fallback_ground_path) else null
		ground_frame_count = 2
	flight_texture = load(flight_path) if ResourceLoader.exists(flight_path) else null
	if ground_texture == null:
		sprite.texture = null
		push_warning("Sprite ausente: %s" % fallback_ground_path)
		return
	set_animation_texture(false)
	if flight_texture == null:
		push_warning("Sprite de voo ausente: %s" % flight_path)

func set_animation_texture(flying: bool) -> void:
	if not sprite:
		return
	var target_texture: Texture2D = flight_texture if flying else ground_texture
	if target_texture == null:
		return
	if using_flight_texture == flying and sprite.texture == target_texture:
		return
	using_flight_texture = flying
	sprite.texture = target_texture
	sprite.hframes = 4 if flying else ground_frame_count
	sprite.vframes = 1
	sprite.frame = 0
	var frame_height := target_texture.get_height() / float(sprite.vframes)
	var display_height := FLIGHT_DISPLAY_HEIGHT if flying else DISPLAY_HEIGHT
	sprite.scale = Vector2.ONE * (display_height / frame_height)
