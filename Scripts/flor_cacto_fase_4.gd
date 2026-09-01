extends Sprite2D

@export_range(0.0, TAU, 0.05) var phase_offset := 0.0
@export_range(0.0, 4.0, 0.1) var float_amplitude := 1.5

const FLOAT_SPEED := 2.5

var active := true
var elapsed := 0.0

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	offset.y = sin(elapsed * FLOAT_SPEED + phase_offset) * float_amplitude

func set_stage_enabled(enabled: bool) -> void:
	active = enabled
	elapsed = 0.0
	offset.y = 0.0
	visible = enabled
	set_process(enabled)

func consume() -> void:
	active = false
	visible = false
	set_process(false)
