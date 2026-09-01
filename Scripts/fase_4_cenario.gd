extends Node2D

@onready var backgrounds: Array[Sprite2D] = [
	$IlhaSementes,
	$IlhaCactos,
	$IlhaTroncos,
]

var island := 0

func _ready() -> void:
	refresh_background()

func set_island(value: int) -> void:
	island = clampi(value, 0, backgrounds.size() - 1)
	refresh_background()

func refresh_background() -> void:
	if not is_node_ready():
		return
	for index in range(backgrounds.size()):
		backgrounds[index].visible = index == island
