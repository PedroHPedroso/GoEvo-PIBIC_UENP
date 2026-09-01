extends Sprite2D

func set_stage_enabled(enabled: bool) -> void:
	visible = enabled
	for child in get_children():
		if child is Area2D:
			child.collision_layer = 2 if enabled else 0
			child.monitorable = enabled
