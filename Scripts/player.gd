extends CharacterBody2D

signal moscas_atualizadas(total: int)

const SPEED = 200.0
const JUMP_VELOCITY = -250.0

@onready var animation := $Anim as AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_attack: CollisionShape2D = $hitbox/colliHitbox

var is_jumping: bool = false
var attacking: bool = false
var moscas: int = 0
var facing_direction: int = 1
var hitbox_distance: float

func _ready() -> void:
	# Desabilita a hitbox e guarda a distancia da Hitbox do personagem
	hitbox_attack.set_deferred("disabled",true)
	hitbox_distance = abs(hitbox.position.x)

func _physics_process(delta: float) -> void:
	# GRAVIDADE
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# ATAQUE
	if (Input.is_action_just_pressed("ataque") and not attacking):
		atacar()

	# PULO
	if (Input.is_action_just_pressed("ui_accept") and is_on_floor() and not attacking):
		velocity.y = JUMP_VELOCITY
		is_jumping = true

	elif is_on_floor():
		is_jumping = false

	# MOVIMENTO
	var direction := Input.get_axis("esquerda", "direita")
	
	if direction != 0:
		velocity.x = direction * SPEED
		if direction > 0:
			facing_direction = 1
			animation.flip_h = false
		else:
			facing_direction = -1
			animation.flip_h = true

		# Move a Hitbox junto com a direção do ataque.
		hitbox.position.x = (hitbox_distance * facing_direction)

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# ANIMAÇÕES
	if not attacking:
		if is_jumping:
			animation.play("jump")
		elif direction != 0:
			animation.play("walk")
		else:
			animation.play("idle")
			
	move_and_slide()

# ATAQUE
func atacar() -> void:
	attacking = true
	animation.play("attack")
	hitbox_attack.set_deferred("disabled", false)

# FIM DO ATAQUE
func _on_anim_animation_finished() -> void:
	if animation.animation == "attack":
		attacking = false
		hitbox_attack.set_deferred("disabled", true)
		
# HITBOX ENCONTROU OUTRA AREA
func _on_hitbox_area_entered(area: Area2D) -> void:
	print("Hitbox encontrou: ", area.name)
	
	if not attacking:
		return

	if not area.is_in_group("hurtbox_mosca"):
		return

	var mosca = area.get_parent()
	
	if mosca.has_method("receber_ataque"):
		var eliminou = mosca.receber_ataque()
		
		if eliminou:
			adicionar_mosca()

# CONTADOR
func adicionar_mosca() -> void:
	moscas += 1
	print("Moscas coletadas: ", moscas)
	moscas_atualizadas.emit(moscas)
