extends CharacterBody2D

@export var speed: float = 180.0
@export var direction_change_interval: float = 0.4
@export var vertical_variation: float = 0.1
@export var acceleration: float = 600.0

@onready var texture: Sprite2D = $Mosca
@onready var wall_detector: RayCast2D = $wallDetector

var target_direction: Vector2 = Vector2.LEFT
var change_timer: float = 0.0
var eliminada: bool = false


func _ready() -> void:
	randomize()
	choose_new_direction()


func _physics_process(delta: float) -> void:
	change_timer -= delta

	if change_timer <= 0.0:
		choose_new_direction()

	# Faz a mosca acelerar suavemente na direção escolhida.
	var target_velocity := target_direction * speed

	velocity = velocity.move_toward(
		target_velocity,
		acceleration * delta
	)

	# Muda de direção ao detectar uma parede.
	if wall_detector.is_colliding():
		target_direction.x *= -1.0
		target_direction.y = randf_range(-vertical_variation, vertical_variation)
		target_direction = target_direction.normalized()

		update_detector_direction()

		change_timer = direction_change_interval

	move_and_slide()

	# Caso colida diretamente com alguma superfície,
	# rebate a direção de acordo com a colisão.
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		target_direction = target_direction.bounce(collision.get_normal())
		target_direction = target_direction.normalized()

	update_sprite_direction()


func choose_new_direction() -> void:
	var horizontal_direction := randf_range(-1.0, 1.0)
	var vertical_direction := randf_range(
		-vertical_variation,
		vertical_variation
	)

	# Evita uma direção horizontal quase zerada.
	if abs(horizontal_direction) < 0.3:
		horizontal_direction = 1.0 if horizontal_direction >= 0.0 else -1.0

	target_direction = Vector2(
		horizontal_direction,
		vertical_direction
	).normalized()

	change_timer = randf_range(
		direction_change_interval * 0.6,
		direction_change_interval * 1.4
	)

	update_detector_direction()


func update_detector_direction() -> void:
	if target_direction.x > 0.0:
		wall_detector.target_position.x = abs(
			wall_detector.target_position.x
		)
	else:
		wall_detector.target_position.x = -abs(
			wall_detector.target_position.x
		)


func update_sprite_direction() -> void:
	if abs(velocity.x) > 5.0:
		texture.flip_h = velocity.x > 0.0
		
func receber_ataque() -> bool:
	if eliminada:
		return false

	eliminada = true
	queue_free()

	return true
