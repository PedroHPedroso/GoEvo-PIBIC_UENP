@tool
extends StaticBody2D

@export var size := Vector2.ONE:
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		update_collision_shape()

func _ready() -> void:
	update_collision_shape()

func setup(rect: Rect2) -> void:
	position = rect.get_center()
	size = rect.size

func set_stage_enabled(enabled: bool) -> void:
	visible = enabled
	collision_layer = 2 if enabled else 0

func update_collision_shape() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision_shape:
		return
	var rectangle := collision_shape.shape as RectangleShape2D
	if not rectangle:
		rectangle = RectangleShape2D.new()
		rectangle.resource_local_to_scene = true
		collision_shape.shape = rectangle
	rectangle.size = size
