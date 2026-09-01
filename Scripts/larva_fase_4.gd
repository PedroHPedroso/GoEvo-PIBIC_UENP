extends Sprite2D

@export_range(0.0, 2.4, 0.05) var phase_offset := 0.0

const CYCLE_DURATION := 2.4
const VISIBLE_DURATION := 0.82

var active := true
var available := true
var elapsed := 0.0

@onready var visible_sprite: Sprite2D = $Visivel
@onready var hidden_sprite: Sprite2D = $Escondida

func _ready() -> void:
	refresh_sprite()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var next_available := fmod(elapsed + phase_offset, CYCLE_DURATION) < VISIBLE_DURATION
	if next_available != available:
		available = next_available
		refresh_sprite()

func set_stage_enabled(enabled: bool) -> void:
	if enabled:
		active = true
		available = true
		elapsed = 0.0
		visible = true
		set_process(true)
		refresh_sprite()
	else:
		active = false
		visible = false
		set_process(false)

func consume() -> void:
	active = false
	visible = false
	set_process(false)

func refresh_sprite() -> void:
	if visible_sprite:
		visible_sprite.visible = available
	if hidden_sprite:
		hidden_sprite.visible = not available
